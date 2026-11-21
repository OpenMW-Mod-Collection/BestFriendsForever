---@diagnostic disable: undefined-field
---@omw-context player
local I = require("openmw.interfaces")
local core = require("openmw.core")

local repairSessionActive = false

local function repairGearReady(data)
    repairSessionActive = true
    I.UI.setMode("Repair", { target = data.tool })
end

local function onUiModeChanged(data)
    if not repairSessionActive or data.oldMode ~= "Repair" or data.newMode == "Repair" then
        return
    end
    repairSessionActive = false
    core.sendGlobalEvent("BestFriendsForever_repairGearClose")
end

return {
    eventHandlers = {
        BestFriendsForever_repairGearReady = repairGearReady,
    },
    onUiModeChanged = onUiModeChanged,
}
