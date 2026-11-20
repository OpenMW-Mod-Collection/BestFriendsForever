---@omw-context menu
local I = require("openmw.interfaces")
local util = require("openmw.util")

local common = require("scripts.BestFriendsForever.settings.common")

I.Settings.registerGroup {
    key = "SettingsBestFriendsForever_HUDFollower",
    page = "BestFriendsForever_HUD",
    l10n = "BestFriendsForever",
    name = "HUDFollower_groupName",
    permanentStorage = true,
    order = 21,
    settings = {
        {
            key = "enabledElements",
            name = "enabledElements_name",
            description = "enabledElements_desc",
            renderer = "multiCheckbox_V1",
            default = {
                name = true,
                health = true,
                magicka = true,
                fatigue = true,
                labels = true,
            },
            argument = {
                l10n = "BestFriendsForever",
                keys = {
                    "name",
                    "health",
                    "magicka",
                    "fatigue",
                    "labels",
                },
            },
        },
        {
            key = "nameTextSize",
            name = "nameTextSize_name",
            renderer = "SuperSlider6",
            default = 18,
            argument = {
                min = 1,
                default = 18,
                showDefaultMark = true,
                showResetButton = true,
                bottomRow = true,
            },
        },
        {
            key = "uiAlign",
            name = "uiAlign_name",
            renderer = "SuperSelect3",
            argument = {
                l10n = "BestFriendsForever",
                items = {
                    "Left",
                    "Center",
                    "Right",
                },
            },
            default = "Center",
        },
        {
            key = "barLength",
            name = "barLength_name",
            renderer = "SuperSlider6",
            default = 100,
            argument = {
                max = 500,
                default = 100,
                showDefaultMark = true,
                showResetButton = true,
                bottomRow = true,
            },
        },
        {
            key = "barWidth",
            name = "barWidth_name",
            renderer = "SuperSlider6",
            default = 16,
            argument = {
                max = 50,
                default = 16,
                showDefaultMark = true,
                showResetButton = true,
                bottomRow = true,
            },
        },
        {
            key = "labelDisplayMode",
            name = "labelDisplayMode_name",
            renderer = "SuperSelect3",
            default = "Current/Max",
            argument = {
                l10n = "BestFriendsForever",
                items = {
                    "Current",
                    "Current/Max",
                    "Percent",
                },
                width = 200,
            },
        },
        {
            key = "horizontalIcons",
            name = "horizontalIcons_name",
            renderer = "checkbox",
            default = true,
        },
        {
            key = "rightIcons",
            name = "rightIcons_name",
            renderer = "checkbox",
            default = true,
        },
        {
            key = "nameColor",
            name = "nameColor_name",
            renderer = "SuperColorPicker2",
            default = util.color.hex("eee2c9"),
            argument = {
                presetColors = common.presetColors,
            },
        },
        {
            key = "healthBarColor",
            name = "healthBarColor_name",
            renderer = "SuperColorPicker2",
            default = util.color.hex("c83c1e"),
            argument = {
                presetColors = common.presetColors,
            },
        },
        {
            key = "magickaBarColor",
            name = "magickaBarColor_name",
            renderer = "SuperColorPicker2",
            default = util.color.hex("35459f"),
            argument = {
                presetColors = common.presetColors,
            },
        },
        {
            key = "fatigueBarColor",
            name = "fatigueBarColor_name",
            renderer = "SuperColorPicker2",
            default = util.color.hex("00963c"),
            argument = {
                presetColors = common.presetColors,
            },
        },
    },
}
