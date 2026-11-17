---@diagnostic disable: param-type-mismatch, need-check-nil
---@omw-context player
local util = require("openmw.util")
local v2 = util.vector2
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local types = require("openmw.types")
local core = require("openmw.core")

local l10n = core.l10n("BestFriendsForever")
local attributeDamageEffects = {
    [core.magic.EFFECT_TYPE.DamageAttribute] = true,
    [core.magic.EFFECT_TYPE.DrainAttribute] = true,
}
local skillDamageEffects = {
    [core.magic.EFFECT_TYPE.DamageSkill] = true,
    [core.magic.EFFECT_TYPE.DrainSkill] = true,
}

local tooltipUI = {}

local function getActorName(fData)
    local actor = fData.actor
    return actor.type.records[actor.recordId].name
end

local function getActorRole(fData)
    local actor = fData.actor
    if types.NPC.objectIsInstance(actor) then
        local npcRecord = types.NPC.record(actor)
        local classRecord = types.NPC.classes.record(npcRecord.class)
        return l10n("followerTooltip_class", { class_name = classRecord.name })
    elseif types.Creature.objectIsInstance(actor) then
        local creatureRecord = types.Creature.record(actor)
        local baseCreature = creatureRecord.baseCreature
            and creatureRecord.baseCreature ~= ""
            and types.Creature.record(creatureRecord.baseCreature)
        local creatureName = baseCreature and baseCreature.name or creatureRecord.name
        return l10n("followerTooltip_creature", { creature_name = creatureName })
    end
end

local function getDiseaseNames(fData)
    local diseaseNames = {}
    for _, spell in pairs(fData.spells) do
        if spell.type == core.magic.SPELL_TYPE.Blight
            or spell.type == core.magic.SPELL_TYPE.Disease
        then
            diseaseNames[#diseaseNames + 1] = core.magic.spells.records[spell.id].name
        end
    end

    table.sort(diseaseNames)
    if #diseaseNames == 0 then
        return l10n("followerTooltip_healthy")
    end
    return table.concat(diseaseNames, ", ")
end

local function addStatName(names, recordList, statId)
    local record = recordList[statId]
    names[#names + 1] = record and record.name or statId
end

local function getDamagedStatNames(fData)
    local affectedAttributes = {}
    local affectedSkills = {}
    local names = {}

    for statId, stat in pairs(fData.attributes) do
        if stat.damage > 0 then
            affectedAttributes[statId] = true
        end
    end
    for statId, stat in pairs(fData.skills) do
        if stat.damage > 0 then
            affectedSkills[statId] = true
        end
    end

    for _, effect in pairs(fData.activeEffects) do
        if effect.magnitude > 0 then
            if attributeDamageEffects[effect.id] and effect.affectedAttribute then
                affectedAttributes[effect.affectedAttribute] = true
            elseif skillDamageEffects[effect.id] and effect.affectedSkill then
                affectedSkills[effect.affectedSkill] = true
            end
        end
    end

    for statId in pairs(affectedAttributes) do
        addStatName(names, core.stats.Attribute.records, statId)
    end
    for statId in pairs(affectedSkills) do
        addStatName(names, core.stats.Skill.records, statId)
    end

    table.sort(names)
    return names
end

local function getStatDamage(fData)
    local damagedStats = getDamagedStatNames(fData)
    if #damagedStats == 0 then
        return nil
    end
    return l10n("followerTooltip_statDamage", {
        stats = table.concat(damagedStats, ", "),
    })
end

local TOOLTIP_FIELDS = {
    {
        name = "name",
        getText = function(fData)
            return l10n("followerTooltip_name", { name = getActorName(fData) })
        end,
    },
    {
        name = "role",
        getText = getActorRole,
    },
    {
        name = "diseases",
        enabledSetting = "diseases",
        getText = function(fData)
            return l10n("followerTooltip_diseases", { diseases = getDiseaseNames(fData) })
        end,
    },
    {
        name = "statDamage",
        enabledSetting = "damagedStats",
        getText = getStatDamage,
    },
}

function tooltipUI.create(layer)
    local fieldLayouts = {}
    for _, definition in ipairs(TOOLTIP_FIELDS) do
        local field = {
            name = "followerTooltip_" .. definition.name,
            template = I.MWUI.templates.textNormal,
            props = {
                textSize = 16,
                textShadow = true,
            },
        }
        fieldLayouts[#fieldLayouts + 1] = field
    end

    local layout = {
        name = "followerTooltip",
        layer = layer,
        type = ui.TYPE.Container,
        props = {
            position = v2(0, 0),
            visible = false,
        },
        content = ui.content {
            {
                name = "followerTooltipFields",
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    gap = 2,
                },
                content = ui.content(fieldLayouts),
            },
        },
    }
    return ui.create(layout)
end

function tooltipUI.update(tooltipElement, fData, enabledElements)
    local fields = tooltipElement.layout.content.followerTooltipFields.content
    for _, definition in ipairs(TOOLTIP_FIELDS) do
        local field = fields["followerTooltip_" .. definition.name]
        local text = definition.getText(fData)
        field.props.text = text
        field.props.visible = text ~= nil
            and (not definition.enabledSetting or enabledElements[definition.enabledSetting] ~= false)
    end
    tooltipElement:update()
end

return tooltipUI
