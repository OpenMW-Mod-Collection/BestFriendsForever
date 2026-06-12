---@omw-context global
local storage = require("openmw.storage")
local async = require("openmw.async")
local settingsCache = require("scripts.GoodCompany.utils.settingsCache")

local settings = {}

-- TODO
-- ignore npcs with CharGenWalkNPC mwscript

local scripts = {
    {
        cond = function(fState)
            local isSummon = string.find(fState.actor.recordId, "_summon$")
                or fState.actor.recordId == "bonewalker_greater_summ"
        return not isSummon
            and fState.followsPlayer
            and settings.enableImmortality
        end,
        path = "scripts/GoodCompany/followerScripts/immortality.lua"
    },
    {
        cond = function(fState)
            return settings.enableTeleport
        end,
        path = "scripts/GoodCompany/followerScripts/teleport.lua"
    },
    {
        cond = function(fState)
            return settings.enableCatchUp
        end,
        path = "scripts/GoodCompany/followerScripts/catchUp.lua"
    }
}

local followers = {}

-- Re-evaluate every script on every current follower.
-- Adds scripts whose cond is now true, removes those whose cond is now false.
local function resyncAll()
    for _, fState in pairs(followers) do
        for _, script in ipairs(scripts) do
            local has  = fState.actor:hasScript(script.path)
            local want = script.cond(fState)
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

settings = settingsCache.new(
    storage.globalSection("SettingsGoodCompany_toggles"),
    async,
    function(key)
        resyncAll()
    end
)

local function syncScripts(actor, fState, addingScript)
    for _, script in ipairs(scripts) do
        local hasScript = actor:hasScript(script.path)
        if addingScript then
            if not hasScript and script.cond(fState) then
                actor:addScript(script.path, {
                    leader = fState.superLeader or fState.leader
                })
            end
        else
            if hasScript then
                actor:removeScript(script.path)
            end
        end
    end
end

local function followerListUpdated(data)
    local currFollowers = data.followers
    for id, fState in pairs(currFollowers) do
        if not followers[id] then
            syncScripts(fState.actor, fState, true)
        end
    end
    for id, fState in pairs(followers) do
        if not currFollowers[id] then
            syncScripts(fState.actor, fState, false)
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
        GoodCompany_detachScript = detachScript,
        GoodCompany_teleport = tp,
    }
}
