---@omw-context menu
local I = require("openmw.interfaces")

I.Settings.registerGroup {
    key = "SettingsBestFriendsForever_tooltip",
    page = "BestFriendsForever_HUD",
    l10n = "BestFriendsForever_settings",
    name = "tooltip_groupName",
    description = "tooltip_groupDesc",
    permanentStorage = true,
    order = 23,
    settings = {
        {
            key = "enabledFields",
            name = "enabledFields_name",
            description = "enabledFields_desc",
            renderer = "multiCheckbox_V1",
            default = {
                class = true,
                diseases = true,
                statDamage = true,
            },
            argument = {
                l10n = "BestFriendsForever_settings",
                keys = {
                    "class",
                    "diseases",
                    "statDamage",
                },
            },
        },
        {
            key = "diseaseVerbosity",
            name = "diseaseVerbosity_name",
            description = "diseaseVerbosity_desc",
            renderer = "SuperSelect3",
            default = "Names",
            argument = {
                l10n = "BestFriendsForever_settings",
                items = {
                    "Names",
                    "By Type",
                    "Unclear",
                },
            },
        },
    },
}
