---@class CObjectsModule
local Module = {}
---@type { [number]: CAquiverObject }
Module.Entities = {}

---@class CAquiverObject
local Object = {
    ---@type MysqlObjectInterface
    data = {},
    isStreamed = false,
    objectHandle = nil
}
Object.__index = Object

---@param d MysqlObjectInterface
Object.new = function(d)
    local self = setmetatable({}, Object)

    self.data = d
    self.isStreamed = false
    self.objectHandle = nil

    self:__init__()

    if Module:exists(self.data.remoteId) then
        -- AQUIVER_SHARED.Utils.Print("^1Object already exists with remoteId: " .. self.data.remoteId)
        return
    end

    Module.Entities[self.data.remoteId] = self

    -- AQUIVER_SHARED.Utils.Print("^3Created new object with remoteId: " .. self.data.remoteId)

    return self
end

function Object:__init__()

end

function Object:getVector3Position()
    return vector3(self.data.x, self.data.y, self.data.z)
end

function Object:getVector3Rotation()
    return vector3(self.data.rx, self.data.ry, self.data.rz)
end

---@param vec3 { x:number; y:number; z: number; }
function Object:dist(vec3)
    return #(self:getVector3Position() - vector3(vec3.x, vec3.y, vec3.z))
end

function Object:addStream()
    if self.isStreamed then return end

    self.isStreamed = true

    local modelHash = GetHashKey(self.data.model)
    if not IsModelValid(modelHash) then return end

    Client.Utils:RequestModel(modelHash)

    local obj = CreateObjectNoOffset(modelHash, self:getVector3Position(), false, false, false)
    SetEntityCoords(obj, self:getVector3Position(), false, false, false, false)
    SetEntityRotation(obj, self:getVector3Rotation(), 2, false)
    FreezeEntityPosition(obj, true)

    self.objectHandle = obj

    self:initAttachments()

    TriggerEvent("onObjectStreamIn", self)

    -- AQUIVER_SHARED.Utils.Print(string.format("^3Object streamed in (%d, %s)", _data.remoteId, _data.model))
end

function Object:removeStream()
    if not self.isStreamed then return end

    if DoesEntityExist(self.objectHandle) then
        DeleteEntity(self.objectHandle)
    end

    self.isStreamed = false

    self:shutdownAttachments()

    TriggerEvent("onObjectStreamOut", self)

    -- AQUIVER_SHARED.Utils.Print(string.format("^3Object streamed out (%d, %s)", _data.remoteId, _data.model))
end

function Object:shutdownAttachments()
    for k, v in pairs(self.data.attachments) do
        self:removeAttachment(k)
    end
end

function Object:initAttachments()
    for k, v in pairs(self.data.attachments) do
        self:addAttachment(k)
    end
end

function Object:hasAttachment(attachmentName)
    return self.data.attachments[attachmentName] and true or false
end

function Object:addAttachment(attachmentName)
    if self:hasAttachment(attachmentName) then return end

    -- local aData = AQUIVER_SHARED.AttachmentManager.get(attachmentName)
    -- if not aData then return end

    -- local modelHash = GetHashKey(aData.model)
    -- AQUIVER_CLIENT.Utils.RequestModel(modelHash)

    -- local obj = CreateObject(modelHash, self.Get.Position(), false, false, false)

    -- while not DoesEntityExist(self.objectHandle) do
    --     Citizen.Wait(50)
    -- end

    -- AttachEntityToEntity(
    --     obj,
    --     self.objectHandle,
    --     0,
    --     aData.x, aData.y, aData.z,
    --     aData.rx, aData.ry, aData.rz,
    --     true, true, false, false, 2, true
    -- )

    -- _attachments[attachmentName] = obj

    -- AQUIVER_SHARED.Utils.Print(string.format("^3Object attachment added (%d, %s, %s)", _data.remoteId,
    --     _data.model,
    --     attachmentName))
end

function Object:removeAttachment(attachmentName)
    if not self:hasAttachment(attachmentName) then return end

    -- if DoesEntityExist(_attachments[attachmentName]) then
    --     DeleteEntity(_attachments[attachmentName])
    -- end

    -- _attachments[attachmentName] = nil

    -- AQUIVER_SHARED.Utils.Print(string.format("^3Object attachment removed (%d, %s, %s)", _data.remoteId, _data.model
    --     , attachmentName))
end

function Object:Destroy()
    if Module:exists(self.data.remoteId) then
        Module.Entities[self.data.remoteId] = nil
    end

    if DoesEntityExist(self.objectHandle) then
        DeleteEntity(self.objectHandle)
    end

    self:shutdownAttachments()

    -- AQUIVER_SHARED.Utils.Print("^3Removed object with remoteId: " .. _data.remoteId)
end

---@param d MysqlObjectInterface
function Module:new(d)
    local nObject = Object.new(d)
    if nObject then
        return nObject
    end
end

function Module:exists(remoteId)
    return self.Entities[remoteId] and true or false
end

function Module:get(remoteId)
    return self:exists(remoteId) and self.Entities[remoteId] or nil
end

function Module:atHandle(handleId)
    for k, v in pairs(self.Entities) do
        if v.objectHandle == handleId then
            return v
        end
    end
end

function Module:atRemoteId(remoteId)
    for k, v in pairs(self.Entities) do
        if v.data.remoteId == remoteId then
            return v
        end
    end
end

function Module:atMysqlId(mysqlId)
    for k, v in pairs(self.Entities) do
        if v.data.id == mysqlId then
            return v
        end
    end
end

function Module:getObjectsInRange(vec3, model, range)
    local collectedObjects = {}

    if type(vec3) ~= "vector3" then return end

    for k, v in pairs(self.Entities) do
        if model then
            if v.data.model == model then
                local dist = v:dist(vec3)
                if dist < range then
                    collectedObjects[#collectedObjects + 1] = v
                end
            end
        else
            local dist = v:dist(vec3)
            if dist < range then
                collectedObjects[#collectedObjects + 1] = v
            end
        end
    end

    return collectedObjects
end

function Module:getNearestObject(vec3, model, range)
    local rangeMeter = range
    local closest

    if type(vec3) ~= "vector3" then return end

    for k, v in pairs(self.Entities) do
        if model then
            if v.data.model == model then
                local dist = v:dist(vec3)
                if dist < rangeMeter then
                    rangeMeter = dist
                    closest = v
                end
            end
        else
            local dist = v:dist(vec3)
            if dist < rangeMeter then
                rangeMeter = dist
                closest = v
            end
        end
    end

    return closest
end

RegisterNetEvent(GetCurrentResourceName() .. "AQUIVER:Object:Create", function(d)
    Module:new(d)
end)
RegisterNetEvent(GetCurrentResourceName() .. "AQUIVER:Object:Destroy", function(remoteId)
    local aObject = Module:get(remoteId)
    if not aObject then return end
    aObject:Destroy()
end)
RegisterNetEvent(GetCurrentResourceName() .. "AQUIVER:Object:Update:Position", function(remoteId, x, y, z)
    local aObject = Module:get(remoteId)
    if not aObject then return end

    aObject.data.x = x
    aObject.data.y = y
    aObject.data.z = z

    if DoesEntityExist(aObject.objectHandle) then
        SetEntityCoords(aObject.objectHandle, aObject:getVector3Position(), false, false, false, false)
    end
end)
RegisterNetEvent(GetCurrentResourceName() .. "AQUIVER:Object:Update:Rotation", function(remoteId, rx, ry, rz)
    local aObject = Module:get(remoteId)
    if not aObject then return end

    aObject.data.rx = rx
    aObject.data.ry = ry
    aObject.data.rz = rz

    if DoesEntityExist(aObject.objectHandle) then
        SetEntityRotation(aObject.objectHandle, aObject:getVector3Rotation(), 2, false)
    end
end)
RegisterNetEvent(GetCurrentResourceName() .. "AQUIVER:Object:Update:Model", function(remoteId, model)
    local aObject = Module:get(remoteId)
    if not aObject then return end

    aObject.data.model = model

    -- Restream object, since we can not change the model directly on FiveM.
    aObject:removeStream()
    aObject:addStream()
end)
RegisterNetEvent(GetCurrentResourceName() .. "AQUIVER:Object:Update:Alpha", function(remoteId, alpha)
    local aObject = Module:get(remoteId)
    if not aObject then return end

    aObject.data.alpha = alpha

    if DoesEntityExist(aObject.objectHandle) then
        SetEntityAlpha(aObject.objectHandle, aObject.data.alpha, false)
    end
end)
RegisterNetEvent(GetCurrentResourceName() .. "AQUIVER:Object:Update:Hide", function(remoteId, state)
    local aObject = Module:get(remoteId)
    if not aObject then return end

    aObject.data.hide = state

    if DoesEntityExist(aObject.objectHandle) then
        SetEntityVisible(aObject.objectHandle, not aObject.data.hide, 0)
        SetEntityCollision(aObject.objectHandle, not aObject.data.hide, true)
    end
end)
RegisterNetEvent(GetCurrentResourceName() .. "AQUIVER:Object:Update:Dimension", function(remoteId, dimension)
    local aObject = Module:get(remoteId)
    if not aObject then return end

    aObject.data.dimension = dimension

    if DoesEntityExist(aObject.objectHandle) and Client.LocalPlayer.dimension ~= dimension then
        aObject:removeStream()
    end
end)
RegisterNetEvent(GetCurrentResourceName() .. "AQUIVER:Object:Update:VariableKey", function(remoteId, key, value)
    local aObject = Module:get(remoteId)
    if not aObject then return end

    aObject.data.variables[key] = value

    --             -- Update the raycast & variables which is shown in the interface.
    --             if AQUIVER_CLIENT.RaycastManager.AimedObjectEntity == self then
    --                 TriggerEvent("onObjectRaycast", self)
    --             end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for k, v in pairs(Module.Entities) do
        v:Destroy()
    end
end)

-- -- STREAMING HANDLER.
Citizen.CreateThread(function()
    while true do

        for k, v in pairs(Module.Entities) do
            if Client.LocalPlayer.dimension ~= v.data.dimension then
                v:removeStream()
            else
                local dist = v:dist(Client.LocalPlayer.cachedPosition)
                if dist < 10.0 then
                    v:addStream()
                else
                    v:removeStream()
                end
            end
        end

        Citizen.Wait(1000)
    end
end)

-- Requesting objects from server on client load.
Citizen.CreateThread(function()
    while true do

        if NetworkIsPlayerActive(PlayerId()) then
            -- Request Data from server.
            TriggerServerEvent(GetCurrentResourceName() .. "AQUIVER:Object:RequestData")
            break
        end

        Citizen.Wait(500)
    end
end)

return Module

-- local Manager = {}
-- ---@type { [number]: ClientObject }
-- Manager.Entities = {}

-- ---@param data MysqlObjectInterface
-- Manager.new = function(data)
--     ---@class ClientObject
--     local self = {}

--     local _data = data
--     ---@type { [string]: number } -- Contains the object handles.
--     local _attachments = {}

--     self.isStreamed = false
--     self.objectHandle = nil


--     Manager.Entities[_data.remoteId] = self
--     AQUIVER_SHARED.Utils.Print("^3Created new object with remoteId: " .. _data.remoteId)

--     return self
-- end

-- RegisterNetEvent("AQUIVER:Object:Attachment:Add", function(remoteId, attachmentName)
--     local ObjectEntity = Manager.get(remoteId)
--     if not ObjectEntity then return end
--     ObjectEntity.AddAttachment(attachmentName)
-- end)
-- RegisterNetEvent("AQUIVER:Object:Attachment:Remove", function(remoteId, attachmentName)
--     local ObjectEntity = Manager.get(remoteId)
--     if not ObjectEntity then return end
--     ObjectEntity.RemoveAttachment(attachmentName)
-- end)

-- AQUIVER_CLIENT.ObjectManager = Manager
