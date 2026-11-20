---@diagnostic disable: undefined-field
---@omw-context global
local storage = require("openmw.storage")
local async = require("openmw.async")
local types = require("openmw.types")
local I = require("openmw.interfaces")
local core = require("openmw.core")

local settingsCache = require("scripts.BestFriendsForever.utils.settingsCache")

-- Constants
local FDU = I.FollowerDetectionUtil
local l10n = core.l10n("BestFriendsForever")
local sectionToggles = storage.globalSection("SettingsBestFriendsForever_toggles")
local sectionBlacklists = storage.globalSection("SettingsBestFriendsForever_blacklist")
local immortalitySpell = "BFF_Immortality"

-- Variables
local settingToggles
local settingsBlacklists
local scripts
local waitingActors = {}

local function blacklisted(actor, noMwscripts, blacklist)
    local mwscript = actor.type.records[actor.recordId].mwscript
    if mwscript then
        if noMwscripts then
            return true
        end

        -- Water Life bullshit filter
        if mwscript:find("^ab01wlcr") then
            return true
        end

        if blacklist[mwscript] then
            return true
        end
    end
    return false
end

local function makeScript(name, path, cond, onAdd, onRemove)
    return {
        name = name,
        path = path,
        cond = cond,
        onAdd = onAdd,
        onRemove = onRemove,
    }
end

local function syncScripts(fState, addingScript)
    local banned = blacklisted(fState.actor, false, settingsBlacklists.globalScriptBlacklist)
    local dead = types.Actor.isDead(fState.actor)
    local leader = fState.rootLeader
    local add = addingScript and not banned and not dead and leader

    for _, script in ipairs(scripts) do
        local hasScript = fState.actor:hasScript(script.path)
        local shouldHaveScript = add and script.cond(fState)
        if shouldHaveScript then
            if not hasScript then
                fState.actor:addScript(script.path, { leader = leader })
                if script.onAdd then
                    script.onAdd(fState)
                end
                -- print(("Attaching script '%s' to %s"):format(script.name, fState.actor.recordId))
            end
        elseif hasScript then
            fState.actor:removeScript(script.path)
            if script.onRemove then
                script.onRemove(fState)
            end
            -- print(("Removing script '%s' from %s"):format(script.name, fState.actor.recordId))
        end
    end
end

local function followerListUpdated(followers)
    for _, fState in pairs(followers) do
        syncScripts(fState, fState.followsPlayer)
    end
end

local function detachScript(data)
    if data.actor:hasScript(data.script) then
        data.actor:removeScript(data.script)
    end
end

local function tp(data)
    data.object:teleport(data.cellName, data.position, data.options)
end

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

local function onSave()
    return {
        waitingActors = waitingActors,
    }
end

local function onLoad(data)
    waitingActors = data and data.waitingActors or {}
end

-- Initialization
settingToggles = settingsCache.new(sectionToggles, async, ResyncAll)
settingsBlacklists = settingsCache.new(sectionBlacklists, async, ResyncAll)

-- TODO: get rid of makeScript() function
scripts = {
    makeScript("Immortality", "scripts/BestFriendsForever/followerScripts/immortality.lua", function(fState)
        local record = fState.actor.type.records[fState.actor.recordId]
        local isSummon = FDU.isSummon(fState.actor)
        local banned = blacklisted(
            fState.actor,
            settingsBlacklists.immortalityBlacklistMWScript,
            settingsBlacklists.immortalityScriptBlacklist
        )
        -- for Loafy's Necromancy https://www.nexusmods.com/morrowind/mods/58901
        local isZombie = record.name:lower():find("'s zombie")
        return not isSummon
            and fState.followsPlayer
            and settingToggles.enableImmortality
            and not banned
            and not isZombie
    end, function(fState)
        local follower = fState.actor
        types.Actor.spells(follower):add(immortalitySpell)
    end, function(fState)
        local follower = fState.actor
        types.Actor.spells(follower):remove(immortalitySpell)
    end),
    makeScript("Teleport", "scripts/BestFriendsForever/followerScripts/teleport.lua", function(fState)
        local banned = blacklisted(
            fState.actor,
            settingsBlacklists.teleportBlacklistMWScript,
            settingsBlacklists.teleportScriptBlacklist
        )
        return settingToggles.enableTeleport and not banned
    end),
    makeScript("Catch Up", "scripts/BestFriendsForever/followerScripts/catchUp.lua", function()
        return settingToggles.enableCatchUp
    end),
    makeScript("Ward", "scripts/BestFriendsForever/followerScripts/ward.lua", function()
        return settingToggles.enableWard
    end),
}

-- Assigned after cache creation to preserve the existing resync behavior.
ResyncAll = function()
    followerListUpdated(FDU and FDU.getFollowerList() or {})
end

I.Activation.addHandlerForType(types.NPC, onActorActivated)
I.Activation.addHandlerForType(types.Creature, onActorActivated)

return {
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        FDU_SyncFollowerList = followerListUpdated,
        BestFriendsForever_waitHere = waitHere,
        BestFriendsForever_detachScript = detachScript,
        BestFriendsForever_teleport = function(data)
            -- teleport method throws harmless errors
            -- if two teleports occur in the same frame
            -- or when the summon gets despawned
            pcall(tp, data)
        end,
    },
}
