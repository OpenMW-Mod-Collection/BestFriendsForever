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
    for followerId, notifList in pairs(notifListPerFollower) do
        if #notifList == 0 then
            notifListPerFollower[followerId] = nil
        else
            local notif = table.remove(notifList)
            notif.actor:sendEvent("GoodCompany_followerDown", notif)
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

local function followerDown(data)
    -- building notification list
    -- to switch aggro on all currently active actors (if there is)
    -- from downed actor to the player
    notifListPerFollower[data.follower.id] = {}
    local notifList = notifListPerFollower[data.follower.id]
    local state = followers[data.follower.id]
    local leader = state.superLeader or state.leader

    for _, actor in pairs(nearby.actors) do
        if not followers[actor.id] and actor.id ~=  self.id then
            notifList[#notifList + 1] = {
                follower = data.follower,
                leader = leader,
                actor = actor,
            }
        end
    end
end

local function followerUp(data)
    notifListPerFollower[data.follower.id] = nil
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
