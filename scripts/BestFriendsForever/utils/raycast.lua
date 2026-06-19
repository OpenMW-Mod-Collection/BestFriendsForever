---@diagnostic disable: missing-fields, undefined-field
---@omw-context local
-- Taken from Attend Me by urm
local util = require("openmw.util")
local nearby = require("openmw.nearby")

local R = {}

local maxTeleportDistance = 200
local teleportPadding = 60
local unit = util.vector3(1, 0, 0)
local verticalAxis = util.vector3(0, 0, 1)
local waistOffset = verticalAxis * teleportPadding

local function findTarget(obj, direction)
    local targetPosition = obj.position + direction * maxTeleportDistance

    local navmeshPosition = nearby.castNavigationRay(obj.position, targetPosition, {
        includeFlags = nearby.NAVIGATOR_FLAGS.Walk + nearby.NAVIGATOR_FLAGS.UsePathgrid,
    })
    if not navmeshPosition then return end

    local physicsPosition = nearby.castRay(

        obj.position + waistOffset,
        navmeshPosition + waistOffset,
        { ignore = obj }).
    hitPos
    if not physicsPosition then return navmeshPosition end

    local physicsDirection, physicsDistance = (physicsPosition - obj.position):normalize()
    if physicsDistance < teleportPadding then
        return nil
    end

    local offsetDirection = physicsDirection * (physicsDistance - teleportPadding)
    return obj.position + offsetDirection
end

R.findSafeTpPos = function(obj)
    local searchFactor = 2
    while searchFactor <= 32 do
        for offset = 1, searchFactor do
            if offset % 2 == 1 or searchFactor == 2 then
                local angle = offset * math.pi / searchFactor
                local rotatedUnit = util.transform.rotate(angle, verticalAxis) * unit
                local target = findTarget(obj, rotatedUnit)
                if target then
                    return target
                end
            end
        end
    end
    return obj.position
end

return R
