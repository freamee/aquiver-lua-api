API.BlipManager = {}
---@type table<string, {registeredResource:string; blip: CBlip; }>
API.BlipManager.Entities = {}

---@class IBlip
---@field position { x:number; y:number; z:number }
---@field alpha number
---@field color number
---@field sprite number
---@field display number
---@field shortRange boolean
---@field scale number
---@field name string
---@field blipUid string

---@param data IBlip
API.BlipManager.new = function(data)
    ---@class CBlip
    local self = {}

    self.data = data

    if API.BlipManager.exists(self.data.blipUid) then
        API.Utils.Debug.Print("^1Blip already exists with uid: " .. self.data.blipUid)
        return
    end

    if API.IsServer then
        self.server = {}

        TriggerClientEvent("AQUIVER:Blip:Create", -1, self.data)
    else
        self.client = {}
        self.client.blipHandle = nil

        local blip = AddBlipForCoord(self.data.position.x, self.data.position.y, self.data.position.z)
        SetBlipColour(blip, self.data.color)
        SetBlipSprite(blip, self.data.sprite)
        SetBlipDisplay(blip, self.data.display)
        SetBlipScale(blip, self.data.scale)
        SetBlipAsShortRange(blip, self.data.shortRange)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(self.data.name)
        EndTextCommandSetBlipName(blip)

        self.client.blipHandle = blip
    end

    self.SetColor = function(color)
        self.data.color = color

        if not API.IsServer then
            if DoesBlipExist(self.client.blipHandle) then
                SetBlipColour(self.client.blipHandle, color)
            end
        else
            TriggerClientEvent("AQUIVER:Blip:Update:Color", -1, self.data.blipUid, color)
        end
    end

    self.SetAlpha = function(alpha)
        self.data.alpha = alpha

        if not API.IsServer then
            if DoesBlipExist(self.client.blipHandle) then
                SetBlipAlpha(self.client.blipHandle, alpha)
            end
        else
            TriggerClientEvent("AQUIVER:Blip:Update:Alpha", -1, self.data.blipUid, alpha)
        end
    end

    self.SetSprite = function(sprite)
        self.data.sprite = sprite

        if not API.IsServer then
            if DoesBlipExist(self.client.blipHandle) then
                SetBlipSprite(self.client.blipHandle, sprite)
            end
        else
            TriggerClientEvent("AQUIVER:Blip:Update:Sprite", -1, self.data.blipUid, sprite)
        end

    end

    self.SetDisplay = function(displayId)
        self.data.display = displayId

        if not API.IsServer then
            if DoesBlipExist(self.client.blipHandle) then
                SetBlipDisplay(self.client.blipHandle, displayId)
            end
        else
            TriggerClientEvent("AQUIVER:Blip:Update:Display", -1, self.data.blipUid, displayId)
        end
    end

    self.SetShortRange = function(state)
        self.data.shortRange = state

        if not API.IsServer then
            if DoesBlipExist(self.client.blipHandle) then
                SetBlipAsShortRange(self.client.blipHandle, state)
            end
        else
            TriggerClientEvent("AQUIVER:Blip:Update:ShortRange", -1, self.data.blipUid, state)
        end
    end

    self.SetScale = function(scale)
        self.data.scale = scale

        if not API.IsServer then
            if DoesBlipExist(self.client.blipHandle) then
                SetBlipScale(self.client.blipHandle, scale)
            end
        else
            TriggerClientEvent("AQUIVER:Blip:Update:Scale", -1, self.data.blipUid, scale)
        end
    end

    self.SetName = function(name)
        self.data.name = name

        if not API.IsServer then
            if DoesBlipExist(self.client.blipHandle) then
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(name)
                EndTextCommandSetBlipName(blip)
            end
        else
            TriggerClientEvent("AQUIVER:Blip:Update:Name", -1, self.data.blipUid, name)
        end
    end

    self.SetPosition = function(position)
        self.data.position = position

        if not API.IsServer then
            if DoesBlipExist(self.client.blipHandle) then
                SetBlipCoords(self.client.blipHandle, position.x, position.y, position.z)
            end
        else
            TriggerClientEvent("AQUIVER:Blip:Update:Position", -1, self.data.blipUid, position)
        end
    end

    self.Destroy = function()
        -- Delete from table
        if API.BlipManager.Entities[self.data.blipUid] then
            API.BlipManager.Entities[self.data.blipUid] = nil
        end

        if API.IsServer then
            TriggerClientEvent("AQUIVER:Blip:Destroy", -1, self.data.blipUid)
        else
            if DoesBlipExist(self.client.blipHandle) then
                RemoveBlip(self.client.blipHandle)
            end
        end
    end

    API.BlipManager.Entities[self.data.blipUid] = {
        blip = self,
        registeredResource = API.InvokeResourceName()
    }

    return self
end

API.BlipManager.exists = function(id)
    if API.BlipManager.Entities[id] then
        return true
    end
end

API.BlipManager.get = function(id)
    if API.BlipManager.exists(id) then
        return API.BlipManager.Entities[id].blip
    end
end

API.BlipManager.getAll = function()
    return API.BlipManager.Entities
end

if API.IsServer then
    AddEventHandler("onResourceStart", function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end

        RegisterNetEvent("AQUIVER:Blip:RequestData", function()
            local source = source

            for k, v in pairs(API.BlipManager.Entities) do
                TriggerClientEvent("AQUIVER:Blip:Create", source, v.blip.data)
            end 
        end)
    end)
else
    AddEventHandler("onClientResourceStart", function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end

        RegisterNetEvent("AQUIVER:Blip:Create", function(data)
            API.BlipManager.new(data)
        end)
        RegisterNetEvent("AQUIVER:Blip:Update:Color", function(uid, color)
            local BlipEntity = API.BlipManager.get(uid)
            if not BlipEntity then return end
            BlipEntity.SetColor(color)
        end)
        RegisterNetEvent("AQUIVER:Blip:Update:Alpha", function(uid, alpha)
            local BlipEntity = API.BlipManager.get(uid)
            if not BlipEntity then return end
            BlipEntity.SetAlpha(alpha)
        end)
        RegisterNetEvent("AQUIVER:Blip:Update:Sprite", function(uid, sprite)
            local BlipEntity = API.BlipManager.get(uid)
            if not BlipEntity then return end
            BlipEntity.SetSprite(sprite)
        end)
        RegisterNetEvent("AQUIVER:Blip:Update:Display", function(uid, displayId)
            local BlipEntity = API.BlipManager.get(uid)
            if not BlipEntity then return end
            BlipEntity.SetDisplay(displayId)
        end)
        RegisterNetEvent("AQUIVER:Blip:Update:ShortRange", function(uid, state)
            local BlipEntity = API.BlipManager.get(uid)
            if not BlipEntity then return end
            BlipEntity.SetShortRange(state)
        end)
        RegisterNetEvent("AQUIVER:Blip:Update:Scale", function(uid,scale)
            local BlipEntity = API.BlipManager.get(uid)
            if not BlipEntity then return end
            BlipEntity.SetScale(scale)
        end)
        RegisterNetEvent("AQUIVER:Blip:Update:Name", function(uid, name)
            local BlipEntity = API.BlipManager.get(uid)
            if not BlipEntity then return end
            BlipEntity.SetName(name)
        end)
        RegisterNetEvent("AQUIVER:Blip:Update:Position", function(uid, position)
            local BlipEntity = API.BlipManager.get(uid)
            if not BlipEntity then return end
            BlipEntity.SetPosition(position)
        end)
        RegisterNetEvent("AQUIVER:Blip:Destroy", function(uid)
            local BlipEntity = API.BlipManager.get(uid)
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
    end)
end

-- Delete if another resource is restarted which has connections to this.
AddEventHandler("onResourceStop", function(resourceName)
    for k, v in pairs(API.BlipManager.Entities) do
        if v.registeredResource == resourceName then
            v.blip.Destroy()
        end
    end
end)
