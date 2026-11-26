---@diagnostic disable: undefined-field
---@omw-context global
local handlers = {
    require("scripts.BestFriendsForever.globalHandlers.customScript"),
    require("scripts.BestFriendsForever.globalHandlers.wait"),
    require("scripts.BestFriendsForever.globalHandlers.repair"),
    require("scripts.BestFriendsForever.globalHandlers.injuries"),
}

local eventHandlers = {
    BestFriendsForever_teleport = function(data)
        -- teleport method throws harmless errors
        -- if two teleports occur in the same frame
        -- or when the summon gets despawned
        -- no, :isValid() doesn't cut it, this is the only option
        pcall(function()
            data.object:teleport(data.cellName, data.position, data.options)
        end)
    end,
}
local saveHandlers = {}
local activationHandlers = {}
local updateHandlers = {}
local actorActiveHandlers = {}

for _, handler in ipairs(handlers) do
    for name, callback in pairs(handler.eventHandlers or {}) do
        eventHandlers[name] = callback
    end
    if handler.onSave then
        saveHandlers[#saveHandlers + 1] = handler.onSave
    end
    if handler.onActivate then
        activationHandlers[#activationHandlers + 1] = handler.onActivate
    end
    if handler.onUpdate then
        updateHandlers[#updateHandlers + 1] = handler.onUpdate
    end
    if handler.onActorActive then
        actorActiveHandlers[#actorActiveHandlers + 1] = handler.onActorActive
    end
end

local function onSave()
    local data = {}
    for _, save in ipairs(saveHandlers) do
        for key, value in pairs(save()) do
            data[key] = value
        end
    end
    return data
end

local function onLoad(data)
    data = data or {}
    for _, handler in ipairs(handlers) do
        if handler.onLoad then
            handler.onLoad(data)
        end
    end
end

local function onActivate(object, actor)
    for _, callback in ipairs(activationHandlers) do
        callback(object, actor)
    end
end

local function onUpdate(dt)
    for _, callback in ipairs(updateHandlers) do
        callback(dt)
    end
end

local function onActorActive(actor)
    for _, callback in ipairs(actorActiveHandlers) do
        callback(actor)
    end
end

return {
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
        onActivate = onActivate,
        onUpdate = onUpdate,
        onActorActive = onActorActive,
    },
    eventHandlers = eventHandlers,
}
