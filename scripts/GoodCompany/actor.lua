---@omw-context local
local I = require("openmw.interfaces")

local downedFollowersToLeaders = {}

-- I have to continuosly check it
-- so they don't change back to attacking the downed follower
local function onUpdate()
    if not next(downedFollowersToLeaders) then return end
    local target = I.AI.getActiveTarget("Combat")
    if target and downedFollowersToLeaders[target.id] then
        I.AI.removePackages("Combat")
        I.AI.startPackage {
            type = "Combat",
            target = downedFollowersToLeaders[target.id],
            cancelOthers = true,
        }
    end
end

local function followerDown(data)
    downedFollowersToLeaders[data.follower.id] = data.leader
    local target = I.AI.getActiveTarget("Combat")
    if target and data.follower.id == target.id then
        I.AI.removePackages("Combat")
        I.AI.startPackage {
            type = "Combat",
            target = data.leader,
            cancelOthers = true,
        }
    end
end

local function onSave()
    return {
        downedFollowersToLeaders = downedFollowersToLeaders
    }
end

local function onLoad(data)
    if not data then return end
    downedFollowersToLeaders = data.downedFollowersToLeaders or downedFollowersToLeaders
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
        onInactive = function()
            downedFollowersToLeaders = {}
        end,
    },
    eventHandlers = {
        Died = function()
            downedFollowersToLeaders = {}
        end,
        GoodCompany_followerDown = followerDown,
    }
}
