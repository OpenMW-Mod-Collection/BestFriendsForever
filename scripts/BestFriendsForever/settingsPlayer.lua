---@omw-context menu
local I = require("openmw.interfaces")

I.Settings.registerPage {
    key = "BestFriendsForever",
    l10n = "BestFriendsForever",
    name = "page_name",
    description = "page_description",
}

I.Settings.registerPage {
    key = "BestFriendsForever_HUD",
    l10n = "BestFriendsForever",
    name = "page_HUD_name",
    description = "page_HUD_description",
}

local groups = {
    "call",
    "HUDFollower",
    "HUDWrapper",
}

for _, group in ipairs(groups) do
    require("scripts.BestFriendsForever.settings." .. group)
end
