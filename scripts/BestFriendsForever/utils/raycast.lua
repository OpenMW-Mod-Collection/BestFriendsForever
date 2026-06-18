---@diagnostic disable: missing-fields, undefined-field
---@omw-context local
--  Taken from Dangers of Broken Artifacts by Foxunder
-- https://www.nexusmods.com/morrowind/mods/58227
local util = require("openmw.util")
local nearby = require("openmw.nearby")

local R = {}

local SPAWN_Z_OFFSET = 50
local GROUND_CHECK_Z = 200

---@param obj GameObject
---@param distance number    Positive numbers = backward, negative = forward
---@return openmw.util.Vector3
R.findSafeTpPos = function(obj, distance)
    local backward      = obj.rotation:apply(util.vector3(0, -1, 0))
    local right         = obj.rotation:apply(util.vector3(1, 0, 0))

    local candidateDirs = {
        backward,
        backward + right * 0.4,
        backward - right * 0.4,
        backward + right * 0.8,
        backward - right * 0.8,
    }

    for _, dir in ipairs(candidateDirs) do
        local candidate = obj.position + dir:normalize() * distance

        local wallCheck = nearby.castRay(
            obj.position + util.vector3(0, 0, 60),
            candidate + util.vector3(0, 0, 60),
            {
                collisionType = nearby.COLLISION_TYPE.World,
                ignore = { obj }
            }
        )

        if not wallCheck.hit then
            local groundCheck = nearby.castRay(
                candidate + util.vector3(0, 0, SPAWN_Z_OFFSET),
                candidate - util.vector3(0, 0, GROUND_CHECK_Z),
                { collisionType = nearby.COLLISION_TYPE.World }
            )

            if groundCheck.hit then
                local heightDiff = math.abs(groundCheck.hitPos.z - obj.position.z)
                if heightDiff < 120 then
                    return groundCheck.hitPos + util.vector3(0, 0, 10)
                end
            end
        end
    end

    return obj.position + backward:normalize() * distance
end

return R
