---@omw-context local|global
local types = require("openmw.types")
local core = require("openmw.core")

-- Portable module for decoding a spell based on I.Spellcasting result

local enchantedItemTypes = { types.Armor, types.Weapon, types.Clothing, types.Book }

local M = {}

M.getMagicRecord = function(options)
    local id = options.id
    local spell = core.magic.spells.records[id]
    if spell then
        return spell
    end

    local enchantment = core.magic.enchantments.records[id]
    if enchantment then
        return enchantment
    end

    for _, itemType in ipairs(enchantedItemTypes) do
        local item = itemType.records[id]
        if item and item.enchant then
            enchantment = core.magic.enchantments.records[item.enchant]
            if enchantment then
                return enchantment
            end
        end
    end

    return types.Potion.records[id] or types.Ingredient.records[id]
end

return M
