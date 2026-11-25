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
local followerIconPacks = require("scripts.BestFriendsForever.utils.followerIconPacks")

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
---@type table<string, fun(actor: openmw.GObject): boolean|nil>
local ruleConditions = {}
---@type string[]
local ruleSuffixes = {}
local tooltipSettings = settingsCache.new(storage.playerSection("SettingsBestFriendsForever_tooltip"), async)

---@param settings table
---@return number
local function iconSizeFrom(settings)
    return math.max(1, tonumber(settings.iconSize) or defaultIconSize)
end

local FALLBACK_ICON_PATH = "textures/bff/icons/default/class_civilian.png"
local FALLBACK_BACKGROUND_PATH = "textures/bff/icons/default/background.png"

local creatureTypeKeys = {
    [types.Creature.TYPE.Creatures] = "creatures",
    [types.Creature.TYPE.Daedra] = "daedra",
    [types.Creature.TYPE.Humanoid] = "humanoid",
    [types.Creature.TYPE.Undead] = "undead",
}

local classIconKeys = {
    combat = "combat",
    magic = "mage",
    stealth = "stealth",
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

---@class FollowerIconSuffixSpec
---@field suffix string
---@field rule fun(actor: openmw.GObject): boolean|nil

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
---@param pack table
---@return FollowerIcon
local function getFallbackIcon(actor, skills, pack)
    if types.Creature.objectIsInstance(actor) then
        local creatureType = creatureTypeKeys[types.Creature.records[actor.recordId].type]
        if creatureType then
            local path = I.FollowerDetectionUtil.isSummon(actor)
                and (pack.summon[creatureType] or pack.creature[creatureType])
                or pack.creature[creatureType]
            if path then
                return { path = path }
            end
        end
        return { path = pack.class.civilian or FALLBACK_ICON_PATH }
    end

    if types.NPC.objectIsInstance(actor) then
        local npcRecord = types.NPC.records[actor.recordId]
        local classRecord = types.NPC.classes.record(npcRecord.class)
        local specializationId = classRecord.specialization:lower()
        local skillIds = specializationSkills[specializationId]
        for _, skillId in ipairs(skillIds) do
            local skill = skills[skillId]
            if skill and skill.base >= skillThreshold then
                local classKey = classIconKeys[specializationId] or specializationId
                return { path = pack.class[classKey] or FALLBACK_ICON_PATH }
            end
        end
    end

    return { path = pack.class.civilian or FALLBACK_ICON_PATH }
end

---@param actor openmw.GObject
---@param skills table<string, openmw.types.DynamicStat>
---@param pack table
---@return FollowerIcon
---@return boolean
local function getFollowerIcon(actor, skills, pack)
    local path = pack.id[actor.recordId:lower()]
    if path then
        return { path = path }, false
    end

    for _, ruleSuffix in ipairs(ruleSuffixes) do
        local condition = ruleConditions[ruleSuffix]
        if condition(actor) then
            path = pack.rule[ruleSuffix]
            if path then
                return { path = path }, false
            end
        end
    end

    return getFallbackIcon(actor, skills, pack), true
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
                    resource = getTexture(FALLBACK_BACKGROUND_PATH),
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
---@param backgroundPath string
---@param backgroundColor openmw.util.Color|nil
local function applyFollowerSlot(slot, icon, backgroundPath, backgroundColor)
    local data = slot.userData or {}
    slot.userData = data

    local background = slot.content.background
    if data.backgroundVisible ~= true then
        background.props.visible = true
        data.backgroundVisible = true
    end
    if data.backgroundPath ~= backgroundPath then
        background.props.resource = getTexture(backgroundPath)
        data.backgroundPath = backgroundPath
    end
    if data.backgroundColor ~= backgroundColor then
        background.props.color = backgroundColor or defaultIconBackgroundColor
        data.backgroundColor = backgroundColor
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

---@param suffix string
---@return string
local function normalizeSuffix(suffix)
    if type(suffix) ~= "string" then
        error("registerFollowerIconSuffix: suffix must be a non-empty key", 3)
    end
    local key = suffix:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
    if key == "" or not key:match("^[%w_ ]+$") then
        error("registerFollowerIconSuffix: suffix must be a non-empty key", 3)
    end
    return key:lower()
end

--- Provide a rule for a rule_* suffix.
---@param spec FollowerIconSuffixSpec
iconsUI.registerFollowerIconSuffix = function(spec)
    local suffix = normalizeSuffix(spec.suffix)
    local rule = spec.rule
    if type(rule) ~= "function" then
        error("registerFollowerIconSuffix requires a rule function", 3)
    end

    iconGeneration = iconGeneration + 1
    if ruleConditions[suffix] == nil then
        ruleSuffixes[#ruleSuffixes + 1] = suffix
    end
    ruleConditions[suffix] = rule
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
    icons.preset = nil

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

    local presetName = settings.iconPreset
    if icons.generation ~= iconGeneration or icons.preset ~= presetName then
        icons.followerIcon = nil
        icons.generation = iconGeneration
        icons.preset = presetName
    end
    local pack = followerIconPacks.get(presetName)

    if firstKind == "follower" or secondKind == "follower" then
        local followerIcon = icons.followerIcon
        if not followerIcon then
            local icon, isFallback = getFollowerIcon(actor, fData.skills, pack)
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
        local backgroundPath = pack.background or FALLBACK_BACKGROUND_PATH
        if firstKind == "follower" then
            applyFollowerSlot(icons.slots.first.follower, followerIcon, backgroundPath, backgroundColor)
        end
        if secondKind == "follower" then
            applyFollowerSlot(icons.slots.second.follower, followerIcon, backgroundPath, backgroundColor)
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

-- Priority: slightly special. Order-dependent: first matching rule wins.
iconsUI.registerFollowerIconSuffix {
    suffix = "animunculi",
    rule = function(actor)
        if not types.Creature.objectIsInstance(actor) then return false end
        local record = types.Creature.records[actor.recordId]
        return record.bloodType == 2 and record.soulValue == 0
    end,
}
iconsUI.registerFollowerIconSuffix {
    suffix = "slave",
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
}

return iconsUI
