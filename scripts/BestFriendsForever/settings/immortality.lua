---@omw-context global
local I = require("openmw.interfaces")

I.Settings.registerGroup {
    key = "SettingsBestFriendsForever_immortality",
    page = "BestFriendsForever",
    l10n = "BestFriendsForever",
    name = "immortality_groupName",
    description = "immortality_groupDesc",
    permanentStorage = true,
    order = 10,
    settings = {
        {
            key = "threshold",
            name = "threshold_name",
            description = "threshold_desc",
            renderer = "number",
            default = 10,
            argument = {
                min = 0,
            },
        },
        {
            key = "waitUntilCombatEnds",
            name = "waitUntilCombatEnds_name",
            renderer = "checkbox",
            default = true,
        },
        {
            key = "upDelay",
            name = "upDelay_name",
            description = "upDelay_desc",
            renderer = "number",
            default = 10,
            argument = {
                min = 0,
            },
        },
        {
            key = "ingoreCommanded",
            name = "ingoreCommanded_name",
            description = "ingoreCommanded_desc",
            renderer = "checkbox",
            default = true,
        },
        {
            key = "changeAggro",
            name = "changeAggro_name",
            description = "changeAggro_desc",
            renderer = "checkbox",
            default = true,
        },
    },
}
