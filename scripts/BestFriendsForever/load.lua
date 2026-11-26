---@diagnostic disable: missing-fields
---@omw-context load
local content = require("openmw.content")
local injuries = require("scripts.BestFriendsForever.common.injuries")

content.spells.records["bff_immortality"] = {
    name = "bff_immortality",
    type = content.spells.TYPE.Ability,
    cost = 0,
    isAutocalc = false,
    starterSpellFlag = false,
    effects = {
        {
            id = "WaterBreathing",
            range = content.RANGE.Self,
            duration = 0,
            magnitudeMin = 1,
            magnitudeMax = 1,
        },
        {
            id = "SlowFall",
            range = content.RANGE.Self,
            duration = 0,
            magnitudeMin = 1,
            magnitudeMax = 1,
        },
    },
}

local function makeInjuryRecord(name, effects)
    content.spells.records[name] = {
        name = name,
        type = content.spells.TYPE.Spell,
        cost = 0,
        isAutocalc = false,
        starterSpellFlag = false,
        effects = effects,
    }
end

local function selfEffect(id, duration, magnitude, extra)
    local effect = {
        id = id,
        range = content.RANGE.Self,
        duration = duration,
        magnitudeMin = magnitude,
        magnitudeMax = magnitude,
    }
    for key, value in pairs(extra or {}) do
        effect[key] = value
    end
    return effect
end

for _, injury in ipairs(injuries.injuries) do
    local duration = injuries.DURATION[injury.tier]
    local effects = {}

    for _, e in ipairs(injury.effects) do
        effects[#effects + 1] = selfEffect(e.id, duration, e.magnitude, {
            affectedAttribute = e.affectedAttribute,
            affectedSkill = e.affectedSkill,
        })
    end

    -- Keep a marker effect for injuries that are entirely runtime-managed.
    if #effects == 0 then
        effects[1] = selfEffect("WaterBreathing", duration, 1)
    end

    makeInjuryRecord(injury.id, effects)
end

makeInjuryRecord(injuries.DEMORALIZE, {
    selfEffect("DemoralizeCreature", 1, 100),
    selfEffect("DemoralizeHumanoid", 1, 100),
})
