---@omw-context global
local I = require("openmw.interfaces")

I.Settings.registerGroup {
    key = "SettingsBestFriendsForever_toggles",
    page = "BestFriendsForever",
    l10n = "BestFriendsForever_settings",
    name = "toggles_groupName",
    permanentStorage = true,
    order = 0,
    settings = {
        {
            key = "enableTeleport",
            name = "enableTeleport_name",
            description = "enableTeleport_desc",
            renderer = "checkbox",
            default = true,
        },
        {
            key = "enableImmortality",
            name = "enableImmortality_name",
            description = "enableImmortality_desc",
            renderer = "checkbox",
            default = true,
        },
        {
            key = "enableCatchUp",
            name = "enableCatchUp_name",
            description = "enableCatchUp_desc",
            renderer = "checkbox",
            default = true,
        },
        {
            key = "enableWard",
            name = "enableWard_name",
            description = "enableWard_desc",
            renderer = "checkbox",
            default = false,
        },
    },
}
