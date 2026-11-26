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
            renderer = "multiCheckbox_V1",
            default = {
                class = true,
                summon = true,
                diseases = true,
                statDamage = true,
                injuries = true,
            },
            argument = {
                l10n = "BestFriendsForever_settings",
                keys = {
                    "class",
                    "summon",
                    "diseases",
                    "statDamage",
                    "injuries",
                },
            },
        },
        {
            key = "diseaseVerbosity",
            name = "diseaseVerbosity_name",
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
