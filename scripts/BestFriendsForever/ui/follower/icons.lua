---@diagnostic disable: param-type-mismatch, need-check-nil, undefined-field
---@omw-context player
local util = require("openmw.util")
local v2 = util.vector2
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local types = require("openmw.types")
local core = require("openmw.core")
local async = require("openmw.async")
local storage = require("openmw.storage")

local settingsCache = require("scripts.BestFriendsForever.utils.settingsCache")

local defaultIconSize = 32
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
local defaultIconBackgroundColor = util.color.rgb(1, 205 / 255, 123 / 255)
local unhealthyIconBackgroundColor = util.color.commaString(core.getGMST("fontcolor_color_negative"))
local downedIconBackgroundColor = util.color.rgb(0.5, 0.5, 0.5)
local effectIconPathPattern = "^(.*[/\\])(.*)$"

---@type table<string, openmw.ui.TextureResource>
local iconCache = {}
---@type table<string, openmw.ui.TextureResource>
local effectIconCache = {}
local iconGeneration = 0
local iconsUI = {}
---@type table<string, FollowerIcon>
local iconById = {}
---@type FollowerIcon[]
local iconRules = {}
local tooltipSettings = settingsCache.new(storage.playerSection("SettingsBestFriendsForever_tooltip"), async)

---@param settings table
---@return number
local function iconSizeFrom(settings)
    return math.max(1, tonumber(settings.iconSize) or defaultIconSize)
end

local defaultIcons = {
    combat = { path = "textures/bffs/npc_warrior.png", transparent = true },
    magic = { path = "textures/bffs/npc_mage.png", transparent = true },
    stealth = { path = "textures/bffs/npc_thief.png", transparent = true },
    civilian = { path = "textures/bffs/npc_citizen.png", transparent = true },
}

-- TODO: add these creature-type textures; the paths below are placeholders.
local creatureTypeIcons = {
    [types.Creature.TYPE.Creatures] = { path = "textures/bffs/Creatures.png", transparent = true },
    [types.Creature.TYPE.Daedra] = { path = "textures/bffs/Daedra.png", transparent = true },
    [types.Creature.TYPE.Humanoid] = { path = "textures/bffs/Humanoid.png", transparent = true },
    [types.Creature.TYPE.Undead] = { path = "textures/bffs/Undead.png", transparent = true },
}

-- TODO: add these summon-type textures; the paths below are placeholders.
local summonTypeIcons = {
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
    local icon = effectIconCache[id]
    if not icon then
        local effect = core.magic.effects.records[id]
        local path = effect.icon:gsub(effectIconPathPattern, "%1b_%2")
        icon = getTexture(path)
        effectIconCache[id] = icon
    end
    return icon
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
        local creatureType = types.Creature.records[actor.recordId].type
        return I.FollowerDetectionUtil.isSummon(actor)
            and summonTypeIcons[creatureType]
            or creatureTypeIcons[creatureType]
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
---@return boolean
local function getFollowerIcon(actor, skills)
    local icon = iconById[actor.recordId]
    if icon then return icon, false end

    for _, entry in ipairs(iconRules) do
        if entry.rule(actor) then return entry, false end
    end

    return getFallbackIcon(actor, skills), true
end

local function hasDisease(fData)
    for _, spell in pairs(fData.spells) do
        if spell.type == core.magic.SPELL_TYPE.Blight or spell.type == core.magic.SPELL_TYPE.Disease then
            return true
        end
    end
    return false
end

local function hasDamagedStats(fData)
    for statId, stat in pairs(fData.attributes) do
        local drain = fData.activeEffects:getEffect(core.magic.EFFECT_TYPE.DrainAttribute, statId)
        if stat.damage - drain.magnitude > 0 then
            return true
        end
    end
    for statId, stat in pairs(fData.skills) do
        local drain = fData.activeEffects:getEffect(core.magic.EFFECT_TYPE.DrainSkill, statId)
        if stat.damage - drain.magnitude > 0 then
            return true
        end
    end
    return false
end

local function shouldHighlight(fData)
    local toggles = tooltipSettings.enabledFields or {}
    local showDiseases = toggles.diseases ~= false
    local showStatDamage = toggles.statDamage ~= false
    return (showDiseases and hasDisease(fData)) or (showStatDamage and hasDamagedStats(fData))
end

---@param name string
---@param size number
---@return openmw.ui.Layout
local function newFollowerSlot(name, size)
    local iconSize = v2(size, size)
    return {
        name = name,
        template = I.MWUI.templates.boxTransparent,
        props = {
            size = iconSize,
        },
        content = ui.content {
            {
                name = "background",
                type = ui.TYPE.Image,
                props = {
                    resource = followerIconBackground,
                    color = defaultIconBackgroundColor,
                    size = iconSize,
                    visible = false,
                },
            },
            {
                name = "icon",
                type = ui.TYPE.Image,
                props = {
                    resource = h2hIcon,
                    size = iconSize,
                },
            },
        },
    }
end

---@param name string
---@param size number
---@return openmw.ui.Layout
local function newCombatSlot(name, size)
    local iconSize = v2(size, size)
    local magicSize = size + 8
    local magicOffset = -(magicSize - size) / 2
    local slot = {
        name = name,
        template = I.MWUI.templates.boxTransparent,
        props = {
            visible = true,
        },
        content = ui.content {
            {
                name = "combatBox",
                props = {
                    size = iconSize,
                },
                content = ui.content {
                    {
                        name = "magic",
                        type = ui.TYPE.Image,
                        props = {
                            resource = magicIcon,
                            position = v2(magicOffset, magicOffset),
                            size = v2(0, 0),
                            visible = false,
                        },
                    },
                    {
                        name = "icon",
                        type = ui.TYPE.Image,
                        props = {
                            resource = h2hIcon,
                            size = iconSize,
                        },
                    },
                },
            },
        },
    }
    slot.userData = {
        magicSize = v2(1, 1) * magicSize,
        zeroSize = v2(0, 0),
    }
    return slot
end

---@param slot openmw.ui.Layout
---@param icon FollowerIcon
---@param backgroundColor openmw.util.Color|nil
local function applyFollowerSlot(slot, icon, backgroundColor)
    local data = slot.userData or {}
    slot.userData = data

    local background = slot.content.background
    if icon.transparent then
        if data.hasBackground ~= true then
            background.props.visible = true
            data.hasBackground = true
        end
        if data.backgroundColor ~= backgroundColor then
            background.props.color = backgroundColor or defaultIconBackgroundColor
            data.backgroundColor = backgroundColor
        end
    elseif data.hasBackground ~= false then
        background.props.visible = false
        data.hasBackground = false
    end

    if data.path ~= icon.path then
        slot.content.icon.props.resource = getTexture(icon.path)
        data.path = icon.path
    end
end

---@param slot openmw.ui.Layout
---@param icon openmw.ui.TextureResource
---@param magic boolean
local function applyCombatSlot(slot, icon, magic)
    local data = slot.userData
    local box = slot.content.combatBox
    if data.magic ~= magic then
        box.content.magic.props.visible = magic
        box.content.magic.props.size = magic and data.magicSize or data.zeroSize
        data.magic = magic
    end
    if data.icon ~= icon then
        box.content.icon.props.resource = icon
        data.icon = icon
    end
end

---@param mode string
---@param stance number
---@return string
local function iconSignature(mode, stance)
    if mode == "Merged" then
        return stance == STANCE.Nothing and "Merged follower" or "Merged combat"
    end
    return mode
end

---@param signature string
---@return string
---@return string|nil
local function iconKinds(signature)
    if signature == "Follower/combat" then
        return "follower", "combat"
    elseif signature == "Combat/follower" then
        return "combat", "follower"
    elseif signature == "Follower only" or signature == "Merged follower" then
        return "follower"
    end
    return "combat"
end

---@param icons IconData
---@param signature string
local function buildIconContent(icons, signature)
    local firstKind, secondKind = iconKinds(signature)
    local content = ui.content {}
    content:add(icons.slots.first[firstKind])
    if secondKind then
        content:add(icons.spacer)
        content:add(icons.slots.second[secondKind])
    end
    icons.container.content = content
    icons.signature = signature
end

---@param actor openmw.GObject
---@param stance number
---@return openmw.ui.TextureResource
---@return boolean
local function combatIconFor(actor, stance)
    local icon = h2hIcon
    local magic = false

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

    return icon, magic
end

---@param actor openmw.GObject
---@param size number
---@return openmw.ui.Layout
iconsUI.renderCombat = function(actor, size)
    local slot = newCombatSlot("combatIcon", size)
    local icon, magic = combatIconFor(actor, types.Actor.getStance(actor))
    applyCombatSlot(slot, icon, magic)
    return slot
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
        iconGeneration = iconGeneration + 1
        return
    end

    for index, entry in ipairs(iconRules) do
        if entry.rule == rule then
            iconRules[index] = { rule = rule, path = icon.path, transparent = icon.transparent }
            iconGeneration = iconGeneration + 1
            return
        end
    end
    table.insert(iconRules, { rule = rule, path = icon.path, transparent = icon.transparent })
    iconGeneration = iconGeneration + 1
end

---@param fData FollowerData
---@param settings table
iconsUI.prepareIcons = function(fData, settings)
    local iconSize = iconSizeFrom(settings)
    local iconGap = math.max(0, tonumber(settings.iconInterval) or 4)
    local spacerSize = settings.iconOrientation == "Vertical" and v2(0, iconGap) or v2(iconGap, 0)
    local spacer = {
        name = "followerIconSpacer",
        props = { size = spacerSize },
    }
    local slotPool = {
        first = {
            follower = newFollowerSlot("followerIcon", iconSize),
            combat = newCombatSlot("combatIcon", iconSize),
        },
        second = {
            follower = newFollowerSlot("followerIcon2", iconSize),
            combat = newCombatSlot("combatIcon2", iconSize),
        },
    }

    local icons = fData.icons
    icons.container = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = settings.iconOrientation ~= "Vertical",
        },
        content = ui.content {},
    }
    icons.slots = slotPool
    icons.spacer = spacer
    icons.signature = nil
    icons.generation = iconGeneration
    icons.followerIcon = nil

    local mode = settings.iconDisplayMode or "Merged"
    local stance = types.Actor.getStance(fData.followerState.actor)
    buildIconContent(icons, iconSignature(mode, stance))
end

---@param fData FollowerData
---@param settings table
iconsUI.updateIcons = function(fData, settings)
    local icons = fData.icons
    local container = icons.container
    if settings.enabledElements.icons == false then
        container.props.visible = false
        return
    end

    local actor = fData.followerState.actor
    local stance = types.Actor.getStance(actor)
    local mode = settings.iconDisplayMode or "Merged"
    local signature = iconSignature(mode, stance)
    if icons.signature ~= signature then
        buildIconContent(icons, signature)
    end
    local firstKind, secondKind = iconKinds(signature)

    if icons.generation ~= iconGeneration then
        icons.followerIcon = nil
        icons.generation = iconGeneration
    end

    if firstKind == "follower" or secondKind == "follower" then
        local followerIcon = icons.followerIcon
        if not followerIcon then
            local icon, isFallback = getFollowerIcon(actor, fData.skills)
            followerIcon = icon
            if not isFallback then
                icons.followerIcon = followerIcon
            end
        end
        local backgroundColor = settings.iconBackgroundColor or defaultIconBackgroundColor
        if fData.down then
            backgroundColor = downedIconBackgroundColor
        elseif shouldHighlight(fData) then
            backgroundColor = unhealthyIconBackgroundColor
        end
        if firstKind == "follower" then
            applyFollowerSlot(icons.slots.first.follower, followerIcon, backgroundColor)
        end
        if secondKind == "follower" then
            applyFollowerSlot(icons.slots.second.follower, followerIcon, backgroundColor)
        end
    end

    if firstKind == "combat" or secondKind == "combat" then
        local icon, magic = combatIconFor(actor, stance)
        if firstKind == "combat" then
            applyCombatSlot(icons.slots.first.combat, icon, magic)
        end
        if secondKind == "combat" then
            applyCombatSlot(icons.slots.second.combat, icon, magic)
        end
    end

    container.props.visible = true
end

-- Priority: unique. Order-independent: record IDs are looked up directly.
-- TODO: replace these placeholder record IDs when the actor IDs are known.
iconsUI.setFollowerIcon {
    recordId = "bff_placeholder_julan_1",
    fileName = "textures/bffs/unique_julan.png",
    isTransparent = true,
}
iconsUI.setFollowerIcon {
    recordId = "bff_placeholder_biz_kuit_1",
    fileName = "textures/bffs/unique_bizkuitz.png",
    isTransparent = true,
}
iconsUI.setFollowerIcon {
    recordId = "bff_placeholder_pack_guar",
    fileName = "textures/bffs/unique_packguar.png",
    isTransparent = true,
}

-- Priority: slightly special. Order-dependent: first matching rule wins.
-- TODO: add the Animunculi texture; the path below is a placeholder.
iconsUI.setFollowerIcon {
    rule = function(actor)
        if not types.Creature.objectIsInstance(actor) then return false end
        local record = types.Creature.records[actor.recordId]
        return record.bloodType == 2 and record.soulValue == 0
    end,
    fileName = "textures/bffs/Animunculi.png",
    isTransparent = true,
}
iconsUI.setFollowerIcon {
    rule = function(actor)
        if not types.NPC.objectIsInstance(actor) then
            return false
        end
        local eq = types.NPC.getEquipment(actor)
        local leftGauntlet = eq[types.NPC.EQUIPMENT_SLOT.LeftGauntlet]
        local rightGauntlet = eq[types.NPC.EQUIPMENT_SLOT.RightGauntlet]
        return leftGauntlet == "slave_bracer_left"
            or rightGauntlet == "slave_bracer_right"
    end,
    fileName = "textures/bffs/cond_slave.png",
    isTransparent = true,
}

return iconsUI
