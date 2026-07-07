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
            key = 'globalBlacklistByScript',
            name = 'globalBlacklistByScript_name',
            description = 'globalBlacklistByScript_desc',
            renderer = 'AttendMeList',
            default = {
                'CharGenWalkNPC',
                "RM_GuardSneak",
            },
        },
        {
            key = 'teleportBlacklistMWScript',
            name = 'teleportBlacklistMWScript_name',
            renderer = 'checkbox',
            default = false,
        },
        {
            key = 'teleportBlacklistByScript',
            name = 'teleportBlacklistByScript_name',
            renderer = 'AttendMeList',
        },
        {
            key = 'immortalityBlacklistMWScript',
            name = 'immortalityBlacklistMWScript_name',
            renderer = 'checkbox',
            default = false,
        },
        {
            key = 'immortalityBlacklistByScript',
            name = 'immortalityBlacklistByScript_name',
            renderer = 'AttendMeList',
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
            key = 'upDelay',
            name = 'upDelay_name',
            renderer = "SuperSlider4",
            default = 10,
            argument = {
                default = 10,
                showDefaultMark = true,
                showResetButton = true,
                bottomRow = true,
                unit = "sec",
            }
        },
        {
            key = 'deathChance',
            name = 'deathChance_name',
            renderer = "SuperSlider4",
            default = 1,
            argument = {
                min = 0,
                max = 100,
                default = 1,
                showResetButton = true,
                bottomRow = true,
                unit = "%",
            }
        },
        {
            key = 'ingoreCommanded',
            name = 'ingoreCommanded_name',
            description = "ingoreCommanded_desc",
            renderer = 'checkbox',
            default = true,
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
