---@diagnostic disable: undefined-field, missing-fields, param-type-mismatch
---@omw-context player
local util = require("openmw.util")
local v2 = util.vector2
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local async = require("openmw.async")
local types = require("openmw.types")
local self = require("openmw.self")
local core = require("openmw.core")

local settingsCache = require("scripts.BestFriendsForever.utils.settingsCache")
local iconsUI = require("scripts.BestFriendsForever.ui.icons")
local barsUI = require("scripts.BestFriendsForever.ui.bars")

local followerUI = {}

---@class IconData
---@field container openmw.ui.Layout|nil
---@field combatLayout openmw.ui.Layout|nil     Layout node for the combat icon image; nil if combatIcon setting is off
---@field debuffLayout openmw.ui.Layout|nil     Layout node for the debuff icon image; nil if no debuff or setting is off

---@class BarData
---@field enabled boolean                   Whether this bar is shown
---@field color openmw.util.Color           Bar fill color
---@field imgLayout openmw.ui.Layout|nil    Layout node for the bar image; nil until the follower's UI is built
---@field label openmw.ui.Layout|nil        Layout node for the current/base label; nil if barLabels is off or UI not yet built

---@class StatEntry
---@field name "health"|"magicka"|"fatigue"
---@field stat openmw.types.DynamicStat|nil     Live stat proxy from dynamic stats
---@field bar BarData

---@class FollowerData
---@field stats StatEntry[]     Ordered: [1]=health, [2]=magicka, [3]=fatigue
---@field icons IconData
---@field actor GameObject
---@field down boolean

---@type table<string, FollowerData>
followerUI.followerData = {}

-- +---------------------+
-- | Settings Management |
-- +---------------------+

local function settingsUpdated()
    followerUI.new(I.FollowerDetectionUtil.getFollowerList())
end

local wrapperSection = storage.playerSection("SettingsBestFriendsForever_UIWrapper")
local settingsWrapper = settingsCache.new(
    wrapperSection,
    async,
    settingsUpdated
)
local settingsLocalUI = settingsCache.new(
    storage.playerSection("SettingsBestFriendsForever_UIFollower"),
    async,
    settingsUpdated
)
local settingsBlacklists = settingsCache.new(
    storage.globalSection("SettingsBestFriendsForever_blacklist"),
    async,
    settingsUpdated
)

-- +-------------------+
-- | Utility Functions |
-- +-------------------+

local function padding(x, y)
    return { props = { size = v2(x, y) } }
end

local function blacklisted(actor, blacklist)
    local mwscript = actor.type.records[actor.recordId].mwscript
    if mwscript then
        for _, blacklistedScript in ipairs(blacklist) do
            if mwscript == blacklistedScript then
                return true
            end
        end
    end
    return false
end

-- +------------------+
-- | Actual variables |
-- +------------------+

local delimiterW = 10
local delimiterH = 15
local alignToAnchor = {
    Start = 0,
    Center = .5,
    End = 1
}
local sideToAlignment = {
    Left = "Start",
    Center = "Center",
    Right = "End",
}
local interval = { template = I.MWUI.templates.interval }
local delimiterPadding = padding(delimiterW, delimiterH)
local delimiterLine = {
    template = settingsWrapper.horizontalLayout
        and I.MWUI.templates.verticalLine
        or I.MWUI.templates.horizontalLine,
    props = {
        relativePosition = v2(0.5, 0.5),
        anchor = v2(0.5, 0.5),
    },
}
local delimiter = {
    external = {
        stretch = 1,
    },
    props = {
        size = v2(delimiterW, delimiterH),
    },
    content = ui.content { delimiterLine },
}
local rootFlex

-- +--------------------+
-- | Draggable UI logic |
-- +--------------------+

local function mousePress(data, elem)
    if data.button ~= 1 or settingsWrapper.lockPosition then return end -- Left mouse button
    if not elem.userData then
        elem.userData = {}
    end
    elem.userData.isDragging = true
    elem.userData.dragStartPosition = data.position
    elem.userData.windowStartPosition = followerUI.root.layout.props.position
        or v2(settingsWrapper.posX, settingsWrapper.posY)

    followerUI.root:update()
end

local function mouseMove(data, elem)
    if not (elem.userData and elem.userData.isDragging) then return end
    -- Calculate new position based on mouse movement
    local deltaX = data.position.x - elem.userData.dragStartPosition.x
    local deltaY = data.position.y - elem.userData.dragStartPosition.y
    local newPosition = util.vector2(
        elem.userData.windowStartPosition.x + deltaX,
        elem.userData.windowStartPosition.y + deltaY
    )
    followerUI.root.layout.props.position = newPosition

    followerUI.root:update()
end

local function mouseRelease(data, elem)
    if elem.userData then
        elem.userData.isDragging = false
    end
    -- kinda idiotic way of doing things, but it works
    I.BestFriendsForever.setPosSettings(
        math.floor(followerUI.root.layout.props.position.x),
        math.floor(followerUI.root.layout.props.position.y)
    )
    followerUI.root:update()
end

local wrapperEventCallbacks = {
    mousePress = async:callback(mousePress),
    mouseMove = async:callback(mouseMove),
    mouseRelease = async:callback(mouseRelease),
}

-- +------------------+
-- | Mental illnesses |
-- +------------------+

local function createRoot()
    rootFlex = {
        name = "rootFlex",
        type = ui.TYPE.Flex,
        props = {
            horizontal = settingsWrapper.horizontalLayout,
            arrange = ui.ALIGNMENT[sideToAlignment[settingsLocalUI.uiAlign]],
        },
        content = ui.content {}
    }

    local rootFlexPadding = {
        name = "rootFlexPadding",
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
        },
        content = ui.content {
            interval,
            rootFlex,
            interval,
        },
    }

    local rootOuterPadding = {
        name = "rootOuterPadding",
        template = I.MWUI.templates.padding,
        props = {
            inheritAlpha = false,
        },
        content = ui.content { rootFlexPadding }
    }

    return ui.create {
        name = "root",
        layer = settingsWrapper.lockPosition and "HUD" or "Modal",
        template = I.MWUI.templates.boxTransparent,
        props = {
            alpha = settingsWrapper.enableBordersAndBg and 1 or 0,
            position = v2(settingsWrapper.posX, settingsWrapper.posY),
            anchor = v2(
                alignToAnchor[settingsWrapper.expansionDirection],
                alignToAnchor[settingsWrapper.expansionDirection]
            )
        },
        events = wrapperEventCallbacks,
        content = ui.content { rootOuterPadding },
        userData = {
            windowStartPosition = v2(settingsWrapper.posX, settingsWrapper.posY)
        },
    }
end

---@param follower GameObject
---@param down boolean
local function newFollowerData(follower, down)
    followerUI.followerData[follower.id] = {
        actor = follower,
        down = down,
        icons = {
            container = {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = settingsLocalUI.horizontalIcons,
                },
                content = ui.content {},
            },
            combatLayout = nil,
            debuffLayout = nil,
        },
        stats = {
            {
                name = "health",
                stat = types.Actor.stats.dynamic.health(follower),
                bar = {
                    enabled = settingsLocalUI.healthBarEnabled,
                    color = settingsLocalUI.healthBarColor,
                    imgLayout = nil,
                    label = nil,
                },
            },
            {
                name = "magicka",
                stat = types.Actor.stats.dynamic.magicka(follower),
                bar = {
                    enabled = settingsLocalUI.magickaBarEnabled,
                    color = settingsLocalUI.magickaBarColor,
                    imgLayout = nil,
                    label = nil,
                },
            },
            {
                name = "fatigue",
                stat = types.Actor.stats.dynamic.fatigue(follower),
                bar = {
                    enabled = settingsLocalUI.fatigueBarEnabled,
                    color = settingsLocalUI.fatigueBarColor,
                    imgLayout = nil,
                    label = nil,
                },
            },
        },
    }
end

---**Returns** bar container and **embeds** icon container into the fData if possible
---@param fData FollowerData
---@return openmw.ui.Layout
local function prepareDataContainers(fData)
    local bars = {}
    for _, data in pairs(fData.stats) do
        local bar = barsUI.barElement(data)
        if data.bar.enabled then
            bars[#bars + 1] = interval
            bars[#bars + 1] = bar
        end
    end

    local barsContainer = {
        name = "followerFlex_Bars",
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
        },
        content = ui.content(bars)
    }

    if settingsLocalUI.combatIcon then
        fData.icons.combatLayout = iconsUI.renderCombat(fData.actor)

        local disease, effect = iconsUI.getDebuff(fData.actor)
        local debuffLayout = iconsUI.renderDebuff(disease, effect)
        fData.icons.debuffLayout = debuffLayout

        iconsUI.placeIconsIntoContainers(fData, disease or effect)
    end

    return barsContainer
end

---@param follower GameObject
---@return openmw.ui.Layout
local function createFollowerFlex(follower, down)
    newFollowerData(follower, down)
    local fData = followerUI.followerData[follower.id]

    local barsContainer = prepareDataContainers(fData)

    local dataFlex = {
        name = "followex_V1_H1",
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            settingsLocalUI.rightIcons and barsContainer or fData.icons.container,
            interval,
            settingsLocalUI.rightIcons and fData.icons.container or barsContainer,
        },
    }

    local followerName = {
        name = "followerName",
        template = I.MWUI.templates.textNormal,
        props = {
            text = follower.type.records[follower.recordId].name,
            textSize = settingsLocalUI.nameTextSize,
            textShadow = true,
            textColor = settingsLocalUI.nameColor,
        },
    }

    local followerFlex = {
        name = "followerFlex_V1",
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            arrange = ui.ALIGNMENT[settingsLocalUI.uiAlign],
        },
        userData = {
            actor = follower,
        },
        events = {
            mouseClick = async:callback(function()
                self:sendEvent("BestFriendsForever_followerWidgetClicked", follower)
                follower:sendEvent("BestFriendsForever_followerWidgetClicked")
                core.sendGlobalEvent("BestFriendsForever_followerWidgetClicked", follower)
            end),
        },
        content = ui.content {
            followerName,
            dataFlex,
        },
    }

    return {
        name = "followerFlex_" .. follower.id,
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
        },
        content = ui.content {
            interval,
            followerFlex,
            interval,
        }
    }
end

---@return openmw.ui.Layout
local function makeDelimiter()
    if settingsWrapper.enableBordersAndBg then
        delimiterLine.template = settingsWrapper.horizontalLayout
            and I.MWUI.templates.verticalLine
            or I.MWUI.templates.horizontalLine
        return delimiter
    else
        return delimiterPadding
    end
end

followerUI.new = function(followers)
    rootFlex.content = ui.content {}
    followerUI.root:destroy()
    followerUI.root = createRoot()
    followerUI.followerData = {}
    local downedFollowers = I.BestFriendsForever
        and I.BestFriendsForever.getDownedFollowers()
        or {}

    for _, fState in pairs(followers) do
        local myFollower = fState.superLeader and fState.superLeader.id == self.id
            or fState.leader and fState.leader.id == self.id
        local banned = blacklisted(fState.actor, settingsBlacklists.globalBlacklistByScript)
        if not myFollower or banned then
            goto continue
        end

        if #rootFlex.content ~= 0 then
            rootFlex.content:add(makeDelimiter())
        end

        local down = downedFollowers[fState.actor.id]
        rootFlex.content:add(createFollowerFlex(fState.actor, down))

        ::continue::
    end

    followerUI.root.layout.props.visible = #rootFlex.content ~= 0
    followerUI.root:update()
end

local function updateStats(fData, down)
    local barSize = v2(settingsLocalUI.barLength, settingsLocalUI.barWidth)
    for _, statData in ipairs(fData.stats) do
        local label = statData.bar.label
        if label then
            if down then
                label.props.text = nil
            else
                label.props.text = barsUI.labelText(statData.stat.current, statData.stat.base)
            end
        end
        local imgLayout = statData.bar.imgLayout
        if imgLayout then
            if down then
                statData.bar.imgLayout.props.color = util.color.rgb(.5, .5, .5)
                imgLayout.props.size = barsUI.barImgSize(barSize, statData.stat.base, statData.stat.base)
            else
                imgLayout.props.size = barsUI.barImgSize(barSize, statData.stat.current, statData.stat.base)
                statData.bar.imgLayout.props.color = statData.bar.color
            end
        end
    end
end

local function updateIcons(fData, down)
    fData.icons.container.props.visible = not down
    if not down then
        fData.icons.combatLayout.content = iconsUI.renderCombat(fData.actor).content
        local disease, effect = iconsUI.getDebuff(fData.actor)
        fData.icons.debuffLayout.content = iconsUI.renderDebuff(disease, effect).content
        fData.icons.container.content = ui.content {}
        iconsUI.placeIconsIntoContainers(fData, disease or effect)
    end
end

followerUI.updateData = function()
    for _, fData in pairs(followerUI.followerData) do
        local down = fData.down and settingsLocalUI.immortalityIntegration
        updateStats(fData, down)
        updateIcons(fData, down)
    end
    followerUI.root:update()
end

followerUI.root = createRoot()

return followerUI
