---@omw-context global
local storage = require("openmw.storage")
local async = require("openmw.async")
local types = require("openmw.types")

local settingsCache = require("scripts.BestFriendsForever.utils.settingsCache")

local resyncAll

local settingToggles = settingsCache.new(
    storage.globalSection("SettingsBestFriendsForever_toggles"),
    async,
    function(key)
        resyncAll()
    end
)
local settingsBlacklists = settingsCache.new(
    storage.globalSection("SettingsBestFriendsForever_blacklist"),
    async,
    function(key)
        resyncAll()
    end
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
        path = "scripts/BestFriendsForever/followerScripts/immortality.lua"
    },
    {
        cond = function(fState)
            local banned = blacklisted(
                fState.actor,
                settingsBlacklists.teleportBlacklistMWScript,
                settingsBlacklists.teleportBlacklistByScript)
            return settingToggles.enableTeleport
                and not banned
        end,
        path = "scripts/BestFriendsForever/followerScripts/teleport.lua"
    },
    {
        cond = function(fState)
            return settingToggles.enableCatchUp
        end,
        path = "scripts/BestFriendsForever/followerScripts/catchUp.lua"
    }
}

local followers = {}

-- Re-evaluate every script on every current follower.
-- Adds scripts whose cond is now true, removes those whose cond is now false.
resyncAll = function()
    for _, fState in pairs(followers) do
        for _, script in ipairs(scripts) do
            local has = fState.actor:hasScript(script.path)
            local banned = blacklisted(fState.actor, false, settingsBlacklists.globalBlacklistByScript)
            local want = script.cond(fState) and not banned
            if want and not has then
                fState.actor:addScript(script.path, {
                    leader = fState.superLeader or fState.leader
                })
            elseif not want and has then
                fState.actor:removeScript(script.path)
            end
        end
    end
end

local function syncScripts(fState, addingScript)
    for _, script in ipairs(scripts) do
        local hasScript = fState.actor:hasScript(script.path)
        if addingScript then
            local banned = blacklisted(fState.actor, false, settingsBlacklists.globalBlacklistByScript)
            if not hasScript and script.cond(fState) and not banned then
                fState.actor:addScript(script.path, {
                    leader = fState.superLeader or fState.leader
                })
            end
        else
            if hasScript then
                fState.actor:removeScript(script.path)
            end
        end
    end
end

local function followerListUpdated(data)
    local currFollowers = data.followers
    for id, fState in pairs(currFollowers) do
        if not followers[id] then
            syncScripts(fState, true)
        end
    end
    for id, fState in pairs(followers) do
        if not currFollowers[id] then
            syncScripts(fState, false)
        end
    end
    followers = currFollowers
end

local function detachScript(data)
    if data.actor:hasScript(data.script) then
        data.actor:removeScript(data.script)
    end
end

local function tp(data)
    -- teleport method throws harmless errors
    -- if two teleports occur in the same frame
    -- or when the summon gets despawned
    pcall(function()
        data.actor:teleport(data.cell, data.pos, data.options)
    end)
end

return {
    eventHandlers = {
        FDU_FollowerListUpdated = followerListUpdated,
        BestFriendsForever_detachScript = detachScript,
        BestFriendsForever_teleport = tp,
    }
}
