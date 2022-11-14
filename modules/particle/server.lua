---@class IParticle
---@field remoteId? number
---@field particleDict string
---@field particleName string
---@field scale number
---@field dimension number
---@field position? { x:number; y:number; z:number; }
---@field rotation { x:number; y:number; z:number; }
---@field offset? { x:number; y:number; z:number; }
---@field toObjectRemoteId? number
---@field particleUid? string
---@field timeMS? number

local remoteIdCount = 1
local Manager = {}

---@type { [number]: ServerParticle }
Manager.Entities = {}

---@param data IParticle
Manager.new = function(data)
    ---@class ServerParticle
    local self = {}

    self.data = data
    self.invokedFromResource = AQUIVER_SHARED.Utils.GetInvokingResource()
    self.data.remoteId = remoteIdCount
    remoteIdCount = remoteIdCount + 1

    if Manager.exists(self.data.remoteId) then
        AQUIVER_SHARED.Utils.Print("^Particle already exists with remoteId: " .. self.data.remoteId)
        return
    end

    self.Get = {
        Position = function()
            return vector3(self.data.position.x, self.data.position.y, self.data.position.z)
        end,
        Rotation = function()
            return vector3(self.data.rotation.x, self.data.rotation.y, self.data.rotation.z)
        end
    }

    self.Destroy = function()
        -- Delete from table.
        if Manager.exists(self.data.remoteId) then
            Manager.Entities[self.data.remoteId] = nil
        end

        TriggerClientEvent("AQUIVER:Particle:Destroy", -1, self.data.remoteId)

        AQUIVER_SHARED.Utils.Print("^3Removed particle with remoteId: " .. self.data.remoteId)
    end

    TriggerClientEvent("AQUIVER:Particle:Create", -1, self.data)

    Manager.Entities[self.data.remoteId] = self
    AQUIVER_SHARED.Utils.Print("^3Created new particle with remoteId: " .. self.data.remoteId)

    -- Start timeout if the timeMS is specified.
    if type(self.data.timeMS) == "number" then
        Citizen.SetTimeout(self.data.timeMS, function()
            if self then self.Destroy() end
        end)
    end

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

Manager.ObjectGetParticleByUid = function(remoteId, uid)
    for k, v in pairs(Manager.Entities) do
        if v.data.toObjectRemoteId == remoteId and v.data.particleUid == uid then
            return v
        end
    end
    return nil
end

Manager.ObjectHasParticleUid = function(remoteId, uid)
    for k, v in pairs(Manager.Entities) do
        if v.data.toObjectRemoteId == remoteId and v.data.particleUid == uid then
            return true
        end
    end
    return false
end

RegisterNetEvent("AQUIVER:Particle:RequestData", function()
    local source = source

    for k, v in pairs(Manager.Entities) do
        TriggerClientEvent("AQUIVER:Particle:Create", source, v.data)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    for k, v in pairs(Manager.Entities) do
        if v.invokedFromResource == resourceName then
            v.Destroy()
        end
    end
end)

AddEventHandler("onObjectDestroyed", function(Object)
    -- Destroy particle if the object got destroyed.
    for k, v in pairs(Manager.Entities) do
        if v.data.toObjectRemoteId == Object.data.remoteId then
            v.Destroy()
        end
    end
end)

AQUIVER_SERVER.ParticleManager = Manager
