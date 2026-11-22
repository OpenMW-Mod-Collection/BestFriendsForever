---@diagnostic disable: param-type-mismatch, need-check-nil, undefined-field
---@omw-context player
local util = require("openmw.util")
local v2 = util.vector2
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local types = require("openmw.types")
local core = require("openmw.core")
local async = require("openmw.async")
local storage = require("openmw.storage")

local settingsCache = require("scripts.BestFriendsForever.utils.settingsCache")

local l10n = core.l10n("BestFriendsForever_ui")
local damagedColor = util.color.commaString(core.getGMST("fontcolor_color_negative"))
local creatureTypeLabels = {
    [types.Creature.TYPE.Creatures] = "creatureType_creatures",
    [types.Creature.TYPE.Daedra] = "creatureType_daedra",
    [types.Creature.TYPE.Humanoid] = "creatureType_humanoid",
    [types.Creature.TYPE.Undead] = "creatureType_undead",
}

local tooltipUI = {}
local registeredFields = {}
local fieldsCache
local settings

local function getActorName(followerState)
    local actor = followerState.actor
    return actor.type.records[actor.recordId].name
end

local function getActorRole(followerState)
    local actor = followerState.actor
    if types.NPC.objectIsInstance(actor) then
        local npcRecord = types.NPC.records[actor.recordId]
        local classRecord = types.NPC.classes.records[npcRecord.class]
        return l10n("followerTooltip_class", { class_name = classRecord.name })
    elseif types.Creature.objectIsInstance(actor) then
        local creatureRecord = types.Creature.records[actor.recordId]
        local creatureName
        if settings.creatureDisplayMode == "Creature Type" then
            local typeLabel = creatureTypeLabels[creatureRecord.type]
            creatureName = typeLabel and l10n(typeLabel) or creatureRecord.type or creatureRecord.name
        else
            local baseCreatureId = creatureRecord.baseCreature
            local baseCreature = baseCreatureId and types.Creature.records[baseCreatureId]
            creatureName = baseCreature and baseCreature.name or creatureRecord.name
        end
        return l10n("followerTooltip_creature", { creature_name = creatureName })
    end
end

local function getDiseases(fData)
    local names = {}
    local types = {}
    local seenTypes = {}
    for _, spell in pairs(fData.spells) do
        if spell.type == core.magic.SPELL_TYPE.Blight or spell.type == core.magic.SPELL_TYPE.Disease then
            names[#names + 1] = core.magic.spells.records[spell.id].name
            local typeName = spell.type == core.magic.SPELL_TYPE.Blight and "Blight" or "Disease"
            if not seenTypes[typeName] then
                seenTypes[typeName] = true
                types[#types + 1] = typeName
            end
        end
    end

    table.sort(names)
    table.sort(types)
    return names, types
end

local function getDiseaseText(fData, verbosity)
    local names, types = getDiseases(fData)
    if #names == 0 then
        return nil
    end
    if verbosity == "By Type" then
        for i, typeName in ipairs(types) do
            types[i] = l10n(typeName)
        end
        return l10n("followerTooltip_diseases", { diseases = table.concat(types, ", ") })
    elseif verbosity == "Unclear" then
        return l10n("followerTooltip_diseased")
    end
    return l10n("followerTooltip_diseases", { diseases = table.concat(names, ", ") })
end

local function addStatName(names, recordList, statId)
    names[#names + 1] = recordList[statId].name
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

local function nameTaken(name)
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
---@field enabledSetting string? HUD element setting that can hide the field.
---@field toggleKey string? Tooltip field setting that can hide the field.
---@field textColor? openmw.util.Color Text color override for text fields.
---@field getText? fun(followerState: table, followerData: FollowerData): string|nil
---@field getLayout? fun(followerState: table, followerData: FollowerData): openmw.ui.Layout|nil

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

    local hasText = type(definition.getText) == "function"
    local hasLayout = type(definition.getLayout) == "function"
    if hasText == hasLayout then
        error("registerFollowerTooltipField: provide exactly one of getText or getLayout", 2)
    end

    local order = tonumber(definition.order) or 100
    if order ~= order or order == math.huge or order == -math.huge then
        error("registerFollowerTooltipField: order must be a finite number", 2)
    end

    registeredFields[#registeredFields + 1] = {
        name = definition.name,
        order = order,
        enabledSetting = definition.enabledSetting,
        toggleKey = definition.toggleKey,
        textColor = definition.textColor,
        getText = definition.getText,
        getLayout = definition.getLayout,
    }
    fieldsCache = nil
end

local function allFields()
    if fieldsCache then
        return fieldsCache
    end

    local fields = {}
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

local function newFieldLayout(definition)
    local name = "followerTooltip_" .. definition.name
    if definition.getLayout then
        return {
            name = name,
            type = ui.TYPE.Container,
            props = { visible = false },
            content = ui.content {},
        }
    end
    local props = {
        textSize = 16,
        textShadow = true,
        visible = false,
    }
    if definition.textColor then
        props.textColor = definition.textColor
    end
    return {
        name = name,
        template = I.MWUI.templates.textNormal,
        props = props,
    }
end

function tooltipUI.create(layer)
    local fieldLayouts = {}
    for _, definition in ipairs(allFields()) do
        fieldLayouts[#fieldLayouts + 1] = newFieldLayout(definition)
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

---@param tooltipElement openmw.ui.Element|nil
---@return openmw.ui.Content|table
function tooltipUI.getFields(tooltipElement)
    local elementLayout = tooltipElement and tooltipElement.layout
    local fields = elementLayout and elementLayout.content and elementLayout.content.followerTooltipFields
    return fields and fields.content or {}
end

function tooltipUI.update(tooltipElement, fData, enabledElements)
    local layouts = tooltipElement.layout.content.followerTooltipFields.content
    local toggles = settings.enabledFields
    for _, definition in ipairs(allFields()) do
        local field = layouts["followerTooltip_" .. definition.name]
        if field then
            local followerState = fData.followerState
            local visible
            if definition.getLayout then
                local layout = definition.getLayout(followerState, fData)
                if field.content[1] ~= layout then
                    field.content = layout and ui.content { layout } or ui.content {}
                end
                visible = layout ~= nil
            else
                local text = definition.getText(followerState, fData)
                field.props.text = text
                visible = text ~= nil
            end
            field.props.visible = visible
                and (not definition.enabledSetting or enabledElements[definition.enabledSetting] ~= false)
                and (not definition.toggleKey or not toggles or toggles[definition.toggleKey] ~= false)
        end
    end
    tooltipElement:update()
end

settings = settingsCache.new(storage.playerSection("SettingsBestFriendsForever_tooltip"), async)

tooltipUI.registerField {
    name = "name",
    order = 1,
    getText = function(followerState)
        return l10n("followerTooltip_name", { name = getActorName(followerState) })
    end,
}

tooltipUI.registerField {
    name = "role",
    order = 2,
    toggleKey = "class",
    getText = getActorRole,
}

tooltipUI.registerField {
    name = "diseases",
    order = 3,
    toggleKey = "diseases",
    textColor = damagedColor,
    getText = function(_, followerData)
        return getDiseaseText(followerData, settings.diseaseVerbosity)
    end,
}

tooltipUI.registerField {
    name = "statDamage",
    order = 4,
    toggleKey = "statDamage",
    textColor = damagedColor,
    getText = function(_, followerData)
        return getStatDamage(followerData)
    end,
}

return tooltipUI
