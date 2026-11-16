---@omw-context global
---@diagnostic disable: missing-fields
local I = require("openmw.interfaces")
local storage = require("openmw.storage")

local blacklistSettings = storage.globalSection("SettingsBestFriendsForever_blacklist")
local legacyBlacklistKeys = {
    globalScriptBlacklist = "globalBlacklistByScript",
    teleportScriptBlacklist = "teleportBlacklistByScript",
    immortalityScriptBlacklist = "immortalityBlacklistByScript",
}

local function migrateBlacklistSettings()
    local storedValues = blacklistSettings:asTable()
    for currentKey, legacyKey in pairs(legacyBlacklistKeys) do
        local legacyValue = storedValues[legacyKey]
        if storedValues[currentKey] == nil and legacyValue ~= nil then
            if type(legacyValue) ~= "table" then
                error(("Legacy blacklist setting '%s' must be a table"):format(legacyKey))
            end

            local migratedValue = {}
            for key, value in pairs(legacyValue) do
                local scriptId
                if type(key) == "number" then
                    scriptId = value
                elseif value then
                    scriptId = key
                end

                if scriptId ~= nil then
                    if type(scriptId) ~= "string" then
                        error(("Legacy blacklist setting '%s' contains a non-string script ID"):format(legacyKey))
                    end
                    migratedValue[scriptId:lower()] = true
                end
            end
            blacklistSettings:set(currentKey, migratedValue)
        end
    end
end

migrateBlacklistSettings()

I.Settings.registerGroup {
    key = "SettingsBestFriendsForever_toggles",
    page = "BestFriendsForever",
    l10n = "BestFriendsForever",
    name = "toggles_groupName",
    permanentStorage = true,
    order = 0,
    settings = {
        {
            key = "enableTeleport",
            name = "enableTeleport_name",
            description = "enableTeleport_desc",
            renderer = "checkbox",
            default = true,
        },
        {
            key = "enableImmortality",
            name = "enableImmortality_name",
            description = "enableImmortality_desc",
            renderer = "checkbox",
            default = true,
        },
        {
            key = "enableCatchUp",
            name = "enableCatchUp_name",
            description = "enableCatchUp_desc",
            renderer = "checkbox",
            default = true,
        },
        {
            key = "enableWard",
            name = "enableWard_name",
            description = "enableWard_desc",
            renderer = "checkbox",
            default = false,
        },
    },
}

I.Settings.registerGroup {
    key = "SettingsBestFriendsForever_blacklist",
    page = "BestFriendsForever",
    l10n = "BestFriendsForever",
    name = "blacklist_groupName",
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = "globalScriptBlacklist",
            name = "globalScriptBlacklist_name",
            description = "globalScriptBlacklist_desc",
            renderer = "textSet_V1",
            default = {
                ["rm_guardsneak"] = true,
                ["mca_guards"] = true,
                ["mca_adventurers"] = true,
                ["_dat_callasscript"] = true,
                ["_dat_gadeleanoscript"] = true,
                ["dat_landsallshotsscript"] = true,
                ["dat_qoranelasscript"] = true,
                ["dat_sunonhisswordscript"] = true,
                ["dat_vaxscript"] = true,
                ["dat_sthralnascript"] = true,
                ["dat_kjetilscript"] = true,
            },
            argument = {
                lower = true,
            },
        },
        {
            key = "teleportBlacklistMWScript",
            name = "teleportBlacklistMWScript_name",
            renderer = "checkbox",
            default = false,
        },
        {
            key = "teleportScriptBlacklist",
            name = "teleportScriptBlacklist_name",
            renderer = "textSet_V1",
            default = {
                ["heartfanghuntscript"] = true,
                ["tr_m3_oe_pack_guar_sc"] = true,
            },
            argument = {
                lower = true,
            },
        },
        {
            key = "immortalityBlacklistMWScript",
            name = "immortalityBlacklistMWScript_name",
            renderer = "checkbox",
            default = false,
        },
        {
            key = "immortalityScriptBlacklist",
            name = "immortalityScriptBlacklist_name",
            renderer = "textSet_V1",
            default = {
                ["heartfanghuntscript"] = true,
            },
            argument = {
                lower = true,
            },
        },
    },
}

I.Settings.registerGroup {
    key = "SettingsBestFriendsForever_immortality",
    page = "BestFriendsForever",
    l10n = "BestFriendsForever",
    name = "immortality_groupName",
    description = "immortality_groupDesc",
    permanentStorage = true,
    order = 10,
    settings = {
        {
            key = "threshold",
            name = "threshold_name",
            description = "threshold_desc",
            renderer = "number",
            default = 10,
            argument = {
                min = 0,
            },
        },
        {
            key = "waitUntilCombatEnds",
            name = "waitUntilCombatEnds_name",
            renderer = "checkbox",
            default = true,
        },
        {
            key = "upDelay",
            name = "upDelay_name",
            description = "upDelay_desc",
            renderer = "number",
            default = 10,
            argument = {
                min = 0,
            },
        },
        {
            key = "deathChance",
            name = "deathChance_name",
            renderer = "SuperSlider6",
            default = 1,
            argument = {
                min = 0,
                max = 100,
                default = 1,
                showResetButton = true,
                bottomRow = true,
                unit = "%",
            },
        },
        {
            key = "ingoreCommanded",
            name = "ingoreCommanded_name",
            description = "ingoreCommanded_desc",
            renderer = "checkbox",
            default = true,
        },
        {
            key = "changeAggro",
            name = "changeAggro_name",
            description = "changeAggro_desc",
            renderer = "checkbox",
            default = true,
        },
    },
}

I.Settings.registerGroup {
    key = "SettingsBestFriendsForever_catchUp",
    page = "BestFriendsForever",
    l10n = "BestFriendsForever",
    name = "catchUp_groupName",
    description = "catchUp_groupDesc",
    permanentStorage = true,
    order = 10,
    settings = {
        {
            key = "startDist",
            name = "startDist_name",
            description = "startDist_desc",
            renderer = "SuperSlider6",
            default = 500,
            argument = {
                max = 5000,
                step = 50,
                default = 500,
                showDefaultMark = true,
                showResetButton = true,
                bottomRow = true,
            },
        },
        {
            key = "maxDist",
            name = "maxDist_name",
            description = "maxDist_desc",
            renderer = "SuperSlider6",
            default = 4000,
            argument = {
                max = 5000,
                step = 50,
                default = 4000,
                showDefaultMark = true,
                showResetButton = true,
                bottomRow = true,
            },
        },
    },
}

I.Settings.registerGroup {
    key = "SettingsBestFriendsForever_ward",
    page = "BestFriendsForever",
    l10n = "BestFriendsForever",
    name = "ward_groupName",
    description = "ward_groupDesc",
    permanentStorage = true,
    order = 10,
    settings = {
        {
            key = "disableDiseases",
            name = "disableDiseases_name",
            renderer = "checkbox",
            default = true,
        },
        {
            key = "disableStatDamage",
            name = "disableStatDamage_name",
            renderer = "checkbox",
            default = true,
        },
        {
            key = "statDamageCheckFrequency",
            name = "statDamageCheckFrequency_name",
            description = "statDamageCheckFrequency_desc",
            renderer = "number",
            default = 300,
            argument = {
                min = 0,
            },
        },
    },
}
