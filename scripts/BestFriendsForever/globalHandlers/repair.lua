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

local function equippedSlots(actor)
    local slots = {}
    local equipment = types.Actor.getEquipment(actor)
    for slot, item in pairs(equipment) do
        slots[item.id] = slot
    end
    return slots
end

local function selectTool(player, follower, preference)
    local candidates = {}
    local function collect(actor, source)
        for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Repair)) do
            local condition = itemCondition(item)
            if condition > 0 then
                local record = item.type.records[item.recordId]
                candidates[#candidates + 1] = {
                    item = item,
                    source = source,
                    quality = record.quality,
                    uses = condition,
                }
            end
        end
    end

    collect(player, "player")
    collect(follower, "follower")

    table.sort(candidates, function(a, b)
        if preference == "Player First" and a.source ~= b.source then
            return a.source == "player"
        end
        if preference == "Follower First" and a.source ~= b.source then
            return a.source == "follower"
        end
        if a.quality ~= b.quality then
            return a.quality > b.quality
        end
        if a.uses ~= b.uses then
            return a.uses > b.uses
        end
        return a.source < b.source
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

local function restore()
    if not session then
        return
    end

    local current = session
    session = nil
    local complete = true
    local follower = current.follower
    local followerValid = follower:isValid()
    local equipmentToRestore = {}

    if current.toolFromFollower then
        if followerValid then
            current.tool:moveInto(types.Actor.inventory(follower))
            if current.toolSlot then
                equipmentToRestore[#equipmentToRestore + 1] = { slot = current.toolSlot, item = current.tool }
            end
        else
            complete = false
        end
    end

    if followerValid then
        local followerInventory = types.Actor.inventory(follower)
        for _, borrowed in ipairs(current.borrowed) do
            if borrowed.item:isValid() then
                borrowed.item:moveInto(followerInventory)
                if borrowed.slot then
                    equipmentToRestore[#equipmentToRestore + 1] = { slot = borrowed.slot, item = borrowed.item }
                end
            end
        end

        if #equipmentToRestore > 0 then
            local equipment = types.Actor.getEquipment(follower)
            for _, entry in ipairs(equipmentToRestore) do
                equipment[entry.slot] = entry.item
            end
            types.Actor.setEquipment(follower, equipment)
        end
    else
        complete = false
    end

    for _, entry in ipairs(current.masked) do
        if entry.item:isValid() then
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
    local preference = settings.toolPreference

    local playerInventory = types.Actor.inventory(player)
    local followerInventory = types.Actor.inventory(follower)
    local slots = equippedSlots(follower)

    local eligible = {}
    for _, item in ipairs(followerInventory:getAll()) do
        if isDamaged(item, threshold) then
            if allInventory or slots[item.id] then
                eligible[#eligible + 1] = { item = item, slot = slots[item.id] }
            end
        end
    end
    if #eligible == 0 then
        notify(player, "msg_repairNoGear")
        return
    end

    local tool = selectTool(player, follower, preference)
    if not tool then
        notify(player, "msg_repairNoTool")
        return
    end

    local masked = {}
    if settings.hidePlayerDamaged then
        masked = maskPlayerItems(playerInventory, tool.item.id)
    end

    local toolFromFollower = tool.source == "follower"
    local toolSlot = toolFromFollower and slots[tool.item.id]
    if toolFromFollower then
        tool.item:moveInto(playerInventory)
    end

    local borrowed = {}
    for _, entry in ipairs(eligible) do
        if entry.item:isValid() then
            entry.item:moveInto(playerInventory)
            borrowed[#borrowed + 1] = { item = entry.item, slot = entry.slot }
        end
    end

    session = {
        player = player,
        follower = follower,
        borrowed = borrowed,
        masked = masked,
        tool = tool.item,
        toolFromFollower = toolFromFollower,
        toolSlot = toolSlot,
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
