---@class IActionShape
---@field position { x:number; y:number; z:number; }
---@field color { r:number; g:number; b:number; a:number; }
---@field sprite number
---@field range number
---@field dimension number
---@field variables table
---@field remoteId number

local remoteIdCount = 1

local Manager = {}
---@type { [number]: ServerActionShape }
Manager.Entities = {}

---@param data IActionShape
Manager.new = function(data)
    ---@class ServerActionShape
    local self = {}

    self.data = data
    self.data.variables = type(self.data.variables) == "table" and self.data.variables or {}
    self.invokedFromResource = AQUIVER_SHARED.Utils.GetInvokingResource()
    self.data.remoteId = remoteIdCount
    remoteIdCount = remoteIdCount + 1

    self.Set = {
        Position = function(vec3)
            self.data.position = vec3
            self.Sync.Position()
        end,
        Variable = function(key, value)
            self.data.variables[key] = value
            self.Sync.Variables()
        end
    }

    self.Get = {
        Position = function()
            return vector3(self.data.position.x, self.data.position.y, self.data.position.z)
        end,
        Variable = function(key)
            return self.data.variables[key]
        end,
        GetData = function()
            return self.data
        end
    }

    self.Sync = {
        Position = function()
            TriggerClientEvent("AQUIVER:ActionShape:Update:Position", -1, self.data.remoteId, self.data.position)
        end,
        Variables = function()
            TriggerClientEvent("AQUIVER:ActionShape:Update:Variable", -1, self.data.remoteId, self.data.variables)
        end
    }

    self.Destroy = function()
        -- Delete from table.
        if Manager.exists(self.data.remoteId) then
            Manager.Entities[self.data.remoteId] = nil
        end

        TriggerClientEvent("AQUIVER:ActionShape:Destroy", -1, self.data.remoteId)

        AQUIVER_SHARED.Utils.Print("^3Removed ActionShape with remoteId: " .. self.data.remoteId)
    end

    TriggerClientEvent("AQUIVER:ActionShape:Create", -1, self.data)

    Manager.Entities[self.data.remoteId] = self

    AQUIVER_SHARED.Utils.Print("^3Created new actionshape with remoteId: " .. self.data.remoteId)

    return self
end

Manager.exists = function(remoteId)
    return Manager.Entities[remoteId] and true or false
end

Manager.get = function(remoteId)
    return Manager.Entities[remoteId] or nil
end

Manager.getAll = function()
    return Manager.Entities
end

RegisterNetEvent("AQUIVER:ActionShape:RequestData", function()
    local source = source

    for k, v in pairs(Manager.Entities) do
        TriggerClientEvent("AQUIVER:ActionShape:Create", source, v.data)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    for k, v in pairs(Manager.Entities) do
        if v.invokedFromResource == resourceName then
            v.Destroy()
        end
    end
end)

AQUIVER_SERVER.ActionShapeManager = Manager
