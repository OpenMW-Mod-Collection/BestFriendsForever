---@omw-context player
local nearby = require("openmw.nearby")
local self = require("openmw.self")

local deps = require("scripts.BoonsAndBurdens.utils.dependencies")
deps.checkAll("Good Company", {
    {
        plugin = "FollowerDetectionUtil.omwscripts",
        interface = true,
    },
    {
        plugin = "h3lp_yours3lf.omwscripts",
        interface = true,
    }
})

local inCombat = false
local combatTargets = {}
local followers = {}
local notifListPerFollower = {}

local function onUpdate()
    -- sparce notification sending
    -- for enemy aggro redirection
    for followerId, notifList in pairs(notifListPerFollower) do
        if #notifList == 0 then
            notifListPerFollower[followerId] = nil
        else
            local notif = table.remove(notifList)
            notif.actor:sendEvent(notif.eventName, notif)
        end
    end
end

local function notifyFollowers(event, data)
    for _, fState in pairs(followers) do
        fState.actor:sendEvent(event, data)
    end
end

local function combatTargetAdded(actor)
    combatTargets[actor.id] = true
    if not inCombat then
        notifyFollowers("GoodCompany_combatMode", true)
    end
    inCombat = true
end

local function combatTargetRemoved(actor)
    combatTargets[actor.id] = nil
    local currentlyInComabt = next(combatTargets) == true
    if not currentlyInComabt then
        notifyFollowers("GoodCompany_combatMode", false)
    end
    inCombat = currentlyInComabt
end

local function fillNotifList(follower, eventName)
    notifListPerFollower[follower.id] = {}
    local notifList = notifListPerFollower[follower.id]
    local state = followers[follower.id]
    local leader = state.superLeader or state.leader

    for _, actor in pairs(nearby.actors) do
        if not followers[actor.id] and actor.id ~=  self.id then
            notifList[#notifList + 1] = {
                eventName = eventName,
                follower = follower,
                leader = leader,
                actor = actor,
            }
        end
    end
end

local function followerDown(data)
    fillNotifList(data.follower, "GoodCompany_followerDown")
end

local function followerUp(data)
    fillNotifList(data.follower, "GoodCompany_followerUp")
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = {
        FDU_UpdateFollowerList = function(data)
            followers = data.followers
        end,
        S3CombatTargetAdded = combatTargetAdded,
        S3CombatTargetRemoved = combatTargetRemoved,
        GoodCompany_followerDown = followerDown,
        GoodCompany_followerUp = followerUp,
    }
}
