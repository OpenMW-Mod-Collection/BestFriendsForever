---@diagnostic disable: missing-fields, undefined-field
---@omw-context local
-- Taken from Attend Me by urm
local util = require("openmw.util")
local nearby = require("openmw.nearby")
local self = require("openmw.self")
local core = require("openmw.core")

local TP = {}

local maxTeleportDistance = 200
local teleportPadding = 60
local verticalAxis = util.vector3(0, 0, 1)
local waistOffset = verticalAxis * teleportPadding
local unit = util.vector3(1, 0, 0)
local navOptions = {
    includeFlags = nearby.NAVIGATOR_FLAGS.Walk + nearby.NAVIGATOR_FLAGS.UsePathgrid,
}

---@param position openmw.util.Vector3
---@param direction openmw.util.Vector3
---@return openmw.util.Vector3|nil
local function findTarget(position, direction)
    local targetPosition = position + direction * maxTeleportDistance
    local navmeshPosition = nearby.castNavigationRay(position, targetPosition, navOptions)
    if not navmeshPosition then return nil end

    local raycast = nearby.castRay(
        position + waistOffset,
        navmeshPosition + waistOffset,
        { ignore = self.object }
    )
    if not raycast.hit then return navmeshPosition end

    return nil
end

---@return openmw.util.Vector3
---@return number
local function getForwardDirection()
    local rot = self.object.rotation
    local fwd = rot * unit
    return util.vector3(fwd.x, fwd.y, 0):normalize()
end

---@param pos openmw.util.Vector3
---@param playerPos openmw.util.Vector3
---@param forwardDir openmw.util.Vector3
---@return number
local function scorePosition(pos, playerPos, forwardDir)
    local toPos = pos - playerPos
    local dist = toPos:length()
    if dist < 1 then return -math.huge end
    local dot = toPos:normalize():dot(forwardDir)
    -- dot == -1 means directly behind, +1 means directly in front
    -- weight: 60% distance (normalized), 40% behind-ness
    local distScore = dist / maxTeleportDistance
    local behindScore = (-dot + 1) * 0.5 -- remap [-1,1] to [1,0]
    return distScore * 0.6 + behindScore * 0.4
end

---@param objects GameObject[]
---@param tpEventName string
TP.teleportBatch = function(objects, tpEventName)
    if #objects == 0 then return end

    local playerPos = self.object.position
    local forwardDir = getForwardDirection()
    local needed = #objects

    -- Collect all valid candidate positions across all search resolutions
    local candidates = {}
    local searchFactor = 2
    while searchFactor <= 32 do
        for offset = 1, searchFactor do
            if offset % 2 == 1 or searchFactor == 2 then
                local angle = offset * math.pi / searchFactor
                local rotatedUnit = util.transform.rotate(angle, verticalAxis) * unit
                local target = findTarget(playerPos, rotatedUnit)
                if target then
                    candidates[#candidates + 1] = target
                end
            end
        end
        -- Keep widening the search until we have enough unique candidates
        if #candidates >= needed then break end
        searchFactor = searchFactor * 2
    end

    -- Sort all candidates: highest score first
    table.sort(candidates, function(a, b)
        return scorePosition(a, playerPos, forwardDir) > scorePosition(b, playerPos, forwardDir)
    end)

    local cellName = self.object.cell.name
    for i, obj in ipairs(objects) do
        core.sendGlobalEvent(tpEventName, {
            object = obj,
            cellName = cellName,
            position = candidates[i] or playerPos,
            options = { onGround = true }
        })
    end
end

return TP
