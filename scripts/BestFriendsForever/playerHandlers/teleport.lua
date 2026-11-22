---@diagnostic disable: undefined-field
---@omw-context player
local I = require("openmw.interfaces")
local core = require("openmw.core")
local async = require("openmw.async")
local input = require("openmw.input")
local self = require("openmw.self")

local tp = require("scripts.BestFriendsForever.utils.teleport")

local teleportCooldown = 0.1
local unloadedFollowers = {}
local teleportAccumulator = teleportCooldown

local function callFollowers(pressed)
    if pressed or I.UI.getMode() or core.isWorldPaused() then
        return
    end

    local myFollowers = {}
    for _, state in ipairs(I.FollowerDetectionUtil.getFollowersOf(self, true)) do
        myFollowers[#myFollowers + 1] = state.actor
    end

    tp.teleportBatch(myFollowers, "BestFriendsForever_teleport")
end

local function followerUnloaded(follower)
    unloadedFollowers[#unloadedFollowers + 1] = follower
end

local function frame(dt)
    teleportAccumulator = teleportAccumulator + dt
    if teleportAccumulator <= teleportCooldown then
        return false
    end
    teleportAccumulator = 0
    if #unloadedFollowers > 0 then
        tp.teleportBatch(unloadedFollowers, "BestFriendsForever_teleport")
        unloadedFollowers = {}
    end
    return true
end

input.registerAction {
    key = "BestFriendsForever_call",
    type = input.ACTION_TYPE.Boolean,
    l10n = "BestFriendsForever_settings",
    name = "callAction_name",
    description = "",
    defaultValue = false,
}
input.registerActionHandler(
    "BestFriendsForever_call",
    async:callback(callFollowers)
)

return {
    eventHandlers = {
        BestFriendsForever_followerUnloaded = followerUnloaded,
    },
    frame = frame,
}
