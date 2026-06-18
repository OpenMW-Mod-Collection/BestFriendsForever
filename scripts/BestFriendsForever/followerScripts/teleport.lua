---@diagnostic disable: undefined-field, assign-type-mismatch
---@omw-context local
local self = require("openmw.self")
local core = require("openmw.core")

local raycast = require("scripts.BestFriendsForever.utils.raycast")

if self.type.isDead(self) then return end

---@type GameObject
local leader

local BEHIND_DISTANCE = 300

local function onInactive()
    if not leader then return end

    -- wrapping it into a pcall in case
    -- they're being teleported on the same frame
    -- or they're a summon
    local eventData = {
        actor = self,
        cell = leader.cell.name,
        pos = raycast.findSafeTpPos(leader, BEHIND_DISTANCE),
        options = { onGround = true }
    }
    core.sendGlobalEvent("BestFriendsForever_teleport", eventData)
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
