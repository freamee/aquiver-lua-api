---@class IRadarBlip
---@field position { x:number; y:number; z:number }
---@field radius number
---@field alpha number
---@field color number
---@field isFlashing? boolean
---@field remoteId number

local remoteIdCount = 1

local Manager = {}
---@type { [number]: ServerRadarBlip }
Manager.Entities = {}

---@param data IRadarBlip
Manager.new = function(data)
    ---@class ServerRadarBlip
    local self = {}

    local _data = data
    _data.remoteId = remoteIdCount
    remoteIdCount = remoteIdCount + 1

    self.invokedFromResource = AQUIVER_SHARED.Utils.GetInvokingResource()

    local Sync = {
        Radius = function()
            TriggerClientEvent("AQUIVER:RadarBlip:Update:Radius", -1, _data.remoteId, radius)
        end,
        Color = function()
            TriggerClientEvent("AQUIVER:RadarBlip:Update:Color", -1, _data.remoteId, color)
        end,
        Alpha = function()
            TriggerClientEvent("AQUIVER:RadarBlip:Update:Alpha", -1, _data.remoteId, alpha)
        end,
        Flashing = function()
            TriggerClientEvent("AQUIVER:RadarBlip:Update:Flashing", -1, _data.remoteId, state)
        end
    }

    self.Set = {
        Radius = function(radius)
            _data.radius = radius
            Sync.Radius()
        end,
        Color = function(colorId)
            _data.color = colorId
            Sync.Color()
        end,
        Alpha = function(alpha)
            _data.alpha = alpha
            Sync.Alpha()
        end,
        Flashing = function(state)
            _data.isFlashing = state
            Sync.Flashing()
        end
    }

    self.Get = {
        Data = function()
            return _data
        end
    }

    self.Destroy = function()
        -- Delete from table
        if Manager.exists(_data.remoteId) then
            Manager.Entities[_data.remoteId] = nil
        end

        TriggerClientEvent("AQUIVER:RadarBlip:Destroy", -1, _data.remoteId)
    end

    if Manager.exists(_data.remoteId) then
        AQUIVER_SHARED.Utils.Print("^1RadarBlip already exists with remoteId: " .. _data.remoteId)
        return
    end

    Manager.Entities[_data.remoteId] = self
    TriggerClientEvent("AQUIVER:RadarBlip:Create", -1, _data)

    return self
end

Manager.exists = function(id)
    return Manager.Entities[id] and true or false
end

Manager.get = function(id)
    return Manager.Entities[id] or nil
end

RegisterNetEvent("AQUIVER:RadarBlip:RequestData", function()
    local source = source

    for k, v in pairs(Manager.Entities) do
        TriggerClientEvent("AQUIVER:RadarBlip:Create", source, v.Get.Data())
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    for k, v in pairs(Manager.Entities) do
        if v.invokedFromResource == resourceName then
            v.Destroy()
        end
    end
end)

-- Assign to the api here.
AQUIVER_SERVER.RadarBlipManager = Manager
