---@omw-context global
local I = require("openmw.interfaces")

I.Settings.registerGroup {
    key = "SettingsBestFriendsForever_catchUp",
    page = "BestFriendsForever",
    l10n = "BestFriendsForever",
    name = "catchUp_groupName",
    description = "catchUp_groupDesc",
    permanentStorage = true,
    order = 10,
    settings = {
        {
            key = "startDist",
            name = "startDist_name",
            description = "startDist_desc",
            renderer = "SuperSlider6",
            default = 500,
            argument = {
                max = 5000,
                step = 50,
                default = 500,
                showDefaultMark = true,
                showResetButton = true,
                bottomRow = true,
            },
        },
        {
            key = "maxDist",
            name = "maxDist_name",
            description = "maxDist_desc",
            renderer = "SuperSlider6",
            default = 4000,
            argument = {
                max = 5000,
                step = 50,
                default = 4000,
                showDefaultMark = true,
                showResetButton = true,
                bottomRow = true,
            },
        },
    },
}