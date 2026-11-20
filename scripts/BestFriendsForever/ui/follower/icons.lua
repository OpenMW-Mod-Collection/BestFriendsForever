---@diagnostic disable: param-type-mismatch, need-check-nil
---@omw-context player
local util = require("openmw.util")
local v2 = util.vector2
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local types = require("openmw.types")
local core = require("openmw.core")

-- Constants
local iconSize = 32
local skillThreshold = 30
local STANCE = types.Actor.STANCE
local EQUIPMENT_SLOT = types.Actor.EQUIPMENT_SLOT
local magicIcon = ui.texture {
    path = "textures/menu_icon_magic.dds",
    offset = v2(0, 0),
    size = v2(42, 42),
}
local h2hIcon = ui.texture { path = "icons/k/stealth_handtohand.dds" }
local followerIconBackground = ui.texture { path = "textures/bffs/bg.png" }
local followerIconBackgroundColor = util.color.rgb(1, 205 / 255, 123 / 255)

-- Variables
---@type table<string, openmw.ui.TextureResource>
local iconCache = {}
local iconsUI = {}
---@type table<string, FollowerIcon>
local iconById = {}
---@type FollowerIcon[]
local iconRules = {}

local defaultIcons = {
    creature = { path = "textures/bffs/Creature.png", transparent = true },
    combat = { path = "textures/bffs/Generic Warrior.png", transparent = true },
    magic = { path = "textures/bffs/Generic Mage.png", transparent = true },
    stealth = { path = "textures/bffs/Generic Thief.png", transparent = true },
    civilian = { path = "textures/bffs/Citizen.png", transparent = true },
}

local creatureTypeIcons = {
    [types.Creature.TYPE.Creatures] = { path = "textures/bffs/Creatures.png", transparent = true },
    [types.Creature.TYPE.Daedra] = { path = "textures/bffs/Daedra.png", transparent = true },
    [types.Creature.TYPE.Humanoid] = { path = "textures/bffs/Humanoid.png", transparent = true },
    [types.Creature.TYPE.Undead] = { path = "textures/bffs/Undead.png", transparent = true },
}

local specializationSkills = {
    combat = {
        "block",
        "armorer",
        "mediumarmor",
        "heavyarmor",
        "bluntweapon",
        "longblade",
        "axe",
        "spear",
        "athletics",
        "handtohand",
    },
    magic = {
        "alchemy",
        "alteration",
        "conjuration",
        "destruction",
        "enchant",
        "illusion",
        "mysticism",
        "restoration",
    },
    stealth = {
        "acrobatics",
        "lightarmor",
        "marksman",
        "mercantile",
        "security",
        "shortblade",
        "sneak",
        "speechcraft",
    },
}

---@class FollowerIcon
---@field path string
---@field transparent boolean
---@field rule? fun(actor: openmw.GObject): boolean|nil

---@class FollowerIconSpec
---@field recordIds? string|string[]
---@field recordId? string
---@field rule? fun(actor: openmw.GObject): boolean|nil
---@field fileName string
---@field isTransparent boolean

---@param path string
---@return openmw.ui.TextureResource
local function getTexture(path)
    if not iconCache[path] then
        iconCache[path] = ui.texture { path = path }
    end
    return iconCache[path]
end

---@param id string
---@return openmw.ui.TextureResource
local function getEffectIcon(id)
    local effect = core.magic.effects.records[id]
    local path = effect.icon:gsub("^(.*[/\\])(.*)$", "%1b_%2")

    return getTexture(path)
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
        return getTexture(path), isMagical
    end
    return h2hIcon, false
end

---@param actor openmw.GObject
---@param skills table<string, openmw.types.DynamicStat>
---@return FollowerIcon
local function getFallbackIcon(actor, skills)
    if types.Creature.objectIsInstance(actor) then
        local record = types.Creature.records[actor.recordId]
        return creatureTypeIcons[record.type] or defaultIcons.creature
    end

    if types.NPC.objectIsInstance(actor) then
        local npcRecord = types.NPC.records[actor.recordId]
        local classRecord = types.NPC.classes.record(npcRecord.class)
        local specializationId = classRecord.specialization:lower()
        local skillIds = specializationSkills[specializationId]
        for _, skillId in ipairs(skillIds) do
            local skill = skills[skillId]
            if skill and skill.base >= skillThreshold then
                return defaultIcons[specializationId]
            end
        end
    end

    return defaultIcons.civilian
end

---@param actor openmw.GObject
---@param skills table<string, openmw.types.DynamicStat>
---@return FollowerIcon
local function getFollowerIcon(actor, skills)
    local icon = iconById[actor.recordId]
    if icon then return icon end

    for _, entry in ipairs(iconRules) do
        if entry.rule(actor) then return entry end
    end

    return getFallbackIcon(actor, skills)
end

---@param icon { path: string, transparent: boolean }
---@return openmw.ui.Layout
local function renderFollowerIcon(icon)
    local content = ui.content {}
    if icon.transparent then
        content:add {
            type = ui.TYPE.Image,
            props = {
                resource = followerIconBackground,
                color = followerIconBackgroundColor,
                size = v2(iconSize, iconSize),
            },
        }
    end
    content:add {
        type = ui.TYPE.Image,
        props = {
            resource = getTexture(icon.path),
            size = v2(iconSize, iconSize),
        },
    }

    return {
        name = "followerIcon",
        type = ui.TYPE.Widget,
        props = {
            size = v2(iconSize, iconSize),
        },
        content = content,
    }
end

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

---@param ids string|string[]
---@return string[]
local function normalizeIds(ids)
    if type(ids) == "string" then ids = { ids } end
    if type(ids) ~= "table" or #ids == 0 then
        error("recordIds must be a non-empty string or list of strings", 3)
    end
    local result = {}
    for _, id in ipairs(ids) do
        if type(id) ~= "string" or id == "" then
            error("recordIds must contain non-empty strings", 3)
        end
        table.insert(result, id:lower())
    end
    return result
end

--- Provide exactly one of recordIds/recordId or rule.
---@param spec FollowerIconSpec
iconsUI.setFollowerIcon = function(spec)
    if spec.recordIds ~= nil and spec.recordId ~= nil then
        error("provide either recordIds or recordId, not both", 3)
    end
    local rule = spec.rule
    local ids = spec.recordIds or spec.recordId
    if ids ~= nil then
        if rule ~= nil then
            error("setFollowerIcon requires either recordIds or rule, not both", 3)
        end
        ids = normalizeIds(ids)
    elseif type(rule) ~= "function" then
        error("setFollowerIcon requires recordIds or rule", 3)
    end

    local fileName = spec.fileName
    if type(fileName) ~= "string" or fileName == "" then
        error("fileName must be a non-empty texture path", 3)
    end
    if type(spec.isTransparent) ~= "boolean" then
        error("isTransparent must be a boolean", 3)
    end

    local icon = { path = fileName, transparent = spec.isTransparent }
    if ids then
        for _, id in ipairs(ids) do
            iconById[id] = icon
        end
        return
    end

    for index, entry in ipairs(iconRules) do
        if entry.rule == rule then
            iconRules[index] = { rule = rule, path = icon.path, transparent = icon.transparent }
            return
        end
    end
    table.insert(iconRules, { rule = rule, path = icon.path, transparent = icon.transparent })
end

---@param fData FollowerData
iconsUI.updateIcons = function(fData)
    local actor = fData.followerState.actor
    local iconLayout
    if types.Actor.getStance(actor) == STANCE.Nothing then
        iconLayout = renderFollowerIcon(getFollowerIcon(actor, fData.skills))
    else
        iconLayout = iconsUI.renderCombat(actor)
    end

    fData.icons.container.props.visible = true
    fData.icons.container.content = ui.content { iconLayout }
end

-- Initialization
-- Priority: unique. Order-independent: record IDs are looked up directly.
-- TODO: replace these placeholder record IDs when the actor IDs are known.
iconsUI.setFollowerIcon {
    recordId = "bff_placeholder_julan_1",
    fileName = "textures/bffs/Julan 1.png",
    isTransparent = true,
}
iconsUI.setFollowerIcon {
    recordId = "bff_placeholder_julan_2",
    fileName = "textures/bffs/Julan 2.png",
    isTransparent = true,
}
iconsUI.setFollowerIcon {
    recordId = "bff_placeholder_biz_kuit_1",
    fileName = "textures/bffs/Biz'Kuit 1.png",
    isTransparent = true,
}
iconsUI.setFollowerIcon {
    recordId = "bff_placeholder_biz_kuit_2",
    fileName = "textures/bffs/Biz'Kuit 2.png",
    isTransparent = true,
}
iconsUI.setFollowerIcon {
    recordId = "bff_placeholder_pack_guar",
    fileName = "textures/bffs/Pack Guar.png",
    isTransparent = true,
}
iconsUI.setFollowerIcon {
    recordId = "bff_placeholder_slave",
    fileName = "textures/bffs/Slave.png",
    isTransparent = true,
}
iconsUI.setFollowerIcon {
    recordId = "bff_placeholder_slave_flat",
    fileName = "textures/bffs/Slave Flat.png",
    isTransparent = true,
}

-- Priority: slightly special. Order-dependent: first matching rule wins.
-- TODO: add the corresponding texture files under textures/bffs.
iconsUI.setFollowerIcon {
    rule = function(actor)
        if not types.Creature.objectIsInstance(actor) then return false end
        local record = types.Creature.records[actor.recordId]
        return record.bloodType == 2 and record.soulValue == 0
    end,
    fileName = "textures/bffs/Animunculi.png",
    isTransparent = true,
}

return iconsUI
