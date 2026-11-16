---@diagnostic disable: need-check-nil
---@omw-context local
local core = require("openmw.core")
local self = require("openmw.self")
local storage = require("openmw.storage")
local async = require("openmw.async")
local types = require("openmw.types")
local I = require("openmw.interfaces")

local settingsCache = require("scripts.BestFriendsForever.utils.settingsCache")
local spellcastRecordDecoder = require("scripts.BestFriendsForever.utils.spellcastRecordDecoder")

local applyWard
local wardSection = storage.globalSection("SettingsBestFriendsForever_ward")
local wardSettings = settingsCache.new(wardSection, async, applyWard)
local activeSpells = types.Actor.activeEffects(self)
local nextStatDamageCheck = 0
local attributes = {}
local skills = {}

for attrId, attrGetter in pairs(types.Actor.stats.attributes) do
    attributes[attrId] = attrGetter(self)
end

if types.NPC.objectIsInstance(self) then
    for skillId, skillGetter in pairs(types.NPC.stats.skills) do
        skills[skillId] = skillGetter(self)
    end
end

local function removeDiseases()
    local spells = types.Actor.spells(self)
    local diseaseIds = {}
    for _, spell in pairs(spells) do
        if spell.type == core.magic.SPELL_TYPE.Blight or spell.type == core.magic.SPELL_TYPE.Disease then
            diseaseIds[#diseaseIds + 1] = spell.id
        end
    end

    for _, spellId in ipairs(diseaseIds) do
        spells:remove(spellId)
    end
end

local function restoreStat(stats, drainEffect)
    for statId, stat in pairs(stats) do
        if stat.damage > 0 then
            stat.damage = activeSpells:getEffect(drainEffect, statId).magnitude
        end
    end
end

local function restoreAllStats()
    restoreStat(attributes, core.magic.EFFECT_TYPE.DrainAttribute)
    restoreStat(skills, core.magic.EFFECT_TYPE.DrainSkill)
end

local function rejectDiseaseSpell(options)
    if not wardSettings.disableDiseases then
        return
    end

    local record = spellcastRecordDecoder.getMagicRecord(options)
    local spellTypes = core.magic.SPELL_TYPE
    if record.type == spellTypes.Blight or record.type == spellTypes.Disease then
        return false
    end
end

I.SpellCasting.addApplyMagicEffectsHandler(rejectDiseaseSpell)

local function onUpdate(dt)
    if not wardSettings.disableStatDamage then
        return
    end

    nextStatDamageCheck = nextStatDamageCheck - dt
    if nextStatDamageCheck > 0 then
        return
    end

    restoreAllStats()
    nextStatDamageCheck = wardSettings.statDamageCheckFrequency
end

removeDiseases()
restoreAllStats()

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = {
        Died = function()
            core.sendGlobalEvent("BestFriendsForever_detachScript", {
                actor = self,
                script = "scripts/BestFriendsForever/followerScripts/ward.lua",
            })
        end,
    },
}
