---@diagnostic disable: undefined-field, param-type-mismatch, need-check-nil
---@omw-context global
local core = require("openmw.core")
local types = require("openmw.types")
local world = require("openmw.world")

local injuries = require("scripts.BestFriendsForever.common.injuries")

local l10n = core.l10n("BestFriendsForever_messages")

local MAX_REDUCTION_CAP = 0.95
local STAT_NAMES = { "health", "fatigue", "magicka" }

---@type table<string, table>
local entries = {}

local function getId(object)
    if not object.contentFile then
        return object.id
    end
    return object.contentFile .. "/" .. object.id:sub(-6)
end

local function validActor(actor)
    return actor ~= nil and types.Actor.objectIsInstance(actor) and actor:isValid()
end

local function actorName(actor)
    local ok, name = pcall(function()
        return actor.type.records[actor.recordId].name
    end)
    if ok and name then
        return name
    end
    return tostring(actor.recordId or actor.id)
end

local function between(min, max)
    return min + math.random() * (max - min)
end

local function bindActor(entry, actor)
    if entry.boundActor == actor and entry.stats then
        return
    end

    entry.actor = actor
    entry.boundActor = actor
    entry.activeSpells = types.Actor.activeSpells(actor)
    entry.stats = {
        health = types.Actor.stats.dynamic.health(actor),
        fatigue = types.Actor.stats.dynamic.fatigue(actor),
        magicka = types.Actor.stats.dynamic.magicka(actor),
    }
end

local function createEntry(actor)
    local entry = {
        actor = actor,
        activeInjuries = {},
        basePenalties = {},
        knockdownUntil = nil,
    }
    bindActor(entry, actor)
    entries[getId(actor)] = entry
    return entry
end

local function spellEffectIndices(id)
    local spell = core.magic.spells.records[id]
    if not spell then
        return nil
    end

    local indices = {}
    for i = 1, #spell.effects do
        indices[i] = i - 1
    end
    return indices
end

local function addActiveSpell(entry, id, effects)
    if not core.magic.spells.records[id] or not entry.activeSpells then
        return
    end

    entry.activeSpells:add({
        id = id,
        effects = effects,
        ignoreResistances = true,
        ignoreSpellAbsorption = true,
        ignoreReflect = true,
    })
end

local function removeActiveSpell(entry, id)
    if not entry.activeSpells then
        return
    end

    local activeIds = {}
    for _, spell in pairs(entry.activeSpells) do
        if spell.id == id and spell.activeSpellId then
            activeIds[#activeIds + 1] = spell.activeSpellId
        end
    end
    for _, activeId in ipairs(activeIds) do
        pcall(function()
            entry.activeSpells:remove(activeId)
        end)
    end
end

local function applyMaxStats(entry)
    for _, statName in ipairs(STAT_NAMES) do
        local stat = entry.stats[statName]
        local previousPenalty = entry.basePenalties[statName] or 0
        local trueBase = stat.base + previousPenalty

        local reduction = 0
        for injuryId in pairs(entry.activeInjuries) do
            local injury = injuries.byId[injuryId]
            if injury and injury.max then
                reduction = reduction + (injury.max[statName] or 0)
            end
        end

        local penalty = trueBase * math.min(reduction, MAX_REDUCTION_CAP)
        stat.base = trueBase - penalty
        entry.basePenalties[statName] = penalty
    end
end

local function clearMaxStats(entry)
    for _, statName in ipairs(STAT_NAMES) do
        local penalty = entry.basePenalties[statName] or 0
        if penalty ~= 0 then
            entry.stats[statName].base = entry.stats[statName].base + penalty
        end
    end
    entry.basePenalties = {}
end

local function hasMajorInjury(entry)
    for injuryId in pairs(entry.activeInjuries) do
        local injury = injuries.byId[injuryId]
        if injury and injury.tier == "major" then
            return true
        end
    end
    return false
end

local function notifyHealed(entry)
    local player = world.players[1]
    if not player or not player:isValid() then
        return
    end

    player:sendEvent("ShowMessage", {
        message = l10n("msg_majorInjuriesHealed", {
            npc_name = actorName(entry.actor),
        }),
    })
end

local function triggerStag(entry, record, injury, now)
    types.Actor.setKnockedDown(entry.actor, true)
    entry.knockdownUntil = math.max(entry.knockdownUntil or 0, now + injury.stag.duration)
    record.nextStag = now + between(injury.stag.min, injury.stag.max)
end

local function triggerDem(entry, record, injury, now)
    local indices = spellEffectIndices(injuries.DEMORALIZE)
    if not indices then
        return
    end

    local effects = {}
    for _, index in ipairs(indices) do
        effects[#effects + 1] = {
            index = index,
            duration = injury.dem.duration,
            magnitudeMin = 100,
            magnitudeMax = 100,
        }
    end

    addActiveSpell(entry, injuries.DEMORALIZE, effects)
    record.nextDem = now + between(injury.dem.min, injury.dem.max)
end

local function clearEntry(key, entry)
    clearMaxStats(entry)
    if entry.knockdownUntil and not types.Actor.isDead(entry.actor) then
        types.Actor.setKnockedDown(entry.actor, false)
    end
    entries[key] = nil
end

local function applyInjury(data)
    data = data or {}
    local actor = data.actor
    local injury = injuries.byId[data.id]
    if not validActor(actor) or not injury then
        return
    end

    local entry = entries[getId(actor)] or createEntry(actor)
    bindActor(entry, actor)
    if entry.activeInjuries[injury.id] or entry.activeSpells:isSpellActive(injury.id) then
        return
    end

    local now = core.getGameTime()
    local record = {
        endsAt = now + injuries.DURATION[injury.tier],
    }
    if injury.stag then
        record.nextStag = now + between(injury.stag.min, injury.stag.max)
    end
    if injury.dem then
        record.nextDem = now + between(injury.dem.min, injury.dem.max)
    end

    entry.activeInjuries[injury.id] = record

    local indices = spellEffectIndices(injury.id)
    if indices then
        addActiveSpell(entry, injury.id, indices)
    end
    applyMaxStats(entry)
end

local function onUpdate()
    local now = core.getGameTime()

    for key, entry in pairs(entries) do
        local actor = entry.actor
        if not validActor(actor) then
            entries[key] = nil
        elseif types.Actor.isDead(actor) then
            clearEntry(key, entry)
        else
            if entry.knockdownUntil and now >= entry.knockdownUntil then
                types.Actor.setKnockedDown(actor, false)
                entry.knockdownUntil = nil
            end

            if not next(entry.activeInjuries) then
                if not entry.knockdownUntil then
                    clearEntry(key, entry)
                end
            else
                local hadMajor = hasMajorInjury(entry)
                local expired = false

                for injuryId, record in pairs(entry.activeInjuries) do
                    if now >= record.endsAt then
                        removeActiveSpell(entry, injuryId)
                        entry.activeInjuries[injuryId] = nil
                        expired = true
                    end
                end

                if expired then
                    if next(entry.activeInjuries) then
                        applyMaxStats(entry)
                    else
                        clearMaxStats(entry)
                    end
                    if hadMajor and not hasMajorInjury(entry) then
                        notifyHealed(entry)
                    end
                end

                if next(entry.activeInjuries) then
                    for injuryId, record in pairs(entry.activeInjuries) do
                        local injury = injuries.byId[injuryId]
                        if injury then
                            if injury.stag and record.nextStag and now >= record.nextStag then
                                triggerStag(entry, record, injury, now)
                            end
                            if injury.dem and record.nextDem and now >= record.nextDem then
                                triggerDem(entry, record, injury, now)
                            end
                        end
                    end
                elseif not entry.knockdownUntil then
                    clearEntry(key, entry)
                end
            end
        end
    end
end

local function onSave()
    local saved = {}
    for _, entry in pairs(entries) do
        if next(entry.activeInjuries) or entry.knockdownUntil or next(entry.basePenalties) then
            saved[#saved + 1] = {
                actor = entry.actor,
                activeInjuries = entry.activeInjuries,
                basePenalties = entry.basePenalties,
                knockdownUntil = entry.knockdownUntil,
            }
        end
    end

    if #saved == 0 then
        return {}
    end
    return { injuryEntries = saved }
end

local function onLoad(data)
    entries = {}

    for _, saved in ipairs((data and data.injuryEntries) or {}) do
        local actor = saved and saved.actor
        if validActor(actor) and not types.Actor.isDead(actor) then
            local entry = createEntry(actor)
            entry.activeInjuries = saved.activeInjuries or {}
            entry.basePenalties = saved.basePenalties or {}
            entry.knockdownUntil = saved.knockdownUntil

            if next(entry.activeInjuries) then
                applyMaxStats(entry)
            end
        end
    end
end

local function onActorActive(actor)
    if not validActor(actor) or types.Actor.isDead(actor) then
        return
    end

    local entry = entries[getId(actor)]
    if not entry then
        return
    end

    bindActor(entry, actor)
    if entry.knockdownUntil and core.getGameTime() < entry.knockdownUntil then
        types.Actor.setKnockedDown(actor, true)
    end
end

return {
    eventHandlers = {
        BestFriendsForever_applyInjury = applyInjury,
    },
    onUpdate = onUpdate,
    onActorActive = onActorActive,
    onSave = onSave,
    onLoad = onLoad,
}
