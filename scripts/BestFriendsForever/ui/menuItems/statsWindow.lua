---@omw-context player
local core = require("openmw.core")
local followerStats = require("scripts.BestFriendsForever.ui.followerStats")

local l10n = core.l10n("BestFriendsForever_ui")

return {
    name = l10n("statsWindow_button"),
    action = function(followerState)
        followerStats.open(followerState)
    end,
    close = function()
        followerStats.close()
    end,
}
