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

    local _data = data
    _data.variables = type(_data.variables) == "table" and _data.variables or {}
    _data.remoteId = remoteIdCount
    remoteIdCount = remoteIdCount + 1

    self.invokedFromResource = AQUIVER_SHARED.Utils.GetInvokingResource()

    local Sync = {
        Position = function()
            TriggerClientEvent("AQUIVER:ActionShape:Update:Position", -1, _data.remoteId, _data.position)
        end,
        Variables = function()
            TriggerClientEvent("AQUIVER:ActionShape:Update:Variables", -1, _data.remoteId, _data.variables)
        end
    }

    self.Set = {
        Position = function(vec3)
            _data.position = vec3
            Sync.Position()
        end,
        Variable = function(key, value)
            _data.variables[key] = value
            Sync.Variables()
        end
    }

    self.Get = {
        Position = function()
            return vector3(_data.position.x, _data.position.y, _data.position.z)
        end,
        Variable = function(key)
            return _data.variables[key]
        end,
        Data = function()
            return _data
        end
    }

    self.Destroy = function()
        -- Delete from table.
        if Manager.exists(_data.remoteId) then
            Manager.Entities[_data.remoteId] = nil
        end

        TriggerClientEvent("AQUIVER:ActionShape:Destroy", -1, _data.remoteId)

        AQUIVER_SHARED.Utils.Print("^3Removed ActionShape with remoteId: " .. _data.remoteId)
    end

    TriggerClientEvent("AQUIVER:ActionShape:Create", -1, _data)

    Manager.Entities[_data.remoteId] = self

    AQUIVER_SHARED.Utils.Print("^3Created new actionshape with remoteId: " .. _data.remoteId)

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
        TriggerClientEvent("AQUIVER:ActionShape:Create", source, v.Get.Data())
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
