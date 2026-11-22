---@omw-context global
local I = require("openmw.interfaces")

I.Settings.registerGroup {
    key = "SettingsBestFriendsForever_ward",
    page = "BestFriendsForever",
    l10n = "BestFriendsForever_settings",
    name = "ward_groupName",
    description = "ward_groupDesc",
    permanentStorage = true,
    order = 10,
    settings = {
        {
            key = "protections",
            name = "protections_name",
            description = "protections_desc",
            renderer = "multiCheckbox_V1",
            default = {
                diseases = true,
                statDamage = true,
            },
            argument = {
                l10n = "BestFriendsForever_settings",
                keys = {
                    "diseases",
                    "statDamage",
                },
            },
        },
        {
            key = "statDamageCheckFrequency",
            name = "statDamageCheckFrequency_name",
            description = "statDamageCheckFrequency_desc",
            renderer = "number",
            default = 300,
            argument = {
                min = 0,
            },
        },
    },
}
