---@class CParticleModule
local Module = {}
---@type { [number]: CAquiverParticle }
Module.Entities = {}

---@class CAquiverParticle
local Particle = {
    ---@type IParticle
    data = {},
    particleHandle = nil,
    isStreamed = false
}
Particle.__index = Particle

---@param d IParticle
Particle.new = function(d)
    local self = setmetatable({}, Particle)

    self.data = d
    self.particleHandle = nil
    self.isStreamed = false

    self:__init__()

    if Module:exists(self.data.remoteId) then
        Shared.Utils:Print("^1Particle already exists with remoteId: " .. self.data.remoteId)
        return
    end

    Module.Entities[self.data.remoteId] = self

    Shared.Utils:Print("^3Created new particle with remoteId: " .. self.data.remoteId)

    return self
end

function Particle:__init__()
    -- Execute add stream instantly
    if self:isObjectParticle() then
        self:addStream()
    end
end

function Particle:Destroy()
    if Module:exists(self.data.remoteId) then
        Module.Entities[self.data.remoteId] = nil
    end

    if DoesParticleFxLoopedExist(self.particleHandle) then
        StopParticleFxLooped(self.particleHandle, false)
    end

    Shared.Utils:Print("^3Removed particle with remoteId: " .. self.data.remoteId)
end

function Particle:isObjectParticle()
    return type(self.data.toObjectRemoteId) == "number" and true or false
end

function Particle:addStream()
    if self.isStreamed then return end

    self.isStreamed = true

    RequestNamedPtfxAsset(self.data.particleDict)
    while not HasNamedPtfxAssetLoaded(self.data.particleDict) do
        Citizen.Wait(10)
    end

    UseParticleFxAssetNextCall(self.data.particleDict)

    if self:isObjectParticle() then
        local aObject = Client.ObjectManager:get(self.data.toObjectRemoteId)
        if aObject and DoesEntityExist(aObject.objectHandle) then
            self.particleHandle = StartParticleFxLoopedOnEntity(
                self.data.particleName,
                aObject.objectHandle,
                self.data.offset.x,
                self.data.offset.y,
                self.data.offset.z,
                self.data.rotation.x,
                self.data.rotation.y,
                self.data.rotation.z,
                self.data.scale,
                false,
                false,
                false
            )
        else
            -- If object is not exists yet, we set the isStreamed to false.
            -- This fixes the issue, that after restarting the script, the particles wont show up.
            self.isStreamed = false
        end
    else
        self.particleHandle = StartParticleFxLoopedAtCoord(
            self.data.particleName,
            self.data.position.x,
            self.data.position.y,
            self.data.position.z,
            self.data.rotation.x,
            self.data.rotation.y,
            self.data.rotation.z,
            self.data.scale,
            false,
            false,
            false,
            false
        )
    end

    Shared.Utils:Print(string.format("^3Particle streamed in (%d, %s, %s)", self.data.remoteId,
        self.data.particleName, self.data.particleUid))
end

function Particle:removeStream()
    if not self.isStreamed then return end

    self.isStreamed = false

    if DoesParticleFxLoopedExist(self.particleHandle) then
        StopParticleFxLooped(self.particleHandle, false)
        self.particleHandle = nil
    end

    Shared.Utils:Print(string.format("^3Particle streamed out (%d, %s, %s)", self.data.remoteId, self.data.particleName,
        self.data.particleUid))
end

function Particle:getVector3Position()
    return vector3(self.data.position.x, self.data.position.y, self.data.position.z)
end

---@param vec3 { x:number; y:number; z: number; }
function Particle:dist(vec3)
    return #(self:getVector3Position() - vector3(vec3.x, vec3.y, vec3.z))
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

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for k, v in pairs(Module.Entities) do
        v:Destroy()
    end
end)

Shared.EventManager:RegisterModuleEvent({
    ["onObjectStreamIn"] = function(remoteId)
        -- Create particle(s) on object stream in.
        for k, v in pairs(Module.Entities) do
            if v.data.toObjectRemoteId == remoteId then
                v:addStream()
            end
        end
    end,
    ["onObjectStreamOut"] = function(remoteId)
        for k, v in pairs(Module.Entities) do
            if v.data.toObjectRemoteId == remoteId then
                v:removeStream()
            end
        end
    end
})

Shared.EventManager:RegisterModuleNetworkEvent({
    ["Particle:Create"] = function(data)
        Module:new(data)
    end,
    ["Particle:Destroy"] = function(remoteId)
        local aParticle = Module:get(remoteId)
        if not aParticle then return end
        aParticle:Destroy()
    end
})

Citizen.CreateThread(function()
    while true do

        if NetworkIsPlayerActive(PlayerId()) then
            -- Request Data from server.
            Shared.EventManager:TriggerModuleServerEvent("Particle:RequestData")
            break
        end

        Citizen.Wait(500)
    end
end)

Citizen.CreateThread(function()
    while true do

        for k, v in pairs(Module.Entities) do
            if not v:isObjectParticle() then
                if Client.LocalPlayer.dimension ~= v.data.dimension then
                    v:removeStream()
                else
                    local dist = v:dist(Client.LocalPlayer.cachedPosition)
                    if dist < Shared.Config.STREAM_DISTANCES.PARTICLE then
                        v:addStream()
                    else
                        v:removeStream()
                    end
                end
            end
        end

        Citizen.Wait(Shared.Config.STREAM_INTERVALS.PARTICLE)
    end
end)

return Module
