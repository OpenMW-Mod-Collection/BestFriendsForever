---@diagnostic disable: undefined-field
---@omw-context player
local util = require("openmw.util")
local v2 = util.vector2
local I = require("openmw.interfaces")
local ui = require("openmw.ui")
local barTexture = ui.texture { path = "textures/menu_bar_gray.dds" }

---@class HUDBarSettings
---@field barDimensions table<string, number>
---@field barLabels table<string, boolean>
---@field barLabelColor openmw.util.Color
---@field labelDisplayMode "Percent"|"Current"|"Current/Max"

local barsUI = {}

---@param statName string
---@param settings HUDBarSettings
---@return openmw.util.Vector2
local function barSizeFor(statName, settings)
    local dimensions = settings.barDimensions or {}
    local width = tonumber(dimensions[statName .. "Width"]) or 100
    local height = tonumber(dimensions[statName .. "Height"]) or 16
    return v2(width, height)
end

barsUI.labelConstructors = {
    ["Percent"] = function(curr, base)
        return ("%i%%"):format(math.floor(100 * curr / base))
    end,
    ["Current"] = function(curr, base)
        return ("%i"):format(math.floor(curr))
    end,
    ["Current/Max"] = function(curr, base)
        return ("%i/%i"):format(math.floor(curr), math.floor(base))
    end,
}

---@param barSize openmw.util.Vector2
---@param curr number
---@param base number
---@return openmw.util.Vector2
barsUI.barImgSize = function(barSize, curr, base)
    return barSize:emul(v2(curr / base, 1))
end

---@param fData StatEntry
---@param settings HUDBarSettings
---@return openmw.ui.Layout
barsUI.barElement = function(fData, settings)
    local barSize = barSizeFor(fData.name, settings)

    local label
    local labels = settings.barLabels or {}
    if labels[fData.name] ~= false then
        local labelConstructor =
            barsUI.labelConstructors[settings.labelDisplayMode]
        label = {
            type = ui.TYPE.Text,
            props = {
                relativePosition = v2(0.5, 0.5),
                anchor = v2(0.5, 0.5),
                text = labelConstructor(fData.stat.current, fData.stat.base),
                textColor = settings.barLabelColor or util.color.rgb(1, 1, 1),
                textSize = barSize.y,
            },
        }
    end

    fData.bar.imgLayout = {
        name = "image",
        type = ui.TYPE.Image,
        props = {
            size = barsUI.barImgSize(
                barSize,
                fData.stat.current,
                fData.stat.base
            ),
            resource = barTexture,
            color = fData.bar.color,
        },
    }
    fData.bar.label = label

    return {
        template = I.MWUI.templates.boxTransparent,
        content = ui.content {
            {
                props = {
                    size = barSize,
                },
                content = ui.content {
                    fData.bar.imgLayout,
                    fData.bar.label,
                },
            },
        },
    }
end

---@param fData FollowerData
---@param down boolean
---@param settings HUDBarSettings
barsUI.updateStats = function(fData, down, settings)
    for _, statData in ipairs(fData.stats) do
        local barSize = barSizeFor(statData.name, settings)
        local label = statData.bar.label
        if label then
            if down then
                label.props.text = nil
            else
                local labelConstructor =
                    barsUI.labelConstructors[settings.labelDisplayMode]
                label.props.text =
                    labelConstructor(statData.stat.current, statData.stat.base)
            end
        end
        local imgLayout = statData.bar.imgLayout
        if imgLayout then
            if down then
                imgLayout.props.color = util.color.rgb(0.5, 0.5, 0.5)
                imgLayout.props.size = barsUI.barImgSize(
                    barSize,
                    statData.stat.base,
                    statData.stat.base
                )
            else
                imgLayout.props.color = statData.bar.color
                imgLayout.props.size = barsUI.barImgSize(
                    barSize,
                    statData.stat.current,
                    statData.stat.base
                )
            end
        end
    end
end

return barsUI
