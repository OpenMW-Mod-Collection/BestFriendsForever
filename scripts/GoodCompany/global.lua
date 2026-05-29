---@omw-context global
local storage = require("openmw.storage")

local settingsToggles = storage.globalSection("SettingsGoodCompany_toggles")
local scripts = {
    {
        cond = function(fState, settings)
            local isSummon = string.find(fState.actor.recordId, "_summon$")
                or fState.actor.recordId == "bonewalker_greater_summ"
            return not isSummon and fState.followsPlayer and settings.immortality
        end,
        path = "scripts/GoodCompany/followerScripts/immortality.lua"
    },
    {
        cond = function(fState, settings)
            return settings.teleport
        end,
        path = "scripts/GoodCompany/followerScripts/teleport.lua"
    },
    {
        cond = function(fState, settings)
            return settings.catchUp
        end,
        path = "scripts/GoodCompany/followerScripts/catchUp.lua"
    }
}

local followers = {}

local function syncScripts(actor, fState, settings, add)
    for _, script in ipairs(scripts) do
        local has = actor:hasScript(script.path)
        if add then
            if not has and script.cond(fState, settings) then
                actor:addScript(script.path, {
                    leader = fState.superLeader or fState.leader
                })
            end
        else
            if has then
                actor:removeScript(script.path)
            end
        end
    end
end

local function followerListUpdated(data)
    local currFollowers = data.followers
    local settings = {
        immortality = settingsToggles:get("enableImmortality"),
        teleport = settingsToggles:get("enableTeleport"),
        catchUp = settingsToggles:get("enableCatchUp"),
    }

    for id, fState in pairs(currFollowers) do
        if not followers[id] then
            syncScripts(fState.actor, fState, settings, true)
        end
    end

    for id, fState in pairs(followers) do
        if not currFollowers[id] then
            syncScripts(fState.actor, fState, settings, false)
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
    -- data.actor:teleport(data.cell, data.pos, data.options)
    pcall(function ()
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