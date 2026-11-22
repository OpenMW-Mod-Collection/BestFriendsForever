---@omw-context menu
local I = require("openmw.interfaces")

I.Settings.registerGroup {
    key = "SettingsBestFriendsForever_menu",
    page = "BestFriendsForever_HUD",
    l10n = "BestFriendsForever_settings",
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
        {
            key = "repairScope",
            name = "repairScope_name",
            description = "repairScope_desc",
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
