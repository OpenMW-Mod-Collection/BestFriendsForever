---@diagnostic disable: assign-type-mismatch, missing-fields
---@omw-context player
local I = require("openmw.interfaces")
local util = require("openmw.util")
local v2 = util.vector2
local async = require("openmw.async")
local ambient = require("openmw.ambient")
local ui = require("openmw.ui")
local auxUi = require("openmw_aux.ui")
local core = require("openmw.core")

local commonUI = {}

local C = {}

C.Colors = {
    DEFAULT = util.color.commaString(core.getGMST("fontcolor_color_normal")),
    DEFAULT_LIGHT = util.color.commaString(core.getGMST("fontcolor_color_normal_over")),
    DEFAULT_PRESSED = util.color.commaString(core.getGMST("fontcolor_color_normal_pressed")),
    ACTIVE = util.color.commaString(core.getGMST("fontcolor_color_active")),
    ACTIVE_LIGHT = util.color.commaString(core.getGMST("fontcolor_color_active_over")),
    ACTIVE_PRESSED = util.color.commaString(core.getGMST("fontcolor_color_active_pressed")),
    DISABLED = util.color.commaString(core.getGMST("fontcolor_color_disabled")),
    DISABLED_LIGHT = util.color.commaString(core.getGMST("fontcolor_color_disabled_over")),
    DISABLED_PRESSED = util.color.commaString(core.getGMST("fontcolor_color_disabled_pressed")),
    BAR_HEALTH = util.color.commaString(core.getGMST("fontcolor_color_health")),
    BAR_MAGIC = util.color.commaString(core.getGMST("fontcolor_color_magic")),
    BAR_FATIGUE = util.color.commaString(core.getGMST("fontcolor_color_fatigue")),
    POSITIVE = util.color.commaString(core.getGMST("fontcolor_color_positive")),
    DAMAGED = util.color.commaString(core.getGMST("fontcolor_color_negative")),
    BACKGROUND = util.color.commaString(core.getGMST("fontcolor_color_background")),
    WHITE = util.color.rgb(1, 1, 1),
    GRAY = util.color.rgb(0.5, 0.5, 0.5),
    DARK_GRAY = util.color.rgb(0.25, 0.25, 0.25),
    BLACK = util.color.rgb(0, 0, 0),
    CYAN = util.color.rgb(0, 1, 1),
    YELLOW = util.color.rgb(1, 1, 0),
    RED = util.color.rgb(1, 0, 0),
    DARK_RED = util.color.rgb(0.5, 0, 0),
    RED_DESAT = util.color.rgb(0.7, 0.3, 0.3),
    DARK_RED_DESAT = util.color.rgb(0.3, 0.05, 0.05),
}

local textNormalSize = I.MWUI.templates.textNormal.props.textSize or 12
local textHeaderSize = I.MWUI.templates.textHeader.props.textSize or textNormalSize

-- Layout numbers mirrored from Stats Window Extender.
commonUI.Sizes = {
    TEXT_NORMAL = textNormalSize,
    TEXT_HEADER = textHeaderSize,
    LINE_HEIGHT = textNormalSize + 2,
    HEADER_HEIGHT = 20,
    BORDER = 2,
    THICK_BORDER = 4,
    BORDER_WIDTH_TOTAL = 4 * 4,
    BOX_INNER_PADDING = 2,
    BOX_OUTER_PADDING = 8,
    SECTION_INDENT_L = 12,
    SECTION_INDENT_R = 4,
}

commonUI.Colors = C.Colors

local buttonBorderSize = 4
local borderSideParts = {
    left = v2(0, 0),
    right = v2(1, 0),
    top = v2(0, 0),
    bottom = v2(0, 1),
}
local borderCornerParts = {
    top_left_corner = v2(0, 0),
    top_right_corner = v2(1, 0),
    bottom_left_corner = v2(0, 1),
    bottom_right_corner = v2(1, 1),
}
local buttonBorderPattern = "textures/menu_button_frame_%s.dds"

local buttonBorderResources = {}
local buttonBorderPieces = {}
commonUI.TEXTURES = {}

commonUI.createTexture = function(path)
    if commonUI.TEXTURES[path] then
        return commonUI.TEXTURES[path]
    else
        local tex = ui.texture { path = path }
        commonUI.TEXTURES[path] = tex
        return tex
    end
end

commonUI.intervalH = function(size)
    return {
        props = {
            size = v2(size, 0),
        },
    }
end

commonUI.intervalV = function(size)
    return {
        props = {
            size = v2(0, size),
        },
    }
end

-- Container that adds an exact amount of padding on every side.
commonUI.padding = function(size)
    local padding = v2(size, size)
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            { props = { size = padding } },
            {
                external = { slot = true },
                props = {
                    position = padding,
                    relativeSize = v2(1, 1),
                },
            },
            {
                props = {
                    position = padding,
                    relativePosition = v2(1, 1),
                    size = padding,
                },
            },
        },
    }
end

commonUI.text = function(value, options)
    options = options or {}
    local props = {
        text = tostring(value),
        textShadow = options.shadow ~= false,
        textAlignV = ui.ALIGNMENT.Center,
    }
    if options.size then
        props.size = options.size
        props.autoSize = false
    end
    if options.align ~= nil then
        props.textAlignH = options.align
    end
    if options.color then
        props.textColor = options.color
    end

    local layout = {
        name = options.name,
        template = options.header and I.MWUI.templates.textHeader or I.MWUI.templates.textNormal,
        props = props,
    }
    if options.grow then
        layout.external = { grow = 1 }
    end
    return layout
end

commonUI.labeledRow = function(label, value, options)
    options = options or {}
    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            autoSize = false,
            size = v2(0, options.height or commonUI.Sizes.LINE_HEIGHT),
            relativeSize = v2(1, 0),
            gap = options.gap or 6,
        },
        content = ui.content {
            commonUI.text(label, {
                align = ui.ALIGNMENT.Start,
                color = options.labelColor,
                grow = true,
                header = options.labelHeader or options.header,
            }),
            commonUI.text(value, {
                align = ui.ALIGNMENT.End,
                color = options.valueColor,
                header = options.valueHeader or options.header,
                size = options.valueWidth and v2(options.valueWidth, options.height or commonUI.Sizes.LINE_HEIGHT),
            }),
        },
    }
end

commonUI.headerRow = function(label)
    return commonUI.labeledRow(label, "", { labelHeader = true })
end

commonUI.bar = function(props)
    props = props or {}
    local value = math.floor(props.value or 0)
    local maxValue = math.floor(props.maxValue or 100)
    local percentage = maxValue ~= 0 and math.min(math.max(value / maxValue, 0), 1) or 1

    return {
        name = props.name,
        template = I.MWUI.templates.borders,
        external = { stretch = 1 },
        props = {
            autoSize = false,
            size = props.size or v2(100, commonUI.Sizes.LINE_HEIGHT),
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    relativeSize = v2(percentage, 1),
                    resource = commonUI.createTexture(props.texture or "textures/menu_bar_gray.dds"),
                    color = props.color or C.Colors.RED,
                },
            },
            {
                type = ui.TYPE.Text,
                props = {
                    anchor = v2(0.5, 0.5),
                    relativePosition = v2(0.5, 0.5),
                    text = props.text or string.format("%i/%i", value, maxValue),
                    textColor = props.textColor or C.Colors.DEFAULT,
                    textShadow = true,
                    textSize = props.textSize or commonUI.Sizes.TEXT_NORMAL,
                },
            },
        },
    }
end

commonUI.progressBar = commonUI.bar

commonUI.divider = function()
    local indentL = commonUI.Sizes.SECTION_INDENT_L
    local indentR = commonUI.Sizes.SECTION_INDENT_R
    return {
        props = {
            relativeSize = v2(1, 0),
            size = v2(0, commonUI.Sizes.LINE_HEIGHT),
        },
        content = ui.content {
            {
                template = I.MWUI.templates.horizontalLine,
                props = {
                    anchor = v2(0, 0.5),
                    relativePosition = v2(0, 0.5),
                    size = v2(-indentL - indentR - 4, 2),
                    position = v2(indentL, 0),
                },
            },
        },
    }
end

for k in pairs(borderSideParts) do
    buttonBorderResources[k] = commonUI.createTexture(buttonBorderPattern:format(k))
    local horizontal = (k == "top" or k == "bottom")
    buttonBorderPieces[k] = {
        type = ui.TYPE.Image,
        props = {
            resource = buttonBorderResources[k],
            tileH = horizontal,
            tileV = not horizontal,
        },
    }
end

for k in pairs(borderCornerParts) do
    buttonBorderResources[k] = commonUI.createTexture(buttonBorderPattern:format(k))
    buttonBorderPieces[k] = {
        type = ui.TYPE.Image,
        props = {
            resource = buttonBorderResources[k],
        },
    }
end

commonUI.buttonBorders = function(borderSize)
    buttonBorderSize = borderSize or buttonBorderSize
    local template = {
        content = ui.content {},
    }
    for k, v in pairs(borderSideParts) do
        local horizontal = (k == "top" or k == "bottom")
        local direction = horizontal and v2(1, 0) or v2(0, 1)
        template.content:add {
            template = buttonBorderPieces[k],
            props = {
                position = (direction - v) * buttonBorderSize,
                relativePosition = v,
                size = (v2(1, 1) - direction * 3) * buttonBorderSize,
                relativeSize = direction,
            },
        }
    end
    for k, v in pairs(borderCornerParts) do
        template.content:add {
            template = buttonBorderPieces[k],
            props = {
                position = -v * buttonBorderSize,
                relativePosition = v,
                size = v2(buttonBorderSize, buttonBorderSize),
            },
        }
    end
    template.content:add {
        ---@diagnostic disable-next-line: missing-fields
        external = { slot = true },
        props = {
            position = v2(buttonBorderSize, buttonBorderSize),
            size = v2(buttonBorderSize * -2, buttonBorderSize * -2),
            relativeSize = v2(1, 1),
        },
    }
    return template
end

commonUI.buttonBox = function()
    local template = {
        type = ui.TYPE.Container,
        content = ui.content {},
    }
    for k, v in pairs(borderSideParts) do
        local horizontal = (k == "top" or k == "bottom")
        local direction = horizontal and v2(1, 0) or v2(0, 1)
        template.content:add {
            template = buttonBorderPieces[k],
            props = {
                position = (direction + v) * buttonBorderSize,
                relativePosition = v,
                size = (v2(1, 1) - direction) * buttonBorderSize,
                relativeSize = direction,
            },
        }
    end
    for k, v in pairs(borderCornerParts) do
        template.content:add {
            template = buttonBorderPieces[k],
            props = {
                position = v * buttonBorderSize,
                relativePosition = v,
                size = v2(buttonBorderSize, buttonBorderSize),
            },
        }
    end
    template.content:add {
        ---@diagnostic disable-next-line: missing-fields
        external = { slot = true },
        props = {
            position = v2(buttonBorderSize, buttonBorderSize),
            relativeSize = v2(1, 1),
        },
    }
    return template
end

commonUI.buttonBoxBgr = function(bgrAlpha)
    local template = auxUi.deepLayoutCopy(commonUI.buttonBox())
    template.content:insert(1, {
        type = ui.TYPE.Image,
        props = {
            resource = commonUI.createTexture("white"),
            color = C.Colors.BLACK,
            alpha = bgrAlpha or 0,
            relativeSize = v2(1, 1),
            size = v2(buttonBorderSize * 2, buttonBorderSize * 2),
        },
    })
    return template
end

commonUI.button = function(text, textSize, onClick, name, bgrAlpha, disabled)
    -- TODO: disabled state doesn't show correctly
    disabled = disabled == true
    local element = ui.create {
        name = name,
        template = commonUI.buttonBoxBgr(bgrAlpha),
        props = {},
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    commonUI.intervalH(8),
                    {
                        name = "btnText",
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = text,
                            textSize = textSize,
                            textColor = disabled and C.Colors.DISABLED or C.Colors.DEFAULT,
                        },
                        userData = { colorable = true },
                    },
                    commonUI.intervalH(8),
                },
            },
        },
        events = {},
        userData = {
            inFocus = false,
        },
    }
    local btnText = element.layout.content[1].content[2]
    element.layout.events.focusLoss = async:callback(function()
        btnText.props.textColor = disabled and C.Colors.DISABLED or C.Colors.DEFAULT
        element:update()
    end)
    element.layout.events.focusGain = async:callback(function()
        btnText.props.textColor = disabled and C.Colors.DISABLED or C.Colors.DEFAULT_LIGHT
        element:update()
    end)
    element.layout.events.mousePress = async:callback(function()
        if disabled then
            return
        end
        ambient.playSound("menu click")
        btnText.props.textColor = C.Colors.DEFAULT_PRESSED
        element:update()
    end)
    element.layout.events.mouseRelease = async:callback(function()
        if disabled then
            return
        end
        btnText.props.textColor = C.Colors.DEFAULT_LIGHT
        element:update()
        if onClick then
            onClick()
        end
    end)
    return element
end

local headerTexturePaths = {
    [1] = "textures/menu_head_block_top_left_corner.dds",
    [2] = "textures/menu_head_block_top.dds",
    [3] = "textures/menu_head_block_top_right_corner.dds",
    [4] = "textures/menu_head_block_left.dds",
    [5] = "textures/menu_head_block_middle.dds",
    [6] = "textures/menu_head_block_right.dds",
    [7] = "textures/menu_head_block_bottom_left_corner.dds",
    [8] = "textures/menu_head_block_bottom.dds",
    [9] = "textures/menu_head_block_bottom_right_corner.dds",
}

local function headerImage(index, tile, size)
    return {
        type = ui.TYPE.Image,
        props = {
            resource = commonUI.createTexture(headerTexturePaths[index]),
            size = size or v2(0, 0),
            tileH = tile,
            tileV = false,
        },
        external = { grow = 1, stretch = 1 },
    }
end

local function headerSection()
    local height = commonUI.Sizes.HEADER_HEIGHT
    return {
        type = ui.TYPE.Flex,
        props = { horizontal = true },
        external = { grow = 1, stretch = 1 },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = { autoSize = false, size = v2(2, height) },
                content = ui.content {
                    headerImage(1, false, v2(2, 2)),
                    headerImage(4, false, v2(2, 16)),
                    headerImage(7, false, v2(2, 2)),
                },
            },
            {
                type = ui.TYPE.Flex,
                props = { autoSize = false, size = v2(0, height) },
                external = { grow = 1, stretch = 1 },
                content = ui.content {
                    headerImage(2, true, v2(0, 2)),
                    headerImage(5, true, v2(0, 16)),
                    headerImage(8, true, v2(0, 2)),
                },
            },
            {
                type = ui.TYPE.Flex,
                props = { autoSize = false, size = v2(2, height) },
                content = ui.content {
                    headerImage(3, false, v2(2, 2)),
                    headerImage(6, false, v2(2, 16)),
                    headerImage(9, false, v2(2, 2)),
                },
            },
        },
    }
end

commonUI.borderedBox = function(body)
    local padding = commonUI.Sizes.BOX_INNER_PADDING
    return {
        template = I.MWUI.templates.borders,
        props = {},
        content = ui.content {
            {
                props = {
                    position = v2(padding, padding),
                    size = v2(-padding * 2, -padding * 2),
                    relativeSize = v2(1, 1),
                },
                content = ui.content {
                    {
                        props = { relativeSize = v2(1, 1) },
                        content = ui.content { body },
                    },
                },
            },
        },
    }
end

local function asContent(value)
    if not value then
        return ui.content {}
    end
    if value.add then
        return value
    end
    return ui.content { value }
end

commonUI.createWindow = function(opts)
    opts = opts or {}
    local name = opts.name or "CommonWindow"
    local size = opts.size or v2(400, 300)

    local windowLayout = {
        name = name,
        layer = opts.layer or "Windows",
        template = I.MWUI.templates.bordersThick,
        props = {
            size = size,
            anchor = v2(0.5, 0.5),
            relativePosition = v2(0.5, 0.5),
            position = v2(0, 0),
        },
        content = ui.content {
            {
                name = name .. "_background",
                type = ui.TYPE.Image,
                props = {
                    resource = commonUI.createTexture("transparent"),
                    color = C.Colors.BACKGROUND,
                    relativeSize = v2(1, 1),
                },
            },
            {
                name = name .. "_foreground",
                type = ui.TYPE.Flex,
                props = {
                    relativeSize = v2(1, 1),
                },
                content = ui.content {
                    {
                        name = name .. "_header",
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                            arrange = ui.ALIGNMENT.Center,
                        },
                        external = { stretch = 1 },
                        content = ui.content {
                            headerSection(),
                            commonUI.intervalH(8),
                            {
                                name = name .. "_title",
                                template = I.MWUI.templates.textNormal,
                                props = { text = tostring(opts.title or "") },
                            },
                            commonUI.intervalH(8),
                            headerSection(),
                        },
                    },
                    {
                        name = name .. "_body",
                        template = I.MWUI.templates.bordersThick,
                        external = { grow = 1, stretch = 1 },
                        content = asContent(opts.content),
                    },
                },
            },
        },
        events = {},
    }

    local element = ui.create(windowLayout)
    local foreground = element.layout.content[2]
    local header = foreground.content[1]
    local body = foreground.content[2]

    local window = { element = element, body = body, title = header.content[3] }

    function window:setTitle(text)
        self.title.props.text = tostring(text)
        self.element:update()
    end

    function window:setContent(content)
        self.body.content = asContent(content)
        self.element:update()
    end

    function window:setSize(newSize)
        self.element.layout.props.size = newSize
        self.element:update()
    end

    function window:destroy()
        if self.element then
            self.element:destroy()
            self.element = nil
            self.body = nil
            self.title = nil
        end
    end

    function window:update()
        if self.element then
            self.element:update()
        end
    end

    return window
end

return commonUI
