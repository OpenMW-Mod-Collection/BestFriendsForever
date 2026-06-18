---@omw-context menu
local I = require("openmw.interfaces")
local ui = require("openmw.ui")
local async = require("openmw.async")

I.Settings.registerRenderer('AttendMeList', function(input, set)
    if not input then
        input = {}
        set(input)
    end

    local header = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
        },
        content = ui.content({}),
        external = {
            stretch = 1,
        },
    }

    local inputText = ''

    header.content:add {
        template = I.MWUI.templates.box,
        content = ui.content { {
            template = I.MWUI.templates.padding,
            content = ui.content { {
                template = I.MWUI.templates.textNormal,
                props = {
                    text = "Add",
                },
                events = {
                    mouseClick = async:callback(function()
                        -- no empty strings allowed
                        if inputText == "" then return end

                        -- no duplicates allowed
                        for _, v in ipairs(input) do
                            if inputText == v then
                                set(input)
                                return
                            end
                        end

                        table.insert(input, inputText)
                        set(input)
                    end),
                },
            } }
        } },
    }
    header.content:add {
        template = I.MWUI.templates.padding,
        external = {
            grow = 1,
        },
    }
    header.content:add {
        template = I.MWUI.templates.box,
        content = ui.content { {
            template = I.MWUI.templates.padding,
            content = ui.content { {
                template = I.MWUI.templates.textEditLine,
                events = {
                    textChanged = async:callback(function(text)
                        inputText = text:lower()
                    end),
                } },
            } },
        },
    }

    local body = {
        type = ui.TYPE.Flex,
        content = ui.content({}),
    }

    local function remove(text)
        for i, v in ipairs(input) do
            if v == text then
                table.remove(input, i)
                return
            end
        end
    end

    for _, text in ipairs(input) do
        body.content:add {
            template = I.MWUI.templates.padding,
        }
        body.content:add {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                arrange = ui.ALIGNMENT.Center,
            },
            content = ui.content {
                {
                    template = I.MWUI.templates.box,
                    content = ui.content { {
                        template = I.MWUI.templates.padding,
                        content = ui.content { {
                            template = I.MWUI.templates.textNormal,
                            props = { text = "x" },
                            events = {
                                mouseClick = async:callback(function()
                                    remove(text)
                                    set(input)
                                end),
                            },
                        } },
                    } },
                },
                {
                    template = I.MWUI.templates.padding,
                },
                {
                    template = I.MWUI.templates.textNormal,
                    props = { text = text },
                },
            },
        }
    end

    return {
        type = ui.TYPE.Flex,
        content = ui.content {
            header,
            body,
        },
    }
end)
