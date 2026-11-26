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
local commonUI = require("scripts.BestFriendsForever.utils.commonUI")
local commonInjuries = require("scripts.BestFriendsForever.common.injuries")

local l10n = core.l10n("BestFriendsForever_ui")
local damagedColor = util.color.commaString(core.getGMST("fontcolor_color_negative"))
local OUTER_PADDING = commonUI.Sizes.BOX_OUTER_PADDING
local FIELD_GAP = 2
local spacerVisibleSize = v2(0, FIELD_GAP)
local spacerHiddenSize = v2(0, 0)

local tooltipUI = {}
local registeredFields = {}
local fieldsCache
local fieldSpacers = {}
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
        local raceRecord = types.NPC.races.records[npcRecord.race]
        local role = {}
        if classRecord and classRecord.name then
            role[#role + 1] = classRecord.name
        end
        if raceRecord and raceRecord.name then
            role[#role + 1] = raceRecord.name
        end
        return table.concat(role, ", ")
    elseif types.Creature.objectIsInstance(actor) then
        local creatureRecord = types.Creature.records[actor.recordId]
        local role = commonUI.creatureTypeLabel(creatureRecord.type) or creatureRecord.type or creatureRecord.name or ""
        local baseCreatureId = creatureRecord.baseCreature
        if baseCreatureId ~= creatureRecord.id then
            local baseCreature = types.Creature.records[baseCreatureId]
            if baseCreature then
                return baseCreature.name .. ", " .. role
            end
        end
        return role
    end
end

local function getDiseases(fData)
    local names = {}
    local diseaseTypes = {}
    local seenTypes = {}
    for _, spell in pairs(fData.spells) do
        if spell.type == core.magic.SPELL_TYPE.Blight or spell.type == core.magic.SPELL_TYPE.Disease then
            names[#names + 1] = core.magic.spells.records[spell.id].name
            local typeName = spell.type == core.magic.SPELL_TYPE.Blight and "Blight" or "Disease"
            if not seenTypes[typeName] then
                seenTypes[typeName] = true
                diseaseTypes[#diseaseTypes + 1] = typeName
            end
        end
    end

    table.sort(names)
    table.sort(diseaseTypes)
    return names, diseaseTypes
end

local function getDiseaseText(fData, verbosity)
    local names, dieseaseTypes = getDiseases(fData)
    if #names == 0 then
        return nil
    end
    if verbosity == "By Type" then
        for i, typeName in ipairs(dieseaseTypes) do
            dieseaseTypes[i] = l10n(typeName)
        end
        return l10n("followerTooltip_diseases", { diseases = table.concat(dieseaseTypes, ", ") })
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

local function getInjuries(fData)
    local active = commonInjuries.activeInjuries(fData.activeSpells)
    if #active == 0 then
        return nil
    end

    local names = {}
    for _, injury in ipairs(active) do
        names[#names + 1] = injury.name
    end
    table.sort(names)
    return l10n("followerTooltip_injuries", {
        injuries = table.concat(names, ", "),
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
---@field header? boolean Use the header text template for text fields.
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
        layoutName = "followerTooltip_" .. definition.name,
        order = order,
        enabledSetting = definition.enabledSetting,
        toggleKey = definition.toggleKey,
        textColor = definition.textColor,
        header = definition.header,
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
    local name = definition.layoutName
    if definition.getLayout then
        return {
            name = name,
            type = ui.TYPE.Container,
            props = { visible = false, autoSize = true, size = v2(0, 0) },
            content = ui.content {},
        }
    end
    local props = {
        textSize = 16,
        textShadow = true,
        textAlignH = ui.ALIGNMENT.Center,
        textAlignV = ui.ALIGNMENT.Center,
        autoSize = true,
        size = v2(0, 0),
        visible = false,
    }
    if definition.textColor then
        props.textColor = definition.textColor
    end
    return {
        name = name,
        template = definition.header and I.MWUI.templates.textHeader or I.MWUI.templates.textNormal,
        props = props,
    }
end

function tooltipUI.create(layer)
    local definitions = allFields()
    local content = ui.content {}
    fieldSpacers = {}
    for index, definition in ipairs(definitions) do
        definition.lastText = nil
        definition.lastLayout = nil
        definition.lastVisible = nil
        content:add(newFieldLayout(definition))
        if index < #definitions then
            local spacer = { props = { size = spacerVisibleSize } }
            content:add(spacer)
            fieldSpacers[definition.name] = spacer
        end
    end

    local fields = {
        name = "followerTooltipFields",
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            arrange = ui.ALIGNMENT.Center,
        },
        content = content,
    }
    local horizontallyPadded = {
        name = "followerTooltipHorizontalPadding",
        type = ui.TYPE.Flex,
        props = { horizontal = true },
        content = ui.content {
            commonUI.intervalH(OUTER_PADDING),
            fields,
            commonUI.intervalH(OUTER_PADDING),
        },
    }
    local outer = {
        name = "followerTooltipOuterPadding",
        type = ui.TYPE.Flex,
        props = { horizontal = false },
        content = ui.content {
            commonUI.intervalV(OUTER_PADDING),
            horizontallyPadded,
            commonUI.intervalV(OUTER_PADDING),
        },
    }
    local layout = {
        name = "followerTooltip",
        layer = layer,
        template = I.MWUI.templates.boxSolid,
        props = {
            position = v2(0, 0),
            visible = false,
        },
        content = ui.content { outer },
    }
    return ui.create(layout)
end

local function getFieldsLayout(tooltipElement)
    local rootContent = tooltipElement and tooltipElement.layout and tooltipElement.layout.content
    local outer = rootContent and rootContent.followerTooltipOuterPadding
    local horizontal = outer and outer.content and outer.content.followerTooltipHorizontalPadding
    return horizontal and horizontal.content and horizontal.content.followerTooltipFields
end

---@param tooltipElement openmw.ui.Element|nil
---@return openmw.ui.Content|table
function tooltipUI.getFields(tooltipElement)
    local fields = getFieldsLayout(tooltipElement)
    return fields and fields.content or {}
end

function tooltipUI.update(tooltipElement, fData, enabledElements)
    local fields = getFieldsLayout(tooltipElement)
    if not fields then
        return
    end
    local layouts = fields.content
    local toggles = settings.enabledFields
    for _, definition in ipairs(allFields()) do
        local field = layouts[definition.layoutName]
        if field then
            local followerState = fData.followerState
            local visible
            if definition.getLayout then
                local layout = definition.getLayout(followerState, fData)
                if definition.lastLayout ~= layout then
                    field.content = layout and ui.content { layout } or ui.content {}
                    definition.lastLayout = layout
                end
                visible = layout ~= nil
            else
                local text = definition.getText(followerState, fData)
                if definition.lastText ~= text then
                    field.props.text = text
                    definition.lastText = text
                end
                visible = text ~= nil
            end
            local isVisible = visible
                and (not definition.enabledSetting or enabledElements[definition.enabledSetting] ~= false)
                and (not definition.toggleKey or not toggles or toggles[definition.toggleKey] ~= false)
            if definition.lastVisible ~= isVisible then
                field.props.visible = isVisible
                field.props.autoSize = isVisible
                local spacer = fieldSpacers[definition.name]
                if spacer then
                    spacer.props.size = isVisible and spacerVisibleSize or spacerHiddenSize
                end
                definition.lastVisible = isVisible
            end
        end
    end
    tooltipElement:update()
end

settings = settingsCache.new(storage.playerSection("SettingsBestFriendsForever_tooltip"), async)

tooltipUI.registerField {
    name = "name",
    order = 1,
    header = true,
    getText = getActorName,
}

tooltipUI.registerField {
    name = "role",
    order = 2,
    toggleKey = "class",
    getText = getActorRole,
}

tooltipUI.registerField {
    name = "summon",
    order = 3,
    toggleKey = "summon",
    getText = function(followerState)
        if followerState.isSummon ~= true then
            return nil
        end
        return l10n("followerTooltip_summon")
    end,
}

tooltipUI.registerField {
    name = "diseases",
    order = 4,
    toggleKey = "diseases",
    textColor = damagedColor,
    getText = function(_, followerData)
        return getDiseaseText(followerData, settings.diseaseVerbosity)
    end,
}

tooltipUI.registerField {
    name = "statDamage",
    order = 5,
    toggleKey = "statDamage",
    textColor = damagedColor,
    getText = function(_, followerData)
        return getStatDamage(followerData)
    end,
}

tooltipUI.registerField {
    name = "injuries",
    order = 6,
    toggleKey = "injuries",
    textColor = damagedColor,
    getText = function(_, followerData)
        return getInjuries(followerData)
    end,
}

return tooltipUI
