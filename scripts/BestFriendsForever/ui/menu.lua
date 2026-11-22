---@diagnostic disable: undefined-field, missing-fields, param-type-mismatch
---@omw-context player
local ui = require("openmw.ui")
local util = require("openmw.util")
local I = require("openmw.interfaces")
local core = require("openmw.core")
local self = require("openmw.self")
local async = require("openmw.async")
local storage = require("openmw.storage")

local settingsCache = require("scripts.BestFriendsForever.utils.settingsCache")
local rawUIMutators = require("scripts.BestFriendsForever.utils.rawUIMutators")
local buttonTemplates = require("scripts.BestFriendsForever.utils.commonUI")
local companionShare = require("scripts.BestFriendsForever.ui.menuItems.companionShare")
local wait = require("scripts.BestFriendsForever.ui.menuItems.wait")
local repairGear = require("scripts.BestFriendsForever.ui.menuItems.repairGear")
local statsWindow = require("scripts.BestFriendsForever.ui.menuItems.statsWindow")

local MENU_MODE = "Interface"
local BUTTON_TARGETS = {
    player = true,
    follower = true,
    global = true,
}

local followerMenu = {}
local buttonsByName = {}
local currentFollowerState
local currentPage = 1
local root
local buttonElements = {}
local buttonsByLayoutName = {}
local actionButtonsByName = {}
local settings

local function conditionMet(button, state)
    if not button.condition then
        return true
    end
    return button.condition(state)
end

local function destroyMenu()
    if root then
        root:destroy()
        root = nil
    end
    for _, element in ipairs(buttonElements) do
        if element.layout then
            element:destroy()
        end
    end
    buttonElements = {}
    buttonsByLayoutName = {}
    actionButtonsByName = {}
end

local function closeMenu(restoreGame)
    destroyMenu()
    statsWindow.close()
    currentFollowerState = nil
    currentPage = 1
    if restoreGame then
        I.UI.setMode()
    end
end

local function sortedButtons()
    local buttons = {}
    for _, button in pairs(buttonsByName) do
        buttons[#buttons + 1] = button
    end
    table.sort(buttons, function(left, right)
        local leftName = left.name:lower()
        local rightName = right.name:lower()
        if leftName == rightName then
            return left.name < right.name
        end
        return leftName < rightName
    end)
    return buttons
end

local function addButtonElement(content, label, name, onClick, disabled, actionName)
    local element = buttonTemplates.button(label, 16, onClick, name, nil, disabled)
    buttonElements[#buttonElements + 1] = element
    buttonsByLayoutName[name] = element
    if actionName then
        actionButtonsByName[actionName] = element
    end
    content:add(element)
    return element
end

local function buildMenu()
    if not currentFollowerState then
        return
    end

    destroyMenu()
    local buttons = sortedButtons()
    local pageSize = math.max(1, math.floor(tonumber(settings.maxButtonsPerPage) or 10))
    local pageCount = math.max(1, math.ceil(#buttons / pageSize))
    currentPage = math.max(1, math.min(currentPage, pageCount))
    local firstIndex = (currentPage - 1) * pageSize + 1
    local lastIndex = math.min(firstIndex + pageSize - 1, #buttons)
    local content = ui.content {
        {
            name = "followerMenuHeader",
            template = I.MWUI.templates.textHeader,
            props = {
                text = currentFollowerState.actor.type.records[currentFollowerState.actor.recordId].name,
                textAlignH = ui.ALIGNMENT.Center,
                textAlignV = ui.ALIGNMENT.Center,
                textShadow = true,
            },
        },
        { props = { size = util.vector2(0, 8) } },
    }

    for index = firstIndex, lastIndex do
        local button = buttons[index]
        local enabled = conditionMet(button, currentFollowerState)
        addButtonElement(content, button.name, "followerMenuAction_" .. index, function()
            local state = currentFollowerState
            if not state or not enabled or not conditionMet(button, state) then
                return
            end

            if button.action then
                button.action(state)
            elseif button.target == "player" then
                self:sendEvent(button.event, state)
            elseif button.target == "follower" then
                state.actor:sendEvent(button.event, state)
            else
                core.sendGlobalEvent(button.event, state)
            end

            if button.closeAfterActivation then
                closeMenu(false)
            end
        end, false, button.name)
        content:add { props = { size = util.vector2(0, 6) } }
    end

    content:add {
        template = I.MWUI.templates.horizontalLine,
        props = {
            size = util.vector2(300, 2),
        },
    }
    content:add { props = { size = util.vector2(0, 8) } }

    local navigation = ui.content {}
    -- TODO: disable butttons if nowhere to paginate further
    addButtonElement(navigation, "Previous", "followerMenuPrevious", function()
        currentPage = currentPage - 1
        buildMenu()
    end)
    navigation:add(buttonTemplates.intervalH(12))
    addButtonElement(navigation, "Exit", "followerMenuExit", function()
        closeMenu(true)
    end)
    navigation:add(buttonTemplates.intervalH(12))
    addButtonElement(navigation, "Next", "followerMenuNext", function()
        currentPage = currentPage + 1
        buildMenu()
    end)

    content:add {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
        },
        content = navigation,
    }

    local menuLayout = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            arrange = ui.ALIGNMENT.Center,
        },
        content = content,
    }
    local doublePadding = {
        template = I.MWUI.templates.padding,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content { menuLayout },
            },
        },
    }
    root = ui.create {
        name = "BestFriendsForever_FollowerMenu",
        layer = "Windows",
        template = I.MWUI.templates.boxSolidThick,
        props = {
            relativePosition = util.vector2(0.5, 0.5),
            anchor = util.vector2(0.5, 0.5),
        },
        content = ui.content { doublePadding },
    }
    rawUIMutators.afterMenuBuild(followerMenu.getSnapshot())
    for _, element in ipairs(buttonElements) do
        element:update()
    end
    root:update()
end

function followerMenu.getSnapshot()
    return {
        root = root,
        state = currentFollowerState,
        page = currentPage,
        buttons = buttonsByLayoutName,
        actions = actionButtonsByName,
    }
end

function followerMenu.refresh()
    for _, element in ipairs(buttonElements) do
        element:update()
    end
    if root then
        root:update()
    end
end

function followerMenu.rebuild()
    if currentFollowerState then
        buildMenu()
    end
end

function followerMenu.registerButton(button)
    if type(button) ~= "table" then
        error("Follower menu button must be a table")
    end
    if type(button.name) ~= "string" or not button.name:match("%S") then
        error("Follower menu button name must be a non-empty string")
    end

    if button.action ~= nil and type(button.action) ~= "function" then
        error("Follower menu button action must be a function")
    end
    if button.event ~= nil and (type(button.event) ~= "string" or not button.event:match("%S")) then
        error("Follower menu button event must be a non-empty string")
    end

    local hasAction = button.action ~= nil
    local hasEvent = button.event ~= nil
    if hasAction == hasEvent then
        error("Follower menu button must define exactly one of action or event")
    end
    if hasEvent and not BUTTON_TARGETS[button.target] then
        error("Follower menu event target must be player, follower, or global")
    end
    if hasAction and button.target ~= nil then
        error("Follower menu action buttons cannot define an event target")
    end
    if button.closeAfterActivation ~= nil and type(button.closeAfterActivation) ~= "boolean" then
        error("Follower menu closeAfterActivation must be a boolean")
    end
    if button.condition ~= nil and type(button.condition) ~= "function" then
        error("Follower menu button condition must be a function")
    end

    local key = button.name:lower()
    if buttonsByName[key] then
        error("A follower menu button named '" .. button.name .. "' is already registered")
    end

    buttonsByName[key] = {
        name = button.name,
        action = button.action,
        event = button.event,
        target = button.target,
        closeAfterActivation = button.closeAfterActivation == true,
        condition = button.condition,
    }
    if currentFollowerState then
        buildMenu()
    end
end

function followerMenu.open(state)
    if type(state) ~= "table" or not state.actor then
        error("Follower menu requires a Follower Detection Util state")
    end

    if I.UI.getMode() == "MainMenu" then
        return
    end

    currentFollowerState = state
    currentPage = 1
    I.UI.setMode(MENU_MODE, { windows = {} })
    buildMenu()
end

function followerMenu.onUiModeChanged(data)
    if currentFollowerState and data.newMode ~= MENU_MODE then
        closeMenu(false)
    end
end

function followerMenu.onFollowerListUpdated(followers)
    if not currentFollowerState then
        return
    end
    local updatedState = followers[currentFollowerState.actor.id]
    if not updatedState then
        closeMenu(true)
        return
    end
    currentFollowerState = updatedState
end

settings = settingsCache.new(storage.playerSection("SettingsBestFriendsForever_menu"), async)

followerMenu.registerButton(companionShare)
followerMenu.registerButton(wait)
followerMenu.registerButton(repairGear)
followerMenu.registerButton(statsWindow)

return followerMenu
