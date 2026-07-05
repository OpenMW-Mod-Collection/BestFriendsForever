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

local followerHUD = {}

---@class IconData
---@field container openmw.ui.Layout|nil
---@field combatLayout openmw.ui.Layout|nil     Layout node for the combat icon image; nil if combatIcon setting is off
---@field debuffLayout openmw.ui.Layout|nil     Layout node for the debuff icon image; nil if no debuff or setting is off

---@class BarData
---@field enabled boolean                   Whether this bar is shown
---@field color openmw.util.Color           Bar fill color
---@field imgLayout openmw.ui.Layout|nil    Layout node for the bar image; nil until the follower's HUD is built
---@field label openmw.ui.Layout|nil        Layout node for the current/base label; nil if barLabels is off or HUD not yet built

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
followerHUD.followerData = {}

followerHUD.hudDisplayMap = {
    ---@param uiMode string
    ---@return boolean
    ["Always"] = function(uiMode)
        return I.UI.isHudVisible()
    end,
    ---@param uiMode string
    ---@return boolean
    ["Interface Only"] = function(uiMode)
        return uiMode ~= nil
            and uiMode ~= "MainMenu"
            and I.UI.isHudVisible()
    end,
    ---@param uiMode string
    ---@return boolean
    ["Hide on Interface"] = function(uiMode)
        return (not uiMode or uiMode == "MainMenu")
            and I.UI.isHudVisible()
    end,
    ---@param uiMode string
    ---@return boolean
    ["Hide on Dialogue Only"] = function(uiMode)
        return uiMode ~= I.UI.MODE.Dialogue
            and I.UI.isHudVisible()
    end
}

-- +---------------------+
-- | Settings Management |
-- +---------------------+

local function settingsUpdated()
    followerHUD.new(I.FollowerDetectionUtil.getFollowerList())
end

local wrapperSection = storage.playerSection("SettingsBestFriendsForever_HUDWrapper")
local settingsWrapper = settingsCache.new(
    wrapperSection,
    async,
    settingsUpdated
)
local settingsLocalHUD = settingsCache.new(
    storage.playerSection("SettingsBestFriendsForever_HUDFollower"),
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
        if mwscript:find("^ab01wlcr") then
            return true
        end

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
    Right = 0,
    Down = 0,
    Center = .5,
    Left = 1,
    Up = 1,
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
-- | Dragging HUD logic |
-- +--------------------+

local function mousePress(data, elem)
    if data.button ~= 1 or settingsWrapper.lockPosition then return end -- Left mouse button
    if not elem.userData then
        elem.userData = {}
    end
    elem.userData.isDragging = true
    elem.userData.dragStartPosition = data.position
    elem.userData.windowStartPosition = followerHUD.root.layout.props.position
        or v2(settingsWrapper.posX, settingsWrapper.posY)

    followerHUD.root:update()
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
    followerHUD.root.layout.props.position = newPosition

    followerHUD.root:update()
end

local function mouseRelease(data, elem)
    if elem.userData then
        elem.userData.isDragging = false
    end
    -- kinda idiotic way of doing things, but it works
    I.BestFriendsForever.setPosSettings(
        math.floor(followerHUD.root.layout.props.position.x),
        math.floor(followerHUD.root.layout.props.position.y)
    )
    followerHUD.root:update()
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
            arrange = ui.ALIGNMENT[sideToAlignment[settingsLocalHUD.uiAlign]],
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
                alignToAnchor[settingsWrapper.expansionDirectionH],
                alignToAnchor[settingsWrapper.expansionDirectionV]
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
    followerHUD.followerData[follower.id] = {
        actor = follower,
        down = down,
        icons = {
            container = {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = settingsLocalHUD.horizontalIcons,
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
                    enabled = settingsLocalHUD.healthBarEnabled,
                    color = settingsLocalHUD.healthBarColor,
                    imgLayout = nil,
                    label = nil,
                },
            },
            {
                name = "magicka",
                stat = types.Actor.stats.dynamic.magicka(follower),
                bar = {
                    enabled = settingsLocalHUD.magickaBarEnabled,
                    color = settingsLocalHUD.magickaBarColor,
                    imgLayout = nil,
                    label = nil,
                },
            },
            {
                name = "fatigue",
                stat = types.Actor.stats.dynamic.fatigue(follower),
                bar = {
                    enabled = settingsLocalHUD.fatigueBarEnabled,
                    color = settingsLocalHUD.fatigueBarColor,
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

    if settingsLocalHUD.combatIcon then
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
    local fData = followerHUD.followerData[follower.id]

    local barsContainer = prepareDataContainers(fData)

    local dataFlex = {
        name = "followex_V1_H1",
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            settingsLocalHUD.rightIcons and barsContainer or fData.icons.container,
            interval,
            settingsLocalHUD.rightIcons and fData.icons.container or barsContainer,
        },
    }

    local followerName = {
        name = "followerName",
        template = I.MWUI.templates.textNormal,
        props = {
            text = follower.type.records[follower.recordId].name,
            textSize = settingsLocalHUD.nameTextSize,
            textShadow = true,
            textColor = settingsLocalHUD.nameColor,
        },
    }

    local followerFlex = {
        name = "followerFlex_V1",
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            arrange = ui.ALIGNMENT[sideToAlignment[settingsLocalHUD.uiAlign]],
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

followerHUD.updateRootVisibility = function(uiMode)
    -- why is this even being triggered?
    if not followerHUD.root or not followerHUD.root.layout then return end

    local isModeAllowed = followerHUD.hudDisplayMap[settingsWrapper.hudDisplay]
    followerHUD.root.layout.props.visible = #rootFlex.content ~= 0
        and isModeAllowed(uiMode)
end

followerHUD.new = function(followers)
    rootFlex.content = ui.content {}
    followerHUD.root:destroy()
    followerHUD.root = createRoot()
    followerHUD.followerData = {}
    local downedFollowers = I.BestFriendsForever
        and I.BestFriendsForever.getDownedFollowers()
        or {}

    local widgetCount = 0
    for _, fState in pairs(followers) do
        if widgetCount > settingsWrapper.maxWidgets then
            break
        end

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
        widgetCount = widgetCount + 1

        ::continue::
    end

    followerHUD.updateRootVisibility(I.UI.getMode())
    followerHUD.root:update()
end

followerHUD.updateData = function()
    for _, fData in pairs(followerHUD.followerData) do
        local down = fData.down and settingsLocalHUD.immortalityIntegration
        barsUI.updateStats(fData, down)
        iconsUI.updateIcons(fData, down)
    end
    followerHUD.updateRootVisibility(I.UI.getMode())
    followerHUD.root:update()
end

followerHUD.root = createRoot()

return followerHUD
