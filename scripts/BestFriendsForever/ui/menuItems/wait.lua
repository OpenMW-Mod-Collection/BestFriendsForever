---@omw-context player
local core = require("openmw.core")
local types = require("openmw.types")
local self = require("openmw.self")

local function hasCommandEffect(actor)
    local effects = types.Actor.activeEffects(actor)
    return effects:getEffect(core.magic.EFFECT_TYPE.CommandCreature).magnitude > 0
        or effects:getEffect(core.magic.EFFECT_TYPE.CommandHumanoid).magnitude > 0
end

return {
    name = "Wait Here",
    action = function(followerState)
        core.sendGlobalEvent("BestFriendsForever_waitHere", {
            actor = followerState.actor,
            player = self,
        })
    end,
    condition = function(followerState)
        return not followerState.isSummon and not hasCommandEffect(followerState.actor)
    end,
    closeAfterActivation = true,
}
