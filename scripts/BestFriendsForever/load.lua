---@diagnostic disable: missing-fields
---@omw-context load
local content = require("openmw.content")

local injuries = require("scripts.BestFriendsForever.common.injuries") ---@type Injuries.Common

content.spells.records["BFF_Immortality"] = {
    name = "BFF_Immortality",
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

-- Injuries

---@class Injuries.EffectDef
---@field id string
---@field magnitude number
---@field affectedAttribute? string
---@field affectedSkill? string

---@generic T
---@param ... T[]
---@return T[]
local function concat(...)
    local out = {}
    for _, list in ipairs { ... } do
        for _, v in ipairs(list) do
            out[#out + 1] = v
        end
    end
    return out
end

---@type string[]
local FINE_HAND = { "marksman", "security", "alchemy", "armorer" }
---@type string[]
local COARSE_HAND = {
    "longblade",
    "shortblade",
    "axe",
    "bluntweapon",
    "spear",
    "handtohand",
    "block",
}
---@type string[]
local HAND = concat(COARSE_HAND, FINE_HAND)
---@type string[]
local LEG = { "athletics", "acrobatics", "sneak" }
---@type string[]
local ARMOR = { "lightarmor", "mediumarmor", "heavyarmor", "unarmored" }
---@type string[]
local ARM_WEAPONS = { "axe", "bluntweapon", "longblade", "spear", "marksman" }
---@type string[]
local ARM_WEAPONS_BLOCK = concat(ARM_WEAPONS, { "block" })

---@param attribute string
---@param magnitude number
---@return Injuries.EffectDef[]
local function drainAttr(attribute, magnitude)
    return {
        {
            id = "DrainAttribute",
            affectedAttribute = attribute,
            magnitude = magnitude,
        },
    }
end

--- One Drain Skill effect per skill, all at the same magnitude.
---@param skills string[]
---@param magnitude number
---@return Injuries.EffectDef[]
local function drainSkills(skills, magnitude)
    local out = {}
    for _, skill in ipairs(skills) do
        out[#out + 1] = {
            id = "DrainSkill",
            affectedSkill = skill,
            magnitude = magnitude,
        }
    end
    return out
end

---@param magnitude number
---@return Injuries.EffectDef[]
local function blind(magnitude)
    return { { id = "Blind", magnitude = magnitude } }
end

---@param magnitude number  Percentage.
---@return Injuries.EffectDef[]
local function weaknessToCommonDisease(magnitude)
    return { { id = "WeaknessToCommonDisease", magnitude = magnitude } }
end

---@type table<string, Injuries.EffectDef[]>
local EFFECTS = {
    -- MINOR ------------------------------------------------------------
    bff_minor_bruised_ribs = concat(
        drainAttr("endurance", 10),
        drainSkills({ "athletics" }, 15)
    ),

    bff_minor_twisted_ankle = concat(
        drainAttr("speed", 20),
        drainSkills(LEG, 20)
    ),

    bff_minor_jarred_wrist = concat(
        drainAttr("strength", 10),
        drainSkills(HAND, 15)
    ),

    bff_minor_pulled_shoulder = concat(
        drainAttr("strength", 25),
        drainSkills(ARM_WEAPONS, 20),
        drainSkills({ "athletics" }, 10)
    ),

    bff_minor_sprained_thumb = concat(
        drainAttr("agility", 10),
        drainSkills(FINE_HAND, 25),
        drainSkills({ "handtohand" }, 20)
    ),

    bff_minor_scraped_knees = concat(
        drainAttr("speed", 10),
        drainSkills({ "acrobatics", "sneak" }, 25)
    ),

    bff_minor_dazed = concat(
        drainAttr("intelligence", 20),
        drainAttr("willpower", 20)
    ),

    bff_minor_shaken_nerves = concat(
        drainAttr("willpower", 25),
        drainAttr("luck", 15)
    ),

    bff_minor_black_eye = concat(
        blind(20),
        drainSkills({ "marksman", "security" }, 20)
    ),

    bff_minor_bleeding_gash = concat( -- + max Health deduction
        drainAttr("agility", 10),
        drainSkills(ARMOR, 15)
    ),

    bff_minor_winded = concat( -- + max Fatigue deduction
        drainSkills({ "athletics" }, 15)
    ),

    bff_minor_muscle_cramp = concat(
        drainAttr("strength", 10),
        drainAttr("speed", 10),
        drainSkills(LEG, 15)
    ),

    -- MAJOR ------------------------------------------------------------
    bff_major_broken_leg = concat(
        drainAttr("speed", 40),
        drainAttr("agility", 25),
        drainSkills(LEG, 50)
    ),

    bff_major_broken_arm = concat(
        drainAttr("strength", 35),
        drainAttr("agility", 15),
        drainSkills(HAND, 40)
    ),

    bff_major_dislocated_shoulder = concat(
        drainAttr("strength", 40),
        drainSkills(ARM_WEAPONS_BLOCK, 40),
        drainSkills({ "armorer" }, 30),
        drainSkills({ "athletics" }, 20)
    ),

    bff_major_maimed_hand = concat(
        drainAttr("agility", 35),
        drainSkills(COARSE_HAND, 50),
        drainSkills(FINE_HAND, 60)
    ),

    bff_major_concussion = concat(
        drainAttr("intelligence", 35),
        drainAttr("willpower", 35),
        blind(20)
    ),

    bff_major_lost_eye = concat(
        blind(50),
        drainSkills({ "marksman", "security" }, 40),
        drainAttr("agility", 15),
        drainAttr("luck", 10)
    ),

    bff_major_punctured_lung = concat( -- + max Health deduction
        drainAttr("endurance", 40),
        drainSkills({ "athletics" }, 40)
    ),

    bff_major_crushed_ribs = concat( -- + max Health deduction
        drainAttr("strength", 25),
        drainAttr("endurance", 30),
        drainSkills(ARMOR, 30)
    ),

    bff_major_internal_bleeding = concat( -- + max Health deduction
        drainAttr("endurance", 30),
        drainSkills(ARMOR, 20)
    ),

    bff_major_festering_wound = concat( -- + max Health deduction
        weaknessToCommonDisease(100),
        drainAttr("endurance", 25),
        drainAttr("personality", 30)
    ),

    bff_major_severe_burns = concat( -- + max Health deduction
        drainAttr("endurance", 15),
        drainAttr("personality", 40),
        drainSkills(ARMOR, 30)
    ),

    bff_major_spinal_trauma = concat(
        drainAttr("agility", 40),
        drainAttr("speed", 25),
        drainAttr("strength", 20),
        drainSkills(LEG, 30)
    ),
}

for _, injury in ipairs(injuries.injuries) do
    local defs = EFFECTS[injury.id]
    local duration = injuries.DURATION[injury.tier]

    local effects = {}
    for _, e in ipairs(defs) do
        effects[#effects + 1] = {
            id = e.id,
            affectedAttribute = e.affectedAttribute,
            affectedSkill = e.affectedSkill,
            range = content.RANGE.Self,
            duration = duration,
            magnitudeMin = e.magnitude,
            magnitudeMax = e.magnitude,
        }
    end

    content.spells.records[injury.id] = {
        name = injury.name,
        type = content.spells.TYPE.Spell,
        cost = 0,
        isAutocalc = false,
        effects = effects,
    }
end
