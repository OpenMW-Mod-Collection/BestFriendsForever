---@omw-context player
---@class RawUIMutatorDefinition
---@field name string Unique registration id.
---@field afterHudBuild? fun(hud: table)
---@field afterTooltipBuild? fun(hud: table)
---@field afterMenuBuild? fun(menu: table)

local mutators = {}

local rawUIMutators = {}

local callbackFields = {
    "afterHudBuild",
    "afterTooltipBuild",
    "afterMenuBuild",
}

---@param definition RawUIMutatorDefinition
function rawUIMutators.register(definition)
    if type(definition) ~= "table" then
        error("registerRawUIMutator: definition must be a table", 2)
    end
    if type(definition.name) ~= "string" or definition.name == "" then
        error("registerRawUIMutator: name must be a non-empty string", 2)
    end

    local entry = { name = definition.name }
    for _, field in ipairs(callbackFields) do
        local callback = definition[field]
        if callback ~= nil and type(callback) ~= "function" then
            error("registerRawUIMutator: " .. field .. " must be a function", 2)
        end
        entry[field] = callback
    end

    for index, existing in ipairs(mutators) do
        if existing.name == definition.name then
            mutators[index] = entry
            return
        end
    end
    mutators[#mutators + 1] = entry
end

local function run(field, snapshot)
    for _, mutator in ipairs(mutators) do
        local callback = mutator[field]
        if callback then
            callback(snapshot)
        end
    end
end

function rawUIMutators.afterHudBuild(hud)
    run("afterHudBuild", hud)
end

function rawUIMutators.afterTooltipBuild(hud)
    run("afterTooltipBuild", hud)
end

function rawUIMutators.afterMenuBuild(menu)
    run("afterMenuBuild", menu)
end

return rawUIMutators
