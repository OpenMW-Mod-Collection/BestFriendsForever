---@diagnostic disable: param-type-mismatch, need-check-nil
---@omw-context player
local util = require("openmw.util")
local v2 = util.vector2
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local types = require("openmw.types")
local core = require("openmw.core")

local iconSize = 32
local magicIcon = ui.texture {
    path = "textures/menu_icon_magic.dds",
    offset = v2(0, 0),
    size = v2(42, 42),
}
local h2hIcon = ui.texture { path = "icons/k/stealth_handtohand.dds" }
local followerIconBackground = ui.texture { path = "textures/bffs/bg.png" }
local followerIconBackgroundColor = util.color.rgb(1, 205 / 255, 123 / 255)

---@type table<string, openmw.ui.TextureResource>
local iconCache = {}

local iconsUI = {}

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

local STANCE = types.Actor.STANCE
local EQUIPMENT_SLOT = types.Actor.EQUIPMENT_SLOT

local defaultIcons = {
    creature = { path = "textures/bffs/Creature.png", transparent = true },
    combat = { path = "textures/bffs/Generic Warrior.png", transparent = true },
    magic = { path = "textures/bffs/Generic Mage.png", transparent = true },
    stealth = { path = "textures/bffs/Generic Thief.png", transparent = true },
    civilian = { path = "textures/bffs/Citizen.png", transparent = true },
}

local customIcons = {
    -- Replace these placeholder record IDs when the actor IDs are known.
    bff_placeholder_julan_1 = {
        path = "textures/bffs/Julan 1.png",
        transparent = true,
    },
    bff_placeholder_julan_2 = {
        path = "textures/bffs/Julan 2.png",
        transparent = true,
    },
    bff_placeholder_biz_kuit_1 = {
        path = "textures/bffs/Biz'Kuit 1.png",
        transparent = true,
    },
    bff_placeholder_biz_kuit_2 = {
        path = "textures/bffs/Biz'Kuit 2.png",
        transparent = true,
    },
    bff_placeholder_pack_guar = {
        path = "textures/bffs/Pack Guar.png",
        transparent = true,
    },
    bff_placeholder_slave = {
        path = "textures/bffs/Slave.png",
        transparent = true,
    },
    bff_placeholder_slave_flat = {
        path = "textures/bffs/Slave Flat.png",
        transparent = false,
    },
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

local skillThreshold = 30

---@param actor openmw.GObject
---@param skills table<string, openmw.types.DynamicStat>
---@return { path: string, transparent: boolean }
local function getFollowerIcon(actor, skills)
    local customIcon = customIcons[actor.recordId:lower()]
    if customIcon then
        return customIcon
    end

    if types.Creature.objectIsInstance(actor) then
        return defaultIcons.creature
    end

    if types.NPC.objectIsInstance(actor) then
        local npcRecord = types.NPC.records[actor.recordId]
        local classRecord = npcRecord and types.NPC.classes.record(npcRecord.class)
        local specialization = classRecord and classRecord.specialization
        local skillIds = specialization and specializationSkills[specialization:lower()]
        if skillIds then
            for _, skillId in ipairs(skillIds) do
                local skill = skills[skillId]
                if skill and skill.base >= skillThreshold then
                    return defaultIcons[specialization:lower()]
                end
            end
        end
    end

    return defaultIcons.civilian
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

---@param recordId string
---@param fileName string
---@param isTransparent boolean
iconsUI.setFollowerIcon = function(recordId, fileName, isTransparent)
    if type(recordId) ~= "string" or recordId == "" then
        error("recordId must be a non-empty string", 2)
    end
    if type(fileName) ~= "string" or fileName == "" then
        error("fileName must be a non-empty texture path", 2)
    end
    if type(isTransparent) ~= "boolean" then
        error("isTransparent must be a boolean", 2)
    end

    customIcons[recordId:lower()] = {
        path = fileName,
        transparent = isTransparent,
    }
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

return iconsUI
