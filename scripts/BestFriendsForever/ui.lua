---@diagnostic disable: missing-fields, param-type-mismatch, undefined-field, cast-local-type
---@omw-context player
local util = require("openmw.util")
local v2 = util.vector2
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local async = require("openmw.async")
local types = require("openmw.types")
local self = require("openmw.self")
local core = require("openmw.core")

local settingsCache = require("scripts.BestFriendsForever.utils.settingsCache")

local followerUI = {}

local wrapperSection = storage.playerSection("SettingsBestFriendsForever_UIWrapper")
local function settingsUpdated(key)
    followerUI.new(I.FollowerDetectionUtil.getFollowerList())
end
local settingsWrapper = settingsCache.new(
    wrapperSection,
    async,
    settingsUpdated
)
local settingsLocalUI = settingsCache.new(
    storage.playerSection("SettingsBestFriendsForever_UIFollower"),
    async,
    settingsUpdated
)
local settingsBlacklists = settingsCache.new(
    storage.globalSection("SettingsBestFriendsForever_blacklist"),
    async,
    settingsUpdated
)

---@class IconData
---@field container openmw.ui.Layout|nil
---@field combatLayout openmw.ui.Layout|nil     Layout node for the combat icon image; nil if combatIcon setting is off
---@field debuffLayout openmw.ui.Layout|nil     Layout node for the debuff icon image; nil if no debuff or setting is off

---@class BarData
---@field enabled boolean                   Whether this bar is shown
---@field color openmw.util.Color           Bar fill color
---@field imgLayout openmw.ui.Layout|nil    Layout node for the bar image; nil until the follower's UI is built
---@field label openmw.ui.Layout|nil        Layout node for the current/base label; nil if barLabels is off or UI not yet built

---@class StatEntry
---@field name "health"|"magicka"|"fatigue"
---@field stat openmw.types.DynamicStat|nil     Live stat proxy from dynamicStats.*()
---@field bar BarData

---@class FollowerData
---@field stats StatEntry[]     Ordered: [1]=health, [2]=magicka, [3]=fatigue
---@field icons IconData
---@field actor GameObject
---@field down boolean

---@type table<string, FollowerData>
followerUI.followerData = {}

local function padding(x, y)
    return {
        props = {
            size = v2(x, y)
        }
    }
end

local sidePadding = 3
local delimiterW = 10
local delimiterH = 15
local alignToAnchor = {
    Start = 0,
    Center = .5,
    End = 1
}
local sideToAlignment = {
    Left = "Start",
    Center = "Center",
    Right = "End",
}
local interval = { template = I.MWUI.templates.interval }
local delimiterPadding = padding(delimiterW, delimiterH)
local padding_0_3 = padding(0, 3)
local barTexture = ui.texture { path = 'textures/menu_bar_gray.dds' }
local magicIcon = ui.texture {
    path = 'textures/menu_icon_magic.dds',
    offset = v2(0, 0),
    size = v2(42, 42),
}
local h2hIcon = ui.texture { path = 'icons/k/stealth_handtohand.dds' }
local iconCache = {}
local rootFlex

local function blacklisted(actor, blacklist)
    local mwscript = actor.type.records[actor.recordId].mwscript
    if mwscript then
        for _, blacklistedScript in ipairs(blacklist) do
            if mwscript == blacklistedScript then
                return true
            end
        end
    end
    return false
end

-- +--------------------+
-- | Draggable UI logic |
-- +--------------------+

local function mousePress(data, elem)
    if data.button ~= 1 or settingsWrapper.lockPosition then return end -- Left mouse button
    if not elem.userData then
        elem.userData = {}
    end
    elem.userData.isDragging = true
    elem.userData.dragStartPosition = data.position
    elem.userData.windowStartPosition = followerUI.root.layout.props.position
        or v2(settingsWrapper.posX, settingsWrapper.posY)

    followerUI.root:update()
end

local function mouseMove(data, elem)
    if not (elem.userData and elem.userData.isDragging) then return end
    -- Calculate new position based on mouse movement
    local deltaX = data.position.x - elem.userData.dragStartPosition.x
    local deltaY = data.position.y - elem.userData.dragStartPosition.y
    local newPosition = util.vector2(
        elem.userData.windowStartPosition.x + deltaX,
        elem.userData.windowStartPosition.y + deltaY
    )
    followerUI.root.layout.props.position = newPosition

    followerUI.root:update()
end

local function mouseRelease(data, elem)
    if elem.userData then
        elem.userData.isDragging = false
    end
    -- kinda idiotic way of doing things, but it works
    I.BestFriendsForever.setPosSettings(
        math.floor(followerUI.root.layout.props.position.x),
        math.floor(followerUI.root.layout.props.position.y)
    )
    followerUI.root:update()
end

local eventCallbacks = {
    mousePress = async:callback(mousePress),
    mouseMove = async:callback(mouseMove),
    mouseRelease = async:callback(mouseRelease),
}

local function createRoot()
    rootFlex = {
        name = "rootFlex",
        type = ui.TYPE.Flex,
        props = {
            horizontal = settingsWrapper.horizontalLayout,
            arrange = ui.ALIGNMENT[sideToAlignment[settingsLocalUI.uiAlign]],
        },
        content = ui.content {}
    }

    local rootFlexPadding = {
        name = "rootFlexPadding",
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
        },
        content = ui.content {
            padding_0_3,
            rootFlex,
            padding_0_3,
        },
    }

    return ui.create {
        name = "root",
        layer = settingsWrapper.lockPosition and "HUD" or "Modal",
        template = I.MWUI.templates.boxTransparent,
        props = {
            alpha = settingsWrapper.enableBordersAndBg and 1 or 0,
            position = v2(settingsWrapper.posX, settingsWrapper.posY),
            anchor = v2(
                alignToAnchor[settingsWrapper.expansionDirection],
                alignToAnchor[settingsWrapper.expansionDirection]
            )
        },
        events = eventCallbacks,
        content = ui.content { {
            name = "rootOuterPadding",
            template = I.MWUI.templates.padding,
            props = {
                inheritAlpha = false,
            },
            content = ui.content { rootFlexPadding }
        } },
        userData = {
            windowStartPosition = v2(settingsWrapper.posX, settingsWrapper.posY)
        },
    }
end

local function labelText(curr, base)
    return ('%i/%i'):format(math.floor(curr), math.floor(base))
end

local function barImgSize(barSize, curr, base)
    return barSize:emul(v2(curr / base, 1))
end

local function barElement(data)
    local barSize = v2(settingsLocalUI.barLength, settingsLocalUI.barWidth)

    local label
    if settingsLocalUI.barLabels then
        label = {
            type = ui.TYPE.Text,
            props = {
                relativePosition = v2(0.5, 0.5),
                anchor = v2(0.5, 0.5),
                text = labelText(data.stat.current, data.stat.base),
                textColor = util.color.rgb(1, 1, 1),
                textSize = settingsLocalUI.barWidth,
            },
        }
    end

    data.bar.imgLayout = {
        name = 'image',
        type = ui.TYPE.Image,
        props = {
            size = barImgSize(barSize, data.stat.current, data.stat.base),
            resource = barTexture,
            color = data.bar.color,
        }
    }
    data.bar.label = label

    return {
        template = I.MWUI.templates.boxTransparent,
        content = ui.content({
            {
                props = {
                    size = barSize,
                },
                content = ui.content {
                    data.bar.imgLayout,
                    data.bar.label,
                },
            },
        }),
    }
end

local function getEffectIcon(id)
    local effect = core.magic.effects.records[id]
    local path = effect.icon:gsub('^(.*[/\\])(.*)$', '%1b_%2')

    if not iconCache[path] then
        iconCache[path] = ui.texture({ path = path })
    end
    return iconCache[path]
end

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

local function renderDisease(spellType)
    local icon
    if spellType == core.magic.SPELL_TYPE.Blight then
        icon = getEffectIcon(core.magic.EFFECT_TYPE.CureBlightDisease)
    else
        icon = getEffectIcon(core.magic.EFFECT_TYPE.CureCommonDisease)
    end
    return renderEquipmentIcon(icon, false, util.color.rgba(1.0, 0.15, 0.15, 1.0))
end

local function getSpellIcon(spell)
    local effect = spell.effects[1]
    if effect then
        return getEffectIcon(effect.effect.id)
    else
        return nil
    end
end

local function getItemIcon(item)
    local itemRecord = (item.type).record(item)
    local path = itemRecord.icon
    if path then
        local isMagical = itemRecord.enchant ~= nil and itemRecord.enchant ~= ''
        if not iconCache[path] then
            iconCache[path] = ui.texture({ path = path })
        end
        return iconCache[path], isMagical
    end
    return h2hIcon
end

local STANCE = types.Actor.STANCE
local EQUIPMENT_SLOT = types.Actor.EQUIPMENT_SLOT
local function renderCombat(actor)
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

local function getDebuff(actor)
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

local function renderDebuff(disease, effect)
    if disease then
        return renderDisease(disease.type)
    elseif effect then
        return renderEquipmentIcon(getEffectIcon(effect.id), false)
    else
        return renderEquipmentIcon(nil, false)
    end
end

local function placeIconsIntoContainers(fData, debuffed)
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

local function populateIcons(fData)
    local combatLayout = renderCombat(fData.actor)
    fData.icons.combatLayout = combatLayout

    local disease, effect = getDebuff(fData.actor)
    local debuffLayout = renderDebuff(disease, effect)
    fData.icons.debuffLayout = debuffLayout

    placeIconsIntoContainers(fData, disease or effect)
end

---@param follower GameObject
---@param down boolean
local function newFollowerData(follower, down)
    followerUI.followerData[follower.id] = {
        actor = follower,
        down = down,
        icons = {
            container = {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = settingsLocalUI.horizontalIcons,
                },
                content = ui.content({}),
            },
            combatLayout = nil,
            debuffLayout = nil,
        },
        stats = {
            {
                name = "health",
                stat = types.Actor.stats.dynamic.health(follower),
                bar = {
                    enabled = settingsLocalUI.healthBarEnabled,
                    color = settingsLocalUI.healthBarColor,
                    imgLayout = nil,
                    label = nil,
                },
            },
            {
                name = "magicka",
                stat = types.Actor.stats.dynamic.magicka(follower),
                bar = {
                    enabled = settingsLocalUI.magickaBarEnabled,
                    color = settingsLocalUI.magickaBarColor,
                    imgLayout = nil,
                    label = nil,
                },
            },
            {
                name = "fatigue",
                stat = types.Actor.stats.dynamic.fatigue(follower),
                bar = {
                    enabled = settingsLocalUI.fatigueBarEnabled,
                    color = settingsLocalUI.fatigueBarColor,
                    imgLayout = nil,
                    label = nil,
                },
            },
        },
    }
end

---@param follower GameObject
---@return table
local function createFollowerFlex(follower, down)
    newFollowerData(follower, down)
    local fData = followerUI.followerData[follower.id]

    local bars = {}
    for _, data in pairs(fData.stats) do
        local bar = barElement(data)
        if data.bar.enabled then
            bars[#bars + 1] = interval
            bars[#bars + 1] = bar
        end
    end

    local barsCountainer = {
        name = "followerFlex_Bars",
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
        },
        content = ui.content(bars)
    }

    if settingsLocalUI.combatIcon then
        populateIcons(fData)
    end

    return {
        name = "followerFlex_" .. follower.id,
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
        },
        content = ui.content {
            padding(sidePadding, 0),
            {
                name = "followerFlex_V1",
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    arrange = ui.ALIGNMENT[settingsLocalUI.uiAlign],
                },
                userData = {
                    actor = follower,
                },
                events = {
                    mouseClick = async:callback(function()
                        self:sendEvent("BestFriendsForever_followerWidgetClicked", follower)
                        follower:sendEvent("BestFriendsForever_followerWidgetClicked")
                        core.sendGlobalEvent("BestFriendsForever_followerWidgetClicked", follower)
                    end),
                },
                content = ui.content {
                    {
                        name = "followerName",
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = follower.type.records[follower.recordId].name,
                            textSize = settingsLocalUI.nameTextSize,
                            textShadow = true,
                            textColor = settingsLocalUI.nameColor,
                        },
                    },
                    {
                        name = "followerFlex_H1",
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                            arrange = ui.ALIGNMENT.Center,
                        },
                        content = ui.content {
                            settingsLocalUI.rightIcons and barsCountainer or fData.icons.container,
                            interval,
                            settingsLocalUI.rightIcons and fData.icons.container or barsCountainer,
                        },
                    },
                },
            },
            padding(sidePadding, 0),
        }
    }
end

followerUI.new = function(followers)
    rootFlex.content = ui.content {}
    followerUI.root:destroy()
    followerUI.root = createRoot()
    followerUI.followerData = {}
    local downedFollowers = I.BestFriendsForever
        and I.BestFriendsForever.getDownedFollowers()
        or {}

    for _, fState in pairs(followers) do
        local myFollower = fState.superLeader and fState.superLeader.id == self.id
            or fState.leader and fState.leader.id == self.id
        local banned = blacklisted(fState.actor, settingsBlacklists.globalBlacklistByScript)
        if not myFollower or banned then
            goto continue
        end

        if #rootFlex.content ~= 0 then
            local delimiter
            if settingsWrapper.enableBordersAndBg then
                delimiter = {
                    external = {
                        stretch = 1,
                    },
                    props = {
                        size = v2(delimiterW, delimiterH),
                    },
                    content = ui.content({
                        {
                            template = settingsWrapper.horizontalLayout
                                and I.MWUI.templates.verticalLine
                                or I.MWUI.templates.horizontalLine,
                            props = {
                                relativePosition = v2(0.5, 0.5),
                                anchor = v2(0.5, 0.5),
                            },
                        },
                    }),
                }
            else
                delimiter = delimiterPadding
            end
            rootFlex.content:add(delimiter)
        end

        local down = downedFollowers[fState.actor.id]
        rootFlex.content:add(createFollowerFlex(fState.actor, down))

        ::continue::
    end

    followerUI.root.layout.props.visible = #rootFlex.content ~= 0
    followerUI.root:update()
end

followerUI.updateData = function()
    for _, fData in pairs(followerUI.followerData) do
        local down = fData.down and settingsLocalUI.immortalityIntegration
        local barSize = v2(settingsLocalUI.barLength, settingsLocalUI.barWidth)
        -- stats
        for _, statData in ipairs(fData.stats) do
            local label = statData.bar.label
            if label then
                if down then
                    label.props.text = nil
                else
                    label.props.text = labelText(statData.stat.current, statData.stat.base)
                end
            end
            local imgLayout = statData.bar.imgLayout
            if imgLayout then
                if down then
                    statData.bar.imgLayout.props.color = util.color.rgb(.5, .5, .5)
                    imgLayout.props.size = barImgSize(barSize, statData.stat.base, statData.stat.base)
                else
                    imgLayout.props.size = barImgSize(barSize, statData.stat.current, statData.stat.base)
                    statData.bar.imgLayout.props.color = statData.bar.color
                end
            end
        end

        -- icons
        fData.icons.container.props.visible = not down
        if not down then
            fData.icons.combatLayout.content = renderCombat(fData.actor).content
            local disease, effect = getDebuff(fData.actor)
            fData.icons.debuffLayout.content = renderDebuff(disease, effect).content
            fData.icons.container.content = ui.content {}
            placeIconsIntoContainers(fData, disease or effect)
        end
    end

    followerUI.root:update()
end

followerUI.root = createRoot()

return followerUI
