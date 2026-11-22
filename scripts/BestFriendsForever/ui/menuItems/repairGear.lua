---@diagnostic disable: undefined-field
---@omw-context player
local core = require("openmw.core")
local self = require("openmw.self")
local async = require("openmw.async")
local storage = require("openmw.storage")

local settingsCache = require("scripts.BestFriendsForever.utils.settingsCache")

local settings = settingsCache.new(storage.playerSection("SettingsBestFriendsForever_menu"), async)

return {
    name = "Repair Gear",
    action = function(followerState)
        core.sendGlobalEvent("BestFriendsForever_repairGearOpen", {
            follower = followerState.actor,
            player = self,
            settings = {
                scope = settings.repairScope,
                threshold = settings.repairThreshold,
                hidePlayerDamaged = settings.hidePlayerDamaged,
                toolSource = settings.repairToolSource,
                toolPreference = settings.repairToolInitialPreference,
            },
        })
    end,
    condition = function(followerState)
        return not followerState.isSummon
    end,
    closeAfterActivation = true,
}
