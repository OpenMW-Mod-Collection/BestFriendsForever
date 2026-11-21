---@diagnostic disable: undefined-field, param-type-mismatch
---@omw-context player
local I = require("openmw.interfaces")
local deps = require("scripts.BestFriendsForever.utils.dependencyChecker")

-- Fail fast before touching the FDU list.
local FDU = I.FollowerDetectionUtil
deps.checkAll("Best Friends Forever", "Sosnoviy Bor's Mods", nil, {
    {
        plugin = "FollowerDetectionUtil.omwscripts",
        interface = FDU,
        minVersion = 7,
        curVersion = FDU and FDU.version or -1,
    },
})

local handlerList = {
    require("scripts.BestFriendsForever.playerHandlers.combat"),
    require("scripts.BestFriendsForever.playerHandlers.teleport"),
    require("scripts.BestFriendsForever.playerHandlers.menu"),
    require("scripts.BestFriendsForever.playerHandlers.repair"),
    require("scripts.BestFriendsForever.playerHandlers.hud"),
    require("scripts.BestFriendsForever.playerHandlers.rawUI"),
}
local combat = handlerList[1]
local teleport = handlerList[2]
local menu = handlerList[3]
local repair = handlerList[4]
local hud = handlerList[5]

local eventHandlers = {}
local reservedEvents = {
    UiModeChanged = true,
    FDU_SyncFollowerList = true,
}

local function addEvent(name, callback)
    local callbacks = eventHandlers[name]
    if not callbacks then
        callbacks = {}
        eventHandlers[name] = callbacks
    end
    callbacks[#callbacks + 1] = callback
end

-- Coupled paths are wired explicitly to preserve their current order.
addEvent("UiModeChanged", function(data)
    menu.onUiModeChanged(data)
end)
addEvent("UiModeChanged", function(data)
    repair.onUiModeChanged(data)
end)
addEvent("UiModeChanged", function(data)
    hud.onUiModeChanged(data)
end)

addEvent("FDU_SyncFollowerList", function(data)
    combat.onFollowerListUpdated(data)
end)
addEvent("FDU_SyncFollowerList", function(data)
    menu.onFollowerListUpdated(data)
end)
addEvent("FDU_SyncFollowerList", function(data)
    hud.onFollowerListUpdated(data)
end)

for _, handler in ipairs(handlerList) do
    for name, callback in pairs(handler.eventHandlers or {}) do
        assert(not reservedEvents[name], "Player handler must not register reserved event: " .. name)
        addEvent(name, callback)
    end
end

for name, callbacks in pairs(eventHandlers) do
    eventHandlers[name] = function(data)
        for _, callback in ipairs(callbacks) do
            callback(data)
        end
    end
end

local function onUpdate(dt)
    combat.frame(dt)
    if teleport.frame(dt) == false then
        return
    end
    hud.frame(dt)
end

local function onSave()
    local data = {}
    for _, handler in ipairs(handlerList) do
        if handler.onSave then
            for key, value in pairs(handler.onSave()) do
                assert(data[key] == nil, "Duplicate BFF player save key: " .. key)
                data[key] = value
            end
        end
    end
    return data
end

local function onLoad(data)
    data = data or {}
    for _, handler in ipairs(handlerList) do
        if handler.onLoad then
            handler.onLoad(data)
        end
    end
end

local interface = { version = 5 }
for _, handler in ipairs(handlerList) do
    for key, value in pairs(handler.interface or {}) do
        assert(interface[key] == nil, "Duplicate BFF player interface member: " .. key)
        interface[key] = value
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = eventHandlers,
    interfaceName = "BestFriendsForever",
    interface = interface,
}
