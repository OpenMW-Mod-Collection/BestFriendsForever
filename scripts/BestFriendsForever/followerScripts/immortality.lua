---@diagnostic disable: undefined-field, param-type-mismatch, redundant-parameter, assign-type-mismatch
---@omw-context local
local self = require("openmw.self")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local async = require("openmw.async")
local types = require("openmw.types")

local settingsCache = require("scripts.BestFriendsForever.utils.settingsCache")
local injuries = require("scripts.BestFriendsForever.common.injuries")

local immortalitySection = storage.globalSection("SettingsBestFriendsForever_immortality")
local l10n = core.l10n("BestFriendsForever_messages")
local selfName = self.type.records[self.recordId].name
local SCRIPT_PATH = "scripts/BestFriendsForever/followerScripts/immortality.lua"

local settings
local selfEffects = types.Actor.activeEffects(self)
local selfActiveSpells = types.Actor.activeSpells(self)
local health = self.type.stats.dynamic.health(self)
local fatigue = self.type.stats.dynamic.fatigue(self)
local eventData = {
    follower = self,
    leader = nil,
}
local dead = types.Actor.isDead(self)
local down = false
local dying = false
local leader
local reviveTimerStarted = false
local revivalTimeRemaining
local combatActive = false

local applyInjuryOutcome

----------------------------------------------------------------------
-- Main
----------------------------------------------------------------------

local function isCommanded()
    local hasEffect = selfEffects:getEffect(core.magic.EFFECT_TYPE.CommandCreature).magnitude > 0
        or selfEffects:getEffect(core.magic.EFFECT_TYPE.CommandHumanoid).magnitude > 0
    return hasEffect and settings.ingoreCommanded
end

local function dieForReal()
    dying = true
    down = false

    -- The Died handler takes care of the teleport script.
    core.sendGlobalEvent("BestFriendsForever_detachScript", {
        actor = self,
        script = SCRIPT_PATH,
    })
    health.current = 0
end

---@return boolean  false when death was committed.
local function selfDown()
    if not applyInjuryOutcome() then
        return false
    end

    down = true
    self:sendEvent("BestFriendsForever_followerDown", eventData)
    leader:sendEvent("BestFriendsForever_followerDown", eventData)
    core.sendGlobalEvent("BestFriendsForever_followerDown", eventData)
    leader:sendEvent("ShowMessage", {
        message = l10n("msg_followerDown", { npc_name = selfName }),
    })
    return true
end

local function revive()
    reviveTimerStarted = false
    revivalTimeRemaining = nil
    down = false

    self:enableAI(true)
    health.current = settings.threshold
    fatigue.current = 1

    -- stop combat because if immortality was triggered due to infighting
    -- they would have a chance to remove their aggro
    I.AI.removePackages("Combat")

    leader:sendEvent("BestFriendsForever_followerUp", eventData)
    core.sendGlobalEvent("BestFriendsForever_followerUp", eventData)
end

local function setCombatStatus(status)
    -- don't loop please
    local target = I.AI.getActiveTarget("Combat")
    if target and target.id == leader.id then
        return
    end
    combatActive = status
end

local function onCombatEnded()
    combatActive = false
    if down then
        reviveTimerStarted = false
        revive()
    end
end

local function onUpdate(dt)
    if dying then
        return
    end

    if not down then
        if health.current < settings.threshold and not isCommanded() then
            selfDown()
        end
    elseif down and not combatActive then
        revive()
    else
        health.current = 10000
        fatigue.current = -100

        if not reviveTimerStarted then
            self:enableAI(false)
            reviveTimerStarted = true
            if not settings.waitUntilCombatEnds then
                revivalTimeRemaining = settings.upDelay
            end
        elseif revivalTimeRemaining then
            revivalTimeRemaining = revivalTimeRemaining - dt
            if revivalTimeRemaining <= 0 then
                revive()
            end
        end
    end
end

local function onSave()
    return {
        down = down,
        dying = dying,
        leader = leader,
        reviveTimerStarted = reviveTimerStarted,
        revivalTimeRemaining = revivalTimeRemaining,
    }
end

local function onLoad(data)
    data = data or {}
    down = data.down or down
    dying = data.dying or dying
    leader = data.leader or leader
    reviveTimerStarted = data.reviveTimerStarted or reviveTimerStarted
    revivalTimeRemaining = data.revivalTimeRemaining or revivalTimeRemaining
    eventData.leader = data.leader or leader

    if revivalTimeRemaining == nil and reviveTimerStarted and not settings.waitUntilCombatEnds then
        revivalTimeRemaining = settings.upDelay
    end
end

----------------------------------------------------------------------
-- Injury
----------------------------------------------------------------------

local OUTCOME_TIER = {
    light = "minor",
    heavy = "major",
}

local function unusedInjuries(outcome)
    local pool = {}
    for _, injury in ipairs(injuries.byTier[OUTCOME_TIER[outcome]] or {}) do
        if not selfActiveSpells:isSpellActive(injury.id) then
            pool[#pool + 1] = injury
        end
    end
    return pool
end

---@param exhausted table<string, boolean>
---@return "light"|"heavy"|"death"? outcome  nil when no outcome has weight left.
local function rollOutcome(exhausted)
    local weights = settings.injuryWeights
    local light = exhausted.light and 0 or weights.light
    local heavy = exhausted.heavy and 0 or weights.heavy
    local death = weights.death
    local total = light + heavy + death
    if total <= 0 then
        return nil
    end

    local roll = math.random() * total
    if roll < light then
        return "light"
    end
    roll = roll - light
    if roll < heavy then
        return "heavy"
    end
    return "death"
end

---@return boolean  false when death was committed.
function applyInjuryOutcome()
    local exhausted = {}
    while true do
        local outcome = rollOutcome(exhausted)
        if outcome == nil then
            return true
        end
        if outcome == "death" then
            dieForReal()
            return false
        end

        local pool = unusedInjuries(outcome)
        if #pool == 0 then
            exhausted[outcome] = true
        else
            local injury = pool[math.random(#pool)]
            core.sendGlobalEvent("BestFriendsForever_applyInjury", {
                actor = self,
                id = injury.id,
            })
            return true
        end
    end
end

-- Initialization
settings = settingsCache.new(immortalitySection, async)

I.Combat.addOnHitHandler(function(attack)
    if down or dying then
        return false
    end

    if not attack.successful or not attack.damage.health or dead then
        return
    end

    -- for some reason the hit handler doesn't get detached together with the script
    local followerList = I.FollowerDetectionUtil.getFollowerList()
    local stillFollowing = followerList[self.id] and followerList[self.id].followsPlayer
    local lethalDamage = attack.damage.health > health.current - settings.threshold
    local dontDown = lethalDamage and not isCommanded() and stillFollowing

    if dontDown then
        if not selfDown() then
            return
        end
        health.current = settings.threshold
        return false
    end
end)

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onInit = function(data)
            data = data or {}
            leader = data.leader
            eventData.leader = leader
        end,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        BestFriendsForever_setCombatStatus = setCombatStatus,
        BestFriendsForever_combatEnded = onCombatEnded,
        Died = function()
            dead = true
            dying = true
            core.sendGlobalEvent("BestFriendsForever_detachScript", {
                actor = self,
                script = "scripts/BestFriendsForever/followerScripts/teleport.lua",
            })
        end,
    },
}
