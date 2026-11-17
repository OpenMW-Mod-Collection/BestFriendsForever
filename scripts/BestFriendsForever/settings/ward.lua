---@omw-context global
local I = require("openmw.interfaces")

I.Settings.registerGroup {
    key = "SettingsBestFriendsForever_ward",
    page = "BestFriendsForever",
    l10n = "BestFriendsForever",
    name = "ward_groupName",
    description = "ward_groupDesc",
    permanentStorage = true,
    order = 10,
    settings = {
        {
            key = "disableDiseases",
            name = "disableDiseases_name",
            renderer = "checkbox",
            default = true,
        },
        {
            key = "disableStatDamage",
            name = "disableStatDamage_name",
            renderer = "checkbox",
            default = true,
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
