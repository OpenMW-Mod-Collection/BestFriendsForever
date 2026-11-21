---@omw-context menu
---@diagnostic disable: missing-fields, param-type-mismatch, redundant-return-value
local ui = require("openmw.ui")
local util = require("openmw.util")
local async = require("openmw.async")
local core = require("openmw.core")
local ambient = require("openmw.ambient")
local inputApi = require("openmw.input")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")

-- A vertical stack of sliders stored as one table.
-- Slider visuals follow the bundled SuperSlider6 renderer by ownlyme; table
-- grouping follows Drop-in Utils' multiInput_V1. Settings arguments and values
-- may be read-only userdata proxies, so both tables and userdata are accepted.
-- Numeric options may be a single value applied to every key, or a table of
-- per-key overrides. "SEPARATOR" inserts extra vertical space.
--
-- Example:
-- {
--  key = "BAR_DIMENSIONS",
--  name = "barDimensions_name",
--  description = "barDimensions_desc",
--  renderer = "BFFMultiSlider_V1",
--  default = { width = 100, height = 16 },
--  argument = {
--      keys = { "width", "height", "SEPARATOR" },
--      l10n = "MyMod",                  -- optional; each key is also an l10n key
--      labels = { width = "Custom Width" }, -- optional overrides for l10n keys
--      min = 1,
--      max = { width = 800, height = 128 },
--      step = 1,
--      stepAffectsTextInput = true,
--      default = { width = 100, height = 16 }, -- needed for marks/reset buttons
--      width = 140,
--      thickness = 14,
--      showDefaultMark = true,
--      showResetButton = true,
--      tinyReset = true,
--  },
-- }
--
-- Resulting stored value: { width = 100, height = 16 }

local RENDERER_ID = "BFFMultiSlider_V1"
local FAMILY_ID = "BFFMultiSlider"
local SEPARATOR_KEY = "SEPARATOR"

local installedRenderers = storage.playerSection("InstalledSettingsRenderers")
installedRenderers:setLifeTime(storage.LIFE_TIME.GameSession)
installedRenderers:set(RENDERER_ID, true)
if (installedRenderers:get(FAMILY_ID) or 0) < 1 then
    installedRenderers:set(FAMILY_ID, 1)
end

local leftArrow = ui.texture { path = "textures/omw_menu_scroll_left.dds" }
local rightArrow = ui.texture { path = "textures/omw_menu_scroll_right.dds" }
local trackTexture = ui.texture { path = "textures/omw_menu_scroll_center_h.dds" }

local defaultArgument = {
    min = 0,
    max = 100,
    step = 1,
    stepAffectsTextInput = false,
    default = nil,
    showDefaultMark = false,
    showResetButton = false,
    tinyReset = false,
    width = 140,
    thickness = 14,
    labelSize = nil,
    unit = "",
    disabled = false,
}

local statesByArgument = setmetatable({}, { __mode = "k" })
local activeControl = nil

-- Settings values and arguments round-trip through storage as read-only
-- userdata proxies, so treat both userdata and plain tables as containers.
local function isContainer(value)
    local kind = type(value)
    return kind == "table" or kind == "userdata"
end

local function copyValues(values)
    local result = {}
    if isContainer(values) then
        for key, value in pairs(values) do
            result[key] = value
        end
    end
    return result
end

local function resolveOption(option, key, fallback)
    local value = option
    if isContainer(option) then
        value = option[key]
        if value == nil then
            value = option.default
        end
    end
    if value == nil then
        return fallback
    end
    return value
end

local function snapValue(value, min, max, step)
    if step <= 0 then
        return util.clamp(value, min, max)
    end
    local snapped = min + math.floor((value - min) / step + 0.5) * step
    return util.clamp(snapped, min, max)
end

local function formatValue(value, step)
    if step >= 1 and math.abs(value % 1) < 0.01 then
        return string.format("%d", math.floor(value + 0.5))
    elseif step >= 0.1 then
        return string.format("%.1f", value)
    elseif step >= 0.01 then
        return string.format("%.2f", value)
    end
    return string.format("%.3f", value)
end

local function colorFromGMST(gmst)
    local colorString = core.getGMST(gmst) or ""
    local channels = {}
    for part in colorString:gmatch("([^,]+)") do
        if #channels == 3 then
            break
        end
        local number = tonumber(part:match("^%s*(.-)%s*$"))
        if number then
            table.insert(channels, number / 255)
        end
    end
    if #channels < 3 then
        return util.color.rgb(1, 1, 1)
    end
    return util.color.rgb(table.unpack(channels))
end

local resetTextColors = {
    normal = colorFromGMST("fontcolor_color_normal"),
    hover = colorFromGMST("fontcolor_color_normal_over"),
    pressed = colorFromGMST("fontcolor_color_normal_pressed"),
}

-- Mouse-wheel support mirrors SuperSlider6. Only activate these triggers when
-- this renderer had to create them; otherwise another renderer already owns
-- the game's wheel behavior.
local ownsWheelTriggers = false
if not inputApi.triggers["MenuMouseWheelUp"] then
    inputApi.registerTrigger {
        key = "MenuMouseWheelUp",
        l10n = "none",
        name = "MenuMouseWheelUp",
        description = "",
    }
    inputApi.registerTrigger {
        key = "MenuMouseWheelDown",
        l10n = "none",
        name = "MenuMouseWheelDown",
        description = "",
    }
    ownsWheelTriggers = true
end

local function onMouseWheel(direction)
    if ownsWheelTriggers then
        if direction > 0 then
            inputApi.activateTrigger("MenuMouseWheelUp")
        else
            inputApi.activateTrigger("MenuMouseWheelDown")
        end
    end

    local control = activeControl
    if not control then
        return
    end

    -- Prefer the current renderer state in case the settings UI rebuilt after
    -- the previous change. Fall back to the state captured by the active row.
    local state = statesByArgument[control.argument] or control.state
    if not state then
        return
    end

    local current = tonumber(state.values[control.key]) or control.min
    local newValue = snapValue(current + direction * control.step, control.min, control.max, control.step)
    if newValue ~= current then
        state.commit(control.key, newValue)
    end
end

I.Settings.registerRenderer(RENDERER_ID, function(value, set, argument)
    if not isContainer(argument) or not isContainer(argument.keys) then
        error(RENDERER_ID .. ": argument.keys is required and must be a table or userdata list")
    end

    local state = { values = copyValues(value) }
    local function commit(key, newValue)
        local values = copyValues(state.values)
        values[key] = newValue
        state.values = values
        set(values)
    end
    state.commit = commit
    statesByArgument[argument] = state

    local keys = argument.keys
    local translate = argument.l10n
        and core.l10n(argument.l10n)
        or function(key) return key end

    local interval = { template = I.MWUI.templates.interval }
    local body = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            arrange = ui.ALIGNMENT.End,
        },
        content = ui.content({}),
    }

    local function addRow(key)
        local min = resolveOption(argument.min, key, defaultArgument.min)
        local max = resolveOption(argument.max, key, defaultArgument.max)
        local step = resolveOption(argument.step, key, defaultArgument.step)
        local unit = tostring(resolveOption(argument.unit, key, defaultArgument.unit))
        local default = resolveOption(argument.default, key, min)
        local width = math.max(40, resolveOption(argument.width, key, defaultArgument.width))
        local thickness = math.max(8, resolveOption(argument.thickness, key, defaultArgument.thickness))
        local labelSize = resolveOption(argument.labelSize, key, math.max(thickness - 2, 10))
        local stepAffectsTextInput = resolveOption(argument.stepAffectsTextInput, key, false)
        local showDefaultMark = resolveOption(argument.showDefaultMark, key, false)
        local showResetButton = resolveOption(argument.showResetButton, key, false)
        local tinyReset = resolveOption(argument.tinyReset, key, false)
        local rowDisabled = resolveOption(argument.disabled, key, false)

        if max < min then
            min, max = max, min
        end
        if step <= 0 then
            step = 1
        end

        default = tonumber(default) or min
        default = snapValue(default, min, max, step)

        local current = tonumber(state.values[key])
        if current == nil then
            current = default
        end
        current = util.clamp(current, min, max)

        local label = (argument.labels and argument.labels[key]) or translate(key)
        local thicknessScale = thickness / 14
        local rowHeight = math.max(thickness, labelSize + 2)
        local handleWidth = math.max(thickness + 2, 4)
        local handleHeight = math.max(thickness - 4, 4)
        local arrowSize = util.vector2(thickness, thickness)
        local trackSpan = math.max(width - handleWidth, 1)
        local editing = {}
        local lastInput = {}

        local function valueToPosition(val)
            if max == min then
                return 0
            end
            return math.floor((val - min) / (max - min) * trackSpan + 0.5)
        end

        local function positionToValue(pos)
            if trackSpan <= 0 or max == min then
                return min
            end
            local normalized = pos / trackSpan
            return snapValue(min + normalized * (max - min), min, max, step)
        end

        local function setActive()
            activeControl = {
                argument = argument,
                state = state,
                key = key,
                min = min,
                max = max,
                step = step,
            }
        end

        local function clearActive()
            if activeControl and activeControl.argument == argument and activeControl.key == key then
                activeControl = nil
            end
        end

        local function commitNumber(newValue, shouldSnap)
            newValue = shouldSnap
                and snapValue(newValue, min, max, step)
                or util.clamp(newValue, min, max)
            local latest = tonumber(state.values[key])
            if latest == nil or math.abs(newValue - latest) > 0.00001 then
                commit(key, newValue)
            end
        end

        local function stepBy(direction)
            local latest = tonumber(state.values[key]) or current
            commitNumber(latest + direction * step, true)
        end

        local decrement = async:callback(function()
            ambient.playSound("menu click")
            setActive()
            stepBy(-1)
        end)
        local increment = async:callback(function()
            ambient.playSound("menu click")
            setActive()
            stepBy(1)
        end)

        local function makeArrow(resource, onClick)
            return {
                template = I.MWUI.templates.box,
                content = ui.content({
                    {
                        type = ui.TYPE.Image,
                        props = {
                            resource = resource,
                            size = arrowSize,
                        },
                        events = { mouseClick = onClick },
                    },
                }),
            }
        end

        local leftBox = makeArrow(leftArrow, decrement)
        local rightBox = makeArrow(rightArrow, increment)

        local updateFromMouse = async:callback(function(e)
            if e.button ~= 1 then
                return
            end
            setActive()
            local pos = util.clamp(e.offset.x - handleWidth / 2, 0, trackSpan)
            commitNumber(positionToValue(pos), true)
        end)

        local trackContent = {}
        if showDefaultMark and default ~= min then
            local markPos = valueToPosition(default)
            table.insert(trackContent, {
                type = ui.TYPE.Widget,
                props = {
                    position = util.vector2(markPos + handleWidth / 2 - 1, 0),
                    size = util.vector2(2, thickness),
                },
                content = ui.content({
                    {
                        type = ui.TYPE.Image,
                        props = {
                            resource = trackTexture,
                            relativeSize = util.vector2(1, 1),
                            alpha = math.abs(current - default) > 0.00001 and 1 or 0,
                        },
                    },
                }),
            })
        end
        table.insert(trackContent, {
            type = ui.TYPE.Widget,
            props = {
                position = util.vector2(valueToPosition(current), (thickness - handleHeight) / 2),
                size = util.vector2(handleWidth, handleHeight),
            },
            content = ui.content({
                {
                    type = ui.TYPE.Image,
                    props = {
                        resource = trackTexture,
                        size = util.vector2(handleWidth, handleHeight),
                    },
                },
            }),
        })

        local trackBox = {
            template = I.MWUI.templates.box,
            content = ui.content({
                {
                    type = ui.TYPE.Widget,
                    props = {
                        size = util.vector2(width, thickness),
                    },
                    content = ui.content(trackContent),
                    events = {
                        mouseMove = updateFromMouse,
                        mousePress = updateFromMouse,
                        focusLoss = async:callback(clearActive),
                    },
                },
            }),
        }

        local unitLength = #unit
        local widestValue = math.max(math.abs(min), math.abs(max), 1)
        unitLength = unitLength + math.max(0, math.floor(math.log10(widestValue)) - 2)
        if min < 0 then
            unitLength = unitLength + 1
        end
        if step < 0.01 then
            unitLength = unitLength + 1
        end

        local textElement
        local function refreshText()
            if not textElement then
                return
            end
            local val = tonumber(state.values[key])
            if val == nil then
                val = default
            end
            local text = formatValue(val, step)
            if not editing[key] then
                text = text .. unit
            end
            textElement.layout.props.text = text
            textElement:update()
        end

        local onTextChanged = async:callback(function(text)
            lastInput[key] = text
        end)
        local onFocusGain = async:callback(function()
            setActive()
            editing[key] = true
            lastInput[key] = nil
            refreshText()
        end)
        local onFocusLoss = async:callback(function()
            editing[key] = false
            local text = lastInput[key]
            if text ~= nil then
                local num = tonumber(text)
                if num then
                    commitNumber(num, stepAffectsTextInput == true)
                end
            end
            lastInput[key] = nil
            refreshText()
            clearActive()
        end)

        local textWidth = math.max(42, math.floor((37 + unitLength * 4) * thicknessScale + 0.5))
        textElement = ui.create {
            template = I.MWUI.templates.textEditLine,
            props = {
                size = util.vector2(textWidth, rowHeight),
                text = formatValue(current, step) .. (editing[key] and "" or unit),
                textSize = thickness + 1,
                textAlignH = ui.ALIGNMENT.Center,
                textAlignV = ui.ALIGNMENT.Center,
                autoSize = false,
            },
            events = {
                textChanged = onTextChanged,
                focusGain = onFocusGain,
                focusLoss = onFocusLoss,
            },
        }

        local textBox = {
            template = I.MWUI.templates.box,
            content = ui.content({ textElement }),
        }

        local resetButton
        if showResetButton and default ~= nil then
            local resetLabel = tinyReset and "R" or core.l10n("Interface")("Reset")
            local resetWidth = tinyReset and 20 or 40
            resetWidth = math.max(resetWidth, math.floor((tinyReset and 18 or 40) * thicknessScale + 0.5))
            local resetText = ui.create {
                template = I.MWUI.templates.textNormal,
                props = {
                    text = resetLabel,
                    size = util.vector2(resetWidth, rowHeight),
                    autoSize = false,
                    textSize = thickness + 1,
                    textAlignH = ui.ALIGNMENT.Center,
                    textAlignV = ui.ALIGNMENT.Center,
                    textColor = resetTextColors.normal,
                },
            }
            local function updateResetColor(color)
                resetText.layout.props.textColor = color
                resetText:update()
            end
            resetButton = {
                template = I.MWUI.templates.box,
                content = ui.content({ resetText }),
                events = {
                    mousePress = async:callback(function()
                        updateResetColor(resetTextColors.pressed)
                    end),
                    mouseRelease = async:callback(function()
                        updateResetColor(resetTextColors.hover)
                    end),
                    focusGain = async:callback(function()
                        updateResetColor(resetTextColors.hover)
                    end),
                    focusLoss = async:callback(function()
                        updateResetColor(resetTextColors.normal)
                    end),
                    mouseClick = async:callback(function()
                        ambient.playSound("menu click")
                        setActive()
                        commitNumber(default, true)
                    end),
                },
            }
        end

        local leftMargin = {
            type = ui.TYPE.Widget,
            props = {
                size = util.vector2(15, rowHeight),
            },
        }
        local labelGap = {
            type = ui.TYPE.Widget,
            props = {
                size = util.vector2(4, rowHeight),
            },
        }

        local rowContent = {
            leftMargin,
            {
                template = I.MWUI.templates.textNormal,
                props = {
                    text = label,
                    textSize = labelSize,
                    textAlignV = ui.ALIGNMENT.Center,
                },
            },
            labelGap,
            leftBox,
            trackBox,
            rightBox,
            interval,
            textBox,
        }
        if resetButton then
            table.insert(rowContent, interval)
            table.insert(rowContent, resetButton)
        end

        local row = {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                arrange = ui.ALIGNMENT.Center,
            },
            content = ui.content(rowContent),
        }
        if rowDisabled then
            row = {
                template = I.MWUI.templates.disabled,
                content = ui.content({ row }),
            }
        end

        return row
    end

    local addedRow = false
    for _, key in ipairs(keys) do
        if key == SEPARATOR_KEY then
            body.content:add(interval)
            body.content:add(interval)
            body.content:add(interval)
        else
            if addedRow then
                body.content:add(interval)
            end
            body.content:add(addRow(key))
            addedRow = true
        end
    end

    local result = {
        type = ui.TYPE.Flex,
        props = {
            arrange = ui.ALIGNMENT.End,
        },
        content = ui.content({ body }),
    }
    if argument.disabled == true then
        result = {
            template = I.MWUI.templates.disabled,
            content = ui.content({ result }),
        }
    end
    return result
end)

return {
    engineHandlers = {
        onMouseWheel = onMouseWheel,
    },
}
