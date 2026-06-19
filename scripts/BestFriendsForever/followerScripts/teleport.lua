---@diagnostic disable: undefined-field, assign-type-mismatch
---@omw-context local
local self = require("openmw.self")
local core = require("openmw.core")

---@type GameObject
local leader

local function onInactive()
    if not leader then return end
    leader:sendEvent("BestFriendsForever_followerUnloaded", self)
end

local function onSave()
    return {
        leader = leader,
    }
end

local function onLoad(data)
    if not data then return end
    leader = data.leader or leader
end

return {
    engineHandlers = {
        onInit = function(data)
            leader = data.leader
        end,
        onInactive = onInactive,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        Died = function()
            core.sendGlobalEvent("BestFriendsForever_detachScript", {
                actor = self,
                script = "scripts/BestFriendsForever/followerScripts/teleport.lua"
            })
        end,
    }
}
