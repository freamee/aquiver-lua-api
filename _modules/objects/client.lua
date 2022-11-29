---@class CObjectsModule
local Module = {}
---@type { [number]: CAquiverObject }
Module.Entities = {}

---@class CAquiverObject
local Object = {
    ---@type MysqlObjectInterface
    data = {},
    isStreamed = false,
    objectHandle = nil,
    ---@type { [string]: number }
    attachments = {}
}
Object.__index = Object

---@param d MysqlObjectInterface
Object.new = function(d)
    local self = setmetatable({}, Object)

    self.data = d
    self.isStreamed = false
    self.objectHandle = nil
    self.attachments = {}

    self:__init__()

    if Module:exists(self.data.remoteId) then
        Shared.Utils:Print("^1Object already exists with remoteId: " .. self.data.remoteId)
        return
    end

    Module.Entities[self.data.remoteId] = self

    Shared.Utils:Print("^3Created new object with remoteId: " .. self.data.remoteId)

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

    TriggerEvent("onObjectStreamIn", GetCurrentResourceName(), self.data.remoteId)

    Shared.Utils:Print(string.format("^3Object streamed in (%d, %s)", self.data.remoteId, self.data.model))
end

function Object:removeStream()
    if not self.isStreamed then return end

    if DoesEntityExist(self.objectHandle) then
        DeleteEntity(self.objectHandle)
    end

    self.isStreamed = false

    self:shutdownAttachments()

    TriggerEvent("onObjectStreamOut", GetCurrentResourceName(), self.data.remoteId)

    Shared.Utils:Print(string.format("^3Object streamed out (%d, %s)", self.data.remoteId, self.data.model))
end

function Object:shutdownAttachments()
    for k, v in pairs(self.attachments) do
        self:removeAttachment(k)
    end
end

function Object:initAttachments()
    for k, v in pairs(self.attachments) do
        self:addAttachment(k)
    end
end

function Object:hasAttachment(attachmentName)
    return self.attachments[attachmentName] and true or false
end

function Object:addAttachment(attachmentName)
    if self:hasAttachment(attachmentName) then return end

    local aData = Shared.AttachmentManager:get(attachmentName)
    if not aData then return end

    local modelHash = GetHashKey(aData.model)
    Client.Utils:RequestModel(aData.model)

    local obj = CreateObject(modelHash, self:getVector3Position(), false, false, false)

    while not DoesEntityExist(self.objectHandle) do
        Citizen.Wait(50)
    end

    AttachEntityToEntity(
        obj,
        self.objectHandle,
        0,
        aData.x, aData.y, aData.z,
        aData.rx, aData.ry, aData.rz,
        true, true, false, false, 2, true
    )

    self.attachments[attachmentName] = obj

    Shared.Utils:Print(string.format("^3Object attachment added (%d, %s, %s)", self.data.remoteId, self.data.model,
        attachmentName))
end

function Object:removeAttachment(attachmentName)
    if not self:hasAttachment(attachmentName) then return end

    if DoesEntityExist(self.attachments[attachmentName]) then
        DeleteEntity(self.attachments[attachmentName])
    end

    self.attachments[attachmentName] = nil

    Shared.Utils:Print(string.format("^3Object attachment removed (%d, %s, %s)", self.data.remoteId, self.data.model,
        attachmentName))
end

function Object:Destroy()
    if Module:exists(self.data.remoteId) then
        Module.Entities[self.data.remoteId] = nil
    end

    if DoesEntityExist(self.objectHandle) then
        DeleteEntity(self.objectHandle)
    end

    self:shutdownAttachments()

    Shared.Utils:Print("^3Removed object with remoteId: " .. self.data.remoteId)
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

Shared.EventManager:RegisterModuleNetworkEvent({
    ["Object:Create"] = function(d)
        Module:new(d)
    end,
    ["Object:Destroy"] = function(remoteId)
        local aObject = Module:get(remoteId)
        if not aObject then return end
        aObject:Destroy()
    end,
    ["Object:Update:Position"] = function(remoteId, x, y, z)
        local aObject = Module:get(remoteId)
        if not aObject then return end

        aObject.data.x = x
        aObject.data.y = y
        aObject.data.z = z

        if DoesEntityExist(aObject.objectHandle) then
            SetEntityCoords(aObject.objectHandle, aObject:getVector3Position(), false, false, false, false)
        end
    end,
    ["Object:Update:Rotation"] = function(remoteId, rx, ry, rz)
        local aObject = Module:get(remoteId)
        if not aObject then return end

        aObject.data.rx = rx
        aObject.data.ry = ry
        aObject.data.rz = rz

        if DoesEntityExist(aObject.objectHandle) then
            SetEntityRotation(aObject.objectHandle, aObject:getVector3Rotation(), 2, false)
        end
    end,
    ["Object:Update:Model"] = function(remoteId, model)
        local aObject = Module:get(remoteId)
        if not aObject then return end

        aObject.data.model = model

        -- Restream object, since we can not change the model directly on FiveM.
        aObject:removeStream()
        aObject:addStream()
    end,
    ["Object:Update:Alpha"] = function(remoteId, alpha)
        local aObject = Module:get(remoteId)
        if not aObject then return end

        aObject.data.alpha = alpha

        if DoesEntityExist(aObject.objectHandle) then
            SetEntityAlpha(aObject.objectHandle, aObject.data.alpha, false)
        end
    end,
    ["Object:Update:Hide"] = function(remoteId, state)
        local aObject = Module:get(remoteId)
        if not aObject then return end

        aObject.data.hide = state

        if DoesEntityExist(aObject.objectHandle) then
            SetEntityVisible(aObject.objectHandle, not aObject.data.hide, 0)
            SetEntityCollision(aObject.objectHandle, not aObject.data.hide, true)
        end
    end,
    ["Object:Update:Dimension"] = function(remoteId, dimension)
        local aObject = Module:get(remoteId)
        if not aObject then return end

        aObject.data.dimension = dimension

        if DoesEntityExist(aObject.objectHandle) and Client.LocalPlayer.dimension ~= dimension then
            aObject:removeStream()
        end
    end,
    ["Object:Update:VariableKey"] = function(remoteId, key, value)
        local aObject = Module:get(remoteId)
        if not aObject then return end

        aObject.data.variables[key] = value

        -- Update the raycast & variables which is shown in the interface.
        if Client.RaycastManager.AimedObjectEntity == self then
            TriggerEvent("onObjectRaycast", self)
        end
    end,
    ["Object:Attachment:Add"] = function(remoteId, attachmentName)
        local aObject = Module:get(remoteId)
        if not aObject then return end

        aObject:addAttachment(attachmentName)
    end,
    ["Object:Attachment:Remove"] = function(remoteId, attachmentName)
        local aObject = Module:get(remoteId)
        if not aObject then return end

        aObject:removeAttachment(attachmentName)
    end
})

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
            Shared.EventManager:TriggerModuleServerEvent("Object:RequestData")
            break
        end

        Citizen.Wait(500)
    end
end)

return Module
