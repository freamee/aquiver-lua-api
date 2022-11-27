local Manager = {}
---@type { [number]: ClientRadarBlip }
Manager.Entities = {}

---@param data IRadarBlip
Manager.new = function(data)
    ---@class ClientRadarBlip
    local self = {}

    local _data = data
    self.blipHandle = nil

    self.Set = {
        Color = function(color)
            _data.color = color

            if DoesBlipExist(self.blipHandle) then
                SetBlipColour(self.blipHandle, color)
            end
        end,
        Radius = function(radius)
            _data.radius = radius

            if DoesBlipExist(self.blipHandle) then
                SetBlipScale(self.blipHandle, radius)
            end
        end,
        Alpha = function(alpha)
            _data.alpha = alpha

            if DoesBlipExist(self.blipHandle) then
                SetBlipAlpha(self.blipHandle, alpha)
            end
        end,
        Flashing = function(state)
            _data.isFlashing = state

            if DoesBlipExist(self.blipHandle) then
                SetBlipFlashes(self.blipHandle, state)
            end
        end
    }

    self.Destroy = function()
        if Manager.exists(_data.remoteId) then
            Manager.Entities[_data.remoteId] = nil
        end

        if DoesBlipExist(self.blipHandle) then
            RemoveBlip(self.blipHandle)
        end
    end

    local blip = AddBlipForRadius(_data.position, _data.radius)
    SetBlipRotation(blip, 0)
    SetBlipAlpha(blip, _data.alpha)
    SetBlipColour(blip, _data.color)
    SetBlipFlashes(blip, _data.isFlashing)
    self.blipHandle = blip

    Manager.Entities[_data.remoteId] = self

    return self
end

Manager.exists = function(id)
    return Manager.Entities[id] and true or false
end

Manager.get = function(id)
    return Manager.Entities[id] or nil
end

RegisterNetEvent("AQUIVER:RadarBlip:Create", function(data)
    Manager.new(data)
end)
RegisterNetEvent("AQUIVER:RadarBlip:Update:Color", function(remoteId, color)
    local RadarBlipEntity = Manager.get(remoteId)
    if not RadarBlipEntity then return end

    RadarBlipEntity.Set.Color(color)
end)
RegisterNetEvent("AQUIVER:RadarBlip:Update:Radius", function(remoteId, radius)
    local RadarBlipEntity = Manager.get(remoteId)
    if not RadarBlipEntity then return end

    RadarBlipEntity.Set.Radius(radius)
end)
RegisterNetEvent("AQUIVER:RadarBlip:Update:Alpha", function(remoteId, alpha)
    local RadarBlipEntity = Manager.get(remoteId)
    if not RadarBlipEntity then return end

    RadarBlipEntity.Set.Alpha(alpha)
end)
RegisterNetEvent("AQUIVER:RadarBlip:Update:Flashing", function(remoteId, state)
    local RadarBlipEntity = Manager.get(remoteId)
    if not RadarBlipEntity then return end

    RadarBlipEntity.Set.Flashing(state)
end)
RegisterNetEvent("AQUIVER:RadarBlip:Destroy", function(remoteId)
    local RadarBlipEntity = Manager.get(remoteId)
    if not RadarBlipEntity then return end
    RadarBlipEntity.Destroy()
end)

Citizen.CreateThread(function()
    while true do

        if NetworkIsPlayerActive(PlayerId()) then
            -- Request Data from server.
            TriggerServerEvent("AQUIVER:RadarBlip:RequestData")
            break
        end

        Citizen.Wait(500)
    end
end)

AQUIVER_CLIENT.RadarBlipManager = Manager
