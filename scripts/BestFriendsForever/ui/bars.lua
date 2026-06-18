---@diagnostic disable: undefined-field
---@omw-context player
local util = require("openmw.util")
local v2 = util.vector2
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local async = require("openmw.async")

local settingsCache = require("scripts.BestFriendsForever.utils.settingsCache")

local settingsLocalUI = settingsCache.new(
    storage.playerSection("SettingsBestFriendsForever_UIFollower"),
    async
)
local barTexture = ui.texture { path = 'textures/menu_bar_gray.dds' }

local barsUI = {}

---@param curr number
---@param base number
---@return string
barsUI.labelText = function(curr, base)
    return ('%i/%i'):format(math.floor(curr), math.floor(base))
end

---@param barSize openmw.util.Vector2
---@param curr number
---@param base number
---@return openmw.util.Vector2
barsUI.barImgSize = function(barSize, curr, base)
    return barSize:emul(v2(curr / base, 1))
end

---@param fData FollowerData
---@return openmw.ui.Layout
barsUI.barElement = function(fData)
    local barSize = v2(settingsLocalUI.barLength, settingsLocalUI.barWidth)

    local label
    if settingsLocalUI.barLabels then
        label = {
            type = ui.TYPE.Text,
            props = {
                relativePosition = v2(0.5, 0.5),
                anchor = v2(0.5, 0.5),
                text = barsUI.labelText(fData.stat.current, fData.stat.base),
                textColor = util.color.rgb(1, 1, 1),
                textSize = settingsLocalUI.barWidth,
            },
        }
    end

    fData.bar.imgLayout = {
        name = 'image',
        type = ui.TYPE.Image,
        props = {
            size = barsUI.barImgSize(barSize, fData.stat.current, fData.stat.base),
            resource = barTexture,
            color = fData.bar.color,
        }
    }
    fData.bar.label = label

    return {
        template = I.MWUI.templates.boxTransparent,
        content = ui.content({
            {
                props = {
                    size = barSize,
                },
                content = ui.content {
                    fData.bar.imgLayout,
                    fData.bar.label,
                },
            },
        }),
    }
end

return barsUI
