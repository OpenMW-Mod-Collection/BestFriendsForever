---@diagnostic disable: undefined-field
---@omw-context local
---@diagnostic disable: assign-type-mismatch
local self = require("openmw.self")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local async = require("openmw.async")
local types = require("openmw.types")

local settingsCache = require("scripts.BestFriendsForever.utils.settingsCache")

local settings = settingsCache.new(
    storage.globalSection("SettingsBestFriendsForever_immortality"),
    async
)
local l10n = core.l10n("BestFriendsForever")
local selfName = self.type.records[self.recordId].name
local selfEffects = self.type.activeEffects(self)
local health = self.type.stats.dynamic.health(self)
local fatigue = self.type.stats.dynamic.fatigue(self)
local eventData = {
    follower = self,
    leader = nil
}
local followerList = I.FollowerDetectionUtil.getFollowerList()

local dead = types.Actor.isDead(self)
local down = false
local inCombat = false
local leader

local function isCommanded()
    local hasEffect = selfEffects:getEffect(core.magic.EFFECT_TYPE.CommandCreature).magnitude > 0
        or selfEffects:getEffect(core.magic.EFFECT_TYPE.CommandHumanoid).magnitude > 0
    return hasEffect and not settings.ingoreCommanded
end

local function selfDown()
    down = true
    leader:sendEvent("BestFriendsForever_followerDown", eventData)
    core.sendGlobalEvent("BestFriendsForever_followerDown", eventData)
    if inCombat then
        leader:sendEvent("ShowMessage", {
            message = l10n("msg_followerDown", { npc_name = selfName })
        })
    end
end

local function onUpdate()
    if not down and health.current < settings.threshold then
        if not isCommanded() then
            selfDown()
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
            health.current = settings.threshold
            fatigue.current = 1
            leader:sendEvent("BestFriendsForever_followerUp", eventData)
            core.sendGlobalEvent("BestFriendsForever_followerUp", eventData)
            -- stop combat because if immortality was triggered due to infighting
            -- they would have a chance to remove their aggro
            I.AI.removePackages("Combat")
        end
    end
end

local function onSave()
    return {
        down = down,
        inCombat = inCombat,
        leader = leader,
    }
end

local function onLoad(data)
    if not data then return end
    down = data.down or down
    inCombat = data.inCombat or inCombat
    leader = data.leader or leader
    eventData.leader = data.leader or leader
end

I.Combat.addOnHitHandler(function(attack)
    if down then
        return false
    end

    if not attack.successful or not attack.damage.health or dead then
        return
    end

    -- for some reason the hit handler doesn't get detached together with the script
    local stillFollowing = followerList[self.id] and followerList[self.id].followsPlayer
    local lethalDamage = attack.damage.health > health.current - settings.threshold
    if lethalDamage and not isCommanded() and stillFollowing then
        if not down and inCombat then
            selfDown()
        end
        health.current = settings.threshold
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
            dead = true
            core.sendGlobalEvent("BestFriendsForever_detachScript", {
                actor = self,
                script = "scripts/BestFriendsForever/followerScripts/teleport.lua"
            })
        end,
        BestFriendsForever_combatMode = function(data)
            inCombat = data
        end,
        FDU_UpdateFollowerList = function(data)
            followerList = data.followers
        end
    }
}
