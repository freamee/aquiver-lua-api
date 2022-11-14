local Manager = {}
---@type { [number]: ClientParticle }
Manager.Entities = {}

---@param data IParticle
Manager.new = function(data)
    ---@class ClientParticle
    local self = {}

    local _data = data

    self.particleHandle = nil
    self.isStreamed = false

    self.AddStream = function()
        if self.isStreamed then return end

        self.isStreamed = true

        RequestNamedPtfxAsset(_data.particleDict)
        while not HasNamedPtfxAssetLoaded(_data.particleDict) do
            Citizen.Wait(10)
        end

        UseParticleFxAssetNextCall(_data.particleDict)

        if self.IsObjectParticle() then
            local findObject = AQUIVER_CLIENT.ObjectManager.get(_data.toObjectRemoteId)
            if findObject then
                if DoesEntityExist(findObject.objectHandle) then
                    self.particleHandle = StartParticleFxLoopedOnEntity(
                        _data.particleName,
                        findObject.objectHandle,
                        _data.offset.x,
                        _data.offset.y,
                        _data.offset.z,
                        _data.rotation.x,
                        _data.rotation.y,
                        _data.rotation.z,
                        _data.scale,
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
            self.particleHandle = StartParticleFxLoopedAtCoord(
                _data.particleName,
                _data.position.x,
                _data.position.y,
                _data.position.z,
                _data.rotation.x,
                _data.rotation.y,
                _data.rotation.z,
                _data.scale,
                false,
                false,
                false,
                false
            )
        end

        AQUIVER_SHARED.Utils.Print(string.format("^3Particle streamed in (%d, %s, %s)", _data.remoteId,
            _data.particleName, _data.particleUid))
    end

    self.RemoveStream = function()
        if not self.isStreamed then return end

        self.isStreamed = false

        if DoesParticleFxLoopedExist(self.particleHandle) then
            StopParticleFxLooped(self.particleHandle, false)
            self.particleHandle = nil
        end

        AQUIVER_SHARED.Utils.Print(string.format("^3Particle streamed out (%d, %s, %s)", _data.remoteId,
            _data.particleName, _data.particleUid))
    end

    self.IsObjectParticle = function()
        return type(_data.toObjectRemoteId) == "number" and true or false
    end

    self.Get = {
        Position = function()
            return vector3(_data.position.x, _data.position.y, _data.position.z)
        end,
        Rotation = function()
            return vector3(_data.rotation.x, _data.rotation.y, _data.rotation.z)
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

        if DoesParticleFxLoopedExist(self.particleHandle) then
            StopParticleFxLooped(self.particleHandle, false)
        end

        AQUIVER_SHARED.Utils.Print("^3Removed particle with remoteId: " .. _data.remoteId)
    end


    -- Execute add stream instantly
    if self.IsObjectParticle() then
        self.AddStream()
    end

    Manager.Entities[_data.remoteId] = self

    AQUIVER_SHARED.Utils.Print("^3Created new particle with remoteId: " .. _data.remoteId)

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

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for k, v in pairs(Manager.Entities) do
        v.Destroy()
    end
end)

RegisterNetEvent("AQUIVER:Particle:Create", function(data)
    Manager.new(data)
end)
RegisterNetEvent("AQUIVER:Particle:Destroy", function(remoteId)
    local ParticleEntity = Manager.get(remoteId)
    if not ParticleEntity then return end
    ParticleEntity.Destroy()
end)
AddEventHandler("onObjectStreamIn", function(ObjectEntity)
    for k, v in pairs(Manager.Entities) do
        if v.Get.Data().toObjectRemoteId == ObjectEntity.data.remoteId then
            v.AddStream()
        end
    end
end)

AddEventHandler("onObjectStreamOut", function(ObjectEntity)
    for k, v in pairs(Manager.Entities) do
        if v.Get.Data().toObjectRemoteId == ObjectEntity.data.remoteId then
            v.RemoveStream()
        end
    end
end)

Citizen.CreateThread(function()
    while true do

        if NetworkIsPlayerActive(PlayerId()) then
            -- Request Data from server.
            TriggerServerEvent("AQUIVER:Particle:RequestData")
            break
        end

        Citizen.Wait(500)
    end
end)

Citizen.CreateThread(function()
    while true do

        for k, v in pairs(Manager.Entities) do
            if not v.IsObjectParticle() then

                if AQUIVER_CLIENT.LocalPlayer.dimension ~= v.Get.Data().dimension then
                    v.RemoveStream()
                else
                    local dist = #(AQUIVER_CLIENT.LocalPlayer.CachedPosition - v.Get.Position())
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


AQUIVER_CLIENT.ParticleManager = Manager
