---@class CActionShapeModule
local Module = {}
---@type { [number]: CAquiverActionShape }
Module.Entities = {}

---@class CAquiverActionShape
local ActionShape = {
    ---@type IActionShape
    data = {},
    isStreamed = false,
    isEntered = false
}
ActionShape.__index = ActionShape

---@param d IActionShape
ActionShape.new = function(d)
    local self = setmetatable({}, ActionShape)

    self.data = d
    self.isStreamed = false
    self.isEntered = false

    if Module:exists(self.data.remoteId) then
        Shared.Utils:Print("^1ActionShape already exists with remoteID: " .. self.data.remoteId)
        return
    end

    self:__init__()

    Module.Entities[self.data.remoteId] = self

    Shared.Utils:Print("^3Created new ActionShape with remoteID: " .. self.data.remoteId)

    return self
end

function ActionShape:__init__()

end

function ActionShape:addStream()
    if self.isStreamed then return end

    self.isStreamed = true

    Citizen.CreateThread(function()
        while self.isStreamed do

            DrawMarker(
                self.data.sprite,
                self.data.position.x, self.data.position.y, self.data.position.z - 1.0,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                1.0, 1.0, 1.0,
                self.data.color.r, self.data.color.g, self.data.color.b, self.data.color.a,
                false, false, 2, false, nil, nil, false
            )

            Citizen.Wait(1)
        end
    end)

    Shared.Utils:Print(string.format("^3ActionShape streamed in (%d)", self.data.remoteId))
end

function ActionShape:removeStream()
    if not self.isStreamed then return end

    self.isStreamed = false

    Shared.Utils:Print(string.format("^3ActionShape streamed out (%d)", self.data.remoteId))
end

function ActionShape:onEnter()
    if self.isEntered then return end

    self.isEntered = true

    TriggerEvent("onActionShapeEnter", GetCurrentResourceName(), self)
    TriggerServerEvent("onActionShapeEnter", GetCurrentResourceName(), self.data.remoteId)
end

function ActionShape:onLeave()
    if not self.isEntered then return end

    self.isEntered = false

    TriggerEvent("onActionShapeLeave", GetCurrentResourceName(), self)
    TriggerServerEvent("onActionShapeLeave", GetCurrentResourceName(), self.data.remoteId)
end

function ActionShape:Destroy()
    if Module:exists(self.data.remoteId) then
        Module.Entities[self.data.remoteId] = nil
    end

    -- Remove from stream when destroyed.
    self:removeStream()

    Shared.Utils:Print("^3Removed ActionShape with remoteId: " .. self.data.remoteId)
end

function ActionShape:getVector3Position()
    return vector3(self.data.position.x, self.data.position.y, self.data.position.z)
end

---@param vec3 { x:number; y:number; z: number; }
function ActionShape:dist(vec3)
    return #(self:getVector3Position() - vector3(vec3.x, vec3.y, vec3.z))
end

---@param d IActionShape
function Module:new(d)
    local aActionShape = ActionShape.new(d)
    if aActionShape then
        return aActionShape
    end
end

function Module:exists(remoteId)
    return self.Entities[remoteId] and true or false
end

function Module:get(remoteId)
    return self.Entities[remoteId] or nil
end

-- STREAMING HANDLER.
Citizen.CreateThread(function()
    while true do

        for k, v in pairs(Module.Entities) do
            if Client.LocalPlayer.dimension ~= v.data.dimension then
                v:removeStream()
            else
                local dist = v:dist(Client.LocalPlayer.cachedPosition)
                if dist < Shared.Config.STREAM_DISTANCES.ACTIONSHAPE then
                    v:addStream()

                    if dist <= v.data.range then
                        v:onEnter()
                    else
                        v:onLeave()
                    end
                else
                    v:removeStream()
                end
            end
        end

        Citizen.Wait(Shared.Config.STREAM_INTERVALS.ACTIONSHAPE)
    end
end)

Citizen.CreateThread(function()
    while true do

        if NetworkIsPlayerActive(PlayerId()) then
            -- Request Data from server.
            Shared.EventManager:TriggerModuleServerEvent("ActionShape:RequestData")
            break
        end

        Citizen.Wait(500)
    end
end)

Shared.EventManager:RegisterModuleNetworkEvent({
    ["ActionShape:Create"] = function(data)
        Module:new(data)
    end,
    ["ActionShape:Destroy"] = function(remoteId)
        local aActionShape = Module:get(remoteId)
        if not aActionShape then return end

        aActionShape:Destroy()
    end
})

return Module
