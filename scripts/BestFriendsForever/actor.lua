---@omw-context local
local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local async = require("openmw.async")

local settingsCache = require("scripts.BestFriendsForever.utils.settingsCache")

-- currently here's only logic for switching enemy aggro
-- from downed followers to their leader

-- Variables
local noOneDowned = true
local downedFollowersToLeaders = {}
local settings

-- I have to continuosly check it
-- so they don't change back to attacking the downed follower
local function onUpdate()
    if noOneDowned then
        return
    end
    local target = I.AI.getActiveTarget("Combat")
    if target then
        local leader = downedFollowersToLeaders[target.id]
        if leader and leader.id ~= target.id then
            I.AI.removePackages("Combat")
            I.AI.startPackage {
                type = "Combat",
                target = leader,
                cancelOthers = true,
            }
        end
    end
end

local function followerDown(data)
    if not settings.changeAggro then
        return
    end
    downedFollowersToLeaders[data.follower.id] = data.leader
    noOneDowned = false
end

local function followerUp(data)
    downedFollowersToLeaders[data.follower.id] = nil
    noOneDowned = not next(downedFollowersToLeaders)
end

local function onSave()
    return {
        downedFollowersToLeaders = downedFollowersToLeaders,
    }
end

local function onLoad(data)
    data = data or {}
    downedFollowersToLeaders = data.downedFollowersToLeaders or downedFollowersToLeaders
    noOneDowned = not next(downedFollowersToLeaders)
end

-- Initialization
settings = settingsCache.new(storage.globalSection("SettingsBestFriendsForever_immortality"), async, function(key)
    if key == "changeAggro" and not settings[key] then
        downedFollowersToLeaders = {}
        noOneDowned = true
    end
end)

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
        onInactive = function()
            downedFollowersToLeaders = {}
            noOneDowned = true
        end,
    },
    eventHandlers = {
        Died = function()
            downedFollowersToLeaders = {}
            noOneDowned = true
        end,
        BestFriendsForever_followerDown = followerDown,
        BestFriendsForever_followerUp = followerUp,
    },
}
