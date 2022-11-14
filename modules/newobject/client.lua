local Manager = {}
---@type { [number]: ClientObject }
Manager.Entities = {}

---@param data MysqlObjectInterface
Manager.new = function(data)
    ---@class ClientObject
    local self = {}

    local _data = data

    self.isStreamed = false
    self.objectHandle = nil

    self.AddStream = function()
        if self.isStreamed then return end

        self.isStreamed = true

        local modelHash = GetHashKey(_data.model)
        if not IsModelValid(modelHash) then return end

        AQUIVER_CLIENT.Utils.RequestModel(modelHash)

        local obj = CreateObjectNoOffset(modelHash, self.Get.Position(), false, false, false)
        SetEntityCoordsNoOffset(obj, self.Get.Position(), false, false, false)
        SetEntityRotation(obj, self.Get.Rotation(), 2, false)
        FreezeEntityPosition(obj, true)

        self.objectHandle = obj

        TriggerEvent("onObjectStreamIn", self)

        AQUIVER_SHARED.Utils.Print(string.format("^3Object streamed in (%d, %s)", _data.remoteId, _data.model))
    end

    self.RemoveStream = function()
        if not self.isStreamed then return end

        if DoesEntityExist(self.objectHandle) then
            DeleteEntity(self.objectHandle)
        end

        self.isStreamed = false

        TriggerEvent("onObjectStreamOut", self)

        AQUIVER_SHARED.Utils.Print(string.format("^3Object streamed out (%d, %s)", _data.remoteId, _data.model))
    end

    self.Destroy = function()
        -- Delete from table.
        if Manager.exists(_data.remoteId) then
            Manager.Entities[_data.remoteId] = nil
        end

        if DoesEntityExist(self.objectHandle) then
            DeleteEntity(self.objectHandle)
        end

        AQUIVER_SHARED.Utils.Print("^3Removed object with remoteId: " .. _data.remoteId)
    end

    self.Set = {
        Position = function(x, y, z)
            _data.x = x
            _data.y = y
            _data.z = z

            if DoesEntityExist(self.objectHandle) then
                SetEntityCoordsNoOffset(self.objectHandle, self.Get.Position(), false, false, false)
            end
        end,
        Rotation = function(rx, ry, rz)
            _data.rx = rx
            _data.ry = ry
            _data.rz = rz

            if DoesEntityExist(self.objectHandle) then
                SetEntityRotation(self.objectHandle, self.Get.Rotation(), 2, false)
            end
        end,
        Model = function(model)
            _data.model = model

            -- Restream object, since we can not change the model directly on FiveM.
            self.RemoveStream()
            self.AddStream()
        end,
        Alpha = function(alpha)
            _data.alpha = alpha

            if DoesEntityExist(self.objectHandle) then
                SetEntityAlpha(self.objectHandle, self.Get.Alpha(), false)
            end
        end,
        Hide = function(state)
            _data.hide = state

            if DoesEntityExist(self.objectHandle) then
                SetEntityVisible(self.objectHandle, not self.Get.Hide(), 0)
                SetEntityCollision(self.objectHandle, not self.Get.Hide(), true)
            end
        end,
        Dimension = function(dimension)
            _data.dimension = dimension

            if DoesEntityExist(self.objectHandle) and AQUIVER_CLIENT.LocalPlayer.dimension ~= dimension then
                self.RemoveStream()
            end
        end,
        Variables = function(variables)
            _data.variables = variables

            -- Update the raycast & variables which is shown in the interface.
            if AQUIVER_CLIENT.RaycastManager.AimedObjectEntity == self then
                TriggerEvent("onObjectRaycast", self)
            end
        end
    }

    self.Get = {
        Position = function()
            return vector3(_data.x, _data.y, _data.z)
        end,
        Rotation = function()
            return vector3(_data.rx, _data.ry, _data.rz)
        end,
        Model = function()
            return _data.model
        end,
        Alpha = function()
            return _data.alpha
        end,
        Hide = function()
            return _data.hide
        end,
        Dimension = function()
            return _data.dimension
        end,
        Variables = function()
            return _data.variables
        end,
        Variable = function(key)
            return _data.variables[key] or nil
        end,
        RemoteId = function()
            return _data.remoteId
        end,
        MysqlId = function()
            return _data.id
        end,
        Data = function()
            return _data
        end
    }

    Manager.Entities[_data.remoteId] = self
    AQUIVER_SHARED.Utils.Print("^3Created new object with remoteId: " .. _data.remoteId)

    return self
end

Manager.atHandle = function(handleId)
    for k, v in pairs(Manager.Entities) do
        if v.objectHandle == handleId then
            return v
        end
    end
end

Manager.exists = function(id)
    return Manager.Entities[id] and true or false
end

Manager.get = function(id)
    return Manager.exists(id) and Manager.Entities[id] or nil
end

Manager.getAll = function()
    return Manager.Entities
end

Manager.atRemoteId = function(remoteId)
    for k, v in pairs(Manager.Entities) do
        if v.Get.RemoteId() == remoteId then
            return v
        end
    end
end

Manager.atMysqlId = function(mysqlId)
    for k, v in pairs(Manager.Entities) do
        if v.Get.MysqlId() == mysqlId then
            return v
        end
    end
end

Manager.GetObjectsInRange = function(vec3, model, range)
    local collectedObjects = {}

    if type(vec3) ~= "vector3" then return end

    for k, v in pairs(Manager.Entities) do
        if model then
            if v.Get.Model() == model then
                local dist = #(v.Get.Position() - vec3)
                if dist < range then
                    collectedObjects[#collectedObjects + 1] = v
                end
            end
        else
            local dist = #(v.Get.Position() - vec3)
            if dist < range then
                collectedObjects[#collectedObjects + 1] = v
            end
        end
    end

    return collectedObjects
end

Manager.GetNearestObject = function(vec3, model, range)
    local rangeMeter = range
    local closest

    if type(vec3) ~= "vector3" then return end

    for k, v in pairs(Manager.Entities) do
        if model then
            if v.Get.Model() == model then
                local dist = #(v.Get.Position() - vec3)

                if dist < rangeMeter then
                    rangeMeter = dist
                    closest = v
                end
            end
        else
            local dist = #(v.Get.Position() - vec3)

            if dist < rangeMeter then
                rangeMeter = dist
                closest = v
            end
        end
    end

    return closest
end

RegisterNetEvent("AQUIVER:Object:Create", function(data)
    Manager.new(data)
end)
RegisterNetEvent("AQUIVER:Object:Update:Position", function(remoteId, x, y, z)
    local ObjectEntity = Manager.get(remoteId)
    if not ObjectEntity then return end

    ObjectEntity.Set.Position(x, y, z)
end)
RegisterNetEvent("AQUIVER:Object:Update:Rotation", function(remoteId, rx, ry, rz)
    local ObjectEntity = Manager.get(remoteId)
    if not ObjectEntity then return end

    ObjectEntity.Set.Rotation(rx, ry, rz)
end)
RegisterNetEvent("AQUIVER:Object:Update:Model", function(remoteId, model)
    local ObjectEntity = Manager.get(remoteId)
    if not ObjectEntity then return end

    ObjectEntity.Set.Model(model)
end)
RegisterNetEvent("AQUIVER:Object:Update:Alpha", function(remoteId, alpha)
    local ObjectEntity = Manager.get(remoteId)
    if not ObjectEntity then return end

    ObjectEntity.Set.Alpha(alpha)
end)
RegisterNetEvent("AQUIVER:Object:Update:Hide", function(remoteId, state)
    local ObjectEntity = Manager.get(remoteId)
    if not ObjectEntity then return end

    ObjectEntity.Set.Hide(state)
end)
RegisterNetEvent("AQUIVER:Object:Update:Dimension", function(remoteId, dimension)
    local ObjectEntity = Manager.get(remoteId)
    if not ObjectEntity then return end

    ObjectEntity.Set.Dimension(dimension)
end)
RegisterNetEvent("AQUIVER:Object:Update:Variables", function(remoteId, variables)
    local ObjectEntity = Manager.get(remoteId)
    if not ObjectEntity then return end

    ObjectEntity.Set.Variables(variables)
end)
RegisterNetEvent("AQUIVER:Object:Destroy", function(remoteId)
    local ObjectEntity = Manager.get(remoteId)
    if not ObjectEntity then return end
    ObjectEntity.Destroy()
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for k, v in pairs(Manager.Entities) do
        v.Destroy()
    end
end)

-- Requesting objects from server on client load.
Citizen.CreateThread(function()
    while true do

        if NetworkIsPlayerActive(PlayerId()) then
            -- Request Data from server.
            TriggerServerEvent("AQUIVER:Object:RequestData")
            break
        end

        Citizen.Wait(500)
    end
end)

-- STREAMING HANDLER.
Citizen.CreateThread(function()
    while true do

        for k, v in pairs(Manager.Entities) do

            -- If dimension is not equals.
            if AQUIVER_CLIENT.LocalPlayer.dimension ~= v.Get.Dimension() then
                v.RemoveStream()
            else
                local dist = #(AQUIVER_CLIENT.LocalPlayer.CachedPosition - v.Get.Position())
                if dist < CONFIG.STREAM_DISTANCES.OBJECT then
                    v.AddStream()
                else
                    v.RemoveStream()
                end
            end
        end

        Citizen.Wait(CONFIG.STREAM_INTERVALS.OBJECT)
    end
end)

AQUIVER_CLIENT.ObjectManager = Manager
