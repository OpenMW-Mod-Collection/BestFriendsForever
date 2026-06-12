---@diagnostic disable: missing-fields, param-type-mismatch
---@omw-context player
local util = require("openmw.util")
local v2 = util.vector2
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local async = require("openmw.async")
local types = require("openmw.types")

local settingsCache = require("scripts.GoodCompany.utils.settingsCache")

local followerUI = {}
local function updateRoot()
    if followerUI.root then
        followerUI.root:update()
    end
end
local settingsWrapper = settingsCache.new(
    storage.playerSection("SettingsGoodCompany_UIWrapper"),
    async,
    updateRoot
)
local settingsLocalUI = settingsCache.new(
    storage.playerSection("SettingsGoodCompany_UIFollower"),
    async,
    updateRoot
)
local barTexture = ui.texture({ path = 'textures/menu_bar_gray.dds' })
local dynamicStats = types.Actor.stats.dynamic
local sidePadding = 3

local followerStats = {
    -- actor.id = {
    --     health = dynamicStats.health(actor),
    --     magicka = dynamicStats.magicka(actor),
    --     fatigue = dynamicStats.fatigue(actor),
    -- }
}
local rootContent = {}

followerUI = {
    root = ui.create {
        name = "root",
        layer = "Windows",
        template = I.MWUI.templates.boxTransparent,
        props = {
            relativePosition = v2(.5, .5),
        },
        content = ui.content { {
            name = "rootPadding",
            template = I.MWUI.templates.padding,
            content = ui.content { {
                name = "rootFlex",
                type = ui.TYPE.Flex,
                props = {
                    horizontal = not settingsWrapper.verticalLayout,
                },
                content = ui.content { rootContent }
            } }
        } }
    }
}

local function padding(x, y)
    return {
        props = {
            size = v2(x, y)
        }
    }
end

local function barElement(stat, color)
    local ratio = stat.current / stat.base
    local barSize = v2(settingsLocalUI.barLength, settingsLocalUI.barWidth)

    local label
    if settingsLocalUI.barLabels then
        label = {
            type = ui.TYPE.Text,
            props = {
                relativePosition = util.vector2(0.5, 0.5),
                anchor = util.vector2(0.5, 0.5),
                text = ('%i/%i'):format(math.floor(stat.current), math.floor(stat.base)),
                textColor = util.color.rgb(1, 1, 1),
                textSize = barSize.y,
            },
        }
    end
    return {
        template = I.MWUI.templates.boxTransparent,
        content = ui.content({
            {
                props = {
                    size = barSize,
                },
                content = ui.content({
                    {
                        name = 'image',
                        type = ui.TYPE.Image,
                        props = {
                            size = barSize:emul(util.vector2(ratio, 1)),
                            resource = barTexture,
                            color = color,
                        },
                    },
                    label,
                }),
            },
        }),
    }
end

---@param follower GameObject
---@return table
local function createFollowerFlex(follower)
    if not followerStats[follower.id] then
        followerStats[follower.id] = {
            health = dynamicStats.health(follower),
            magicka = dynamicStats.magicka(follower),
            fatigue = dynamicStats.fatigue(follower)
        }
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
                },
                content = ui.content {
                    {
                        name = "followerName",
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = follower.type.records[follower.recordId].name,
                            textSize = settingsLocalUI.nameTextSize,
                        }
                    },
                    {
                        name = "followerFlex_H1",
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true
                        },
                        content = ui.content {
                            {
                                name = "followerFlex_Bars",
                                type = ui.TYPE.Flex,
                                props = {
                                    horizontal = false,
                                },
                                content = ui.content {
                                    barElement(followerStats[follower.id].health, settingsLocalUI.healthBarColor),
                                    padding(0, 3),
                                    barElement(followerStats[follower.id].magicka, settingsLocalUI.magickaBarColor),
                                    padding(0, 3),
                                    barElement(followerStats[follower.id].fatigue, settingsLocalUI.fatigueBarColor),
                                }
                            },
                            {
                                -- TODO combat icon
                            }
                        }
                    }
                }
            },
            padding(sidePadding, 0),
        }
    }
end

followerUI.new = function(followers)
    followerUI.root.layout.content = ui.content {}

    for _, state in pairs(followers) do
        print("parsing", state.actor)
        if #rootContent ~= 0 then
            followerUI.root.layout.content:add {
                name = "delimiter",
                template = settingsWrapper.verticalLayout
                    and I.MWUI.templates.horizontalLine
                    or I.MWUI.templates.verticalLine
            }
        end
        followerUI.root.layout.content:add(createFollowerFlex(state.actor))
    end

    followerUI.root:update()
end

followerUI.visible = function(visible)

end

followerUI.addFollower = function(follower)

end

followerUI.removeFollower = function(follower)

end

return followerUI
