---@diagnostic disable: undefined-field, assign-type-mismatch, different-requires
---@omw-context local
local self = require("openmw.self")
local core = require("openmw.core")
local time = require("openmw_aux.time")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")

if self.type.isDead(self) then return end

---@type GameObject
local leader

local settings = storage.globalSection("SettingsGoodCompany_catchUp")
local speed = self.type.stats.attributes.speed(self)
local BOOST_START_DIST = settings:get("startDist")
local BOOST_MAX_DIST = settings:get("maxDist")
local MAX_SPEED_BOOST = settings:get("maxSpeed")
local LERP_SPEED = settings:get("lerpSpeed")

local currentBoost = 0
local targetBoost = 0 -- written by the timer, read by onUpdate

local function updateTarget()
    if not leader then return end

    local distance = (self.position - leader.position):length()

    if distance <= BOOST_START_DIST then
        targetBoost = 0
    elseif distance >= BOOST_MAX_DIST then
        targetBoost = MAX_SPEED_BOOST
    else
        local t = (distance - BOOST_START_DIST) / (BOOST_MAX_DIST - BOOST_START_DIST)
        targetBoost = t * MAX_SPEED_BOOST
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
    1 * time.second,
    {
        initialDelay = math.random(),
        type = time.SimulationTime,
    }
)

local function onUpdate()
    if not leader then return end

    if I.AI.getActiveTarget("Combat") then
        onCleanup()
        return
    end

    -- Lerp currentBoost toward targetBoost every frame
    currentBoost = currentBoost + (targetBoost - currentBoost) * LERP_SPEED
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
