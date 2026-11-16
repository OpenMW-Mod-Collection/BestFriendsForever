---@diagnostic disable: missing-fields, undefined-field
---@omw-context local
-- Taken from Attend Me by urm
local util = require("openmw.util")
local nearby = require("openmw.nearby")
local self = require("openmw.self")
local core = require("openmw.core")

local TP = {}

local maxTeleportDistance = 500
local preferredTeleportDistances = { 200, 300 }
local minCandidateSpacing = 50
local teleportPadding = 60
local verticalAxis = util.vector3(0, 0, 1)
local waistOffset = verticalAxis * teleportPadding
local unit = util.vector3(1, 0, 0)
local navOptions = {
    includeFlags = nearby.NAVIGATOR_FLAGS.Walk + nearby.NAVIGATOR_FLAGS.UsePathgrid,
}

---@param position openmw.util.Vector3
---@param direction openmw.util.Vector3
---@param distance number
---@return openmw.util.Vector3|nil
local function findTarget(position, direction, distance)
    local targetPosition = position + direction * distance
    local navmeshPosition = nearby.castNavigationRay(position, targetPosition, navOptions)
    if not navmeshPosition then
        return nil
    end

    local raycast = nearby.castRay(position + waistOffset, navmeshPosition + waistOffset, { ignore = self.object })
    if not raycast.hit then
        return navmeshPosition
    end

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
    if dist < 1 then
        return -math.huge
    end
    local dot = toPos:normalize():dot(forwardDir)
    -- dot == -1 means directly behind, +1 means directly in front
    -- weight: 60% distance (normalized), 40% behind-ness
    local distScore = dist / maxTeleportDistance
    local behindScore = (-dot + 1) * 0.5 -- remap [-1,1] to [1,0]
    return distScore * 0.6 + behindScore * 0.4
end

local function addCandidate(candidates, position, tier, playerPos, forwardDir)
    for _, candidate in ipairs(candidates) do
        if (candidate.position - position):length() < minCandidateSpacing then
            return
        end
    end

    candidates[#candidates + 1] = {
        position = position,
        tier = tier,
        score = scorePosition(position, playerPos, forwardDir),
    }
end

local function sortCandidates(a, b)
    return a.tier ~= b.tier and a.tier < b.tier or a.score > b.score
end

---@param objects openmw.GObject[]
---@param tpEventName string
TP.teleportBatch = function(objects, tpEventName)
    if #objects == 0 then
        return
    end

    local playerPos = self.object.position
    local forwardDir = getForwardDirection()
    local needed = #objects

    -- Check the rear semicircle first, including positions directly behind and to either side.
    local candidates = {}
    for _, distance in ipairs(preferredTeleportDistances) do
        for offset = 0, 8 do
            local angle = math.pi / 2 + offset * math.pi / 8
            local direction = util.transform.rotate(angle, verticalAxis) * forwardDir
            local target = findTarget(playerPos, direction, distance)
            if target then
                addCandidate(candidates, target, 1, playerPos, forwardDir)
            end
        end
    end

    -- If the close formation does not have enough clear spots, search farther in every direction.
    local searchFactor = 8
    while #candidates < needed and searchFactor <= 32 do
        for offset = 0, searchFactor - 1 do
            local angle = offset * 2 * math.pi / searchFactor
            local direction = util.transform.rotate(angle, verticalAxis) * forwardDir
            local target = findTarget(playerPos, direction, maxTeleportDistance)
            if target then
                addCandidate(candidates, target, 2, playerPos, forwardDir)
            end
        end
        searchFactor = searchFactor * 2
    end

    -- Keep preferred spots ahead of fallback spots; within each tier, favor behind the player.
    table.sort(candidates, sortCandidates)

    local cellName = self.object.cell.name
    for i, obj in ipairs(objects) do
        core.sendGlobalEvent(tpEventName, {
            object = obj,
            cellName = cellName,
            position = candidates[i] and candidates[i].position or playerPos,
            options = { onGround = true },
        })
    end
end

return TP
