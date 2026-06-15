---@diagnostic disable: missing-fields
---@omw-context menu
local I = require('openmw.interfaces')
local util = require("openmw.util")

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
    key = 'GoodCompany',
    l10n = 'GoodCompany',
    name = 'page_name',
    description = 'page_description',
}

I.Settings.registerGroup {
    key = 'SettingsGoodCompany_UIWrapper',
    page = 'GoodCompany',
    l10n = 'GoodCompany',
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
            renderer = 'number',
            default = .1,
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
            renderer = 'number',
            default = 10,
        },
        {
            key = 'posY',
            name = 'posY_name',
            renderer = 'number',
            default = 10,
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
    key = 'SettingsGoodCompany_UIFollower',
    page = 'GoodCompany',
    l10n = 'GoodCompany',
    name = 'UIFollower_groupName',
    permanentStorage = true,
    order = 21,
    settings = {
        {
            key = 'nameTextSize',
            name = 'nameTextSize_name',
            renderer = 'number',
            default = 18,
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
            key = 'textAlign',
            name = 'textAlign_name',
            renderer = 'select',
            argument = {
                l10n = "GoodCompany",
                items = {
                    "Start",
                    "Center",
                    "End",
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
            renderer = 'number',
            default = 100,
        },
        {
            key = 'barWidth',
            name = 'barWidth_name',
            renderer = 'number',
            default = 16,
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
            description = "horizontalIcons_desc",
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
