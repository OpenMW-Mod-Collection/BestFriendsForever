---@diagnostic disable: param-type-mismatch, need-check-nil
---@omw-context player
local util = require("openmw.util")
local v2 = util.vector2
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local types = require("openmw.types")
local core = require("openmw.core")

local l10n = core.l10n("BestFriendsForever")

local tooltipUI = {}
local registeredFields = {}
local fieldsCache

local function getActorName(fData)
    local actor = fData.followerState.actor
    return actor.type.records[actor.recordId].name
end

local function getActorRole(fData)
    local actor = fData.followerState.actor
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
        if spell.type == core.magic.SPELL_TYPE.Blight or spell.type == core.magic.SPELL_TYPE.Disease then
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

local function fillAffectedStats(stats, affectedStats, activeEffects, effectId)
    for statId, stat in pairs(stats) do
        local drain = activeEffects:getEffect(effectId, statId)
        if stat.damage - drain.magnitude > 0 then
            affectedStats[statId] = true
        end
    end
end

local function getDamagedStatNames(fData)
    local affectedAttributes = {}
    local affectedSkills = {}
    local names = {}

    fillAffectedStats(fData.attributes, affectedAttributes, fData.activeEffects, core.magic.EFFECT_TYPE.DrainAttribute)
    fillAffectedStats(fData.skills, affectedSkills, fData.activeEffects, core.magic.EFFECT_TYPE.DrainSkill)

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
        order = 1,
        getText = function(fData)
            return l10n("followerTooltip_name", { name = getActorName(fData) })
        end,
    },
    {
        name = "role",
        order = 2,
        getText = getActorRole,
    },
    {
        name = "diseases",
        order = 3,
        enabledSetting = "diseases",
        getText = function(fData)
            return l10n("followerTooltip_diseases", { diseases = getDiseaseNames(fData) })
        end,
    },
    {
        name = "statDamage",
        order = 4,
        enabledSetting = "damagedStats",
        getText = getStatDamage,
    },
}

local function nameTaken(name)
    for _, definition in ipairs(TOOLTIP_FIELDS) do
        if definition.name == name then
            return true
        end
    end
    for _, definition in ipairs(registeredFields) do
        if definition.name == name then
            return true
        end
    end
    return false
end

---@class TooltipFieldDef
---@field name string Unique field name.
---@field order number? sort weight, defaults to 100.
---@field getText fun(followerState: table): string|nil

---@param definition TooltipFieldDef
function tooltipUI.registerField(definition)
    if type(definition) ~= "table" then
        error("registerFollowerTooltipField: definition must be a table", 2)
    end
    if type(definition.name) ~= "string" or definition.name == "" then
        error("registerFollowerTooltipField: name must be a non-empty string", 2)
    end
    if nameTaken(definition.name) then
        error(("registerFollowerTooltipField: '%s' is already registered"):format(definition.name), 2)
    end
    if type(definition.getText) ~= "function" then
        error("registerFollowerTooltipField: getText must be a function", 2)
    end

    local order = tonumber(definition.order) or 100
    if order ~= order or order == math.huge or order == -math.huge then
        error("registerFollowerTooltipField: order must be a finite number", 2)
    end

    registeredFields[#registeredFields + 1] = {
        name = definition.name,
        order = order,
        getText = definition.getText,
        usesFollowerState = true,
    }
    fieldsCache = nil
end

local function allFields()
    if fieldsCache then
        return fieldsCache
    end

    local fields = {}
    for _, definition in ipairs(TOOLTIP_FIELDS) do
        fields[#fields + 1] = definition
    end
    for _, definition in ipairs(registeredFields) do
        fields[#fields + 1] = definition
    end

    table.sort(fields, function(a, b)
        if a.order ~= b.order then
            return a.order < b.order
        end
        return a.name < b.name
    end)
    fieldsCache = fields
    return fields
end

function tooltipUI.create(layer)
    local fieldLayouts = {}
    for _, definition in ipairs(allFields()) do
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
        template = I.MWUI.templates.boxSolid,
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
    local layouts = tooltipElement.layout.content.followerTooltipFields.content
    for _, definition in ipairs(allFields()) do
        local field = layouts["followerTooltip_" .. definition.name]
        if field then
            local argument = definition.usesFollowerState and fData.followerState or fData
            local text = definition.getText(argument)
            field.props.text = text
            field.props.visible = text ~= nil
                and (not definition.enabledSetting or enabledElements[definition.enabledSetting] ~= false)
        end
    end
    tooltipElement:update()
end

return tooltipUI
