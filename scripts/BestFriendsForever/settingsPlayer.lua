---@diagnostic disable: missing-fields
---@omw-context menu
local I = require('openmw.interfaces')
local util = require("openmw.util")
local ui   = require("openmw.ui")

local presetColors = {
    "d4edfc", -- thirst
    "bfd4bc", -- hunger
    "cfbddb", -- sleep
    "81cded", -- fav color of blue
    "caa560", -- fontColor_color_normal
    "d4b77f", -- goldenMix
    "dfc99f", -- FontColor_color_normal_over
    "eee2c9", -- lightText
    "253170", -- fontColor_color_journal_link
    "3a4daf", -- fontColor_color_journal_link_over
    "707ecf", -- fontColor_color_journal_link_pressed
}

I.Settings.registerPage {
    key = 'BestFriendsForever',
    l10n = 'BestFriendsForever',
    name = 'page_name',
    description = 'page_description',
}

I.Settings.registerGroup {
    key = 'SettingsBestFriendsForever_call',
    page = 'BestFriendsForever',
    l10n = 'BestFriendsForever',
    name = 'call_groupName',
    description = "call_groupDesc",
    permanentStorage = true,
    order = 10,
    settings = {
        {
            key = 'callKeybind',
            name = 'callKeybind_name',
            description = "callKeybind_desc",
            renderer = 'inputBinding',
            argument = {
                key = "BestFriendsForever_call",
                type = "action",
            },
            default = "None",
        },
        {
            key = 'callDistance',
            name = 'callDistance_name',
            description = "callDistance_desc",
            renderer = 'SuperSlider4',
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
            }
        },
    }
}

I.Settings.registerPage {
    key = 'BestFriendsForever_UI',
    l10n = 'BestFriendsForever',
    name = 'page_UI_name',
    description = 'page_UI_description',
}

I.Settings.registerGroup {
    key = 'SettingsBestFriendsForever_UIWrapper',
    page = 'BestFriendsForever_UI',
    l10n = 'BestFriendsForever',
    name = 'UIWrapper_groupName',
    permanentStorage = true,
    order = 20,
    settings = {
        {
            key = 'enable',
            name = 'enable_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'pollingRate',
            name = 'pollingRate_name',
            description = 'pollingRate_desc',
            renderer = "SuperSlider4",
            default = .1,
            argument = {
                max = 2,
                step = .1,
                default = .1,
                showDefaultMark = true,
                showResetButton = true,
                bottomRow = true,
                unit = "sec",
            }
        },
        {
            key = 'lockPosition',
            name = 'lockPosition_name',
            description = "lockPosition_desc",
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'posX',
            name = 'posX_name',
            renderer = "SuperSlider4",
            default = 10,
            argument = {
                max = ui.screenSize().x,
                step = 1,
                default = 10,
                showDefaultMark = true,
                showResetButton = true,
                bottomRow = true,
            }
        },
        {
            key = 'posY',
            name = 'posY_name',
            renderer = "SuperSlider4",
            default = 10,
            argument = {
                max = ui.screenSize().y,
                step = 1,
                default = 10,
                showDefaultMark = true,
                showResetButton = true,
                bottomRow = true,
            }
        },
        {
            key = 'expansionDirection',
            name = 'expansionDirection_name',
            description = 'expansionDirection_desc',
            renderer = 'select',
            argument = {
                l10n = "BestFriendsForever",
                items = {
                    "Start",
                    "Center",
                    "End",
                },
            },
            default = "Start",
        },
        {
            key = 'enableBordersAndBg',
            name = 'enableBordersAndBg_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'horizontalLayout',
            name = 'horizontalLayout_name',
            renderer = 'checkbox',
            default = false,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsBestFriendsForever_UIFollower',
    page = 'BestFriendsForever_UI',
    l10n = 'BestFriendsForever',
    name = 'UIFollower_groupName',
    permanentStorage = true,
    order = 21,
    settings = {
        {
            key = 'nameTextSize',
            name = 'nameTextSize_name',
            renderer = 'SuperSlider4',
            default = 18,
            argument = {
                min = 1,
                default = 18,
                showDefaultMark = true,
                showResetButton = true,
                bottomRow = true,
            }
        },
        {
            key = 'nameColor',
            name = 'nameColor_name',
            renderer = "SuperColorPicker2",
            default = util.color.hex("eee2c9"),
            argument = {
                presetColors = presetColors,
            },
        },
        {
            key = 'uiAlign',
            name = 'uiAlign_name',
            renderer = 'select',
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
            key = 'healthBarEnabled',
            name = 'healthBarEnabled_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'healthBarColor',
            name = 'healthBarColor_name',
            renderer = "SuperColorPicker2",
            default = util.color.hex("c83c1e"),
            argument = {
                presetColors = presetColors,
            },
        },
        {
            key = 'magickaBarEnabled',
            name = 'magickaBarEnabled_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'magickaBarColor',
            name = 'magickaBarColor_name',
            renderer = "SuperColorPicker2",
            default = util.color.hex("35459f"),
            argument = {
                presetColors = presetColors,
            },
        },
        {
            key = 'fatigueBarEnabled',
            name = 'fatigueBarEnabled_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'fatigueBarColor',
            name = 'fatigueBarColor_name',
            renderer = "SuperColorPicker2",
            default = util.color.hex("00963c"),
            argument = {
                presetColors = presetColors,
            },
        },
        {
            key = 'barLength',
            name = 'barLength_name',
            renderer = 'SuperSlider4',
            default = 100,
            argument = {
                max = 500,
                default = 100,
                showDefaultMark = true,
                showResetButton = true,
                bottomRow = true,
            }
        },
        {
            key = 'barWidth',
            name = 'barWidth_name',
            renderer = 'SuperSlider4',
            default = 16,
            argument = {
                max = 50,
                default = 16,
                showDefaultMark = true,
                showResetButton = true,
                bottomRow = true,
            }
        },
        {
            key = 'barLabels',
            name = 'barLabels_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'combatIcon',
            name = 'combatIcon_name',
            description = 'combatIcon_desc',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'horizontalIcons',
            name = 'horizontalIcons_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'rightIcons',
            name = 'rightIcons_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'immortalityIntegration',
            name = 'immortalityIntegration_name',
            description = "immortalityIntegration",
            renderer = 'checkbox',
            default = true,
        },
    }
}
