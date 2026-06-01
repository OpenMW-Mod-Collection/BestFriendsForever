---@diagnostic disable: undefined-field, assign-type-mismatch, different-requires
---@omw-context local
local self = require("openmw.self")
local core = require("openmw.core")
local time = require("openmw_aux.time")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local async = require("openmw.async")

local settingsCache = require("scripts.GoodCompany.utils.settingsCache")

if self.type.isDead(self) then return end

---@type GameObject
local leader

local settings = settingsCache.new(
    storage.globalSection("SettingsGoodCompany_catchUp"),
    async
)
local speed = self.type.stats.attributes.speed(self)

local currentBoost = 0
local targetBoost = 0 -- written by the timer, read by onUpdate

local function updateTarget()
    if not leader then return end

    local distance = (self.position - leader.position):length()

    if distance <= settings.startDist then
        targetBoost = 0
    elseif distance >= settings.maxDist then
        targetBoost = settings.maxSpeed
    else
        local t = (distance - settings.startDist) / (settings.maxDist - settings.startDist)
        targetBoost = t * settings.maxSpeed
    end
end

local function onCleanup()
    if self:isValid() then
        speed.modifier = 0
    end
end

-- Timer started at init time, as required by runRepeatedly
local stopTimer = time.runRepeatedly(
    updateTarget,
    .25,
    { initialDelay = math.random() }
)

local function onUpdate()
    if not leader then return end

    if I.AI.getActiveTarget("Combat") then
        onCleanup()
        return
    end

    -- Lerp currentBoost toward targetBoost every frame
    currentBoost = currentBoost + (targetBoost - currentBoost) * settings.lerpSpeed
    if math.abs(currentBoost) < 0.5 then currentBoost = 0 end
    speed.modifier = currentBoost
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
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        Died = function()
            stopTimer()
            onCleanup()
            core.sendGlobalEvent("GoodCompany_detachScript", {
                actor = self,
                script = "scripts/GoodCompany/followerScripts/catchUp.lua"
            })
        end,
    }
}
