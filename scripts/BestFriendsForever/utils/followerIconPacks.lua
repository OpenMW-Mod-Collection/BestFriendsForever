---@diagnostic disable: undefined-field, need-check-nil
---@omw-context menu|player
local vfs = require("openmw.vfs")

local M = {}

local ROOT = "textures/bff/icons/"
local DEFAULT_PACK = "default"
M.DEFAULT_PACK = DEFAULT_PACK

local CATEGORIES = { "class", "creature", "summon", "id", "rule" }
local CATEGORY_SET = {}
local CATEGORY_INDEX = {}
for index, category in ipairs(CATEGORIES) do
    CATEGORY_SET[category] = true
    CATEGORY_INDEX[category] = index
end

-- Preference order only breaks ties; previews normally use the key with the most variants.
local PREVIEW_KEYS = {
    { "class", "civilian" },
    { "class", "combat" },
    { "class", "mage" },
    { "class", "stealth" },
    { "id", "julan" },
    { "id", "mlss_biz'kuitz" },
    { "id", "tr_m3_oe_pack_guar" },
    { "rule", "slave" },
}

local scanCache
local mergedCache = {}

local function newPack()
    local pack = { background = nil }
    for _, category in ipairs(CATEGORIES) do
        pack[category] = {}
    end
    return pack
end

local function normalizePath(path)
    return path:gsub("\\", "/")
end

local function normalizeName(name)
    if type(name) ~= "string" then return nil end
    local normalized = name:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " "):lower()
    if normalized == "" then return nil end
    return normalized
end

local function parseFile(path)
    local relative = path:sub(#ROOT + 1)
    local packName, fileName = relative:match("^([^/]+)/([^/]+)$")
    if not packName or not fileName then return end
    if packName:match("^%._") or fileName:match("^%._") then return end

    local stem, extension = fileName:match("^(.*)%.([^.]+)$")
    if not stem or not extension then return end
    extension = extension:lower()
    if extension ~= "png" and extension ~= "dds" then return end

    packName = normalizeName(packName)
    if not packName then return end
    if stem:lower() == "background" then
        return packName, "background", nil, path
    end

    local category, key = stem:match("^([%a]+)_([%w_ ']+)$")
    if not category or not key then return end

    key = key:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
    if key == "" then return end

    category = category:lower()
    if not CATEGORY_SET[category] then return end
    return packName, category, key:lower(), path
end

local function variantPacks(variants, category, key)
    local byCategory = variants[category]
    if not byCategory then
        byCategory = {}
        variants[category] = byCategory
    end
    local byKey = byCategory[key]
    if not byKey then
        byKey = {}
        byCategory[key] = byKey
    end
    return byKey
end

local function countVariants(packs)
    local count = 0
    for _ in pairs(packs) do
        count = count + 1
    end
    return count
end

local function previewPreference(category, key)
    for index, preview in ipairs(PREVIEW_KEYS) do
        if preview[1] == category and preview[2] == key then
            return index
        end
    end
    return #PREVIEW_KEYS + 1
end

local function betterPreview(candidate, best)
    if not best then return true end
    if candidate.count ~= best.count then return candidate.count > best.count end
    if candidate.preference ~= best.preference then return candidate.preference < best.preference end
    if candidate.category ~= best.category then return candidate.category < best.category end
    return candidate.key < best.key
end

local function scan()
    local packs = {}
    local names = {}
    local variants = {}
    for path in vfs.pathsWithPrefix(ROOT) do
        path = normalizePath(path)
        local packName, category, key, iconPath = parseFile(path)
        if packName then
            local pack = packs[packName]
            if not pack then
                pack = newPack()
                packs[packName] = pack
                names[#names + 1] = packName
            end
            if category == "background" then
                pack.background = iconPath
            else
                pack[category][key] = iconPath
                variantPacks(variants, category, key)[packName] = iconPath
            end
        end
    end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)

    local previews = {}
    for _, name in ipairs(names) do
        local pack = packs[name]
        local best
        for _, category in ipairs(CATEGORIES) do
            for key, path in pairs(pack[category]) do
                local candidate = {
                    path = path,
                    count = countVariants(variantPacks(variants, category, key)),
                    preference = previewPreference(category, key),
                    category = CATEGORY_INDEX[category],
                    key = key,
                }
                if betterPreview(candidate, best) then
                    best = candidate
                end
            end
        end
        if best then
            previews[name] = best.path
        end
    end

    return { names = names, packs = packs, previews = previews }
end

local function getScan()
    if not scanCache then
        scanCache = scan()
    end
    return scanCache
end

function M.names()
    return getScan().names
end

function M.get(presetName)
    local name = normalizeName(presetName) or DEFAULT_PACK
    local cached = mergedCache[name]
    if cached then return cached end

    local source = getScan()
    local fallback = source.packs[DEFAULT_PACK] or newPack()
    local selected = source.packs[name] or newPack()
    local pack = newPack()
    pack.background = selected.background or fallback.background

    for _, category in ipairs(CATEGORIES) do
        for key, path in pairs(fallback[category]) do
            pack[category][key] = path
        end
        for key, path in pairs(selected[category]) do
            pack[category][key] = path
        end
    end

    mergedCache[name] = pack
    return pack
end

function M.backgroundIcons()
    local result = {}
    for _, name in ipairs(getScan().names) do
        local pack = M.get(name)
        if pack.background then
            result[name] = pack.background
        end
    end
    return result
end

function M.previewIcons()
    local result = {}
    for name, path in pairs(getScan().previews) do
        result[name] = path
    end
    return result
end

return M
