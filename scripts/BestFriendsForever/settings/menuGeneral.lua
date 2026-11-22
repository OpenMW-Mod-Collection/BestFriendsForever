---@omw-context menu
local I = require("openmw.interfaces")

I.Settings.registerGroup {
    key = "SettingsBestFriendsForever_menuGeneral",
    page = "BestFriendsForever_Menu",
    l10n = "BestFriendsForever_settings",
    name = "menuGeneral_groupName",
    permanentStorage = true,
    order = 10,
    settings = {
        {
            key = "maxButtonsPerPage",
            name = "maxButtonsPerPage_name",
            renderer = "number",
            default = 10,
            argument = {
                min = 1,
            },
        },
    },
}
