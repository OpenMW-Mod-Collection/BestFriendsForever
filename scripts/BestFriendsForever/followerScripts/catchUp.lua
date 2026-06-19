---@diagnostic disable: undefined-field, assign-type-mismatch, different-requires, param-type-mismatch
---@omw-context local
local self = require("openmw.self")
local core = require("openmw.core")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local async = require("openmw.async")
local types = require("openmw.types")

local settingsCache = require("scripts.BestFriendsForever.utils.settingsCache")

---@type GameObject
local leader
local leaderSpeed
local selfSpeed = types.Actor.stats.attributes.speed(self)

local settings = settingsCache.new(
    storage.globalSection("SettingsBestFriendsForever_catchUp"),
    async
)

local function getTargetBoost()
    if not leader then return 0 end

    local distance = (self.position - leader.position):length()

    if distance <= settings.startDist then
        return 0
    elseif distance >= settings.maxDist then
        return leaderSpeed.modified * 1.5
    else
        local t = (distance - settings.startDist) / (settings.maxDist - settings.startDist)
        return t * leaderSpeed.modified * 1.5
    end
end

local function onCleanup()
    if self:isValid() then
        selfSpeed.modifier = 0
    end
end

local function onUpdate(dt)
    if not leader then return end

    if I.AI.getActiveTarget("Combat") then
        onCleanup()
        return
    end

    selfSpeed.modifier = getTargetBoost()
end

local function onSave()
    return {
        leader = leader,
    }
end

local function onLoad(data)
    if not data then return end
    leader = data.leader or leader
    leaderSpeed = types.Actor.stats.attributes.speed(leader)
end

return {
    engineHandlers = {
        onInit = function(data)
            leader = data.leader
            leaderSpeed = types.Actor.stats.attributes.speed(leader)
        end,
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        Died = function()
            onCleanup()
            core.sendGlobalEvent("BestFriendsForever_detachScript", {
                actor = self,
                script = "scripts/BestFriendsForever/followerScripts/catchUp.lua"
            })
        end,
    }
}
