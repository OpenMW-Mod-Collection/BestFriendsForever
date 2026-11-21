---@diagnostic disable: undefined-field, param-type-mismatch, redundant-parameter, assign-type-mismatch
---@omw-context local
local self = require("openmw.self")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local async = require("openmw.async")
local types = require("openmw.types")

local settingsCache = require("scripts.BestFriendsForever.utils.settingsCache")

local immortalitySection = storage.globalSection("SettingsBestFriendsForever_immortality")
local l10n = core.l10n("BestFriendsForever")
local selfName = self.type.records[self.recordId].name
local SCRIPT_PATH = "scripts/BestFriendsForever/followerScripts/immortality.lua"

local settings
local selfEffects = types.Actor.activeEffects(self)
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
local outcomeProvider
local outcomeProviderId

local function isCommanded()
    local hasEffect = selfEffects:getEffect(core.magic.EFFECT_TYPE.CommandCreature).magnitude > 0
        or selfEffects:getEffect(core.magic.EFFECT_TYPE.CommandHumanoid).magnitude > 0
    return hasEffect and settings.ingoreCommanded
end

---@param id string
---@param fn fun(): ("down"|"death"|nil)
local function setOutcomeProvider(id, fn)
    if type(id) ~= "string" or id == "" then
        error("BestFriendsForeverDown.setOutcomeProvider: id must be a non-empty string", 2)
    end
    if type(fn) ~= "function" then
        error("BestFriendsForeverDown.setOutcomeProvider: provider must be a function", 2)
    end

    outcomeProviderId = id
    outcomeProvider = fn
end

---@param id string
local function clearOutcomeProvider(id)
    if outcomeProviderId == id then
        outcomeProviderId = nil
        outcomeProvider = nil
    end
end

---@return "down"|"death"|nil
local function resolveDownOutcome()
    if not outcomeProvider then
        return nil
    end

    local ok, outcome = pcall(outcomeProvider)
    if not ok then
        print(("[BestFriendsForever] Down outcome provider '%s' failed: %s")
            :format(tostring(outcomeProviderId), tostring(outcome)))
        return nil
    end

    if outcome ~= "down" and outcome ~= "death" then
        if outcome ~= nil then
            print(("[BestFriendsForever] Down outcome provider '%s' returned an invalid outcome: %s")
                :format(tostring(outcomeProviderId), tostring(outcome)))
        end
        return nil
    end

    return outcome
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

---@return boolean  false when the resolved outcome was real death.
local function selfDown()
    if resolveDownOutcome() == "death" then
        dieForReal()
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
        local downed = selfDown()
        if not downed then
            -- dieForReal() already committed the death.
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
    interfaceName = "BestFriendsForeverDown",
    interface = {
        version = 1,
        setOutcomeProvider = setOutcomeProvider,
        clearOutcomeProvider = clearOutcomeProvider,
    },
}
