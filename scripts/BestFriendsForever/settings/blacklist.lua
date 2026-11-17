---@omw-context global
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
