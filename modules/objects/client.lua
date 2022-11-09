---@param data MysqlObjectInterface
local new = function(data)
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

        local obj = CreateObjectNoOffset(modelHash, self.GetPositionVector3(), false, false, false)
        SetEntityCoordsNoOffset(obj, self.GetPositionVector3(), false, false, false)
        SetEntityRotation(obj, self.GetRotationVector3(), 2, false)
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

    self.GetRotationVector3 = function()
        return vector3(self.data.rx, self.data.ry, self.data.rz)
    end

    self.GetPositionVector3 = function()
        return vector3(self.data.x, self.data.y, self.data.z)
    end

    API.Objects.Entities[self.data.remoteId] = self

    API.Utils.Debug.Print("^3Created new object with remoteId: " .. self.data.remoteId)
end

RegisterNetEvent("AQUIVER:Object:Create", function(data)
    new(data)
end)
RegisterNetEvent("AQUIVER:Object:Update:Position", function(remoteId, x, y, z)
    local Object = API.Objects.get(remoteId) --[[@as ClientObject]]
    if not Object then return end

    Object.data.x = x
    Object.data.y = y
    Object.data.z = z

    if DoesEntityExist(Object.objectHandle) then
        SetEntityCoordsNoOffset(Object.objectHandle, Object.GetPositionVector3(), false, false, false)
    end
end)