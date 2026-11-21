---@diagnostic disable: undefined-field
---@omw-context global
local types = require("openmw.types")
local I = require("openmw.interfaces")
local core = require("openmw.core")

local FDU = I.FollowerDetectionUtil
local l10n = core.l10n("BestFriendsForever")
local waitingActors = {}

local function hasCommandEffect(actor)
    local effects = types.Actor.activeEffects(actor)
    return effects:getEffect(core.magic.EFFECT_TYPE.CommandCreature).magnitude > 0
        or effects:getEffect(core.magic.EFFECT_TYPE.CommandHumanoid).magnitude > 0
end

local function waitHere(data)
    local actor = data.actor
    if not actor or FDU.isSummon(actor) or hasCommandEffect(actor) then
        return
    end

    waitingActors[actor.id] = actor
    actor:sendEvent("RemoveAIPackages", "Follow")
    local player = data.player
    if player then
        player:sendEvent("ShowMessage", {
            message = l10n("msg_followerWaiting", {
                npc_name = actor.type.records[actor.recordId].name,
            }),
        })
    end
end

local function onActorActivated(object, activator)
    local waitingActor = waitingActors[object.id]
    if not waitingActor or not activator or not types.Player.objectIsInstance(activator) then
        return
    end

    if FDU.isSummon(waitingActor) or hasCommandEffect(waitingActor) then
        return
    end

    waitingActors[object.id] = nil
    waitingActor:sendEvent("StartAIPackage", {
        type = "Follow",
        target = activator,
        cancelOthers = true,
    })
    activator:sendEvent("ShowMessage", {
        message = l10n("msg_followerFollowingAgain", {
            npc_name = waitingActor.type.records[waitingActor.recordId].name,
        }),
    })
end

I.Activation.addHandlerForType(types.NPC, onActorActivated)
I.Activation.addHandlerForType(types.Creature, onActorActivated)

return {
    eventHandlers = {
        BestFriendsForever_waitHere = waitHere,
    },
    onSave = function()
        return {
            waitingActors = waitingActors,
        }
    end,
    onLoad = function(data)
        waitingActors = data and data.waitingActors or {}
    end,
}
