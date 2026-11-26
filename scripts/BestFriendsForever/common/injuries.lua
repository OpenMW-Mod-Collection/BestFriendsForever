---@omw-context local | global | player | load

---@class Injuries.Effect
---@field id string
---@field magnitude number
---@field affectedAttribute? string
---@field affectedSkill? string

---@class Injuries.MaxDeduction
---@field health? number
---@field fatigue? number
---@field magicka? number

---@class Injuries.Periodic
---@field min number
---@field max number
---@field duration number

---@class Injuries.Injury
---@field id string
---@field name string
---@field tier string
---@field effects Injuries.Effect[]
---@field max? Injuries.MaxDeduction
---@field stag? Injuries.Periodic
---@field dem? Injuries.Periodic

---@class Injuries.Common
---@field DURATION table<string, number>
---@field DEMORALIZE string
---@field injuries Injuries.Injury[]
---@field byId table<string, Injuries.Injury>
---@field byTier table<string, Injuries.Injury[]>
local common = {}

---@type table<string, number>
common.DURATION = {
    minor = 10 * 60,
    major = 7 * 24 * 60 * 60,
}

---@type string
common.DEMORALIZE = "bff_demoralize"

---@generic T
---@param ... T[]
---@return T[]
local function concat(...)
    local out = {}
    for _, list in ipairs({ ... }) do
        for _, value in ipairs(list) do
            out[#out + 1] = value
        end
    end
    return out
end

---@param attribute string
---@param magnitude number
---@return Injuries.Effect[]
local function attr(attribute, magnitude)
    return { { id = "DrainAttribute", affectedAttribute = attribute, magnitude = magnitude } }
end

---@param skill string
---@param magnitude number
---@return Injuries.Effect[]
local function skill(skillName, magnitude)
    return { { id = "DrainSkill", affectedSkill = skillName, magnitude = magnitude } }
end

---@param skills string[]
---@param magnitude number
---@return Injuries.Effect[]
local function skills(skillNames, magnitude)
    local out = {}
    for _, skillName in ipairs(skillNames) do
        out[#out + 1] = { id = "DrainSkill", affectedSkill = skillName, magnitude = magnitude }
    end
    return out
end

---@param id string
---@param magnitude number
---@return Injuries.Effect[]
local function effect(id, magnitude)
    return { { id = id, magnitude = magnitude } }
end

---@type Injuries.Injury[]
common.injuries = {
    -- MINOR ------------------------------------------------------------
    {
        id = "bff_minor_winded",
        name = "Winded",
        tier = "minor",
        effects = {},
        max = { fatigue = 0.50 },
    },
    {
        id = "bff_minor_bruised_ribs",
        name = "Bruised Ribs",
        tier = "minor",
        effects = concat(
            attr("endurance", 15)
        ),
        max = { fatigue = 0.25 },
    },
    {
        id = "bff_minor_sprained_ankle",
        name = "Sprained Ankle",
        tier = "minor",
        effects = concat(
            attr("speed", 20),
            skill("acrobatics", 40)
        ),
    },
    {
        id = "bff_minor_jarred_wrist",
        name = "Jarred Wrist",
        tier = "minor",
        effects = concat(
            attr("agility", 15),
            attr("strength", 10)
        ),
    },
    {
        id = "bff_minor_dazed",
        name = "Dazed",
        tier = "minor",
        effects = effect("Blind", 20),
    },
    {
        id = "bff_minor_rattled",
        name = "Rattled",
        tier = "minor",
        effects = attr("willpower", 20),
        max = { magicka = 0.30 },
    },
    {
        id = "bff_minor_ringing_ears",
        name = "Ringing Ears",
        tier = "minor",
        effects = concat(
            effect("Sound", 20),
            attr("willpower", 10)
        ),
    },
    {
        id = "bff_minor_singed",
        name = "Singed",
        tier = "minor",
        effects = concat(
            effect("WeaknessToFire", 25),
            attr("endurance", 10)
        ),
    },
    {
        id = "bff_minor_stumbling",
        name = "Stumbling",
        tier = "minor",
        effects = {},
        stag = { min = 45, max = 90, duration = 1 },
    },
    {
        id = "bff_minor_skittish",
        name = "Skittish",
        tier = "minor",
        effects = {},
        dem = { min = 60, max = 120, duration = 10 },
    },

    -- MAJOR ------------------------------------------------------------
    {
        id = "bff_major_broken_leg",
        name = "Broken Leg",
        tier = "major",
        effects = concat(
            attr("speed", 60),
            skill("acrobatics", 100),
            skill("athletics", 60),
            effect("Burden", 100)
        ),
    },
    {
        id = "bff_major_broken_sword_arm",
        name = "Broken Sword Arm",
        tier = "major",
        effects = concat(
            attr("strength", 50),
            attr("agility", 40),
            skills({ "longblade", "shortblade", "axe", "bluntweapon", "spear" }, 50),
            skill("block", 50)
        ),
    },
    {
        id = "bff_major_shattered_ribs",
        name = "Shattered Ribs",
        tier = "major",
        effects = attr("endurance", 50),
        max = { fatigue = 0.75, health = 0.25 },
    },
    {
        id = "bff_major_severe_concussion",
        name = "Severe Concussion",
        tier = "major",
        effects = concat(
            attr("intelligence", 50),
            attr("willpower", 50),
            effect("Blind", 40)
        ),
        stag = { min = 20, max = 40, duration = 1 },
    },
    {
        id = "bff_major_crushed_hand",
        name = "Crushed Hand",
        tier = "major",
        effects = concat(
            attr("agility", 60),
            attr("strength", 30),
            skill("block", 100),
            skill("marksman", 60),
            effect("Burden", 50)
        ),
    },
    {
        id = "bff_major_maimed_eye",
        name = "Maimed Eye",
        tier = "major",
        effects = concat(
            effect("Blind", 50),
            skill("marksman", 60),
            attr("agility", 20)
        ),
    },
    {
        id = "bff_major_festering_wound",
        name = "Festering Wound",
        tier = "major",
        effects = concat(
            effect("WeaknessToCommonDisease", 100),
            effect("WeaknessToBlightDisease", 50),
            attr("endurance", 20)
        ),
        max = { health = 0.40 },
    },
    {
        id = "bff_major_burnt_out_channels",
        name = "Burnt-Out Channels",
        tier = "major",
        effects = concat(
            effect("StuntedMagicka", 1),
            effect("Silence", 1),
            attr("willpower", 30)
        ),
        max = { magicka = 0.80 },
    },
    {
        id = "bff_major_broken_nerve",
        name = "Broken Nerve",
        tier = "major",
        effects = concat(
            attr("willpower", 40),
            effect("WeaknessToMagicka", 30)
        ),
        dem = { min = 30, max = 60, duration = 15 },
    },
    {
        id = "bff_major_raw_burns",
        name = "Raw Burns",
        tier = "major",
        effects = concat(
            effect("WeaknessToFire", 75),
            effect("WeaknessToFrost", 40),
            effect("WeaknessToShock", 40),
            attr("endurance", 30)
        ),
        max = { health = 0.30 },
    },
}

---@type table<string, Injuries.Injury>
common.byId = {}
---@type table<string, Injuries.Injury[]>
common.byTier = { minor = {}, major = {} }
for _, injury in ipairs(common.injuries) do
    common.byId[injury.id] = injury
    table.insert(common.byTier[injury.tier], injury)
end

---@param activeSpells table
---@return Injuries.Injury[]
function common.activeInjuries(activeSpells)
    local active = {}
    local seen = {}
    for _, spell in pairs(activeSpells or {}) do
        local injury = spell.id and common.byId[spell.id]
        if injury and not seen[injury.id] then
            seen[injury.id] = true
            active[#active + 1] = injury
        end
    end
    return active
end

---@param activeSpells table
---@return boolean
function common.hasActiveInjury(activeSpells)
    for _, spell in pairs(activeSpells or {}) do
        if spell.id and common.byId[spell.id] then
            return true
        end
    end
    return false
end

---@param tier string
---@return Injuries.Injury? injury  nil when `tier` is unknown or empty.
function common.randomInjury(tier)
    local pool = common.byTier[tier]
    if not pool or #pool == 0 then
        return nil
    end
    return pool[math.random(#pool)]
end

return common
