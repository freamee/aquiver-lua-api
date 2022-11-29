---@class SParticleModule
local Module = {}
---@type { [number]: SAquiverParticle }
Module.Entities = {}

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

---@class SAquiverParticle
local Particle = {
    ---@type IParticle
    data = {}
}
Particle.__index = Particle

---@param d IParticle
Particle.new = function(d)
    local self = setmetatable({}, Particle)

    self.data = d
    self.data.remoteId = remoteIdCount
    remoteIdCount = (remoteIdCount or 0) + 1

    if Module:exists(self.data.remoteId) then
        Shared.Utils:Print("^1Particle already exists with remoteID: " .. self.data.remoteId)
        return
    end

    self:__init__()

    Module.Entities[self.data.remoteId] = self

    Shared.EventManager:TriggerModuleClientEvent("Particle:Create", -1, self.data)

    Shared.Utils:Print("^3Created new Particle with remoteID: " .. self.data.remoteId)

    return self
end

function Particle:__init__()
    -- Start timeout if the timeMS is specified.
    if type(self.data.timeMS) == "number" then
        Citizen.SetTimeout(self.data.timeMS, function()
            if self then self:Destroy() end
        end)
    end
end

function Particle:Destroy()
    if Module:exists(self.data.remoteId) then
        Module.Entities[self.data.remoteId] = nil
    end

    Shared.EventManager:TriggerModuleClientEvent("Particle:Destroy", -1, self.data.remoteId)

    Shared.Utils:Print("^3Removed particle with remoteId: " .. self.data.remoteId)
end

---@param d IParticle
function Module:new(d)
    local aParticle = Particle.new(d)
    if aParticle then
        return aParticle
    end
end

function Module:exists(remoteId)
    return self.Entities[remoteId] and true or false
end

function Module:get(remoteId)
    return self.Entities[remoteId] or nil
end

function Module:getObjectParticleByUid(objectRemoteId, particleUid)
    for k, v in pairs(self.Entities) do
        if v.data.toObjectRemoteId == objectRemoteId and v.data.particleUid == particleUid then
            return v
        end
    end
end

function Module:hasObjectParticleByUid(objectRemoteId, particleUid)
    for k, v in pairs(self.Entities) do
        if v.data.toObjectRemoteId == objectRemoteId and v.data.particleUid == particleUid then
            return true
        end
    end
    return false
end

Shared.EventManager:RegisterModuleNetworkEvent("Particle:RequestData", function()
    local source = source

    for k, v in pairs(Module.Entities) do
        Shared.EventManager:TriggerModuleClientEvent("Particle:Create", source, v.data)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for k, v in pairs(Module.Entities) do
        v:Destroy()
    end
end)

---@param resourceName string
---@param remoteId number
AddEventHandler("onObjectDestroyed", function(resourceName, remoteId)
    if resourceName ~= GetCurrentResourceName() then return end

    -- Destroy particle if the object got destroyed.
    for k, v in pairs(Module.Entities) do
        if v.data.toObjectRemoteId == remoteId then
            v:Destroy()
        end
    end
end)

return Module
