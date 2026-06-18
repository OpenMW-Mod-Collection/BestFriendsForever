---@omw-context global
---@diagnostic disable: missing-fields
local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'SettingsBestFriendsForever_toggles',
    page = 'BestFriendsForever',
    l10n = 'BestFriendsForever',
    name = 'toggles_groupName',
    permanentStorage = true,
    order = 0,
    settings = {
        {
            key = 'enableTeleport',
            name = 'enableTeleport_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'enableImmortality',
            name = 'enableImmortality_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'enableCatchUp',
            name = 'enableCatchUp_name',
            renderer = 'checkbox',
            default = true,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsBestFriendsForever_blacklist',
    page = 'BestFriendsForever',
    l10n = 'BestFriendsForever',
    name = 'blacklist_groupName',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'teleportBlacklistMWScript',
            name = 'teleportBlacklistMWScript_name',
            renderer = 'checkbox',
            default = false,
        },
        {
            key = 'immortalityBlacklistMWScript',
            name = 'immortalityBlacklistMWScript_name',
            renderer = 'checkbox',
            default = false,
        },
        {
            key = 'catchUpBlacklistMWScript',
            name = 'catchUpBlacklistMWScript_name',
            renderer = 'checkbox',
            default = false,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsBestFriendsForever_immortality',
    page = 'BestFriendsForever',
    l10n = 'BestFriendsForever',
    name = 'immortality_groupName',
    description = "immortality_groupDesc",
    permanentStorage = true,
    order = 10,
    settings = {
        {
            key = 'ingoreCommanded',
            name = 'ingoreCommanded_name',
            description = "ingoreCommanded_desc",
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'threshold',
            name = 'threshold_name',
            description = "threshold_desc",
            renderer = "SuperSlider4",
            default = 10,
            argument = {
                default = 10,
                showDefaultMark = true,
                showResetButton = true,
                bottomRow = true,
            }
        },
        {
            key = 'changeAggro',
            name = 'changeAggro_name',
            description = "changeAggro_desc",
            renderer = 'checkbox',
            default = true,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsBestFriendsForever_catchUp',
    page = 'BestFriendsForever',
    l10n = 'BestFriendsForever',
    name = 'catchUp_groupName',
    description = "catchUp_groupDesc",
    permanentStorage = true,
    order = 10,
    settings = {
        {
            key = 'startDist',
            name = 'startDist_name',
            description = "startDist_desc",
            renderer = 'SuperSlider4',
            default = 200,
            argument = {
                max = 5000,
                step = 50,
                default = 200,
                showDefaultMark = true,
                showResetButton = true,
                bottomRow = true,
            }
        },
        {
            key = 'maxDist',
            name = 'maxDist_name',
            description = "maxDist_desc",
            renderer = 'SuperSlider4',
            default = 2000,
            argument = {
                max = 5000,
                step = 50,
                default = 2000,
                showDefaultMark = true,
                showResetButton = true,
                bottomRow = true,
            }
        },
    }
}
