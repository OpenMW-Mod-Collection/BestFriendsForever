---@omw-context menu
local I = require("openmw.interfaces")

I.Settings.registerGroup {
    key = "SettingsBestFriendsForever_menu",
    page = "BestFriendsForever_HUD",
    l10n = "BestFriendsForever",
    name = "menu_groupName",
    description = "menu_groupDesc",
    permanentStorage = true,
    order = 24,
    settings = {
        {
            key = "maxButtonsPerPage",
            name = "maxButtonsPerPage_name",
            description = "maxButtonsPerPage_desc",
            renderer = "number",
            default = 10,
            argument = {
                min = 1,
            },
        },
    },
}
