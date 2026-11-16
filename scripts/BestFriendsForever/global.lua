---@diagnostic disable: undefined-field
---@omw-context global
local storage = require("openmw.storage")
local async = require("openmw.async")
local types = require("openmw.types")
local I = require("openmw.interfaces")

local settingsCache = require("scripts.BestFriendsForever.utils.settingsCache")
local FDU = I.FollowerDetectionUtil

local sectionToggles = storage.globalSection("SettingsBestFriendsForever_toggles")
local sectionBlacklists = storage.globalSection("SettingsBestFriendsForever_blacklist")
local settingToggles = settingsCache.new(sectionToggles, async, ResyncAll)
local settingsBlacklists = settingsCache.new(sectionBlacklists, async, ResyncAll)

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

local scripts = {
    {
        name = "Immortality",
        path = "scripts/BestFriendsForever/followerScripts/immortality.lua",
        cond = function(fState)
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
        end,
    },
    {
        name = "Teleport",
        path = "scripts/BestFriendsForever/followerScripts/teleport.lua",
        cond = function(fState)
            local banned = blacklisted(
                fState.actor,
                settingsBlacklists.teleportBlacklistMWScript,
                settingsBlacklists.teleportScriptBlacklist
            )
            return settingToggles.enableTeleport and not banned
        end,
    },
    {
        name = "Catch Up",
        path = "scripts/BestFriendsForever/followerScripts/catchUp.lua",
        cond = function()
            return settingToggles.enableCatchUp
        end,
    },
    {
        name = "Ward",
        path = "scripts/BestFriendsForever/followerScripts/ward.lua",
        cond = function()
            return settingToggles.enableWard
        end,
    },
}

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
                -- print(("Attaching script '%s' to %s"):format(script.name, fState.actor.recordId))
            end
        elseif hasScript then
            fState.actor:removeScript(script.path)
            -- print(("Removing script '%s' from %s"):format(script.name, fState.actor.recordId))
        end
    end
end

local function followerListUpdated(followers)
    for _, fState in pairs(followers) do
        syncScripts(fState, fState.followsPlayer)
    end
end

ResyncAll = function()
    followerListUpdated(FDU and FDU.getFollowerList() or {})
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
        FDU_SyncFollowerList = followerListUpdated,
        BestFriendsForever_detachScript = detachScript,
        BestFriendsForever_teleport = function(data)
            -- teleport method throws harmless errors
            -- if two teleports occur in the same frame
            -- or when the summon gets despawned
            pcall(tp, data)
        end,
    },
}
