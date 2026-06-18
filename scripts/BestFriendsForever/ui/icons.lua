---@diagnostic disable: param-type-mismatch
---@omw-context player
local util = require("openmw.util")
local v2 = util.vector2
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local types = require("openmw.types")
local core = require("openmw.core")

local interval = { template = I.MWUI.templates.interval }
local magicIcon = ui.texture {
    path = 'textures/menu_icon_magic.dds',
    offset = v2(0, 0),
    size = v2(42, 42),
}
local h2hIcon = ui.texture { path = 'icons/k/stealth_handtohand.dds' }
---@type table<string, openmw.ui.TextureResource>
local iconCache = {}

local iconsUI = {}

---@param id string
---@return openmw.ui.TextureResource
local function getEffectIcon(id)
    local effect = core.magic.effects.records[id]
    local path = effect.icon:gsub('^(.*[/\\])(.*)$', '%1b_%2')

    if not iconCache[path] then
        iconCache[path] = ui.texture({ path = path })
    end
    return iconCache[path]
end

---@param icon openmw.ui.TextureResource
---@param magic boolean
---@param tint openmw.util.Color|nil
---@return openmw.ui.Layout
local function renderEquipmentIcon(icon, magic, tint)
    local box = {
        props = {
            size = v2(32, 32),
        },
        content = ui.content({}),
    }

    if magic then
        box.content:add({
            type = ui.TYPE.Image,
            props = {
                resource = magicIcon,
                position = v2(-5, -5),
                size = v2(1, 1) * 40,
            },
        })
    end

    box.content:add {
        type = ui.TYPE.Image,
        props = {
            resource = icon,
            size = v2(32, 32),
            color = tint,
        },
    }

    return {
        template = I.MWUI.templates.boxTransparent,
        props = { visible = true },
        content = ui.content({ box }),
    }
end

---@param spellType openmw.core.SpellType
---@return openmw.ui.Layout
local function renderDisease(spellType)
    local icon
    if spellType == core.magic.SPELL_TYPE.Blight then
        icon = getEffectIcon(core.magic.EFFECT_TYPE.CureBlightDisease)
    else
        icon = getEffectIcon(core.magic.EFFECT_TYPE.CureCommonDisease)
    end
    return renderEquipmentIcon(icon, false, util.color.rgba(1.0, 0.15, 0.15, 1.0))
end

---@param spell openmw.core.Spell
---@return openmw.ui.TextureResource|nil
local function getSpellIcon(spell)
    local effect = spell.effects[1]
    if effect then
        return getEffectIcon(effect.effect.id)
    else
        return nil
    end
end

---@param item GameObject
---@return openmw.ui.TextureResource
---@return boolean
local function getItemIcon(item)
    local itemRecord = item.type.records[item.recordId]
    local path = itemRecord.icon
    if path then
        local isMagical = itemRecord.enchant ~= nil and itemRecord.enchant ~= ''
        if not iconCache[path] then
            iconCache[path] = ui.texture({ path = path })
        end
        return iconCache[path], isMagical
    end
    return h2hIcon, false
end

local STANCE = types.Actor.STANCE
local EQUIPMENT_SLOT = types.Actor.EQUIPMENT_SLOT
---@param actor GameObject
---@return openmw.ui.Layout
iconsUI.renderCombat = function(actor)
    local icon
    local magic = false

    local stance = types.Actor.getStance(actor)
    if stance == STANCE.Spell then
        local spell = types.Actor.getSelectedSpell(actor)
        local enchantedItem = types.Actor.getSelectedEnchantedItem(actor)
        icon = spell and getSpellIcon(spell) or (enchantedItem and getItemIcon(enchantedItem)) or magicIcon
        magic = true
    elseif stance == STANCE.Weapon then
        local weapon = types.Actor.getEquipment(actor, EQUIPMENT_SLOT.CarriedRight)
        if weapon then
            icon, magic = getItemIcon(weapon)
        else
            icon = h2hIcon
            magic = false
        end
    end

    return renderEquipmentIcon(icon, magic)
end

---@param actor GameObject
---@return openmw.core.Spell|nil
---@return openmw.core.MagicEffect|nil
iconsUI.getDebuff = function(actor)
    local disease
    for _, spell in pairs(types.Actor.spells(actor)) do
        if spell.type == core.magic.SPELL_TYPE.Blight then
            disease = spell
            break
        elseif spell.type == core.magic.SPELL_TYPE.Disease then
            disease = spell
        end
    end

    if disease then
        return disease, nil
    end

    local effect
    for _, active in pairs(types.Actor.activeEffects(actor)) do
        if active.id == core.magic.EFFECT_TYPE.DamageAttribute then
            effect = active
            break
        elseif active.id == core.magic.EFFECT_TYPE.DamageSkill then
            effect = active
        end
    end

    return nil, effect
end

---@param disease openmw.core.Spell|nil
---@param effect openmw.core.MagicEffect|nil
---@return openmw.ui.Layout
iconsUI.renderDebuff = function(disease, effect)
    if disease then
        return renderDisease(disease.type)
    elseif effect then
        return renderEquipmentIcon(getEffectIcon(effect.id), false)
    else
        return renderEquipmentIcon(nil, false)
    end
end

---@param fData FollowerData
---@param debuffed boolean
iconsUI.placeIconsIntoContainers = function(fData, debuffed)
    if types.Actor.getStance(fData.actor) ~= STANCE.Nothing then
        fData.icons.container.content:add(fData.icons.combatLayout)
    end
    if debuffed then
        if #fData.icons.container.content > 0 then
            fData.icons.container.content:add(interval)
        end
        fData.icons.container.content:add(fData.icons.debuffLayout)
    end
end

return iconsUI
