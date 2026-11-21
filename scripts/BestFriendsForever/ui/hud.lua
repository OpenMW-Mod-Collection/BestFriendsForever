---@diagnostic disable: undefined-field, missing-fields, param-type-mismatch
---@omw-context player
local util = require("openmw.util")
local v2 = util.vector2
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local types = require("openmw.types")
local storage = require("openmw.storage")
local async = require("openmw.async")
local self = require("openmw.self")
local input = require("openmw.input")

local settingsCache = require("scripts.BestFriendsForever.utils.settingsCache")
local followerUI = require("scripts.BestFriendsForever.ui.follower.widget")
local tooltipUI = require("scripts.BestFriendsForever.ui.tooltip")

-- Constants
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
local delimiterPadding = { props = { size = v2(delimiterW, delimiterH) } }
local delimiterLine = {
    props = {
        relativePosition = v2(0.5, 0.5),
        anchor = v2(0.5, 0.5),
    },
}
local tooltipCursorOffset = v2(16, 16)
local tooltipLayer = "Notification"
local delimiter = {
    external = {
        stretch = 1,
    },
    props = {
        size = v2(delimiterW, delimiterH),
    },
    content = ui.content { delimiterLine },
}

-- Variables
local followerHUD = {}

---@type table<string, FollowerData>
followerHUD.followerData = {}
---@type openmw.ui.Element|nil
followerHUD.tooltipElement = nil
local activeTooltipData
local dragClickSuppressed = false
local settingsWrapper
local settingsLocalHUD
local settingsBlacklists
local rootFlex
local wrapperEventCallbacks

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

local function settingsUpdated(key)
    if key == "posX" or key == "posY" then
        if settingsWrapper and followerHUD.root and followerHUD.root.layout then
            followerHUD.root.layout.props.position = v2(settingsWrapper.posX, settingsWrapper.posY)
            followerHUD.root:update()
        end
        return
    end
    if not settingsWrapper or not settingsWrapper.enable then
        if followerHUD.root then
            followerHUD.destroy()
        end
        return
    end
    followerHUD.new(I.FollowerDetectionUtil.getFollowerList())
end

-- Utilities

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

local function primaryWeight(primary, state)
    local actor = state.actor
    if primary == "NPCs first" then
        return types.NPC.objectIsInstance(actor) and 0 or 1
    elseif primary == "Creatures first" then
        return types.Creature.objectIsInstance(actor) and 0 or 1
    elseif primary == "By level" then
        return -(types.Actor.stats.level(actor).current or 0)
    elseif primary == "By max health" then
        return -(types.Actor.stats.dynamic.health(actor).max or 0)
    end
end

local function nameOf(state)
    return state.actor.type.records[state.actor.recordId].name or ""
end

local function sortedFollowers(followers)
    local list = {}
    for _, state in pairs(followers) do
        list[#list + 1] = state
    end

    local primary = settingsLocalHUD.primarySort
    local keepSummonsAtBottom = settingsLocalHUD.keepSummonsAtBottom == true

    table.sort(list, function(left, right)
        if keepSummonsAtBottom then
            local leftSummon = left.isSummon == true
            local rightSummon = right.isSummon == true
            if leftSummon ~= rightSummon then
                return not leftSummon
            end
        end

        local leftWeight = primaryWeight(primary, left)
        local rightWeight = primaryWeight(primary, right)
        if leftWeight and rightWeight and leftWeight ~= rightWeight then
            return leftWeight < rightWeight
        end

        local leftName = nameOf(left):lower()
        local rightName = nameOf(right):lower()
        return leftName < rightName
    end)

    return list
end

local modifierChecks = {
    Ctrl = function()
        return input.isCtrlPressed()
    end,
    Alt = function()
        return input.isAltPressed()
    end,
    Shift = function()
        return input.isShiftPressed()
    end,
}

local function canDrag()
    local mode = settingsWrapper.dragModifier
    if mode == "Disabled" then
        return false
    end
    local check = modifierChecks[mode]
    return not check or check()
end

local function hudLayer()
    return settingsWrapper.dragModifier == "Disabled" and "HUD" or "Modal"
end

local function consumeDragClick()
    local suppressed = dragClickSuppressed
    dragClickSuppressed = false
    return suppressed
end

-- Dragging

local function mousePress(data, elem)
    if data.button ~= 1 then
        return
    end -- Left mouse button
    dragClickSuppressed = false
    if not canDrag() then
        return
    end
    if not elem.userData then
        elem.userData = {}
    end
    elem.userData.didDrag = false
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
    if math.abs(deltaX) > 3 or math.abs(deltaY) > 3 then
        elem.userData.didDrag = true
    end
    local newPosition =
        util.vector2(elem.userData.windowStartPosition.x + deltaX, elem.userData.windowStartPosition.y + deltaY)
    followerHUD.root.layout.props.position = newPosition

    followerHUD.root:update()
end

local function mouseRelease(data, elem)
    if elem.userData then
        dragClickSuppressed = elem.userData.didDrag == true
        elem.userData.isDragging = false
    end
    -- kinda idiotic way of doing things, but it works
    I.BestFriendsForever.setPosSettings(
        math.floor(followerHUD.root.layout.props.position.x),
        math.floor(followerHUD.root.layout.props.position.y)
    )
    followerHUD.root:update()
end

-- Layout construction

local function createRoot()
    local layer = hudLayer()
    rootFlex = {
        name = "rootFlex",
        type = ui.TYPE.Flex,
        props = {
            horizontal = settingsWrapper.hudOrientation == "Horizontal",
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
        delimiterLine.template = settingsWrapper.hudOrientation == "Horizontal" and I.MWUI.templates.verticalLine
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
    followerHUD.tooltipElement = tooltipUI.create(tooltipLayer)
    activeTooltipData = nil
end

followerHUD.new = function(followers)
    followerHUD.destroy()
    followerHUD.root = createRoot()
    followerHUD.tooltipElement = tooltipUI.create(tooltipLayer)
    followerHUD.followerData = {}
    local downedFollowers = I.BestFriendsForever and I.BestFriendsForever.getDownedFollowers() or {}

    local widgetCount = 0
    for _, fState in pairs(sortedFollowers(followers)) do
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
            fData, layout =
                followerUI.create(fState, down, settingsLocalHUD, showTooltip, hideTooltip, consumeDragClick)
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

-- Initialization
local wrapperSection = storage.playerSection("SettingsBestFriendsForever_HUDWrapper")
settingsWrapper = settingsCache.new(wrapperSection, async, settingsUpdated)
settingsLocalHUD =
    settingsCache.new(storage.playerSection("SettingsBestFriendsForever_HUDFollower"), async, settingsUpdated)
settingsBlacklists =
    settingsCache.new(storage.globalSection("SettingsBestFriendsForever_blacklist"), async, settingsUpdated)

wrapperEventCallbacks = {
    mousePress = async:callback(mousePress),
    mouseMove = async:callback(mouseMove),
    mouseRelease = async:callback(mouseRelease),
}

return followerHUD
