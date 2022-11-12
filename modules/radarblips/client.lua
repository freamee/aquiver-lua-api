local Manager = {}
---@type { [number]: ClientRadarBlip }
Manager.Entities = {}

---@param data IRadarBlip
Manager.new = function(data)
    ---@class ClientRadarBlip
    local self = {}

    self.data = data
    self.blipHandle = nil

    self.Destroy = function()
        if Manager.exists(self.data.remoteId) then
            Manager.Entities[self.data.remoteId] = nil
        end

        if DoesBlipExist(self.blipHandle) then
            RemoveBlip(self.blipHandle)
        end
    end

    local blip = AddBlipForRadius(self.data.position, self.data.radius)
    SetBlipRotation(blip, 0)
    SetBlipAlpha(blip, self.data.alpha)
    SetBlipColour(blip, self.data.color)
    SetBlipFlashes(blip, self.data.isFlashing)
    self.blipHandle = blip

    Manager.Entities[self.data.remoteId] = self

    return self
end

Manager.exists = function(id)
    return Manager.Entities[id] and true or false
end

Manager.get = function(id)
    return Manager.Entities[id] or nil
end

Manager.getAll = function()
    return Manager.Entities
end

RegisterNetEvent("AQUIVER:RadarBlip:Create", function(data)
    Manager.new(data)
end)
RegisterNetEvent("AQUIVER:RadarBlip:Update:Color", function(remoteId, color)
    local RadarBlipEntity = Manager.get(remoteId)
    if not RadarBlipEntity then return end

    RadarBlipEntity.data.color = color

    if DoesBlipExist(RadarBlipEntity.blipHandle) then
        SetBlipColour(RadarBlipEntity.blipHandle, color)
    end
end)
RegisterNetEvent("AQUIVER:RadarBlip:Update:Radius", function(remoteId, radius)
    local RadarBlipEntity = Manager.get(remoteId)
    if not RadarBlipEntity then return end

    RadarBlipEntity.data.radius = radius

    if DoesBlipExist(RadarBlipEntity.blipHandle) then
        SetBlipScale(RadarBlipEntity.blipHandle, radius)
    end
end)
RegisterNetEvent("AQUIVER:RadarBlip:Update:Alpha", function(remoteId, alpha)
    local RadarBlipEntity = Manager.get(remoteId)
    if not RadarBlipEntity then return end

    RadarBlipEntity.data.alpha = alpha

    if DoesBlipExist(RadarBlipEntity.blipHandle) then
        SetBlipAlpha(RadarBlipEntity.blipHandle, alpha)
    end
end)
RegisterNetEvent("AQUIVER:RadarBlip:Update:Flashing", function(remoteId, state)
    local RadarBlipEntity = Manager.get(remoteId)
    if not RadarBlipEntity then return end

    RadarBlipEntity.data.isFlashing = state

    if DoesBlipExist(RadarBlipEntity.blipHandle) then
        SetBlipFlashes(RadarBlipEntity.blipHandle, state)
    end
end)
RegisterNetEvent("AQUIVER:RadarBlip:Destroy", function(uid)
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
