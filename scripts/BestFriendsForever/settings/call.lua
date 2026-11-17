---@omw-context menu
local I = require("openmw.interfaces")

I.Settings.registerGroup {
    key = "SettingsBestFriendsForever_call",
    page = "BestFriendsForever",
    l10n = "BestFriendsForever",
    name = "call_groupName",
    description = "call_groupDesc",
    permanentStorage = true,
    order = 10,
    settings = {
        {
            key = "callKeybind",
            name = "callKeybind_name",
            description = "callKeybind_desc",
            renderer = "inputBinding",
            default = "BestFriendsForever_call",
            argument = {
                key = "BestFriendsForever_call",
                type = "action",
            },
        },
        {
            key = "callDistance",
            name = "callDistance_name",
            description = "callDistance_desc",
            renderer = "SuperSlider6",
            default = 200,
            argument = {
                min = -1000,
                max = 1000,
                step = 50,
                default = 200,
                showDefaultMark = true,
                showResetButton = true,
                bottomRow = true,
                minLabel = "In front of",
                maxLabel = "Behind",
            },
        },
    },
}
