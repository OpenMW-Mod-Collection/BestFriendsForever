---@diagnostic disable: undefined-field, assign-type-mismatch, different-requires, param-type-mismatch, need-check-nil
---@omw-context local
local I = require("openmw.interfaces")
local async = require("openmw.async")
local core = require("openmw.core")
local self = require("openmw.self")
local storage = require("openmw.storage")
local types = require("openmw.types")

local settingsCache = require("scripts.BestFriendsForever.utils.settingsCache")

---@type openmw.GObject|nil
local leader
local leaderSpeed
local selfSpeed = types.Actor.stats.attributes.speed(self)
local settings
local updateAccumulator
local lastBoost = 0

local function getTargetBoost()
    if not leader or not leader:isValid() then
        return 0
    end

    local distance = (self.position - leader.position):length()
    local distances = settings.distances

    if distance <= distances.startDist then
        return 0
    elseif distance >= distances.maxDist then
        return leaderSpeed.modified * 1.5
    else
        local t = (distance - distances.startDist)
            / (distances.maxDist - distances.startDist)
        return t * leaderSpeed.modified * 1.5
    end
end

local function setModifier(value)
    if lastBoost == value then
        return
    end
    if self:isValid() then
        selfSpeed.modifier = value
    end
    lastBoost = value
end

local function onCleanup()
    setModifier(0)
end

local function onUpdate(dt)
    if not leader then
        return
    end

    if I.AI.getActiveTarget("Combat") then
        onCleanup()
        return
    end

    updateAccumulator = updateAccumulator + dt
    if updateAccumulator <= settings.updateInterval then
        return
    end
    updateAccumulator = 0

    setModifier(getTargetBoost())
end

local function onSave()
    return {
        leader = leader,
    }
end

local function onLoad(data)
    data = data or {}
    leader = data.leader or leader
    leaderSpeed = types.Actor.stats.attributes.speed(leader)
end

settings = settingsCache.new(
    storage.globalSection("SettingsBestFriendsForever_catchUp"),
    async
)
updateAccumulator = settings.updateInterval

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
                script = "scripts/BestFriendsForever/followerScripts/catchUp.lua",
            })
        end,
    },
}
