---@omw-context global
---@diagnostic disable: missing-fields
local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'SettingsGoodCompany_toggles',
    page = 'GoodCompany',
    l10n = 'GoodCompany',
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
    key = 'SettingsGoodCompany_blacklist',
    page = 'GoodCompany',
    l10n = 'GoodCompany',
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
    key = 'SettingsGoodCompany_immortality',
    page = 'GoodCompany',
    l10n = 'GoodCompany',
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
            renderer = 'number',
            default = 10,
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
    key = 'SettingsGoodCompany_catchUp',
    page = 'GoodCompany',
    l10n = 'GoodCompany',
    name = 'catchUp_groupName',
    description = "catchUp_groupDesc",
    permanentStorage = true,
    order = 10,
    settings = {
        {
            key = 'startDist',
            name = 'startDist_name',
            description = "startDist_desc",
            renderer = 'number',
            default = 200,
        },
        {
            key = 'maxDist',
            name = 'maxDist_name',
            description = "maxDist_desc",
            renderer = 'number',
            default = 2000,
        },
        {
            key = 'maxSpeed',
            name = 'maxSpeed_name',
            renderer = 'number',
            default = 300,
        },
        {
            key = 'lerpSpeed',
            name = 'lerpSpeed_name',
            description = "lerpSpeed_desc",
            renderer = 'number',
            default = .1,
        },
    }
}
