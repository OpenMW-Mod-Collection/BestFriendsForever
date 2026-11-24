---@omw-context player
local I = require("openmw.interfaces")

local PresetManager = require("scripts.BestFriendsForever.utils.presetManager")

local presets = PresetManager.register {
    selector = {
        section = 'SettingsBestFriendsForever_hudPresets',
        key = 'hudPreset',
    },
    sections = {
        'SettingsBestFriendsForever_HUDWrapper',
        'SettingsBestFriendsForever_HUDFollower',
    },
    presets = {
        attendMe = {
            SettingsBestFriendsForever_HUDWrapper = {
                enableBordersAndBg = true,
            },
            SettingsBestFriendsForever_HUDFollower = {
                enabledElements = {
                    name = true,
                    health = true,
                    magicka = true,
                    fatigue = true,
                    icons = true,
                },
                uiAlign = "Center",
                nameTextSize = 18,
                barDimensions = {
                    healthWidth = 100,
                    healthHeight = 16,
                    magickaWidth = 100,
                    magickaHeight = 16,
                    fatigueWidth = 100,
                    fatigueHeight = 16,
                },
                barLabels = {
                    health = true,
                    magicka = true,
                    fatigue = true,
                },
                labelDisplayMode = "Current/Max",
                barInterval = 4,
                barAlignment = "Center",
                iconSize = 32,
                iconDisplayMode = "Follower/combat",
                iconOrientation = "Horizontal",
                iconSide = "Right",
                iconInterval = 4,
            },
        },
        authorsChoice = {
            SettingsBestFriendsForever_HUDWrapper = {
                enableBordersAndBg = false,
            },
            SettingsBestFriendsForever_HUDFollower = {
                enabledElements = {
                    name = true,
                    health = true,
                    magicka = true,
                    fatigue = true,
                    icons = true,
                },
                uiAlign = "Left",
                nameTextSize = 16,
                barDimensions = {
                    healthWidth = 100,
                    healthHeight = 14,
                    magickaWidth = 80,
                    magickaHeight = 8,
                    fatigueWidth = 60,
                    fatigueHeight = 8,
                },
                barLabels = {
                    health = true,
                    magicka = false,
                    fatigue = false,
                },
                labelDisplayMode = "Current/Max",
                barInterval = 0,
                barAlignment = "Left",
                iconSize = 38,
                iconDisplayMode = "Merged",
                iconOrientation = "Horizontal",
                iconSide = "Left",
                iconInterval = 4,
            },
        },
        compact = {
            SettingsBestFriendsForever_HUDWrapper = {
                enableBordersAndBg = false,
            },
            SettingsBestFriendsForever_HUDFollower = {
                enabledElements = {
                    name = true,
                    health = true,
                    magicka = true,
                    fatigue = true,
                    icons = true,
                },
                uiAlign = "Left",
                nameTextSize = 16,
                barDimensions = {
                    healthWidth = 100,
                    healthHeight = 8,
                    magickaWidth = 80,
                    magickaHeight = 8,
                    fatigueWidth = 60,
                    fatigueHeight = 8,
                },
                barLabels = {
                    health = false,
                    magicka = false,
                    fatigue = false,
                },
                labelDisplayMode = "Current/Max",
                barInterval = 0,
                barAlignment = "Left",
                iconSize = 32,
                iconDisplayMode = "Merged",
                iconOrientation = "Horizontal",
                iconSide = "Left",
                iconInterval = 4,
            },
        },
    },
}

I.Settings.registerGroup {
    key = "SettingsBestFriendsForever_hudPresets",
    page = "BestFriendsForever_HUD",
    l10n = "BestFriendsForever_settings",
    name = "hudPresets_groupName",
    permanentStorage = true,
    order = 0,
    settings = {
        {
            key = "hudPreset",
            name = "hudPreset_name",
            renderer = "SuperSelect3",
            default = "authorsChoice",
            argument = {
                l10n = "BestFriendsForever_settings",
                items = presets.names(),
            },
        },
    },
}
