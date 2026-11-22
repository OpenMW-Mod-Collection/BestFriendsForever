---@omw-context global
local I = require("openmw.interfaces")

I.Settings.registerGroup {
    key = "SettingsBestFriendsForever_catchUp",
    page = "BestFriendsForever",
    l10n = "BestFriendsForever_settings",
    name = "catchUp_groupName",
    description = "catchUp_groupDesc",
    permanentStorage = true,
    order = 10,
    settings = {
        {
            key = "distances",
            name = "distances_name",
            description = "distances_desc",
            renderer = "multiInput_V1",
            default = {
                startDist = 500,
                maxDist = 4000,
            },
            argument = {
                mode = "number",
                keys = {
                    "startDist",
                    "maxDist",
                },
                l10n = "BestFriendsForever_settings",
                width = 100,
                integer = true,
                min = {
                    startDist = 0,
                    maxDist = 0,
                },
                max = {
                    startDist = 5000,
                    maxDist = 5000,
                },
            },
        },
    },
}