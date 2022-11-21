local Manager = {}
---@type { [number]: ClientBlip }
Manager.Entities = {}

---@param data IBlip
Manager.new = function(data)
    ---@class ClientBlip
    local self = {}

    local _data = data
    self.blipHandle = nil

    self.Destroy = function()
        -- Delete from table
        if Manager.exists(_data.remoteId) then
            Manager.Entities[_data.remoteId] = nil
        end

        if DoesBlipExist(self.blipHandle) then
            RemoveBlip(self.blipHandle)
        end
    end

    self.Set = {
        Color = function(color)
            _data.color = color

            if DoesEntityExist(self.blipHandle) then
                SetBlipColour(self.blipHandle, color)
            end
        end,
        Alpha = function(alpha)
            _data.alpha = alpha

            if DoesBlipExist(self.blipHandle) then
                SetBlipAlpha(self.blipHandle, alpha)
            end
        end,
        Sprite = function(sprite)
            _data.sprite = sprite

            if DoesBlipExist(self.blipHandle) then
                SetBlipSprite(self.blipHandle, sprite)
            end
        end,
        Display = function(displayId)
            _data.display = displayId

            if DoesBlipExist(self.blipHandle) then
                SetBlipDisplay(self.blipHandle, displayId)
            end
        end,
        ShortRange = function(state)
            _data.shortRange = state

            if DoesBlipExist(self.blipHandle) then
                SetBlipAsShortRange(self.blipHandle, state)
            end
        end,
        Scale = function(scale)
            _data.scale = scale

            if DoesBlipExist(self.blipHandle) then
                SetBlipScale(self.blipHandle, scale)
            end
        end,
        Name = function(name)
            _data.name = name

            if DoesBlipExist(self.blipHandle) then
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(name)
                EndTextCommandSetBlipName(self.blipHandle)
            end
        end,
        Position = function(vec3)
            _data.position = vec3

            if DoesBlipExist(self.blipHandle) then
                SetBlipCoords(self.blipHandle, vec3.x, vec3.y, vec3.z)
            end
        end
    }

    -- Creating the blip here.
    local blip = AddBlipForCoord(_data.position.x, _data.position.y, _data.position.z)
    SetBlipSprite(blip, _data.sprite)
    SetBlipDisplay(blip, _data.display)
    SetBlipScale(blip, _data.scale)
    SetBlipAlpha(blip, _data.alpha)
    SetBlipAsShortRange(blip, _data.shortRange)
    SetBlipColour(blip, _data.color)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(_data.name)
    EndTextCommandSetBlipName(blip)

    self.blipHandle = blip

    Manager.Entities[_data.remoteId] = self
    AQUIVER_SHARED.Utils.Print("^3Created new blip with remoteId: " .. _data.remoteId)
    TriggerEvent("onBlipCreated", self)

    return self
end

Manager.exists = function(id)
    return Manager.Entities[id] and true or false
end

Manager.get = function(id)
    return Manager.Entities[id] or nil
end

RegisterNetEvent("AQUIVER:Blip:Create", function(data)
    Manager.new(data)
end)
RegisterNetEvent("AQUIVER:Blip:Update:Color", function(remoteId, color)
    local BlipEntity = Manager.get(remoteId)
    if not BlipEntity then return end

    BlipEntity.Set.Color(color)
end)
RegisterNetEvent("AQUIVER:Blip:Update:Alpha", function(remoteId, alpha)
    local BlipEntity = Manager.get(remoteId)
    if not BlipEntity then return end

    BlipEntity.Set.Alpha(alpha)
end)
RegisterNetEvent("AQUIVER:Blip:Update:Sprite", function(remoteId, sprite)
    local BlipEntity = Manager.get(remoteId)
    if not BlipEntity then return end

    BlipEntity.Set.Sprite(sprite)
end)
RegisterNetEvent("AQUIVER:Blip:Update:Display", function(remoteId, displayId)
    local BlipEntity = Manager.get(remoteId)
    if not BlipEntity then return end

    BlipEntity.Set.Display(displayId)
end)
RegisterNetEvent("AQUIVER:Blip:Update:ShortRange", function(remoteId, state)
    local BlipEntity = Manager.get(remoteId)
    if not BlipEntity then return end

    BlipEntity.Set.ShortRange(state)
end)

RegisterNetEvent("AQUIVER:Blip:Update:Scale", function(remoteId, scale)
    local BlipEntity = Manager.get(remoteId)
    if not BlipEntity then return end

    BlipEntity.Set.Scale(scale)
end)
RegisterNetEvent("AQUIVER:Blip:Update:Name", function(remoteId, name)
    local BlipEntity = Manager.get(remoteId)
    if not BlipEntity then return end

    BlipEntity.Set.Name(name)
end)
RegisterNetEvent("AQUIVER:Blip:Update:Position", function(remoteId, position)
    local BlipEntity = Manager.get(remoteId)
    if not BlipEntity then return end

    BlipEntity.Set.Position(position)
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
