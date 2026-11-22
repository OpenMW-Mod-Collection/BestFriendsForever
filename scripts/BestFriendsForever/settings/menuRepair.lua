---@omw-context menu
local I = require("openmw.interfaces")

I.Settings.registerGroup {
    key = "SettingsBestFriendsForever_menuRepair",
    page = "BestFriendsForever_Menu",
    l10n = "BestFriendsForever_settings",
    name = "menuRepair_groupName",
    permanentStorage = true,
    order = 20,
    settings = {
        {
            key = "repairScope",
            name = "repairScope_name",
            renderer = "SuperSelect3",
            default = "Equipped Only",
            argument = {
                l10n = "BestFriendsForever_settings",
                items = {
                    "Equipped Only",
                    "All Inventory",
                },
            },
        },
        {
            key = "repairThreshold",
            name = "repairThreshold_name",
            description = "repairThreshold_desc",
            renderer = "SuperSlider6",
            default = 85,
            argument = {
                min = 0,
                max = 100,
                step = 5,
                default = 85,
                showDefaultMark = true,
                showResetButton = true,
                bottomRow = true,
                unit = "%",
            },
        },
        {
            key = "hidePlayerDamaged",
            name = "hidePlayerDamaged_name",
            description = "hidePlayerDamaged_desc",
            renderer = "checkbox",
            default = true,
        },
        {
            key = "repairToolSource",
            name = "repairToolSource_name",
            description = "repairToolSource_desc",
            renderer = "SuperSelect3",
            default = "Player First",
            argument = {
                l10n = "BestFriendsForever_settings",
                items = {
                    "Player First",
                    "Follower First",
                },
            },
        },
        {
            key = "repairToolInitialPreference",
            name = "repairToolInitialPreference_name",
            description = "repairToolInitialPreference_desc",
            renderer = "SuperSelect3",
            default = "Highest Quality",
            argument = {
                l10n = "BestFriendsForever_settings",
                items = {
                    "Highest Quality",
                    "Highest Max Uses",
                    "Highest Weight",
                },
                width = 200,
            },
        },
    },
}
