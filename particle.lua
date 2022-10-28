API.ParticleManager = {}
---@type table <number, CParticle>
API.ParticleManager.Entities = {}
API.ParticleManager.remoteIdCount = 1

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

---@param data IParticle
API.ParticleManager.new = function(data)
    ---@class CParticle
    local self = {}

    self.data = data

    if API.IsServer then
        self.server = {}
        self.server.invokedFromResource = API.InvokeResourceName()
        self.data.remoteId = API.ParticleManager.remoteIdCount
        API.ParticleManager.remoteIdCount = (API.ParticleManager.remoteIdCount or 0) + 1

        API.EventManager.TriggerClientLocalEvent("Particle:Create", -1, self.data)
    else
        self.client = {}
        self.client.particleHandle = nil
        self.client.isStreamed = false

        self.AddStream = function()
            if self.client.isStreamed then return end

            self.client.isStreamed = true

            RequestNamedPtfxAsset(self.data.particleDict)
            while not HasNamedPtfxAssetLoaded(self.data.particleDict) do
                Citizen.Wait(10)
            end

            UseParticleFxAssetNextCall(self.data.particleDict)

            if self.IsObjectParticle() then
                local findObject = API.ObjectManager.get(self.data.toObjectRemoteId)
                if findObject then
                    if DoesEntityExist(findObject.client.objectHandle) then
                        self.client.particleHandle = StartParticleFxLoopedOnEntity(
                            self.data.particleName,
                            findObject.client.objectHandle,
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
                end
            else
                self.client.particleHandle = StartParticleFxLoopedAtCoord(
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

            API.Utils.Debug.Print(string.format("^3Particle streamed in (%d, %s, %s)", self.data.remoteId,
                self.data.particleName, self.data.particleUid))
        end

        self.RemoveStream = function()
            if not self.client.isStreamed then return end

            if DoesParticleFxLoopedExist(self.client.particleHandle) then
                StopParticleFxLooped(self.client.particleHandle, false)
                self.client.particleHandle = nil
            end

            self.client.isStreamed = false

            API.Utils.Debug.Print(string.format("^3Particle streamed out (%d, %s, %s)", self.data.remoteId,
                self.data.particleName, self.data.particleUid))
        end
    end

    self.GetPositionVector3 = function()
        return vector3(self.data.position.x, self.data.position.y, self.data.position.z)
    end

    self.GetRotationVector3 = function()
        return vector3(self.data.rotation.x, self.data.rotation.y, self.data.rotation.z)
    end

    self.IsObjectParticle = function()
        if type(self.data.toObjectRemoteId) == "number" then
            return true
        end
        return false
    end

    self.Destroy = function()
        -- Delete from table.
        if API.ParticleManager.Entities[self.data.remoteId] then
            API.ParticleManager.Entities[self.data.remoteId] = nil
        end

        if API.IsServer then
            API.EventManager.TriggerClientLocalEvent("Particle:Destroy", -1, self.data.remoteId)
        else
            if DoesEntityExist(self.client.particleHandle) then
                DeleteEntity(self.client.particleHandle)
            end
        end

        API.Utils.Debug.Print("^3Removed particle with remoteId: " .. self.data.remoteId)
    end

    -- Start timeout if the timeMS is specified.
    if type(data.timeMS) == "number" then
        Citizen.SetTimeout(data.timeMS, function()
            if self then self.Destroy() end
        end)
    end

    API.ParticleManager.Entities[self.data.remoteId] = self

    API.Utils.Debug.Print("^3Created new particle with remoteId: " .. self.data.remoteId)

    return self
end

API.ParticleManager.exists = function(remoteId)
    if API.ParticleManager.Entities[remoteId] then
        return true
    end
end

API.ParticleManager.get = function(remoteId)
    if API.ParticleManager.exists(remoteId) then
        return API.ParticleManager.Entities[remoteId]
    end
end

API.ParticleManager.getAll = function()
    return API.ParticleManager.Entities
end

if API.IsServer then
    AddEventHandler("onResourceStart", function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end

        API.EventManager.AddLocalEvent("Particle:RequestData", function()
            local source = source

            for k, v in pairs(API.ParticleManager.Entities) do
                API.EventManager.TriggerClientLocalEvent("Particle:Create", source, v.data)
            end
        end)
    end)

    AddEventHandler("onResourceStop", function(resourceName)
        for k, v in pairs(API.ParticleManager.Entities) do
            if v.server.invokedFromResource == resourceName then
                v.Destroy()
            end
        end
    end)
else
    AddEventHandler("onResourceStop", function(resourceName)
        if resourceName ~= GetCurrentResourceName() then return end

        for k, v in pairs(API.ParticleManager.Entities) do
            v.Destroy()
        end
    end)

    AddEventHandler("onClientResourceStart", function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end

        API.EventManager.AddLocalEvent({
            ["Particle:Create"] = function(data)
                API.ParticleManager.new(data)
            end,
            ["Particle:Destroy"] = function(remoteId)
                local ParticleEntity = API.ParticleManager.get(remoteId)
                if not ParticleEntity then return end
                ParticleEntity.Destroy()
            end
        })

        API.EventManager.AddGlobalEvent({
            ---@param ObjectEntity CObject
            ["onObjectStreamIn"] = function(ObjectEntity)
                for k, v in pairs(API.ParticleManager.Entities) do
                    if v.data.toObjectRemoteId == ObjectEntity.data.remoteId then
                        v.AddStream()
                    end
                end
            end,
            ---@param ObjectEntity CObject
            ["onObjectStreamOut"] = function(ObjectEntity)
                for k, v in pairs(API.ParticleManager.Entities) do
                    if v.data.toObjectRemoteId == ObjectEntity.data.remoteId then
                        v.RemoveStream()
                    end
                end
            end
        })

        Citizen.CreateThread(function()
            while true do

                if NetworkIsPlayerActive(PlayerId()) then
                    -- Request Data from server.
                    API.EventManager.TriggerServerLocalEvent("Particle:RequestData")
                    break
                end

                Citizen.Wait(500)
            end
        end)

        Citizen.CreateThread(function()
            while true do

                local playerPos = GetEntityCoords(PlayerPedId())

                for k, v in pairs(API.ParticleManager.Entities) do
                    if not v.IsObjectParticle() then

                        if API.LocalPlayer.dimension ~= v.data.dimension then
                            v.RemoveStream()
                        else
                            local dist = #(playerPos - v.GetPositionVector3())
                            if dist < CONFIG.STREAM_DISTANCES.PARTICLE then
                                v.AddStream()
                            else
                                v.RemoveStream()
                            end
                        end
                    end
                end

                Citizen.Wait(CONFIG.STREAM_INTERVALS.PARTICLE)
            end
        end)
    end)
end
