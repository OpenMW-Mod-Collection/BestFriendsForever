---@diagnostic disable: undefined-field, param-type-mismatch, need-check-nil
---@omw-context player
local core = require("openmw.core")
local ui = require("openmw.ui")
local util = require("openmw.util")
local v2 = util.vector2
local types = require("openmw.types")

local l10n = core.l10n("BestFriendsForever_ui")
local commonUI = require("scripts.BestFriendsForever.utils.commonUI")
local rawUIMutators = require("scripts.BestFriendsForever.utils.rawUIMutators")

local WINDOW_ID = "BestFriendsForever_FollowerStats"
local MIN_BOX_WIDTH = 220
local MAX_BOX_WIDTH = 420
local BAR_WIDTH = 130
local MAX_VALUE_WIDTH = 120
local BOX_GAP = 8
local COLUMN_GAP = 10
local EXIT_GAP = 8
local EXIT_HEIGHT = 26
local LABEL_INDENT = "  "

local BOX_PADDING = commonUI.Sizes.BOX_INNER_PADDING
local BOX_FRAME_TOTAL = 2 * (commonUI.Sizes.BORDER + BOX_PADDING)
local OUTER_MARGIN = commonUI.Sizes.BOX_OUTER_PADDING
local ROW_HEIGHT = commonUI.Sizes.LINE_HEIGHT
local BORDER_WIDTH_TOTAL = commonUI.Sizes.BORDER_WIDTH_TOTAL
local HEADER_HEIGHT = commonUI.Sizes.HEADER_HEIGHT

local statsWindow = {}
local currentState
local window
local registered = false

local function closeStatsWindow()
    statsWindow.close()
end

local LABELS = {
    level = core.getGMST("sLevel"),
    race = core.getGMST("sRace"),
    class = core.getGMST("sClass"),
    faction = core.getGMST("sFaction"),
    major = core.getGMST("sSkillClassMajor"),
    minor = core.getGMST("sSkillClassMinor"),
    misc = core.getGMST("sSkillClassMisc"),
    combat = core.getGMST("sSpecializationCombat"),
    magic = core.getGMST("sSpecializationMagic"),
    stealth = core.getGMST("sSpecializationStealth"),
    expelled = core.getGMST("sExpelled"),
}

local DYNAMIC_STATS = {
    {
        get = types.Actor.stats.dynamic.health,
        label = core.getGMST("sHealth"),
        color = commonUI.Colors.BAR_HEALTH,
    },
    {
        get = types.Actor.stats.dynamic.magicka,
        label = core.getGMST("sMagic"),
        color = commonUI.Colors.BAR_MAGIC,
    },
    {
        get = types.Actor.stats.dynamic.fatigue,
        label = core.getGMST("sFatigue"),
        color = commonUI.Colors.BAR_FATIGUE,
    },
}

local function statColor(stat)
    if stat.modified > stat.base then
        return commonUI.Colors.POSITIVE
    elseif stat.modified < stat.base then
        return commonUI.Colors.DAMAGED
    end
    return nil
end

local function statValue(stat)
    if not stat then
        return "0", nil
    end
    return tostring(math.floor(stat.modified)), statColor(stat)
end

local function dynamicValues(stat)
    if not stat then
        return 0, 0
    end
    local max = math.max(0, math.floor(stat.base + stat.modifier))
    local current = util.clamp(math.floor(stat.current), 0, max)
    return current, max
end

local function estimateTextWidth(text, extra)
    return math.ceil(#tostring(text) * commonUI.Sizes.TEXT_NORMAL * 0.62) + (extra or 8)
end

local function addRow(rows, layout, width, height, fillWidth)
    rows[#rows + 1] = {
        layout = layout,
        width = width or 0,
        height = height or ROW_HEIGHT,
        fillWidth = fillWidth == true,
    }
end

local function addLabeledRow(rows, label, value, valueColor, labelColor, labelHeader)
    local valueWidth = math.min(estimateTextWidth(value, 8), MAX_VALUE_WIDTH)
    local layout = commonUI.labeledRow(label, value, {
        height = ROW_HEIGHT,
        labelColor = labelColor,
        labelHeader = labelHeader,
        valueColor = valueColor,
        valueWidth = valueWidth,
    })
    local width = estimateTextWidth(label, 12) + valueWidth + 12
    addRow(rows, layout, width, ROW_HEIGHT, true)
end

local function addHeaderRow(rows, label)
    addRow(rows, commonUI.headerRow(label), estimateTextWidth(label, 12), ROW_HEIGHT, true)
end

local function addBarRow(rows, label, stat, color)
    local current, max = dynamicValues(stat)
    local layout = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            autoSize = false,
            size = v2(0, ROW_HEIGHT),
            relativeSize = v2(1, 0),
            gap = 6,
        },
        content = ui.content {
            commonUI.text(label, { header = true, grow = true }),
            commonUI.bar {
                value = current,
                maxValue = max,
                size = v2(BAR_WIDTH, ROW_HEIGHT),
                color = color,
            },
        },
    }
    addRow(rows, layout, estimateTextWidth(label, 12) + BAR_WIDTH + 12, ROW_HEIGHT, true)
end

local function addDynamicRows(rows, actor)
    for _, definition in ipairs(DYNAMIC_STATS) do
        addBarRow(rows, definition.label, definition.get(actor), definition.color)
    end
end

local function makeBox(rows)
    local bodyWidth, bodyHeight = MIN_BOX_WIDTH, 0
    for _, row in ipairs(rows) do
        bodyWidth = math.max(bodyWidth, row.width)
        bodyHeight = bodyHeight + row.height
    end
    bodyWidth = math.min(bodyWidth, MAX_BOX_WIDTH)

    local width = bodyWidth + BOX_FRAME_TOTAL
    local height = bodyHeight + BOX_FRAME_TOTAL

    local content = ui.content {}
    for _, row in ipairs(rows) do
        content:add(row.layout)
    end

    local body = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            autoSize = false,
            size = v2(bodyWidth, bodyHeight),
        },
        content = content,
    }

    local box = commonUI.borderedBox(body)
    box.props.size = v2(width, height)
    return {
        layout = box,
        body = body,
        rows = rows,
        width = width,
        height = height,
        bodyWidth = bodyWidth,
        bodyHeight = bodyHeight,
    }
end

local function makeColumn(boxes, columnWidth, footer)
    local width = columnWidth or 0
    if not columnWidth then
        for _, box in ipairs(boxes) do
            width = math.max(width, box.width)
        end
    end

    local boxesHeight = 0
    for index, box in ipairs(boxes) do
        local innerWidth = width - BOX_FRAME_TOTAL
        box.layout.props.size = v2(width, box.height)
        box.body.props.size = v2(innerWidth, box.bodyHeight)
        box.bodyWidth = innerWidth
        for _, row in ipairs(box.rows) do
            row.layout.props = row.layout.props or {}
            row.layout.props.size = v2(row.fillWidth and 0 or innerWidth, row.height)
        end
        boxesHeight = boxesHeight + box.height
        if index > 1 then
            boxesHeight = boxesHeight + BOX_GAP
        end
    end

    local content = ui.content {}
    for index, box in ipairs(boxes) do
        content:add(box.layout)
        if index < #boxes then
            content:add(commonUI.intervalV(BOX_GAP))
        end
    end

    local naturalHeight = boxesHeight
    if footer then
        content:add {
            type = ui.TYPE.Flex,
            external = { grow = 1, stretch = 1 },
            props = {},
        }
        content:add(commonUI.intervalV(EXIT_GAP))
        content:add(footer)
        naturalHeight = naturalHeight + EXIT_GAP + EXIT_HEIGHT
    end

    local column = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            autoSize = false,
            size = v2(width, naturalHeight),
        },
        content = content,
    }
    return column, width, naturalHeight
end

local function addNpcSkillRows(rows, actor)
    local record = actor.type.records[actor.recordId]
    local classRecord = record and types.NPC.classes.records[record.class]
    local seen = {}

    local function addGroup(headerLabel, skillIds)
        addHeaderRow(rows, headerLabel)
        for _, skillId in ipairs(skillIds or {}) do
            local skillRecord = core.stats.Skill.records[skillId]
            if skillRecord then
                seen[skillId] = true
                local value, color = statValue(types.NPC.stats.skills[skillId](actor))
                addLabeledRow(rows, LABEL_INDENT .. skillRecord.name, value, color)
            end
        end
    end

    addGroup(LABELS.major, classRecord and classRecord.majorSkills)
    addRow(rows, commonUI.divider(), 0, ROW_HEIGHT, true)
    addGroup(LABELS.minor, classRecord and classRecord.minorSkills)
    addRow(rows, commonUI.divider(), 0, ROW_HEIGHT, true)

    local misc = {}
    for _, skillRecord in ipairs(core.stats.Skill.records) do
        if not seen[skillRecord.id] then
            misc[#misc + 1] = skillRecord.id
        end
    end
    addGroup(LABELS.misc, misc)
end

local function addCreatureSkillRows(rows, record)
    addHeaderRow(rows, l10n("statsWindow_skills"))
    addLabeledRow(rows, LABEL_INDENT .. LABELS.combat, tostring(record.combatSkill or 0))
    addLabeledRow(rows, LABEL_INDENT .. LABELS.magic, tostring(record.magicSkill or 0))
    addLabeledRow(rows, LABEL_INDENT .. LABELS.stealth, tostring(record.stealthSkill or 0))
end

local function creatureTypeLabel(record)
    return commonUI.creatureTypeLabel(record.type) or tostring(record.type or record.name or "")
end

local function buildContent(actor)
    local isCreature = types.Creature.objectIsInstance(actor)
    local leftBoxes, rightRows = {}, {}

    local dynamicRows = {}
    addDynamicRows(dynamicRows, actor)
    leftBoxes[#leftBoxes + 1] = makeBox(dynamicRows)

    local identityRows = {}
    local attributeRows = {}

    if isCreature then
        local actorRecord = actor.type.records[actor.recordId] or {}
        local record = types.Creature.records[actor.recordId] or actorRecord
        local baseRecord = record.baseCreature and types.Creature.records[record.baseCreature]

        addLabeledRow(identityRows, LABELS.level, tostring(types.Actor.stats.level(actor).current), nil, nil, true)
        addLabeledRow(identityRows, l10n("Creature Type"), creatureTypeLabel(record), nil, nil, true)
        addLabeledRow(
            identityRows,
            l10n("Base Creature"),
            baseRecord and baseRecord.name or record.name or actorRecord.name or "",
            nil,
            nil,
            true
        )
        leftBoxes[#leftBoxes + 1] = makeBox(identityRows)

        for _, attribute in ipairs(core.stats.Attribute.records) do
            local value, color = statValue(types.Actor.stats.attributes[attribute.id](actor))
            addLabeledRow(attributeRows, attribute.name, value, color)
        end
        leftBoxes[#leftBoxes + 1] = makeBox(attributeRows)

        addCreatureSkillRows(rightRows, record)
        leftBoxes[#leftBoxes + 1] = makeBox(rightRows)
    else
        local actorRecord = actor.type.records[actor.recordId] or {}
        local raceRecord = types.NPC.races.records[actorRecord.race]
        local classRecord = types.NPC.classes.records[actorRecord.class]

        addLabeledRow(identityRows, LABELS.level, tostring(types.Actor.stats.level(actor).current), nil, nil, true)
        addLabeledRow(identityRows, LABELS.race, raceRecord and raceRecord.name or "", nil, nil, true)
        addLabeledRow(identityRows, LABELS.class, classRecord and classRecord.name or "", nil, nil, true)
        leftBoxes[#leftBoxes + 1] = makeBox(identityRows)

        for _, attribute in ipairs(core.stats.Attribute.records) do
            local value, color = statValue(types.Actor.stats.attributes[attribute.id](actor))
            addLabeledRow(attributeRows, attribute.name, value, color)
        end
        leftBoxes[#leftBoxes + 1] = makeBox(attributeRows)

        local factionRows = {}
        addHeaderRow(factionRows, LABELS.faction)
        for _, factionId in ipairs(types.NPC.getFactions(actor)) do
            local factionRecord = core.factions.records[factionId]
            local value = types.NPC.isExpelled(actor, factionId)
                and LABELS.expelled
                or tostring(types.NPC.getFactionRank(actor, factionId))
            addLabeledRow(factionRows, LABEL_INDENT .. (factionRecord and factionRecord.name), value)
        end
        leftBoxes[#leftBoxes + 1] = makeBox(factionRows)

        addNpcSkillRows(rightRows, actor)
    end

    local rightBox = not isCreature and makeBox(rightRows) or nil
    local columnWidth = 0
    for _, box in ipairs(leftBoxes) do
        columnWidth = math.max(columnWidth, box.width)
    end
    if rightBox then
        columnWidth = math.max(columnWidth, rightBox.width)
    end

    local exitButton = commonUI.button(
        l10n("statsWindow_exit"),
        commonUI.Sizes.TEXT_NORMAL,
        closeStatsWindow,
        "BestFriendsForever_statsWindow_exit"
    )
    local exitFooter = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            align = ui.ALIGNMENT.Start,
        },
        content = ui.content { exitButton },
    }

    local leftColumn, _, leftHeight = makeColumn(leftBoxes, columnWidth, exitFooter)
    local rightColumn
    local rightHeight = 0
    if rightBox then
        rightColumn, _, rightHeight = makeColumn({ rightBox }, columnWidth)
    end
    local columnsWidth = rightColumn and columnWidth * 2 + COLUMN_GAP or columnWidth
    local columnsHeight = math.max(leftHeight, rightHeight)
    leftColumn.props.size = v2(columnWidth, columnsHeight)
    if rightColumn then
        rightColumn.props.size = v2(columnWidth, columnsHeight)
    end

    local columnContent = ui.content { leftColumn }
    if rightColumn then
        columnContent:add(rightColumn)
    end

    local columns = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            gap = COLUMN_GAP,
        },
        content = columnContent,
    }

    local body = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
        },
        content = ui.content { columns },
    }

    local horizontallyPadded = {
        type = ui.TYPE.Flex,
        props = { horizontal = true },
        content = ui.content {
            commonUI.intervalH(OUTER_MARGIN),
            body,
            commonUI.intervalH(OUTER_MARGIN),
        },
    }

    local outer = {
        type = ui.TYPE.Flex,
        props = { horizontal = false },
        content = ui.content {
            commonUI.intervalV(OUTER_MARGIN),
            horizontallyPadded,
            commonUI.intervalV(OUTER_MARGIN),
        },
    }

    local content = ui.content { outer }
    local innerSize = v2(
        columnsWidth + 2 * OUTER_MARGIN,
        columnsHeight + 2 * OUTER_MARGIN
    )
    local windowSize = v2(
        innerSize.x + BORDER_WIDTH_TOTAL,
        innerSize.y + BORDER_WIDTH_TOTAL + HEADER_HEIGHT
    )
    return content, windowSize
end

function statsWindow.open(followerState)
    if not registered or not followerState or not followerState.actor then
        return
    end
    statsWindow.close(true)
    currentState = followerState

    local actor = followerState.actor
    local record = actor.type.records[actor.recordId]
    local title = record and record.name or l10n("statsWindow_title")
    local content, size = buildContent(actor)
    size = v2(math.max(size.x, estimateTextWidth(title, 64)), size.y)

    window = commonUI.createWindow {
        name = WINDOW_ID,
        title = title,
        size = size,
        content = content,
    }
end

function statsWindow.close(keepState)
    if window then
        window:destroy()
        window = nil
    end
    if not keepState then
        currentState = nil
    end
end

function statsWindow.ensureOnTop()
    if currentState then
        statsWindow.open(currentState)
    end
end

function statsWindow.register()
    if registered then
        return
    end
    rawUIMutators.register {
        name = "BestFriendsForever_followerStats_zOrder",
        afterMenuBuild = function()
            statsWindow.ensureOnTop()
        end,
    }
    registered = true
end

return statsWindow
