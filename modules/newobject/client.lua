local Manager = {}
---@type { [number]: ClientObject }
Manager.Entities = {}

---@param data MysqlObjectInterface
Manager.new = function(data)
    ---@class ClientObject
    local self = {}

    self.data = data
    self.isStreamed = false
    self.objectHandle = nil

    self.AddStream = function()
        if self.isStreamed then return end

        self.isStreamed = true

        local modelHash = GetHashKey(self.data.model)
        if not IsModelValid(modelHash) then return end

        API.Utils.Client.requestModel(modelHash)

        local obj = CreateObjectNoOffset(modelHash, self.Get.Position(), false, false, false)
        SetEntityCoordsNoOffset(obj, self.Get.Position(), false, false, false)
        SetEntityRotation(obj, self.Get.Rotation(), 2, false)
        FreezeEntityPosition(obj, true)

        self.objectHandle = obj

        TriggerEvent("onObjectStreamIn", self)

        API.Utils.Debug.Print(string.format("^3Object streamed in (%d, %s)", self.data.remoteId, self.data.model))
    end

    self.RemoveStream = function()
        if not self.isStreamed then return end

        if DoesEntityExist(self.objectHandle) then
            DeleteEntity(self.objectHandle)
        end

        self.isStreamed = false

        TriggerEvent("onObjectStreamOut", self)

        API.Utils.Debug.Print(string.format("^3Object streamed out (%d, %s)", self.data.remoteId, self.data.model))
    end

    self.Destroy = function()
        -- Delete from table.
        if Manager.exists(self.data.remoteId) then
            Manager.Entities[self.data.remoteId] = nil
        end

        if DoesEntityExist(self.objectHandle) then
            DeleteEntity(self.objectHandle)
        end

        API.Utils.Debug.Print("^3Removed object with remoteId: " .. self.data.remoteId)
    end

    self.Get = {
        Position = function()
            return vector3(self.data.x, self.data.y, self.data.z)
        end,
        Rotation = function()
            return vector3(self.data.rx, self.data.ry, self.data.rz)
        end,
        Model = function()
            return self.data.model
        end,
        Alpha = function()
            return self.data.alpha
        end,
        Hide = function()
            return self.data.hide
        end,
        Dimension = function()
            return self.data.dimension
        end,
        Variables = function()
            return self.data.variables
        end,
        Variable = function(key)
            return self.data.variables[key] or nil
        end,
        RemoteId = function()
            return self.data.remoteId
        end,
        MysqlId = function()
            return self.data.id
        end,
        Data = function()
            return self.data
        end
    }

    Manager.Entities[self.data.remoteId] = self
    API.Utils.Debug.Print("^3Created new object with remoteId: " .. self.data.remoteId)

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
        if v.data.remoteId == remoteId then
            return v
        end
    end
end

Manager.atMysqlId = function(mysqlId)
    for k, v in pairs(Manager.Entities) do
        if v.data.id == mysqlId then
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

    ObjectEntity.data.x = x
    ObjectEntity.data.y = y
    ObjectEntity.data.z = z

    if DoesEntityExist(ObjectEntity.objectHandle) then
        SetEntityCoordsNoOffset(ObjectEntity.objectHandle, ObjectEntity.Get.Position(), false, false, false)
    end
end)
RegisterNetEvent("AQUIVER:Object:Update:Rotation", function(remoteId, rx, ry, rz)
    local ObjectEntity = Manager.get(remoteId)
    if not ObjectEntity then return end

    ObjectEntity.data.rx = rx
    ObjectEntity.data.ry = ry
    ObjectEntity.data.rz = rz

    if DoesEntityExist(ObjectEntity.objectHandle) then
        SetEntityRotation(ObjectEntity.objectHandle, ObjectEntity.Get.Rotation(), 2, false)
    end
end)
RegisterNetEvent("AQUIVER:Object:Update:Model", function(remoteId, model)
    local ObjectEntity = Manager.get(remoteId)
    if not ObjectEntity then return end

    ObjectEntity.data.model = model

    -- Restream object, since we can not change the model directly on FiveM.
    ObjectEntity.RemoveStream()
    ObjectEntity.AddStream()
end)
RegisterNetEvent("AQUIVER:Object:Update:Alpha", function(remoteId, alpha)
    local ObjectEntity = Manager.get(remoteId)
    if not ObjectEntity then return end

    ObjectEntity.data.alpha = alpha

    if DoesEntityExist(ObjectEntity.objectHandle) then
        SetEntityAlpha(ObjectEntity.objectHandle, ObjectEntity.Get.Alpha(), false)
    end
end)
RegisterNetEvent("AQUIVER:Object:Update:Hide", function(remoteId, state)
    local ObjectEntity = Manager.get(remoteId)
    if not ObjectEntity then return end

    ObjectEntity.data.hide = state

    if DoesEntityExist(ObjectEntity.objectHandle) then
        SetEntityVisible(ObjectEntity.objectHandle, not ObjectEntity.Get.Hide(), 0)
        SetEntityCollision(ObjectEntity.objectHandle, not ObjectEntity.Get.Hide(), true)
    end
end)
RegisterNetEvent("AQUIVER:Object:Update:Dimension", function(remoteId, dimension)
    local ObjectEntity = Manager.get(remoteId)
    if not ObjectEntity then return end

    ObjectEntity.data.dimension = dimension

    if DoesEntityExist(ObjectEntity.objectHandle) and API.LocalPlayer.dimension ~= ObjectEntity.Get.Dimension() then
        ObjectEntity.RemoveStream()
    end
end)
RegisterNetEvent("AQUIVER:Object:Update:Variables", function(remoteId, variables)
    local ObjectEntity = Manager.get(remoteId)
    if not ObjectEntity then return end

    ObjectEntity.data.variables = variables

    -- Update the raycast & variables which is shown in the interface.
    if API.RaycastManager.AimedObjectEntity == ObjectEntity then
        TriggerEvent("onObjectRaycast", ObjectEntity)
    end
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
            if API.LocalPlayer.dimension ~= v.Get.Dimension() then
                v.RemoveStream()
            else
                local dist = #(API.LocalPlayer.CachedPosition - v.Get.Position())
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
