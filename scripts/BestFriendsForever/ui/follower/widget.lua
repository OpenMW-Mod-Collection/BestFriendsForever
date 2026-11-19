---@diagnostic disable: undefined-field, missing-fields, param-type-mismatch
---@omw-context player
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local async = require("openmw.async")
local types = require("openmw.types")

local iconsUI = require("scripts.BestFriendsForever.ui.follower.icons")
local barsUI = require("scripts.BestFriendsForever.ui.follower.bars")
local followerMenu = require("scripts.BestFriendsForever.ui.menu")

local followerUI = {}
local interval = { template = I.MWUI.templates.interval }
local sideToAlignment = {
    Left = "Start",
    Center = "Center",
    Right = "End",
}

---@class IconData
---@field container openmw.ui.Layout

---@class BarData
---@field enabled boolean
---@field color openmw.util.Color
---@field imgLayout openmw.ui.Layout|nil
---@field label openmw.ui.Layout|nil

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
        icons = {
            container = {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = settings.horizontalIcons,
                },
                content = ui.content {},
            },
        },
        stats = stats,
    }

    iconsUI.updateIcons(fData)
    return fData
end

---@param fData FollowerData
---@param settings table
---@return openmw.ui.Layout
local function createBarsContainer(fData, settings)
    local bars = {}
    for _, statData in ipairs(fData.stats) do
        local bar = barsUI.barElement(statData, settings)
        if statData.bar.enabled then
            bars[#bars + 1] = interval
            bars[#bars + 1] = bar
        end
    end

    return {
        name = "followerFlex_Bars",
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
        },
        content = ui.content(bars),
    }
end

---@param followerState table
---@param fData FollowerData
---@param settings table
---@param showTooltip fun(fData: FollowerData, position: openmw.util.Vector2)
---@param hideTooltip fun(fData: FollowerData)
---@return openmw.ui.Layout
local function createLayout(followerState, fData, settings, showTooltip, hideTooltip)
    local follower = followerState.actor
    local enabledElements = settings.enabledElements
    local barsContainer = createBarsContainer(fData, settings)
    local dataContent = settings.rightIcons and { barsContainer, interval, fData.icons.container }
        or { fData.icons.container, interval, barsContainer }

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
        events = {
            mouseClick = async:callback(function()
                followerMenu.open(followerState)
            end),
            mouseMove = async:callback(function(data)
                showTooltip(fData, data.position)
            end),
            focusLoss = async:callback(function()
                hideTooltip(fData)
            end),
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
---@return FollowerData
---@return openmw.ui.Layout
followerUI.create = function(followerState, down, settings, showTooltip, hideTooltip)
    local fData = newFollowerData(followerState, down, settings)
    return fData, createLayout(followerState, fData, settings, showTooltip, hideTooltip)
end

---@param fData FollowerData
---@param settings table
followerUI.update = function(fData, settings)
    barsUI.updateStats(fData, fData.down, settings)
    iconsUI.updateIcons(fData)
end

return followerUI
