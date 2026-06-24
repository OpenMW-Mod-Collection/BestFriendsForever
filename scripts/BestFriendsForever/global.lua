---@diagnostic disable: undefined-field
---@omw-context global
local storage = require("openmw.storage")
local async = require("openmw.async")
local types = require("openmw.types")
local I = require("openmw.interfaces")

local settingsCache = require("scripts.BestFriendsForever.utils.settingsCache")

local resyncAll

local settingToggles = settingsCache.new(
    storage.globalSection("SettingsBestFriendsForever_toggles"),
    async,
    resyncAll
)
local settingsBlacklists = settingsCache.new(
    storage.globalSection("SettingsBestFriendsForever_blacklist"),
    async,
    resyncAll
)

local function blacklisted(actor, noMwscripts, blacklist)
    local mwscript = actor.type.records[actor.recordId].mwscript
    if mwscript then
        if noMwscripts then
            return true
        end
        for _, blacklistedScript in ipairs(blacklist) do
            if mwscript == blacklistedScript then
                return true
            end
        end
    end
    return false
end

local scripts = {
    {
        name = "Immortality",
        path = "scripts/BestFriendsForever/followerScripts/immortality.lua",
        cond = function(fState)
            local isSummon = string.find(fState.actor.recordId, "_summon$")
                or fState.actor.recordId == "bonewalker_greater_summ"
            local banned = blacklisted(
                fState.actor,
                settingsBlacklists.immortalityBlacklistMWScript,
                settingsBlacklists.immortalityBlacklistByScript)
            return not isSummon
                and fState.followsPlayer
                and settingToggles.enableImmortality
                and not banned
        end,
    },
    {
        name = "Teleport",
        path = "scripts/BestFriendsForever/followerScripts/teleport.lua",
        cond = function(fState)
            local banned = blacklisted(
                fState.actor,
                settingsBlacklists.teleportBlacklistMWScript,
                settingsBlacklists.teleportBlacklistByScript)
            return settingToggles.enableTeleport
                and not banned
        end,
    },
    {
        name = "Catch Up",
        path = "scripts/BestFriendsForever/followerScripts/catchUp.lua",
        cond = function(fState)
            return settingToggles.enableCatchUp
        end,
    }
}

local function syncScripts(fState, addingScript)
    for _, script in ipairs(scripts) do
        local hasScript = fState.actor:hasScript(script.path)
        local banned = blacklisted(fState.actor, false, settingsBlacklists.globalBlacklistByScript)
        local dead = types.Actor.isDead(fState.actor)

        if addingScript and not banned and not dead then
            if not hasScript and script.cond(fState) then
                fState.actor:addScript(script.path, {
                    leader = fState.superLeader or fState.leader
                })
                -- print(("Attaching script '%s' to %s"):format(script.name, fState.actor.recordId))
            end
        else
            if hasScript then
                fState.actor:removeScript(script.path)
                -- print(("Removing script '%s' from %s"):format(script.name, fState.actor.recordId))
            end
        end
    end
end

local function followerListUpdated(data)
    for _, fState in pairs(data.followers) do
        syncScripts(fState, fState.followsPlayer)
    end
end

resyncAll = function()
    followerListUpdated {
        followers = I.FollowerDetectionUtil
            and I.FollowerDetectionUtil.getFollowerList()
            or {}
    }
end

local function detachScript(data)
    if data.actor:hasScript(data.script) then
        data.actor:removeScript(data.script)
    end
end

local function tp(data)
    data.object:teleport(data.cellName, data.position, data.options)
end

return {
    eventHandlers = {
        FDU_FollowerListUpdated = followerListUpdated,
        BestFriendsForever_detachScript = detachScript,
        BestFriendsForever_teleport = function(data)
            -- teleport method throws harmless errors
            -- if two teleports occur in the same frame
            -- or when the summon gets despawned
            pcall(tp, data)
        end,
    }
}
