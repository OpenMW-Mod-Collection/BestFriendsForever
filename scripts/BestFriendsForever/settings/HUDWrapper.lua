---@omw-context menu
local I = require("openmw.interfaces")
local ui = require("openmw.ui")

I.Settings.registerGroup {
    key = "SettingsBestFriendsForever_HUDWrapper",
    page = "BestFriendsForever_HUD",
    l10n = "BestFriendsForever",
    name = "HUDWrapper_groupName",
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
            key = "maxWidgets",
            name = "maxWidgets_name",
            renderer = "number",
            default = 5,
            argument = {
                min = 0,
            }
        },
        {
            key = "lockPosition",
            name = "lockPosition_name",
            description = "lockPosition_desc",
            renderer = "checkbox",
            default = true,
        },
        {
            key = "posX",
            name = "posX_name",
            renderer = "SuperSlider6",
            default = 10,
            argument = {
                max = ui.screenSize().x,
                step = 1,
                default = 10,
                showDefaultMark = true,
                showResetButton = true,
                bottomRow = true,
            },
        },
        {
            key = "posY",
            name = "posY_name",
            renderer = "SuperSlider6",
            default = 10,
            argument = {
                max = ui.screenSize().y,
                step = 1,
                default = 10,
                showDefaultMark = true,
                showResetButton = true,
                bottomRow = true,
            },
        },
        {
            key = "expansionDirectionV",
            name = "expansionDirectionV_name",
            renderer = "SuperSelect3",
            argument = {
                l10n = "BestFriendsForever",
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
                l10n = "BestFriendsForever",
                items = {
                    "Left",
                    "Center",
                    "Right",
                },
            },
            default = "Right",
        },
        {
            key = "horizontalLayout",
            name = "horizontalLayout_name",
            renderer = "checkbox",
            default = false,
        },
        {
            key = "enableBordersAndBg",
            name = "enableBordersAndBg_name",
            renderer = "checkbox",
            default = true,
        },
        {
            key = "hudDisplay",
            name = "hudDisplay_name",
            renderer = "SuperSelect3",
            argument = {
                l10n = "BestFriendsForever",
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
