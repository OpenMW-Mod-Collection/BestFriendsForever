---@omw-context local
---@diagnostic disable: assign-type-mismatch
local self = require("openmw.self")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local storage = require("openmw.storage")

if self.type.isDead(self) then return end

local settings = storage.globalSection("SettingsGoodCompany_immortality")
local l10n = core.l10n("GoodCompany")
local selfName = self.type.records[self.recordId].name
local selfEffects = self.type.activeEffects(self)
local health = self.type.stats.dynamic.health(self)
local fatigue = self.type.stats.dynamic.fatigue(self)
local threshold = settings:get("threshold")
local eventData = {
    follower = self,
    leader = nil
}

local down = false
local inCombat = false
local leader

local function onUpdate()
    if not down and health.current < threshold then
        local isCommanded = selfEffects:getEffect(core.magic.EFFECT_TYPE.CommandCreature).magnitude > 0
            or selfEffects:getEffect(core.magic.EFFECT_TYPE.CommandHumanoid).magnitude > 0
        if not isCommanded or settings:get("ingoreCommanded") then
            down = true
            leader:sendEvent("GoodCompany_followerDown", eventData)
            core.sendGlobalEvent("GoodCompany_followerDown", eventData)
            leader:sendEvent("ShowMessage", {
                message = l10n("msg_followerDown", { npc_name = selfName })
            })
        end
    end

    if down then
        ---@diagnostic disable-next-line: redundant-parameter, param-type-mismatch
        self:enableAI(not inCombat)
        if inCombat then
            health.current = 10000
            fatigue.current = -100
        else
            down = false
            health.current = threshold
            fatigue.current = 1
            leader:sendEvent("GoodCompany_followerUp", eventData)
            core.sendGlobalEvent("GoodCompany_followerUp", eventData)
        end
    end
end

local function onSave()
    return {
        leader = leader,
    }
end

local function onLoad(data)
    if not data then return end
    leader = data.leader or leader
    eventData.leader = data.leader or leader
end

I.Combat.addOnHitHandler(function(attack)
    if down then return false end
    if not attack.successful then return end
    if attack.damage.health > health.current - threshold then
        down = true
        health.current = threshold
        return false
    end
end)

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onInit = function(data)
            leader = data.leader
        end,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        Died = function()
            core.sendGlobalEvent("GoodCompany_detachScript", {
                actor = self,
                script = "scripts/GoodCompany/followerScripts/teleport.lua"
            })
        end,
        GoodCompany_combatMode = function(data)
            inCombat = data
        end,
    }
}
