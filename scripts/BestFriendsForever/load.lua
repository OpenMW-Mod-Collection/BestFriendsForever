---@diagnostic disable: missing-fields
---@omw-context load
local content = require("openmw.content")

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
