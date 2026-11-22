---@omw-context menu
local I = require("openmw.interfaces")

local groups = {
    "call",
    "HUDFollower",
    "HUDWrapper",
    "tooltip",
    "menuGeneral",
    "menuRepair",
}

I.Settings.registerPage {
    key = "BestFriendsForever",
    l10n = "BestFriendsForever_settings",
    name = "page_name",
    description = "page_description",
}

I.Settings.registerPage {
    key = "BestFriendsForever_HUD",
    l10n = "BestFriendsForever_settings",
    name = "page_HUD_name",
    description = "page_HUD_description",
}

I.Settings.registerPage {
    key = "BestFriendsForever_Menu",
    l10n = "BestFriendsForever_settings",
    name = "page_Menu_name",
    description = "page_Menu_description",
}

for _, group in ipairs(groups) do
    require("scripts.BestFriendsForever.settings." .. group)
end
