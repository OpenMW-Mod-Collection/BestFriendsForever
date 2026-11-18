---@omw-context player|global
local time = require("openmw_aux.time")

---@class Injuries.Injury
---@field id string
---@field name string
---@field tier string
---@field health? number
---@field magicka? number
---@field fatigue? number

---@class Injuries.Deductions
---@field health number
---@field magicka number
---@field fatigue number

---@class Injuries.Common
---@field DURATION table<string, integer>
---@field injuries Injuries.Injury[]
---@field byId table<string, Injuries.Injury>
---@field byTier table<string, Injuries.Injury[]>
local common = {}

---@type table<string, integer>
common.DURATION = {
    minor = 10 * time.minute,
    major = 7 * time.day,
}

---@type Injuries.Injury[]
common.injuries = {
    -- MINOR ------------------------------------------------------------
    {
        id = "bff_minor_bruised_ribs",
        name = "Bruised Ribs",
        tier = "minor",
    },
    {
        id = "bff_minor_twisted_ankle",
        name = "Twisted Ankle",
        tier = "minor",
    },
    {
        id = "bff_minor_jarred_wrist",
        name = "Jarred Wrist",
        tier = "minor",
    },
    {
        id = "bff_minor_pulled_shoulder",
        name = "Pulled Shoulder",
        tier = "minor",
    },
    {
        id = "bff_minor_sprained_thumb",
        name = "Sprained Thumb",
        tier = "minor",
    },
    {
        id = "bff_minor_scraped_knees",
        name = "Scraped Knees",
        tier = "minor",
    },
    {
        id = "bff_minor_dazed",
        name = "Dazed",
        tier = "minor",
    },
    {
        id = "bff_minor_shaken_nerves",
        name = "Shaken Nerves",
        tier = "minor",
    },
    {
        id = "bff_minor_black_eye",
        name = "Black Eye",
        tier = "minor",
    },
    {
        id = "bff_minor_bleeding_gash",
        name = "Bleeding Gash",
        tier = "minor",
        health = 0.10,
    },
    {
        id = "bff_minor_winded",
        name = "Winded",
        tier = "minor",
        fatigue = 0.30,
    },
    {
        id = "bff_minor_muscle_cramp",
        name = "Muscle Cramp",
        tier = "minor",
    },

    -- MAJOR ------------------------------------------------------------
    {
        id = "bff_major_broken_leg",
        name = "Broken Leg",
        tier = "major",
    },
    {
        id = "bff_major_broken_arm",
        name = "Broken Arm",
        tier = "major",
    },
    {
        id = "bff_major_dislocated_shoulder",
        name = "Dislocated Shoulder",
        tier = "major",
    },
    {
        id = "bff_major_maimed_hand",
        name = "Maimed Hand",
        tier = "major",
    },
    {
        id = "bff_major_concussion",
        name = "Concussion",
        tier = "major",
    },
    {
        id = "bff_major_lost_eye",
        name = "Lost Eye",
        tier = "major",
    },
    {
        id = "bff_major_punctured_lung",
        name = "Punctured Lung",
        tier = "major",
        health = 0.20,
    },
    {
        id = "bff_major_crushed_ribs",
        name = "Crushed Ribs",
        tier = "major",
        health = 0.20,
    },
    {
        id = "bff_major_internal_bleeding",
        name = "Internal Bleeding",
        tier = "major",
        health = 0.35,
    },
    {
        id = "bff_major_festering_wound",
        name = "Festering Wound",
        tier = "major",
        health = 0.25,
    },
    {
        id = "bff_major_severe_burns",
        name = "Severe Burns",
        tier = "major",
        health = 0.15,
    },
    {
        id = "bff_major_spinal_trauma",
        name = "Spinal Trauma",
        tier = "major",
    },
}

---@type table<string, Injuries.Injury>
common.byId = {}
---@type table<string, Injuries.Injury[]>
common.byTier = { minor = {}, major = {} }
for _, inj in ipairs(common.injuries) do
    common.byId[inj.id] = inj
    table.insert(common.byTier[inj.tier], inj)
end

---@param id integer
---@return Injuries.Deductions? deductions  nil if `id` is not a known injury.
function common.getDeductions(id)
    local inj = common.byId[id]
    if not inj then
        return nil
    end
    return {
        health = inj.health or 0,
        magicka = inj.magicka or 0,
        fatigue = inj.fatigue or 0,
    }
end

---@param tier string
---@return Injuries.Injury? injury  nil if `tier` is unknown or has no injuries.
function common.randomInjury(tier)
    local pool = common.byTier[tier]
    return pool and pool[math.random(#pool)] or nil
end

return common
