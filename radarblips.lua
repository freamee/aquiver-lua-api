local IS_SERVER = IsDuplicityVersion()

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

    if IS_SERVER then
        self.server = {}

        API.EventManager.TriggerClientLocalEvent("RadarBlip:Create", -1, self.data)
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

        if not IS_SERVER then
            if DoesBlipExist(self.client.blipHandle) then
                SetBlipScale(self.client.blipHandle, radius)
            end
        else
            API.EventManager.TriggerClientLocalEvent("RadarBlip:Update:Radius", -1, self.data.blipUid, radius)
        end
    end

    self.SetColor = function(color)
        self.data.color = color

        if not IS_SERVER then
            if DoesBlipExist(self.client.blipHandle) then
                SetBlipColour(self.client.blipHandle, color)
            end
        else
            API.EventManager.TriggerClientLocalEvent("RadarBlip:Update:Color", -1, self.data.blipUid, color)
        end
    end

    self.SetAlpha = function(alpha)
        self.data.alpha = alpha

        if not IS_SERVER then
            if DoesBlipExist(self.client.blipHandle) then
                SetBlipAlpha(self.client.blipHandle, alpha)
            end
        else
            API.EventManager.TriggerClientLocalEvent("RadarBlip:Update:Alpha", -1, self.data.blipUid, alpha)
        end
    end

    self.SetFlashing = function(state)
        self.data.isFlashing = state

        if not IS_SERVER then
            if DoesBlipExist(self.client.blipHandle) then
                SetBlipFlashes(self.client.blipHandle, state)
            end
        else
            API.EventManager.TriggerClientLocalEvent("RadarBlip:Update:Flasing", -1, self.data.blipUid, state)
        end
    end

    self.Destroy = function()
        -- Delete from table
        if RadarBlipManager.Entities[API.InvokeResourceName() .. self.data.blipUid] then
            RadarBlipManager.Entities[API.InvokeResourceName() .. self.data.blipUid] = nil
        end

        if IS_SERVER then
            API.EventManager.TriggerClientLocalEvent("RadarBlip:Destroy", -1, self.data.blipUid)
        else
            if DoesBlipExist(self.client.blipHandle) then
                RemoveBlip(self.client.blipHandle)
            end
        end
    end

    API.RadarBlipManager.Entities[API.InvokeResourceName() .. self.data.blipUid] = {
        blip = self,
        registeredResource = API.InvokeResourceName()
    }

    return self
end

API.RadarBlipManager.exists = function(id)
    if API.RadarBlipManager.Entities[API.InvokeResourceName() .. id] then
        return true
    end
end

API.RadarBlipManager.get = function(id)
    if API.RadarBlipManager.exists(id) then
        return API.RadarBlipManager.Entities[API.InvokeResourceName() .. id].blip
    end
end

API.RadarBlipManager.getAll = function()
    return API.RadarBlipManager.Entities
end

if IS_SERVER then
    AddEventHandler("onResourceStart", function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end

        API.EventManager.AddLocalEvent("RadarBlip:RequestData", function()
            local source = source

            for k, v in pairs(API.RadarBlipManager.Entities) do
                API.EventManager.TriggerClientLocalEvent("RadarBlip:Create", source, v.blip.data)
            end
        end)
    end)
else
    AddEventHandler("onClientResourceStart", function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end

        API.EventManager.AddLocalEvent({
            ["RadarBlip:Create"] = function(data)
                API.RadarBlipManager.new(data)
            end,
            ["RadarBlip:Update:Color"] = function(uid, color)
                local RadarBlipEntity = API.RadarBlipManager.get(uid)
                if not RadarBlipEntity then return end
                RadarBlipEntity.SetColor(color)
            end,
            ["RadarBlip:Update:Radius"] = function(uid, radius)
                local RadarBlipEntity = API.RadarBlipManager.get(uid)
                if not RadarBlipEntity then return end
                RadarBlipEntity.SetRadius(radius)
            end,
            ["RadarBlip:Update:Alpha"] = function(uid, alpha)
                local RadarBlipEntity = API.RadarBlipManager.get(uid)
                if not RadarBlipEntity then return end
                RadarBlipEntity.SetAlpha(alpha)
            end,
            ["RadarBlip:Update:Flashing"] = function(uid, state)
                local RadarBlipEntity = API.RadarBlipManager.get(uid)
                if not RadarBlipEntity then return end
                RadarBlipEntity.SetFlashing(state)
            end,
            ["RadarBlip:Destroy"] = function(uid)
                local RadarBlipEntity = API.RadarBlipManager.get(uid)
                if not RadarBlipEntity then return end
                RadarBlipEntity.Destroy()
            end
        })

        Citizen.CreateThread(function()
            while true do

                if NetworkIsPlayerActive(PlayerId()) then
                    -- Request Data from server.
                    API.EventManager.TriggerServerLocalEvent("RadarBlip:RequestData")
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
