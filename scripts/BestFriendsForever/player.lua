---@diagnostic disable: undefined-field, param-type-mismatch
---@omw-context player
local nearby = require("openmw.nearby")
local self = require("openmw.self")
local storage = require("openmw.storage")
local async = require("openmw.async")
local I = require("openmw.interfaces")
local input = require("openmw.input")
local core = require("openmw.core")

local settingsCache = require("scripts.BestFriendsForever.utils.settingsCache")
local tp = require("scripts.BestFriendsForever.utils.teleport")
local followerHUD = require("scripts.BestFriendsForever.ui.main")

local sectionWrapper = storage.playerSection("SettingsBestFriendsForever_HUDWrapper")
local settingsWrapper = settingsCache.new(sectionWrapper, async)
-- local settingsCall = settingsCache.new(storage.playerSection("SettingsBestFriendsForever_call"), async)

local deps = require("scripts.BestFriendsForever.utils.dependencies")
deps.checkAll("Best Friends Forever", {
    {
        plugin = "FollowerDetectionUtil.omwscripts",
        interface = I.FollowerDetectionUtil,
    },
})

local followers = I.FollowerDetectionUtil.getFollowerList()
local notifListPerFollower = {}
local downedFollowers = {}
local unloadedFollowers = {}

if settingsWrapper.enable then
    followerHUD.new(followers)
end

input.registerAction {
    key = "BestFriendsForever_call",
    type = input.ACTION_TYPE.Boolean,
    l10n = "BestFriendsForever",
    name = "callAction_name",
    description = "",
    defaultValue = false,
}

input.registerActionHandler(
    "BestFriendsForever_call",
    async:callback(function(pressed)
        if pressed or I.UI.getMode() or core.isWorldPaused() then return end

        local myFollowers = {}
        for _, state in pairs(followers) do
            local myFollower = state.superLeader and state.superLeader.id == self.id
                or state.leader and state.leader.id == self.id
            if myFollower then
                myFollowers[#myFollowers+1] = state.actor
            end
        end

        tp.teleportBatch(myFollowers, "BestFriendsForever_teleport")
    end)
)

local teleportAccumulator = 0
local teleportCooldown = .1
local function onUpdate(dt)
    -- sparce notification sending
    -- for enemy aggro redirection
    for followerId, notifList in pairs(notifListPerFollower) do
        if #notifList == 0 then
            notifListPerFollower[followerId] = nil
        else
            local notif = table.remove(notifList)
            notif.actor:sendEvent(notif.eventName, notif)
        end
    end
    
    -- teleporting everyone on a cooldown to place them the nice way
    teleportAccumulator = teleportAccumulator + dt
    if teleportCooldown >= teleportAccumulator then
        return
    end
    teleportAccumulator = 0
    if #unloadedFollowers ~= 0 then
        tp.teleportBatch(unloadedFollowers, "BestFriendsForever_teleport")
        unloadedFollowers = {}
    end
end

local uiUpdateAccumulator = 0
local function onFrame(dt)
    uiUpdateAccumulator = uiUpdateAccumulator + dt
    if settingsWrapper.pollingRate >= uiUpdateAccumulator then
        return
    end
    uiUpdateAccumulator = 0

    if settingsWrapper.enable then
        if not followerHUD.root then
            followerHUD.new(followers)
        else
            followerHUD.updateData()
            followerHUD.root:update()
        end
    else
        if followerHUD.root then
            followerHUD.root:destroy()
        end
    end
end

local function fillNotifList(follower, eventName)
    notifListPerFollower[follower.id] = {}
    local notifList = notifListPerFollower[follower.id]
    local state = followers[follower.id]
    local leader = state.superLeader or state.leader

    for _, actor in pairs(nearby.actors) do
        if not followers[actor.id] and actor.id ~= self.id then
            notifList[#notifList + 1] = {
                eventName = eventName,
                follower = follower,
                leader = leader,
                actor = actor,
            }
        end
    end
end

local function followerListUpdated(data)
    followers = data.followers
    if settingsWrapper.enable then
        followerHUD.new(followers)
    end
end

local function followerUnloaded(follower)
    unloadedFollowers[#unloadedFollowers+1] = follower
end

local function followerDown(data)
    downedFollowers[data.follower.id] = data.follower
    fillNotifList(data.follower, "BestFriendsForever_followerDown")
    followerHUD.followerData[data.follower.id].down = true
end

local function followerUp(data)
    downedFollowers[data.follower.id] = nil
    fillNotifList(data.follower, "BestFriendsForever_followerUp")
    followerHUD.followerData[data.follower.id].down = false
end

local function uiModeChanged(data)
    followerHUD.updateRootVisibility(data.newMode)
    followerHUD.root:update()
end

local function onSave()
    return {
        downedFollowers = downedFollowers
    }
end

local function onLoad(data)
    if not data then return end
    downedFollowers = data.downedFollowers or downedFollowers
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onFrame = onFrame,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        UiModeChanged = uiModeChanged,
        FDU_UpdateFollowerList = followerListUpdated,
        BestFriendsForever_followerUnloaded = followerUnloaded,
        BestFriendsForever_followerDown = followerDown,
        BestFriendsForever_followerUp = followerUp,
    },
    interfaceName = "BestFriendsForever",
    interface = {
        version = 1,
        getDownedFollowers = function()
            return downedFollowers
        end,
        setPosSettings = function(x, y)
            sectionWrapper:set("posX", x)
            sectionWrapper:set("posY", y)
        end,
    }
}
