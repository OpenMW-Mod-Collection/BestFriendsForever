---@diagnostic disable: undefined-field, param-type-mismatch
---@omw-context player
local I = require("openmw.interfaces")
local async = require("openmw.async")
local core = require("openmw.core")
local input = require("openmw.input")
local self = require("openmw.self")
local storage = require("openmw.storage")

local CombatTracker = require("scripts.BestFriendsForever.utils.combatTracker")
local followerHUD = require("scripts.BestFriendsForever.ui.hud")
local followerMenu = require("scripts.BestFriendsForever.ui.menu")
local followerTooltip = require("scripts.BestFriendsForever.ui.tooltip")
local iconsUI = require("scripts.BestFriendsForever.ui.follower.icons")
local settingsCache = require("scripts.BestFriendsForever.utils.settingsCache")
local tp = require("scripts.BestFriendsForever.utils.teleport")
local deps = require("scripts.BestFriendsForever.utils.dependencyChecker")

local teleportCooldown = 0.1

local sectionWrapper
local settingsWrapper
local combatTracker
local FDU = I.FollowerDetectionUtil
local followers
local downedFollowers = {}
local unloadedFollowers = {}
local teleportAccumulator = teleportCooldown
local uiUpdateAccumulator
local repairSessionActive = false

-- Fail fast before touching the FDU list.
deps.checkAll("Best Friends Forever", "Sosnoviy Bor's Mods", nil, {
    {
        plugin = "FollowerDetectionUtil.omwscripts",
        interface = FDU,
        minVersion = 7,
        curVersion = FDU and FDU.version or -1,
    },
})
followers = FDU.getFollowerList()

local function isPlayerGroupInCombat()
    local inCombat = false
    combatTracker.forEach(function(actor, targets)
        if actor.id == self.id or followers[actor.id] then
            inCombat = true
            return
        end

        for _, target in ipairs(targets) do
            if target.id == self.id or followers[target.id] then
                inCombat = true
                return
            end
        end
    end)
    return inCombat
end

local function onCombatLeave()
    if isPlayerGroupInCombat() then
        return
    end

    for _, follower in pairs(downedFollowers) do
        if follower:isValid() then
            follower:sendEvent("BestFriendsForever_combatEnded")
        end
    end
end

local function onCombatEnter()
    if not isPlayerGroupInCombat() then
        return
    end

    for _, follower in pairs(downedFollowers) do
        if follower:isValid() then
            follower:sendEvent("BestFriendsForever_setCombatStatus", true)
        end
    end
end

-- HUD lifecycle

local function destroyHUD()
    followerHUD.destroy()
end

-- Follower actions

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

-- Updates

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
    followerMenu.onFollowerListUpdated(data)
    if settingsWrapper.enable then
        followerHUD.new(data)
    else
        destroyHUD()
    end
end

local function openFollowerMenu(followerState)
    followerMenu.open(followerState)
end

local function followerUnloaded(follower)
    unloadedFollowers[#unloadedFollowers + 1] = follower
end

local function followerDown(data, updateCombatStatus)
    downedFollowers[data.follower.id] = data.follower
    if updateCombatStatus ~= false then
        data.follower:sendEvent(
            "BestFriendsForever_setCombatStatus",
            isPlayerGroupInCombat()
        )
    end
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

local function repairGearReady(data)
    repairSessionActive = true
    I.UI.setMode("Repair", { target = data.tool })
end

local function repairGearClosed()
    if not repairSessionActive then
        return
    end
    repairSessionActive = false
    core.sendGlobalEvent("BestFriendsForever_repairGearClose")
end

local function uiModeChanged(data)
    followerMenu.onUiModeChanged(data)
    if repairSessionActive and data.oldMode == "Repair" and data.newMode ~= "Repair" then
        repairGearClosed()
    end
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
        followerDown({ follower = downedFollower }, false)
    end
    onCombatEnter()
end

local function registerFollowerTooltipField(definition)
    followerTooltip.registerField(definition)
    followerHUD.rebuildTooltip()
end

sectionWrapper = storage.playerSection("SettingsBestFriendsForever_HUDWrapper")
settingsWrapper = settingsCache.new(sectionWrapper, async)
uiUpdateAccumulator = settingsWrapper.pollingRate

combatTracker = CombatTracker.new {
    onEnter = onCombatEnter,
    onLeave = onCombatLeave,
}

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
    async:callback(callFollowers)
)

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
        BestFriendsForever_openFollowerMenu = openFollowerMenu,
        BestFriendsForever_repairGearReady = repairGearReady,
    },
    interfaceName = "BestFriendsForever",
    interface = {
        version = 4,
        getDownedFollowers = function()
            return downedFollowers
        end,
        setPosSettings = function(x, y)
            sectionWrapper:set("posX", x)
            sectionWrapper:set("posY", y)
        end,
        setFollowerIcon = function(spec)
            iconsUI.setFollowerIcon(spec)
        end,
        registerFollowerMenuButton = followerMenu.registerButton,
        registerFollowerTooltipField = registerFollowerTooltipField,
    },
}
