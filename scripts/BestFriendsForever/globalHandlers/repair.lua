---@diagnostic disable: undefined-field, param-type-mismatch, need-check-nil
---@omw-context global
local types = require("openmw.types")
local I = require("openmw.interfaces")
local core = require("openmw.core")

local FDU = I.FollowerDetectionUtil
local l10n = core.l10n("BestFriendsForever_messages")

local session

local function notify(player, key)
    if not player:isValid() then
        return
    end
    player:sendEvent("ShowMessage", { message = l10n(key) })
end

local function itemCondition(item)
    local data = types.Item.itemData(item)
    local record = item.type.records[item.recordId]
    return data.condition, record.health or record.maxCondition, data
end

local function isRepairableGear(item)
    if not types.Weapon.objectIsInstance(item) and not types.Armor.objectIsInstance(item) then
        return false
    end
    local record = item.type.records[item.recordId]
    return record.health > 0
end

local function isDamaged(item, threshold)
    if not isRepairableGear(item) then
        return false
    end
    local condition, maxCondition = itemCondition(item)
    return condition < maxCondition and condition <= maxCondition * threshold
end

local function selectTool(player, follower, sourcePreference, toolPreference)
    local candidates = {}
    local function collect(actor, source)
        for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Repair)) do
            local condition, maxCondition = itemCondition(item)
            if condition > 0 and item.count > 0 then
                local record = item.type.records[item.recordId]
                candidates[#candidates + 1] = {
                    item = item,
                    source = source,
                    quality = record.quality or 0,
                    maxUses = maxCondition or 0,
                    remainingUses = condition or 0,
                    weight = record.weight or 0,
                }
            end
        end
    end

    collect(player, "player")
    collect(follower, "follower")

    local primaryFields = {
        ["Highest Quality"] = "quality",
        ["Highest Max Uses"] = "maxUses",
        ["Highest Weight"] = "weight",
    }
    local primaryField = primaryFields[toolPreference]

    table.sort(candidates, function(a, b)
        if a.source ~= b.source then
            if sourcePreference == "Player First" then
                return a.source == "player"
            end
            return a.source == "follower"
        end

        local aPrimary = a[primaryField]
        local bPrimary = b[primaryField]
        if aPrimary ~= bPrimary then
            return aPrimary > bPrimary
        end

        local aTieBreak = a.weight * a.remainingUses
        local bTieBreak = b.weight * b.remainingUses
        if aTieBreak ~= bTieBreak then
            return aTieBreak > bTieBreak
        end

        return a.item.id < b.item.id
    end)
    return candidates[1]
end

local function maskPlayerItems(inventory, excludedId)
    local masked = {}
    for _, item in ipairs(inventory:getAll()) do
        if item.id ~= excludedId and isRepairableGear(item) then
            local condition, maxCondition, data = itemCondition(item)
            if condition < maxCondition then
                masked[#masked + 1] = { item = item, condition = condition }
                data.condition = maxCondition
            end
        end
    end
    return masked
end

local function payBackTools(current, follower)
    if not current.player:isValid() then
        return false
    end

    local playerInventory = types.Actor.inventory(current.player)
    local followerInventory = types.Actor.inventory(follower)
    local candidates = {}
    local returnedByRecordId = {}
    for _, item in ipairs(playerInventory:getAll(types.Repair)) do
        if item.count > 0 then
            candidates[#candidates + 1] = item
        end
    end

    for _, entry in ipairs(current.borrowedTools or {}) do
        local owed = entry.count
        for _, item in ipairs(candidates) do
            if owed <= 0 then
                break
            end
            if item:isValid() and item.count > 0 and item.recordId == entry.recordId then
                local toReturn = math.min(owed, item.count)
                local returned = item
                if toReturn < item.count then
                    returned = item:split(toReturn)
                end
                returned:moveInto(followerInventory)
                returnedByRecordId[entry.recordId] = returnedByRecordId[entry.recordId] or {}
                returnedByRecordId[entry.recordId][#returnedByRecordId[entry.recordId] + 1] = returned
                owed = owed - toReturn
            end
        end
    end

    return true, returnedByRecordId
end

local function restore()
    if not session then
        return
    end

    local current = session
    session = nil
    local complete = true
    local follower = current.follower
    local followerValid = follower:isValid()
    local itemsToUse = {}

    if current.toolFromFollower then
        if followerValid then
            local returned, returnedTools = payBackTools(current, follower)
            if not returned then
                complete = false
            end
            if current.toolEquipped then
                local tools = returnedTools and returnedTools[current.toolRecordId]
                if tools and #tools > 0 then
                    itemsToUse[#itemsToUse + 1] = tools[1]
                end
            end
        else
            complete = false
        end
    end

    if followerValid then
        local followerInventory = types.Actor.inventory(follower)
        for _, borrowed in ipairs(current.borrowed) do
            if borrowed.item:isValid() and borrowed.item.count > 0 then
                borrowed.item:moveInto(followerInventory)
                if borrowed.equipped then
                    itemsToUse[#itemsToUse + 1] = borrowed.item
                end
            else
                complete = false
            end
        end
    else
        complete = false
    end

    if followerValid then
        for _, item in ipairs(itemsToUse) do
            if item:isValid() then
                core.sendGlobalEvent("UseItem", { object = item, actor = follower })
            end
        end
    end

    for _, entry in ipairs(current.masked) do
        if entry.item:isValid() and entry.item.count > 0 then
            types.Item.itemData(entry.item).condition = entry.condition
        end
    end

    if not complete then
        notify(current.player, "msg_repairRestoredPartial")
    end
end

local function openRepair(data)
    if session then
        restore()
    end

    local follower = data.follower
    local player = data.player
    if not follower:isValid() or not player:isValid() then
        return
    end

    local followers = FDU.getFollowerList()
    if not followers[follower.id] then
        return
    end

    local settings = data.settings
    local threshold = settings.threshold / 100
    local allInventory = settings.scope == "All Inventory"
    local sourcePreference = settings.toolSource
    local toolPreference = settings.toolPreference

    local playerInventory = types.Actor.inventory(player)
    local followerInventory = types.Actor.inventory(follower)

    local eligible = {}
    for _, item in ipairs(followerInventory:getAll()) do
        if isDamaged(item, threshold) then
            local equipped = types.Actor.hasEquipped(follower, item)
            if allInventory or equipped then
                eligible[#eligible + 1] = { item = item, equipped = equipped }
            end
        end
    end
    if #eligible == 0 then
        notify(player, "msg_repairNoGear")
        return
    end

    local tool = selectTool(player, follower, sourcePreference, toolPreference)
    if not tool then
        notify(player, "msg_repairNoTool")
        return
    end

    local masked = {}
    if settings.hidePlayerDamaged then
        masked = maskPlayerItems(playerInventory, tool.item.id)
    end

    local toolFromFollower = tool.source == "follower"
    local toolEquipped = toolFromFollower and types.Actor.hasEquipped(follower, tool.item)
    local borrowedTools = {}
    if toolFromFollower then
        borrowedTools[#borrowedTools + 1] = {
            recordId = tool.item.recordId,
            count = tool.item.count,
        }
        tool.item:moveInto(playerInventory)
    end

    local borrowed = {}
    for _, entry in ipairs(eligible) do
        if entry.item:isValid() then
            entry.item:moveInto(playerInventory)
            borrowed[#borrowed + 1] = { item = entry.item, equipped = entry.equipped }
        end
    end

    session = {
        player = player,
        follower = follower,
        borrowed = borrowed,
        masked = masked,
        tool = tool.item,
        toolRecordId = tool.item.recordId,
        toolFromFollower = toolFromFollower,
        toolEquipped = toolEquipped,
        borrowedTools = borrowedTools,
    }

    player:sendEvent("BestFriendsForever_repairGearReady", { tool = tool.item })
end

return {
    eventHandlers = {
        BestFriendsForever_repairGearOpen = openRepair,
        BestFriendsForever_repairGearClose = restore,
    },
    onSave = function()
        return { repairSession = session }
    end,
    onLoad = function(data)
        session = data.repairSession
        if session then
            restore()
        end
    end,
}
