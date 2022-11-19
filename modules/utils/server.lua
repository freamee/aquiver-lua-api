local Manager = {}

--- Calculate and return new position after offsets are applied with heading
---@param vec3 { x:number; y:number; z:number }
---@param heading number
---@param oX number
---@param oY number
---@param oZ number
Manager.GetOffsetFromVector3 = function(vec3, heading, oX, oY, oZ)
    local newPos = {
        x = vec3.x,
        y = vec3.y,
        z = vec3.z
    }
    local angle = (heading * math.pi) / 180

    newPos.x = oX * math.cos(angle) - oY * math.sin(angle)
    newPos.y = oX * math.sin(angle) + oY * math.cos(angle)

    return vec3 + vector3(newPos.x, newPos.y, oZ or 0)
end

AQUIVER_SERVER.Utils = Manager
