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
            },
            argument = {
                l10n = "BestFriendsForever",
                keys = {
                    "name",
                    "health",
                    "magicka",
                    "fatigue",
                },
            },
        },
        {
            key = "primarySort",
            name = "primarySort_name",
            description = "primarySort_desc",
            renderer = "SuperSelect3",
            default = "None",
            argument = {
                l10n = "BestFriendsForever",
                items = {
                    "None",
                    "NPCs first",
                    "Creatures first",
                    "By level",
                    "By max health",
                },
            },
        },
        {
            key = "keepSummonsAtBottom",
            name = "keepSummonsAtBottom_name",
            description = "keepSummonsAtBottom_desc",
            renderer = "checkbox",
            default = false,
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
            key = "barDimensions",
            name = "barDimensions_name",
            description = "barDimensions_desc",
            renderer = "multiInput_V1",
            default = {
                healthWidth = 100,
                healthHeight = 16,
                magickaWidth = 100,
                magickaHeight = 16,
                fatigueWidth = 100,
                fatigueHeight = 16,
            },
            argument = {
                mode = "number",
                integer = true,
                l10n = "BestFriendsForever",
                width = 80,
                keys = {
                    "healthWidth",
                    "healthHeight",
                    "magickaWidth",
                    "magickaHeight",
                    "fatigueWidth",
                    "fatigueHeight",
                },
                min = {
                    healthWidth = 1,
                    healthHeight = 1,
                    magickaWidth = 1,
                    magickaHeight = 1,
                    fatigueWidth = 1,
                    fatigueHeight = 1,
                },
            },
        },
        {
            key = "barLabels",
            name = "barLabels_name",
            description = "barLabels_desc",
            renderer = "multiCheckbox_V1",
            default = {
                health = true,
                magicka = true,
                fatigue = true,
            },
            argument = {
                l10n = "BestFriendsForever",
                keys = {
                    "health",
                    "magicka",
                    "fatigue",
                },
            },
        },
        {
            key = "barLabelColor",
            name = "barLabelColor_name",
            renderer = "SuperColorPicker2",
            default = util.color.hex("ffffff"),
            argument = {
                presetColors = common.presetColors,
            },
        },
        {
            key = "barAlignment",
            name = "barAlignment_name",
            description = "barAlignment_desc",
            renderer = "SuperSelect3",
            default = "Center",
            argument = {
                l10n = "BestFriendsForever",
                items = {
                    "Left",
                    "Center",
                    "Right",
                },
            },
        },
        {
            key = "barInterval",
            name = "barInterval_name",
            description = "barInterval_desc",
            renderer = "SuperSlider6",
            default = 4,
            argument = {
                min = 0,
                max = 50,
                step = 1,
                default = 4,
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
            key = "iconSize",
            name = "iconSize_name",
            description = "iconSize_desc",
            renderer = "SuperSlider6",
            default = 32,
            argument = {
                min = 8,
                max = 128,
                step = 1,
                default = 32,
                showDefaultMark = true,
                showResetButton = true,
                bottomRow = true,
            },
        },
        {
            key = "iconInterval",
            name = "iconInterval_name",
            description = "iconInterval_desc",
            renderer = "SuperSlider6",
            default = 4,
            argument = {
                min = 0,
                max = 50,
                step = 1,
                default = 4,
                showDefaultMark = true,
                showResetButton = true,
                bottomRow = true,
            },
        },
        {
            key = "iconOrientation",
            name = "iconOrientation_name",
            description = "iconOrientation_desc",
            renderer = "SuperSelect3",
            default = "Horizontal",
            argument = {
                l10n = "BestFriendsForever",
                items = {
                    "Horizontal",
                    "Vertical",
                },
            },
        },
        {
            key = "iconSide",
            name = "iconSide_name",
            description = "iconSide_desc",
            renderer = "SuperSelect3",
            default = "Right",
            argument = {
                l10n = "BestFriendsForever",
                items = {
                    "Left",
                    "Right",
                },
            },
        },
        {
            key = "iconDisplayMode",
            name = "iconDisplayMode_name",
            description = "iconDisplayMode_desc",
            renderer = "SuperSelect3",
            default = "Merged",
            argument = {
                l10n = "BestFriendsForever",
                items = {
                    "Merged",
                    "Follower/combat",
                    "Combat/follower",
                    "Follower only",
                    "Combat only",
                },
                width = 200,
            },
        },
        {
            key = "iconBackgroundColor",
            name = "iconBackgroundColor_name",
            description = "iconBackgroundColor_desc",
            renderer = "SuperColorPicker2",
            default = util.color.hex("ffcd7b"),
            argument = {
                presetColors = common.presetColors,
            },
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
