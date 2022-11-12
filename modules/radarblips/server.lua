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

    self.data = data
    self.invokedFromResource = API.InvokeResourceName()
    self.data.remoteId = remoteIdCount
    remoteIdCount = remoteIdCount + 1

    self.Set = {
        Radius = function(radius)
            self.data.radius = radius
            self.Sync.Radius()
        end,
        Color = function(colorId)
            self.data.color = colorId
            self.Sync.Color()
        end,
        Alpha = function(alpha)
            self.data.alpha = alpha
            self.Sync.Alpha()
        end,
        Flashing = function(state)
            self.data.isFlashing = state
            self.Sync.Flashing()
        end
    }

    self.Sync = {
        Radius = function()
            TriggerClientEvent("AQUIVER:RadarBlip:Update:Radius", -1, self.data.remoteId, radius)
        end,
        Color = function()
            TriggerClientEvent("AQUIVER:RadarBlip:Update:Color", -1, self.data.remoteId, color)
        end,
        Alpha = function()
            TriggerClientEvent("AQUIVER:RadarBlip:Update:Alpha", -1, self.data.remoteId, alpha)
        end,
        Flashing = function()
            TriggerClientEvent("AQUIVER:RadarBlip:Update:Flashing", -1, self.data.remoteId, state)
        end
    }

    self.Destroy = function()
        -- Delete from table
        if Manager.exists(self.data.remoteId) then
            Manager.Entities[self.data.remoteId] = nil
        end

        TriggerClientEvent("AQUIVER:RadarBlip:Destroy", -1, self.data.remoteId)
    end

    if Manager.exists(self.data.remoteId) then
        API.Utils.Debug.Print("^1RadarBlip already exists with remoteId: " .. self.data.remoteId)
        return
    end

    Manager.Entities[self.data.remoteId] = self
    TriggerClientEvent("AQUIVER:RadarBlip:Create", -1, self.data)

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

RegisterNetEvent("AQUIVER:RadarBlip:RequestData", function()
    local source = source

    for k, v in pairs(Manager.Entities) do
        TriggerClientEvent("AQUIVER:RadarBlip:Create", source, v.data)
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
