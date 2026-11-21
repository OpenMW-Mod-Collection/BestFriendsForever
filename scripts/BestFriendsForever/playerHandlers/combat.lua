---@diagnostic disable: undefined-field
---@omw-context player
local I = require("openmw.interfaces")
local self = require("openmw.self")

local CombatTracker = require("scripts.BestFriendsForever.utils.combatTracker")

local combatTracker
local downedFollowers = {}
local followers = I.FollowerDetectionUtil.getFollowerList()

local function isPlayerGroupInCombat()
    local inCombat = false
    combatTracker.forEach(function(actor, targets)
        if actor.id == self.id or followers[actor.id] then
            inCombat = true
            return
        end

        for _, target in ipairs(targets) do
            if target.id == self.id or followers[target.id] then
                inCombat = true
                return
            end
        end
    end)
    return inCombat
end

local function onCombatLeave()
    if isPlayerGroupInCombat() then
        return
    end

    for _, follower in pairs(downedFollowers) do
        if follower:isValid() then
            follower:sendEvent("BestFriendsForever_combatEnded")
        end
    end
end

local function onCombatEnter()
    if not isPlayerGroupInCombat() then
        return
    end

    for _, follower in pairs(downedFollowers) do
        if follower:isValid() then
            follower:sendEvent("BestFriendsForever_setCombatStatus", true)
        end
    end
end

local function notifyCombatants(data, eventName)
    local follower = data.follower
    local state = followers[follower.id]
    local leader = state and state.rootLeader or data.leader

    combatTracker.prune()
    combatTracker.forEach(function(actor)
        if actor.id ~= self.id and not followers[actor.id] then
            actor:sendEvent(eventName, {
                actor = actor,
                follower = follower,
                leader = leader,
            })
        end
    end)
end

local function followerDown(data, updateCombatStatus)
    downedFollowers[data.follower.id] = data.follower
    if updateCombatStatus ~= false then
        data.follower:sendEvent(
            "BestFriendsForever_setCombatStatus",
            isPlayerGroupInCombat()
        )
    end
    notifyCombatants(data, "BestFriendsForever_followerDown")
end

local function followerUp(data)
    downedFollowers[data.follower.id] = nil
    notifyCombatants(data, "BestFriendsForever_followerUp")
end

local function onFollowerListUpdated(data)
    followers = data
end

local function onLoad(data)
    downedFollowers = data.downedFollowers or downedFollowers

    for _, downedFollower in pairs(downedFollowers) do
        followerDown({ follower = downedFollower }, false)
    end
    onCombatEnter()
end

combatTracker = CombatTracker.new {
    onEnter = onCombatEnter,
    onLeave = onCombatLeave,
}

return {
    eventHandlers = {
        OMWMusicCombatTargetsChanged = combatTracker.onCombatTargetsChanged,
        BestFriendsForever_followerDown = followerDown,
        BestFriendsForever_followerUp = followerUp,
    },
    onFollowerListUpdated = onFollowerListUpdated,
    frame = function(dt)
        combatTracker.onUpdate(dt)
    end,
    onSave = function()
        return {
            downedFollowers = downedFollowers,
        }
    end,
    onLoad = onLoad,
    interface = {
        getDownedFollowers = function()
            return downedFollowers
        end,
    },
}
