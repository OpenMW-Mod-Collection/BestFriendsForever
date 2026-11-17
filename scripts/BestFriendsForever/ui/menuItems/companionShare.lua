---@omw-context player
local I = require("openmw.interfaces")

return {
    name = "Companion Share",
    action = function(followerState)
        I.UI.setMode("Companion", { target = followerState.actor })
    end,
    condition = function(followerState)
        return not followerState.isSummon
    end,
    closeAfterActivation = true,
}
