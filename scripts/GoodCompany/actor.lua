---@omw-context local
local I = require("openmw.interfaces")

local function followerDown(data)
    local target = I.AI.getActiveTarget("Combat")
    if target and data.follower.id == target.id then
        I.AI.startPackage {
            type = "Combat",
            target = data.leader
        }
    end
end

return {
    eventHandlers = {
        GoodCompany_followerDown = followerDown,
    }
}