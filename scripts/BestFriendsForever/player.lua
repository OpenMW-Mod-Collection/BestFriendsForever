---@diagnostic disable: undefined-field, param-type-mismatch
---@omw-context player
local self = require("openmw.self")
local storage = require("openmw.storage")
local async = require("openmw.async")
local I = require("openmw.interfaces")
local input = require("openmw.input")
local core = require("openmw.core")

local settingsCache = require("scripts.BestFriendsForever.utils.settingsCache")
local tp = require("scripts.BestFriendsForever.utils.teleport")
local followerHUD = require("scripts.BestFriendsForever.ui.main")
local combatTrackerConstructor = require("scripts.BestFriendsForever.utils.combatTracker")

-- Initialization
local sectionWrapper = storage.playerSection("SettingsBestFriendsForever_HUDWrapper")
local settingsWrapper = settingsCache.new(sectionWrapper, async)
local combatTracker = combatTrackerConstructor.new()
local FDU = I.FollowerDetectionUtil

local deps = require("scripts.BestFriendsForever.utils.dependencyChecker")
deps.checkAll("Best Friends Forever", "Sosnoviy Bor's Mods", nil, {
    {
        plugin = "FollowerDetectionUtil.omwscripts",
        interface = FDU,
        minVersion = 7,
        curVersion = FDU and FDU.version or -1,
    },
})

local followers = FDU.getFollowerList()
local downedFollowers = {}
local unloadedFollowers = {}

-- HUD lifecycle
if settingsWrapper.enable then
    followerHUD.new(followers)
end

local function destroyHUD()
    if followerHUD.root then
        followerHUD.root:destroy()
        followerHUD.root = nil
    end
end

-- Follower actions
input.registerAction {
    key = "BestFriendsForever_call",
    type = input.ACTION_TYPE.Boolean,
    l10n = "BestFriendsForever",
    name = "callAction_name",
    description = "",
    defaultValue = false,
}

local function callFollowers(pressed)
    if pressed or I.UI.getMode() or core.isWorldPaused() then
        return
    end

    local myFollowers = {}
    for _, state in ipairs(FDU.getFollowersOf(self, true)) do
        myFollowers[#myFollowers + 1] = state.actor
    end

    tp.teleportBatch(myFollowers, "BestFriendsForever_teleport")
end

input.registerActionHandler("BestFriendsForever_call", async:callback(callFollowers))

-- Updates
local teleportCooldown = 0.1
local teleportAccumulator = teleportCooldown
local uiUpdateAccumulator = settingsWrapper.pollingRate

local function teleportUnloadedFollowers(dt)
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

local function updateHUD(dt)
    uiUpdateAccumulator = uiUpdateAccumulator + dt
    if uiUpdateAccumulator <= settingsWrapper.pollingRate then
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
        destroyHUD()
    end
end

local function onUpdate(dt)
    combatTracker.onUpdate(dt)
    if not teleportUnloadedFollowers(dt) then
        return
    end
    updateHUD(dt)
end

-- Follower notifications
local function notifyCombatants(data, eventName)
    local follower = data.follower
    local state = followers[follower.id]
    local leader = state and state.rootLeader or data.leader

    combatTracker.prune()
    combatTracker.forEach(function(actor)
        if actor.id ~= self.id and not followers[actor.id] then
            actor:sendEvent(eventName, {
                actor = actor,
                follower = follower,
                leader = leader,
            })
        end
    end)
end

local function followerListUpdated(data)
    followers = data
    if settingsWrapper.enable then
        followerHUD.new(data)
    else
        destroyHUD()
    end
end

local function followerUnloaded(follower)
    unloadedFollowers[#unloadedFollowers + 1] = follower
end

local function followerDown(data)
    downedFollowers[data.follower.id] = data.follower
    notifyCombatants(data, "BestFriendsForever_followerDown")
    local followerData = followerHUD.followerData[data.follower.id]
    if followerData then
        followerData.down = true
    end
end

local function followerUp(data)
    downedFollowers[data.follower.id] = nil
    notifyCombatants(data, "BestFriendsForever_followerUp")
    local followerData = followerHUD.followerData[data.follower.id]
    if followerData then
        followerData.down = false
    end
end

local function uiModeChanged(data)
    if not followerHUD.root then
        return
    end
    followerHUD.updateRootVisibility(data.newMode)
    followerHUD.root:update()
end

-- Persistence and public interface
local function onSave()
    return {
        downedFollowers = downedFollowers,
    }
end

local function onLoad(data)
    data = data or {}
    downedFollowers = data.downedFollowers or downedFollowers

    for _, downedFollower in pairs(downedFollowers) do
        followerDown { follower = downedFollower }
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        UiModeChanged = uiModeChanged,
        FDU_SyncFollowerList = followerListUpdated,
        OMWMusicCombatTargetsChanged = combatTracker.onCombatTargetsChanged,
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
    },
}
