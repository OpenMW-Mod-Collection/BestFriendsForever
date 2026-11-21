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

-- Constants
local wardSection = storage.globalSection("SettingsBestFriendsForever_ward")

-- Variables
local wardSettings
local selfActiveSpells = types.Actor.activeEffects(self)
local selfSpells = types.Actor.spells(self)
local nextStatDamageCheck = 0
local attributes = {}
local skills = {}

local function isProtected(effect)
    local protections = wardSettings.protections or {}
    return protections[effect] ~= false
end

local function removeDiseases()
    if not isProtected("diseases") then
        return
    end

    local diseaseIds = {}
    for _, spell in pairs(selfSpells) do
        if spell.type == core.magic.SPELL_TYPE.Blight or spell.type == core.magic.SPELL_TYPE.Disease then
            diseaseIds[#diseaseIds + 1] = spell.id
        end
    end

    for _, spellId in ipairs(diseaseIds) do
        selfSpells:remove(spellId)
    end
end

local function restoreStat(stats, drainEffect)
    for statId, stat in pairs(stats) do
        if stat.damage > 0 then
            stat.damage = selfActiveSpells:getEffect(drainEffect, statId).magnitude
        end
    end
end

local function restoreAllStats()
    if not isProtected("statDamage") then
        return
    end
    
    restoreStat(attributes, core.magic.EFFECT_TYPE.DrainAttribute)
    restoreStat(skills, core.magic.EFFECT_TYPE.DrainSkill)
end

local function rejectDiseaseSpell(options)
    if not isProtected("diseases") then
        return
    end

    local record = spellcastRecordDecoder.getMagicRecord(options)
    local spellTypes = core.magic.SPELL_TYPE
    if record.type == spellTypes.Blight or record.type == spellTypes.Disease then
        return false
    end
end

local function onUpdate(dt)
    nextStatDamageCheck = nextStatDamageCheck - dt
    if nextStatDamageCheck > 0 then
        return
    end

    restoreAllStats()
    removeDiseases()
    nextStatDamageCheck = wardSettings.statDamageCheckFrequency
end

-- Initialization
wardSettings = settingsCache.new(wardSection, async)

for attrId, attrGetter in pairs(types.Actor.stats.attributes) do
    attributes[attrId] = attrGetter(self)
end
if types.NPC.objectIsInstance(self) then
    for skillId, skillGetter in pairs(types.NPC.stats.skills) do
        skills[skillId] = skillGetter(self)
    end
end

I.SpellCasting.addApplyMagicEffectsHandler(rejectDiseaseSpell)

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
