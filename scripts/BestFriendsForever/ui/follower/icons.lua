---@diagnostic disable: param-type-mismatch, need-check-nil
---@omw-context player
local util = require("openmw.util")
local v2 = util.vector2
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local types = require("openmw.types")
local core = require("openmw.core")

local interval = { template = I.MWUI.templates.interval }
local iconSize = 32
local magicIcon = ui.texture {
    path = "textures/menu_icon_magic.dds",
    offset = v2(0, 0),
    size = v2(42, 42),
}
local h2hIcon = ui.texture { path = "icons/k/stealth_handtohand.dds" }

---@type table<string, openmw.ui.TextureResource>
local iconCache = {}

local iconsUI = {}

---@param id string
---@return openmw.ui.TextureResource
local function getEffectIcon(id)
    local effect = core.magic.effects.records[id]
    local path = effect.icon:gsub("^(.*[/\\])(.*)$", "%1b_%2")

    if not iconCache[path] then
        iconCache[path] = ui.texture { path = path }
    end
    return iconCache[path]
end

---@param icon openmw.ui.TextureResource
---@param magic boolean
---@return openmw.ui.Layout
local function renderEquipmentIcon(icon, magic)
    local box = {
        props = {
            size = v2(iconSize, iconSize),
        },
        content = ui.content {},
    }

    if magic then
        box.content:add {
            type = ui.TYPE.Image,
            props = {
                resource = magicIcon,
                position = v2(-5, -5),
                size = v2(1, 1) * 40,
            },
        }
    end

    box.content:add {
        type = ui.TYPE.Image,
        props = {
            resource = icon,
            size = v2(iconSize, iconSize),
        },
    }

    return {
        template = I.MWUI.templates.boxTransparent,
        props = { visible = true },
        content = ui.content { box },
    }
end

---@param spell openmw.core.Spell
---@return openmw.ui.TextureResource|nil
local function getSpellIcon(spell)
    local effect = spell.effects[1]
    if effect then
        return getEffectIcon(effect.effect.id)
    end
end

---@param item openmw.GObject
---@return openmw.ui.TextureResource
---@return boolean
local function getItemIcon(item)
    local itemRecord = item.type.records[item.recordId]
    local path = itemRecord.icon
    if path then
        local isMagical = itemRecord.enchant ~= nil and itemRecord.enchant ~= ""
        if not iconCache[path] then
            iconCache[path] = ui.texture { path = path }
        end
        return iconCache[path], isMagical
    end
    return h2hIcon, false
end

local STANCE = types.Actor.STANCE
local EQUIPMENT_SLOT = types.Actor.EQUIPMENT_SLOT

---@param actor openmw.GObject
---@return openmw.ui.Layout
iconsUI.renderCombat = function(actor)
    local icon = h2hIcon
    local magic = false

    local stance = types.Actor.getStance(actor)
    if stance == STANCE.Spell then
        local spell = types.Actor.getSelectedSpell(actor)
        local enchantedItem = types.Actor.getSelectedEnchantedItem(actor)
        icon = spell and getSpellIcon(spell) or (enchantedItem and getItemIcon(enchantedItem)) or magicIcon
        magic = true
    else
        local weapon = types.Actor.getEquipment(actor, EQUIPMENT_SLOT.CarriedRight)
        if weapon then
            icon, magic = getItemIcon(weapon)
        end
    end

    return renderEquipmentIcon(icon, magic)
end

local function createFollowerIcon()
    local followerIcon = {
        name = "followerIconMark",
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textHeader,
        props = {
            size = v2(iconSize, iconSize),
            autoSize = false,
            text = "?",
            textSize = 24,
            textAlignH = ui.ALIGNMENT.Center,
            textAlignV = ui.ALIGNMENT.Center,
            textShadow = true,
        },
    }

    return {
        name = "followerIcon",
        type = ui.TYPE.Widget,
        props = {
            size = v2(iconSize, iconSize),
        },
        content = ui.content { followerIcon },
    }
end

---@param fData FollowerData
iconsUI.updateIcons = function(fData)
    if not fData.icons.followerIconLayout then
        fData.icons.followerIconLayout = createFollowerIcon()
    end

    local combatLayout = iconsUI.renderCombat(fData.actor)
    if fData.icons.combatLayout then
        fData.icons.combatLayout.content = combatLayout.content
    else
        fData.icons.combatLayout = combatLayout
    end

    fData.icons.container.props.visible = true
    fData.icons.container.content = ui.content {
        fData.icons.followerIconLayout,
        interval,
        fData.icons.combatLayout,
    }
end

return iconsUI
