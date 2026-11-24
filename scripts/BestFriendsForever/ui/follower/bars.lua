---@diagnostic disable: undefined-field
---@omw-context player
local util = require("openmw.util")
local v2 = util.vector2
local I = require("openmw.interfaces")
local ui = require("openmw.ui")
local barTexture = ui.texture { path = "textures/menu_bar_gray.dds" }
local defaultLabelColor = util.color.rgb(1, 1, 1)
local downedBarColor = util.color.rgb(0.5, 0.5, 0.5)

---@class HUDBarSettings
---@field barDimensions table<string, number>
---@field barLabels table<string, boolean>
---@field barLabelColor openmw.util.Color
---@field labelDisplayMode "Percent"|"Current"|"Current/Max"

local barsUI = {}

---@param statName string
---@param settings HUDBarSettings
---@return openmw.util.Vector2
barsUI.barSizeFor = function(statName, settings)
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
    return v2(barSize.x * (curr / base), barSize.y)
end

---@param fData StatEntry
---@param settings HUDBarSettings
---@return openmw.ui.Layout
barsUI.barElement = function(fData, settings)
    local barSize = fData.bar.size
    local curr = fData.stat.current
    local base = fData.stat.base
    local text
    local label
    local labels = settings.barLabels or {}
    if labels[fData.name] ~= false then
        local labelConstructor = barsUI.labelConstructors[settings.labelDisplayMode]
        text = labelConstructor(curr, base)
        label = {
            type = ui.TYPE.Text,
            props = {
                relativePosition = v2(0.5, 0.5),
                anchor = v2(0.5, 0.5),
                text = text,
                textColor = settings.barLabelColor or defaultLabelColor,
                textSize = barSize.y,
            },
        }
    end

    fData.bar.imgLayout = {
        name = "image",
        type = ui.TYPE.Image,
        props = {
            size = barsUI.barImgSize(barSize, curr, base),
            resource = barTexture,
            color = fData.bar.color,
        },
    }
    fData.bar.label = label
    fData.bar.lastText = text
    fData.bar.lastColor = fData.bar.color
    fData.bar.lastCurr = curr
    fData.bar.lastBase = base

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
    local labelConstructor = barsUI.labelConstructors[settings.labelDisplayMode]
    for _, statData in ipairs(fData.stats) do
        local bar = statData.bar
        local label = bar.label
        if label then
            local text
            if not down then
                text = labelConstructor(statData.stat.current, statData.stat.base)
            end
            if bar.lastText ~= text then
                label.props.text = text
                bar.lastText = text
            end
        end

        local imgLayout = bar.imgLayout
        if imgLayout then
            local color = down and downedBarColor or bar.color
            if bar.lastColor ~= color then
                imgLayout.props.color = color
                bar.lastColor = color
            end

            local base = statData.stat.base
            local curr = down and base or statData.stat.current
            if bar.lastCurr ~= curr or bar.lastBase ~= base then
                imgLayout.props.size = barsUI.barImgSize(bar.size, curr, base)
                bar.lastCurr = curr
                bar.lastBase = base
            end
        end
    end
end

return barsUI
