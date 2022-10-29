API.RadarBlipManager = {}
---@type table<string, { registeredResource:string; blip: CRadarBlip; }>
API.RadarBlipManager.Entities = {}

---@class IRadarBlip
---@field position { x:number; y:number; z:number }
---@field radius number
---@field alpha number
---@field color number
---@field isFlashing? boolean
---@field blipUid string

---@param data IRadarBlip
API.RadarBlipManager.new = function(data)
    ---@class CRadarBlip
    local self = {}

    self.data = data

    if API.RadarBlipManager.exists(self.data.blipUid) then
        API.Utils.Debug.Print("^1RadarBlip already exists with uid: " .. self.data.blipUid)
        return
    end

    if API.IsServer then
        self.server = {}

        TriggerClientEvent("AQUIVER:RadarBlip:Create", -1, self.data)
    else
        self.client = {}
        self.client.blipHandle = nil

        local blip = AddBlipForRadius(self.data.position, self.data.radius)
        SetBlipRotation(blip, 0)
        SetBlipAlpha(blip, self.data.alpha)
        SetBlipColour(blip, self.data.color)
        SetBlipFlashes(blip, self.data.isFlashing)

        self.client.blipHandle = blip
    end

    self.SetRadius = function(radius)
        self.data.radius = radius

        if not API.IsServer then
            if DoesBlipExist(self.client.blipHandle) then
                SetBlipScale(self.client.blipHandle, radius)
            end
        else
            TriggerClientEvent("AQUIVER:RadarBlip:Update:Radius", -1, self.data.blipUid, radius)
        end
    end

    self.SetColor = function(color)
        self.data.color = color

        if not API.IsServer then
            if DoesBlipExist(self.client.blipHandle) then
                SetBlipColour(self.client.blipHandle, color)
            end
        else
            TriggerClientEvent("AQUIVER:RadarBlip:Update:Color", -1, self.data.blipUid, color)
        end
    end

    self.SetAlpha = function(alpha)
        self.data.alpha = alpha

        if not API.IsServer then
            if DoesBlipExist(self.client.blipHandle) then
                SetBlipAlpha(self.client.blipHandle, alpha)
            end
        else
            TriggerClientEvent("AQUIVER:RadarBlip:Update:Alpha", -1, self.data.blipUid, alpha)
        end
    end

    self.SetFlashing = function(state)
        self.data.isFlashing = state

        if not API.IsServer then
            if DoesBlipExist(self.client.blipHandle) then
                SetBlipFlashes(self.client.blipHandle, state)
            end
        else
            TriggerClientEvent("AQUIVER:RadarBlip:Update:Flashing", -1, self.data.blipUid, state)
        end
    end

    self.Destroy = function()
        -- Delete from table
        if RadarBlipManager.Entities[self.data.blipUid] then
            RadarBlipManager.Entities[self.data.blipUid] = nil
        end

        if API.IsServer then
            TriggerClientEvent("AQUIVER:RadarBlip:Destroy", -1, self.data.blipUid)
        else
            if DoesBlipExist(self.client.blipHandle) then
                RemoveBlip(self.client.blipHandle)
            end
        end
    end

    API.RadarBlipManager.Entities[self.data.blipUid] = {
        blip = self,
        registeredResource = API.InvokeResourceName()
    }

    return self
end

API.RadarBlipManager.exists = function(id)
    if API.RadarBlipManager.Entities[id] then
        return true
    end
end

API.RadarBlipManager.get = function(id)
    if API.RadarBlipManager.exists(id) then
        return API.RadarBlipManager.Entities[id].blip
    end
end

API.RadarBlipManager.getAll = function()
    return API.RadarBlipManager.Entities
end

if API.IsServer then
    AddEventHandler("onResourceStart", function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end

        RegisterNetEvent("AQUIVER:RadarBlip:RequestData", function()
            local source = source

            for k, v in pairs(API.RadarBlipManager.Entities) do
                TriggerClientEvent("AQUIVER:RadarBlip:Create", source, v.blip.data)
            end
        end)
    end)
else
    AddEventHandler("onClientResourceStart", function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end

        RegisterNetEvent("AQUIVER:RadarBlip:Create", function(data)
            API.RadarBlipManager.new(data)
        end)
        RegisterNetEvent("AQUIVER:RadarBlip:Update:Color", function(uid,color)
            local RadarBlipEntity = API.RadarBlipManager.get(uid)
            if not RadarBlipEntity then return end
            RadarBlipEntity.SetColor(color)
        end)
        RegisterNetEvent("AQUIVER:RadarBlip:Update:Radius", function(uid,radius)
            local RadarBlipEntity = API.RadarBlipManager.get(uid)
            if not RadarBlipEntity then return end
            RadarBlipEntity.SetRadius(radius)
        end)
        RegisterNetEvent("AQUIVER:RadarBlip:Update:Alpha", function(uid,alpha)
            local RadarBlipEntity = API.RadarBlipManager.get(uid)
            if not RadarBlipEntity then return end
            RadarBlipEntity.SetAlpha(alpha)
        end)
        RegisterNetEvent("AQUIVER:RadarBlip:Update:Flashing", function(uid,state)
            local RadarBlipEntity = API.RadarBlipManager.get(uid)
            if not RadarBlipEntity then return end
            RadarBlipEntity.SetFlashing(state)
        end)
        RegisterNetEvent("AQUIVER:RadarBlip:Destroy", function(uid)
            local RadarBlipEntity = API.RadarBlipManager.get(uid)
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
    end)
end

-- Delete if another resource is restarted which has connections to this.
AddEventHandler("onResourceStop", function(resourceName)
    for k, v in pairs(API.RadarBlipManager.Entities) do
        if v.registeredResource == resourceName then
            v.blip.Destroy()
        end
    end
end)
