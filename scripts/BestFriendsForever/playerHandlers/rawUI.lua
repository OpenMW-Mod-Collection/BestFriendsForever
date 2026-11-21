---@diagnostic disable: undefined-field
---@omw-context player
local types = require("openmw.types")

local hudUI = require("scripts.BestFriendsForever.ui.hud")
local menuUI = require("scripts.BestFriendsForever.ui.menu")
local rawUIMutators = require("scripts.BestFriendsForever.utils.rawUIMutators")

local function followerId(actorOrId)
    if type(actorOrId) == "string" then
        return actorOrId
    end
    if types.Actor.objectIsInstance(actorOrId) then
        return actorOrId.id
    end
    error("getFollowerWidget expects an Actor or actor id", 2)
end

local function getRawUI()
    return {
        hud = hudUI.getSnapshot(),
        menu = menuUI.getSnapshot(),
    }
end

local function getFollowerWidget(actorOrId)
    return getRawUI().hud.followers[followerId(actorOrId)]
end

local function refreshRawUI()
    hudUI.refresh()
    menuUI.refresh()
end

local function rebuildRawUI()
    hudUI.rebuild()
    menuUI.rebuild()
end

return {
    interface = {
        getRawUI = getRawUI,
        getFollowerWidget = getFollowerWidget,
        refreshRawUI = refreshRawUI,
        rebuildRawUI = rebuildRawUI,
        registerRawUIMutator = rawUIMutators.register,
    },
}
