---@diagnostic disable: undefined-field
---@omw-context player
local followerMenu = require("scripts.BestFriendsForever.ui.menu")

local function openFollowerMenu(followerState)
    followerMenu.open(followerState)
end

return {
    eventHandlers = {
        BestFriendsForever_openFollowerMenu = openFollowerMenu,
    },
    onUiModeChanged = followerMenu.onUiModeChanged,
    onFollowerListUpdated = followerMenu.onFollowerListUpdated,
    interface = {
        registerFollowerMenuButton = followerMenu.registerButton,
    },
}
