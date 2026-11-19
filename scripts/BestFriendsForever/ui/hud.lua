---@diagnostic disable: undefined-field, missing-fields, param-type-mismatch
---@omw-context player
local util = require("openmw.util")
local v2 = util.vector2
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local async = require("openmw.async")
local self = require("openmw.self")

local settingsCache = require("scripts.BestFriendsForever.utils.settingsCache")
local followerUI = require("scripts.BestFriendsForever.ui.follower.widget")
local tooltipUI = require("scripts.BestFriendsForever.ui.tooltip")

local followerHUD = {}

---@type table<string, FollowerData>
followerHUD.followerData = {}
---@type openmw.ui.Element|nil
followerHUD.tooltipElement = nil
local activeTooltipData

followerHUD.hudDisplayMap = {
    ---@param uiMode string
    ---@return boolean
    ["Always"] = function(uiMode)
        return I.UI.isHudVisible()
    end,
    ---@param uiMode string
    ---@return boolean
    ["Interface Only"] = function(uiMode)
        return uiMode ~= nil and uiMode ~= "MainMenu" and I.UI.isHudVisible()
    end,
    ---@param uiMode string
    ---@return boolean
    ["Hide on Interface"] = function(uiMode)
        return (not uiMode or uiMode == "MainMenu") and I.UI.isHudVisible()
    end,
    ---@param uiMode string
    ---@return boolean
    ["Hide on Dialogue Only"] = function(uiMode)
        return uiMode ~= I.UI.MODE.Dialogue and I.UI.isHudVisible()
    end,
}

-- Settings

local settingsWrapper

local function settingsUpdated()
    if not settingsWrapper or not settingsWrapper.enable then
        if followerHUD.root then
            followerHUD.destroy()
        end
        return
    end
    followerHUD.new(I.FollowerDetectionUtil.getFollowerList())
end

local wrapperSection = storage.playerSection("SettingsBestFriendsForever_HUDWrapper")
settingsWrapper = settingsCache.new(wrapperSection, async, settingsUpdated)
local settingsLocalHUD =
    settingsCache.new(storage.playerSection("SettingsBestFriendsForever_HUDFollower"), async, settingsUpdated)
local settingsBlacklists =
    settingsCache.new(storage.globalSection("SettingsBestFriendsForever_blacklist"), async, settingsUpdated)

-- Utilities

local function padding(x, y)
    return { props = { size = v2(x, y) } }
end

local function blacklisted(actor, blacklist)
    local mwscript = actor.type.records[actor.recordId].mwscript
    if mwscript then
        if mwscript:find("^ab01wlcr") then
            return true
        end

        if blacklist[mwscript] then
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

-- Layout constants

local delimiterW = 10
local delimiterH = 15
local alignToAnchor = {
    Right = 0,
    Down = 0,
    Center = 0.5,
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
    template = settingsWrapper.horizontalLayout and I.MWUI.templates.verticalLine or I.MWUI.templates.horizontalLine,
    props = {
        relativePosition = v2(0.5, 0.5),
        anchor = v2(0.5, 0.5),
    },
}
local tooltipCursorOffset = v2(16, 16)
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

-- Dragging

local function mousePress(data, elem)
    if data.button ~= 1 or settingsWrapper.lockPosition then
        return
    end -- Left mouse button
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
    if not (elem.userData and elem.userData.isDragging) then
        return
    end
    -- Calculate new position based on mouse movement
    local deltaX = data.position.x - elem.userData.dragStartPosition.x
    local deltaY = data.position.y - elem.userData.dragStartPosition.y
    local newPosition =
        util.vector2(elem.userData.windowStartPosition.x + deltaX, elem.userData.windowStartPosition.y + deltaY)
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

-- Layout construction

local function createRoot()
    local layer = settingsWrapper.lockPosition and "HUD" or "Modal"
    rootFlex = {
        name = "rootFlex",
        type = ui.TYPE.Flex,
        props = {
            horizontal = settingsWrapper.horizontalLayout,
            arrange = ui.ALIGNMENT[sideToAlignment[settingsLocalHUD.uiAlign]],
        },
        content = ui.content {},
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
        content = ui.content { rootFlexPadding },
    }

    return ui.create {
        name = "root",
        layer = layer,
        template = I.MWUI.templates.boxTransparent,
        props = {
            alpha = settingsWrapper.enableBordersAndBg and 1 or 0,
            position = v2(settingsWrapper.posX, settingsWrapper.posY),
            anchor = v2(
                alignToAnchor[settingsWrapper.expansionDirectionH],
                alignToAnchor[settingsWrapper.expansionDirectionV]
            ),
        },
        events = wrapperEventCallbacks,
        content = ui.content { rootOuterPadding },
        userData = {
            windowStartPosition = v2(settingsWrapper.posX, settingsWrapper.posY),
        },
    }
end

local function hideTooltip(fData)
    if fData and activeTooltipData ~= fData then
        return
    end
    activeTooltipData = nil

    local tooltipElement = followerHUD.tooltipElement
    if tooltipElement and tooltipElement.layout then
        tooltipElement.layout.props.visible = false
        tooltipElement:update()
    end
end

local function showTooltip(fData, mousePosition)
    local tooltipElement = followerHUD.tooltipElement
    if
        not tooltipElement
        or not tooltipElement.layout
        or not followerHUD.root
        or not followerHUD.root.layout
        or followerHUD.followerData[fData.followerState.actor.id] ~= fData
        or followerHUD.root.layout.props.visible == false
    then
        return
    end

    if activeTooltipData ~= fData then
        activeTooltipData = fData
        tooltipUI.update(tooltipElement, fData, settingsLocalHUD.enabledElements)
    end

    tooltipElement.layout.props.position = mousePosition + tooltipCursorOffset
    tooltipElement.layout.props.visible = true
    tooltipElement:update()
end

---@return openmw.ui.Layout
local function makeDelimiter()
    if settingsWrapper.enableBordersAndBg then
        delimiterLine.template = settingsWrapper.horizontalLayout and I.MWUI.templates.verticalLine
            or I.MWUI.templates.horizontalLine
        return delimiter
    else
        return delimiterPadding
    end
end

followerHUD.updateRootVisibility = function(uiMode)
    -- why is this even being triggered?
    if not followerHUD.root or not followerHUD.root.layout then
        return
    end

    local isModeAllowed = followerHUD.hudDisplayMap[settingsWrapper.hudDisplay]
    followerHUD.root.layout.props.visible = #rootFlex.content ~= 0 and isModeAllowed(uiMode)
    if not followerHUD.root.layout.props.visible then
        hideTooltip()
    end
end

followerHUD.destroy = function()
    if followerHUD.root then
        followerHUD.root:destroy()
        followerHUD.root = nil
    end
    if followerHUD.tooltipElement then
        followerHUD.tooltipElement:destroy()
        followerHUD.tooltipElement = nil
    end
    followerHUD.followerData = {}
    activeTooltipData = nil
end

followerHUD.rebuildTooltip = function()
    if not followerHUD.root then
        return
    end
    if followerHUD.tooltipElement then
        followerHUD.tooltipElement:destroy()
    end
    followerHUD.tooltipElement = tooltipUI.create(settingsWrapper.lockPosition and "HUD" or "Modal")
    activeTooltipData = nil
end

followerHUD.new = function(followers)
    followerHUD.destroy()
    followerHUD.root = createRoot()
    followerHUD.tooltipElement = tooltipUI.create(settingsWrapper.lockPosition and "HUD" or "Modal")
    followerHUD.followerData = {}
    local downedFollowers = I.BestFriendsForever and I.BestFriendsForever.getDownedFollowers() or {}

    local widgetCount = 0
    for _, fState in pairs(followers) do
        if widgetCount >= settingsWrapper.maxWidgets then
            break
        end

        local myFollower = fState.superLeader and fState.superLeader.id == self.id
            or fState.leader and fState.leader.id == self.id
        local banned = blacklisted(fState.actor, settingsBlacklists.globalScriptBlacklist)
        if myFollower and not banned then
            if #rootFlex.content ~= 0 then
                rootFlex.content:add(makeDelimiter())
            end

            local down = downedFollowers[fState.actor.id]
            local actorId = fState.actor.id
            local fData
            local layout
            fData, layout = followerUI.create(fState, down, settingsLocalHUD, showTooltip, hideTooltip)
            followerHUD.followerData[actorId] = fData
            rootFlex.content:add(layout)
            widgetCount = widgetCount + 1
        end
    end

    followerHUD.updateRootVisibility(I.UI.getMode())
    followerHUD.root:update()
end

followerHUD.updateData = function()
    for _, fData in pairs(followerHUD.followerData) do
        followerUI.update(fData, settingsLocalHUD)
    end
    if activeTooltipData and followerHUD.tooltipElement then
        tooltipUI.update(followerHUD.tooltipElement, activeTooltipData, settingsLocalHUD.enabledElements)
    end
    followerHUD.updateRootVisibility(I.UI.getMode())
    followerHUD.root:update()
end

return followerHUD
