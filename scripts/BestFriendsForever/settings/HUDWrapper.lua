---@omw-context menu
local I = require("openmw.interfaces")
local ui = require("openmw.ui")

I.Settings.registerGroup {
    key = "SettingsBestFriendsForever_HUDWrapper",
    page = "BestFriendsForever_HUD",
    l10n = "BestFriendsForever_settings",
    name = "HUDWrapper_groupName",
    description = "HUDWrapper_groupDesc",
    permanentStorage = true,
    order = 20,
    settings = {
        {
            key = "enable",
            name = "enable_name",
            renderer = "checkbox",
            default = true,
        },
        {
            key = "pollingRate",
            name = "pollingRate_name",
            description = "pollingRate_desc",
            renderer = "number",
            default = 0.1,
            argument = {
                min = 0,
            }
        },
        {
            key = "position",
            name = "position_name",
            description = "position_desc",
            renderer = "MultiSlider_V1",
            default = {
                posX = 10,
                posY = 10,
            },
            argument = {
                l10n = "BestFriendsForever_settings",
                keys = {
                    "posX",
                    "posY",
                },
                min = 0,
                max = {
                    posX = ui.screenSize().x,
                    posY = ui.screenSize().y,
                },
                step = 1,
                stepAffectsTextInput = true,
                default = {
                    posX = 10,
                    posY = 10,
                },
                showDefaultMark = true,
                showResetButton = true,
                tinyReset = true,
            },
        },
        {
            key = "dragModifier",
            name = "dragModifier_name",
            description = "dragModifier_desc",
            renderer = "SuperSelect3",
            default = "Shift",
            argument = {
                l10n = "BestFriendsForever_settings",
                items = {
                    "Disabled",
                    "None",
                    "Ctrl",
                    "Alt",
                    "Shift",
                },
            },
        },
        {
            key = "expansionDirectionV",
            name = "expansionDirectionV_name",
            renderer = "SuperSelect3",
            argument = {
                l10n = "BestFriendsForever_settings",
                items = {
                    "Up",
                    "Center",
                    "Down",
                },
            },
            default = "Down",
        },
        {
            key = "expansionDirectionH",
            name = "expansionDirectionH_name",
            renderer = "SuperSelect3",
            argument = {
                l10n = "BestFriendsForever_settings",
                items = {
                    "Left",
                    "Center",
                    "Right",
                },
            },
            default = "Right",
        },
        {
            key = "hudOrientation",
            name = "hudOrientation_name",
            description = "hudOrientation_desc",
            renderer = "SuperSelect3",
            default = "Vertical",
            argument = {
                l10n = "BestFriendsForever_settings",
                items = {
                    "Horizontal",
                    "Vertical",
                },
            },
        },
        {
            key = "maxWidgets",
            name = "maxWidgets_name",
            renderer = "number",
            default = 10,
            argument = {
                min = 0,
            }
        },
        {
            key = "hudFollowerScope",
            name = "hudFollowerScope_name",
            description = "hudFollowerScope_desc",
            renderer = "SuperSelect3",
            default = "Everyone in Chain",
            argument = {
                l10n = "BestFriendsForever_settings",
                items = {
                    "Direct Followers",
                    "Followers of Followers",
                    "Everyone in Chain",
                },
                width = 200,
            },
        },
        {
            key = "primarySort",
            name = "primarySort_name",
            description = "primarySort_desc",
            renderer = "SuperSelect3",
            default = "By level",
            argument = {
                l10n = "BestFriendsForever_settings",
                items = {
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
            renderer = "checkbox",
            default = true,
        },
        {
            key = "enableBordersAndBg",
            name = "enableBordersAndBg_name",
            renderer = "checkbox",
            default = false,
        },
        {
            key = "hudDisplay",
            name = "hudDisplay_name",
            renderer = "SuperSelect3",
            argument = {
                l10n = "BestFriendsForever_settings",
                items = {
                    "Always",
                    "Interface Only",
                    "Hide on Interface",
                    "Hide on Dialogue Only",
                },
                width = 200,
            },
            default = "Hide on Dialogue Only",
        },
    },
}
