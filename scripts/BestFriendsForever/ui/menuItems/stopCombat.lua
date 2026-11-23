---@omw-context player
local core = require("openmw.core")

local l10n = core.l10n("BestFriendsForever_ui")

return {
    name = l10n("stopCombat_button"),
    action = function(followerState)
        followerState.actor:sendEvent("RemoveAIPackages", "Combat")
        followerState.actor:sendEvent("RemoveAIPackages", "Pursue")
    end,
    closeAfterActivation = true,
}
