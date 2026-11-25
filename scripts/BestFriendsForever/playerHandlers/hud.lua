---@diagnostic disable: undefined-field, param-type-mismatch
---@omw-context player
local I = require("openmw.interfaces")
local async = require("openmw.async")
local storage = require("openmw.storage")

local followerHUD = require("scripts.BestFriendsForever.ui.hud")
local followerTooltip = require("scripts.BestFriendsForever.ui.tooltip")
local iconsUI = require("scripts.BestFriendsForever.ui.follower.icons")
local settingsCache = require("scripts.BestFriendsForever.utils.settingsCache")

local sectionWrapper
local settingsWrapper
local uiUpdateAccumulator

local function destroyHUD()
    followerHUD.destroy()
end

local function updateHUD(dt)
    uiUpdateAccumulator = uiUpdateAccumulator + dt
    if uiUpdateAccumulator <= settingsWrapper.pollingRate then
        return
    end
    uiUpdateAccumulator = 0

    if settingsWrapper.enable then
        if not followerHUD.root then
            followerHUD.new(I.FollowerDetectionUtil.getFollowerList())
        else
            followerHUD.updateData()
        end
    else
        destroyHUD()
    end
end

local function onUiModeChanged(data)
    if not followerHUD.root then
        return
    end
    followerHUD.updateRootVisibility(data.newMode)
    followerHUD.root:update()
end

local function onFollowerListUpdated(data)
    if settingsWrapper.enable then
        followerHUD.new(data)
    else
        destroyHUD()
    end
end

local function registerFollowerTooltipField(definition)
    followerTooltip.registerField(definition)
    followerHUD.rebuildTooltip()
end

local function setPosSettings(x, y)
    sectionWrapper:set("position", { posX = x, posY = y })
end

local function markFollowerDown(data)
    local followerData = followerHUD.followerData[data.follower.id]
    if followerData then
        followerData.down = true
    end
end

local function markFollowerUp(data)
    local followerData = followerHUD.followerData[data.follower.id]
    if followerData then
        followerData.down = false
    end
end

sectionWrapper = storage.playerSection("SettingsBestFriendsForever_HUDWrapper")
settingsWrapper = settingsCache.new(sectionWrapper, async)
uiUpdateAccumulator = settingsWrapper.pollingRate

if settingsWrapper.enable then
    followerHUD.new(I.FollowerDetectionUtil.getFollowerList())
end

return {
    eventHandlers = {
        BestFriendsForever_followerDown = markFollowerDown,
        BestFriendsForever_followerUp = markFollowerUp,
    },
    onUiModeChanged = onUiModeChanged,
    onFollowerListUpdated = onFollowerListUpdated,
    frame = updateHUD,
    interface = {
        setPosSettings = setPosSettings,
        registerFollowerIconSuffix = iconsUI.registerFollowerIconSuffix,
        registerFollowerTooltipField = registerFollowerTooltipField,
    },
}
