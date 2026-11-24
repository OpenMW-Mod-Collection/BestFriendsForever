---@diagnostic disable: undefined-field, missing-fields, param-type-mismatch
---@omw-context player
local util = require("openmw.util")
local v2 = util.vector2
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local async = require("openmw.async")
local types = require("openmw.types")

local iconsUI = require("scripts.BestFriendsForever.ui.follower.icons")
local barsUI = require("scripts.BestFriendsForever.ui.follower.bars")
local followerMenu = require("scripts.BestFriendsForever.ui.menu")

local interval = { template = I.MWUI.templates.interval }
local sideToAlignment = {
    Left = "Start",
    Center = "Center",
    Right = "End",
}
local STAT_DEFINITIONS = {
    {
        name = "health",
        getStat = types.Actor.stats.dynamic.health,
        colorSetting = "healthBarColor",
    },
    {
        name = "magicka",
        getStat = types.Actor.stats.dynamic.magicka,
        colorSetting = "magickaBarColor",
    },
    {
        name = "fatigue",
        getStat = types.Actor.stats.dynamic.fatigue,
        colorSetting = "fatigueBarColor",
    },
}

local followerUI = {}

local function onWidgetMouseClick(data, element)
    local context = element.userData
    if context.consumeDragClick and context.consumeDragClick() then
        return true
    end
    followerMenu.open(context.followerState)
end

local function onWidgetMouseMove(data, element)
    local context = element.userData
    context.showTooltip(context.fData, data.position)
    -- let the HUD root's drag handler receive this event too
    return true
end

local function onWidgetFocusLoss(data, element)
    local context = element.userData
    context.hideTooltip(context.fData)
end

local widgetEventCallbacks = {
    mouseClick = async:callback(onWidgetMouseClick),
    mouseMove = async:callback(onWidgetMouseMove),
    focusLoss = async:callback(onWidgetFocusLoss),
}

---@class IconData
---@field container openmw.ui.Layout
---@field slots table
---@field spacer openmw.ui.Layout
---@field signature string|nil
---@field generation integer
---@field followerIcon table|nil

---@class BarData
---@field enabled boolean
---@field color openmw.util.Color
---@field size openmw.util.Vector2
---@field imgLayout openmw.ui.Layout|nil
---@field label openmw.ui.Layout|nil
---@field lastText string|nil
---@field lastColor openmw.util.Color|nil
---@field lastCurr number|nil
---@field lastBase number|nil

---@class StatEntry
---@field name "health"|"magicka"|"fatigue"
---@field stat openmw.types.DynamicStat|nil
---@field bar BarData

---@class FollowerData
---@field stats StatEntry[]
---@field icons IconData
---@field followerState table
---@field down boolean
---@field spells table
---@field activeEffects table
---@field attributes table<string, table>
---@field skills table<string, table>

---@param followerState table
---@param down boolean
---@param settings table
---@return FollowerData
local function newFollowerData(followerState, down, settings)
    local follower = followerState.actor
    local stats = {}
    local attributes = {}
    local skills = {}

    for _, definition in ipairs(STAT_DEFINITIONS) do
        stats[#stats + 1] = {
            name = definition.name,
            stat = definition.getStat(follower),
            bar = {
                enabled = settings.enabledElements[definition.name],
                color = settings[definition.colorSetting],
                size = barsUI.barSizeFor(definition.name, settings),
                imgLayout = nil,
                label = nil,
            },
        }
    end

    for statId, getStat in pairs(types.Actor.stats.attributes) do
        attributes[statId] = getStat(follower)
    end
    if types.NPC.objectIsInstance(follower) then
        for statId, getStat in pairs(types.NPC.stats.skills) do
            skills[statId] = getStat(follower)
        end
    end

    local fData = {
        followerState = followerState,
        down = down,
        spells = types.Actor.spells(follower),
        activeEffects = types.Actor.activeEffects(follower),
        attributes = attributes,
        skills = skills,
        icons = {},
        stats = stats,
    }

    iconsUI.prepareIcons(fData, settings)
    iconsUI.updateIcons(fData, settings)
    return fData
end

---@param fData FollowerData
---@param settings table
---@return openmw.ui.Layout
local function createBarsContainer(fData, settings)
    local bars = {}
    local barGap = math.max(0, tonumber(settings.barInterval) or 4)
    for _, statData in ipairs(fData.stats) do
        if statData.bar.enabled then
            if #bars > 0 then
                bars[#bars + 1] = { props = { size = v2(0, barGap) } }
            end
            bars[#bars + 1] = barsUI.barElement(statData, settings)
        end
    end

    return {
        name = "followerFlex_Bars",
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            arrange = ui.ALIGNMENT[sideToAlignment[settings.barAlignment] or "Center"],
        },
        content = ui.content(bars),
    }
end

---@param followerState table
---@param fData FollowerData
---@param settings table
---@param showTooltip fun(fData: FollowerData, position: openmw.util.Vector2)
---@param hideTooltip fun(fData: FollowerData)
---@param consumeDragClick fun(): boolean
---@return openmw.ui.Layout
local function createLayout(followerState, fData, settings, showTooltip, hideTooltip, consumeDragClick)
    local follower = followerState.actor
    local enabledElements = settings.enabledElements
    local barsContainer = createBarsContainer(fData, settings)
    local dataContent = { barsContainer }
    if settings.enabledElements.icons ~= false then
        local iconSpacer = { props = { size = v2(settings.iconInterval, 0) } }
        dataContent = settings.iconSide ~= "Left"
            and { barsContainer, iconSpacer, fData.icons.container }
            or { fData.icons.container, iconSpacer, barsContainer }
    end

    local dataFlex = {
        name = "followex_V1_H1",
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content(dataContent),
    }

    local followerContent = { dataFlex }
    if enabledElements.name then
        table.insert(followerContent, 1, {
            name = "followerName",
            template = I.MWUI.templates.textNormal,
            props = {
                text = follower.type.records[follower.recordId].name,
                textSize = settings.nameTextSize,
                textShadow = true,
                textColor = settings.nameColor,
            },
        })
        table.insert(followerContent, 2, interval)
    end

    local followerFlex = {
        name = "followerFlex_V1",
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            arrange = ui.ALIGNMENT[sideToAlignment[settings.uiAlign]],
        },
        userData = {
            actor = follower,
        },
        content = ui.content(followerContent),
    }

    return {
        name = "followerFlex_" .. follower.id,
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
        },
        events = widgetEventCallbacks,
        userData = {
            fData = fData,
            followerState = followerState,
            showTooltip = showTooltip,
            hideTooltip = hideTooltip,
            consumeDragClick = consumeDragClick,
        },
        content = ui.content {
            interval,
            followerFlex,
            interval,
        },
    }
end

---@param followerState table
---@param down boolean
---@param settings table
---@param showTooltip fun(fData: FollowerData, position: openmw.util.Vector2)
---@param hideTooltip fun(fData: FollowerData)
---@param consumeDragClick fun(): boolean
---@return FollowerData
---@return openmw.ui.Layout
followerUI.create = function(followerState, down, settings, showTooltip, hideTooltip, consumeDragClick)
    local fData = newFollowerData(followerState, down, settings)
    return fData, createLayout(followerState, fData, settings, showTooltip, hideTooltip, consumeDragClick)
end

---@param fData FollowerData
---@param settings table
followerUI.update = function(fData, settings)
    barsUI.updateStats(fData, fData.down, settings)
    iconsUI.updateIcons(fData, settings)
end

return followerUI
