local Manager = {}
---@type { [number]: ClientBlip }
Manager.Entities = {}

---@param data IBlip
Manager.new = function(data)
    ---@class ClientBlip
    local self = {}

    self.data = data
    self.blipHandle = nil

    self.Destroy = function()
        -- Delete from table
        if Manager.exists(self.data.remoteId) then
            Manager.Entities[self.data.remoteId] = nil
        end

        if DoesBlipExist(self.blipHandle) then
            RemoveBlip(self.blipHandle)
        end
    end

    -- Creating the blip here.
    local blip = AddBlipForCoord(self.data.position.x, self.data.position.y, self.data.position.z)
    SetBlipSprite(blip, self.data.sprite)
    SetBlipDisplay(blip, self.data.display)
    SetBlipScale(blip, self.data.scale)
    SetBlipAlpha(blip, self.data.alpha)
    SetBlipAsShortRange(blip, self.data.shortRange)
    SetBlipColour(blip, self.data.color)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(self.data.name)
    EndTextCommandSetBlipName(blip)

    self.blipHandle = blip

    Manager.Entities[self.data.remoteId] = self
    AQUIVER_SHARED.Utils.Print("^3Created new blip with remoteId: " .. self.data.remoteId)
    TriggerEvent("onBlipCreated", self)

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

RegisterNetEvent("AQUIVER:Blip:Create", function(data)
    Manager.new(data)
end)
RegisterNetEvent("AQUIVER:Blip:Update:Color", function(remoteId, color)
    local BlipEntity = Manager.get(remoteId)
    if not BlipEntity then return end

    BlipEntity.data.color = color

    if DoesBlipExist(BlipEntity.blipHandle) then
        SetBlipColour(BlipEntity.blipHandle, color)
    end
end)
RegisterNetEvent("AQUIVER:Blip:Update:Alpha", function(remoteId, alpha)
    local BlipEntity = Manager.get(remoteId)
    if not BlipEntity then return end

    BlipEntity.data.alpha = alpha

    if DoesBlipExist(BlipEntity.blipHandle) then
        SetBlipAlpha(BlipEntity.blipHandle, alpha)
    end
end)
RegisterNetEvent("AQUIVER:Blip:Update:Sprite", function(remoteId, sprite)
    local BlipEntity = Manager.get(remoteId)
    if not BlipEntity then return end

    BlipEntity.data.sprite = sprite

    if DoesBlipExist(BlipEntity.blipHandle) then
        SetBlipSprite(BlipEntity.blipHandle, sprite)
    end
end)
RegisterNetEvent("AQUIVER:Blip:Update:Display", function(remoteId, displayId)
    local BlipEntity = Manager.get(remoteId)
    if not BlipEntity then return end

    BlipEntity.data.display = displayId

    if DoesBlipExist(BlipEntity.blipHandle) then
        SetBlipDisplay(BlipEntity.blipHandle, displayId)
    end
end)
RegisterNetEvent("AQUIVER:Blip:Update:ShortRange", function(remoteId, state)
    local BlipEntity = Manager.get(remoteId)
    if not BlipEntity then return end

    BlipEntity.data.shortRange = state

    if DoesBlipExist(BlipEntity.blipHandle) then
        SetBlipAsShortRange(BlipEntity.blipHandle, state)
    end
end)

RegisterNetEvent("AQUIVER:Blip:Update:Scale", function(remoteId, scale)
    local BlipEntity = Manager.get(remoteId)
    if not BlipEntity then return end

    BlipEntity.data.scale = scale

    if DoesBlipExist(BlipEntity.blipHandle) then
        SetBlipScale(BlipEntity.blipHandle, scale)
    end
end)
RegisterNetEvent("AQUIVER:Blip:Update:Name", function(remoteId, name)
    local BlipEntity = Manager.get(remoteId)
    if not BlipEntity then return end

    BlipEntity.data.name = name

    if DoesBlipExist(BlipEntity.blipHandle) then
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(name)
        EndTextCommandSetBlipName(BlipEntity.blipHandle)
    end
end)
RegisterNetEvent("AQUIVER:Blip:Update:Position", function(remoteId, position)
    local BlipEntity = Manager.get(remoteId)
    if not BlipEntity then return end

    BlipEntity.data.position = position

    if DoesBlipExist(BlipEntity.blipHandle) then
        SetBlipCoords(BlipEntity.blipHandle, position.x, position.y, position.z)
    end
end)
RegisterNetEvent("AQUIVER:Blip:Destroy", function(remoteId)
    local BlipEntity = Manager.get(remoteId)
    if not BlipEntity then return end
    BlipEntity.Destroy()
end)

Citizen.CreateThread(function()
    while true do

        if NetworkIsPlayerActive(PlayerId()) then
            -- Request Data from server.
            TriggerServerEvent("AQUIVER:Blip:RequestData")
            break
        end

        Citizen.Wait(500)
    end
end)

AQUIVER_CLIENT.BlipManager = Manager
