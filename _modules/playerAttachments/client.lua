local Module = {}
---@type { [number]: CAquiverPlayer }
Module.Entities = {}

---@class CAquiverPlayer
local Player = {
    source = nil,
    dimension = nil,
    attachments = {},
    attachmentHandles = {},
    isStreamed = false
}
Player.__index = Player

Player.new = function(source, attachments, dimension)
    local self = setmetatable({}, Player)

    self.source = source
    self.dimension = dimension
    self.attachments = attachments
    self.attachmentHandles = {}
    self.isStreamed = false

    if Module:exists(self.source) then
        Shared.Utils.Print:Error("GlobalPlayer already exists with source: " .. self.source)
        return
    end

    Module.Entities[self.source] = self

    Shared.Utils.Print:Debug("Created GlobalPlayer with source: " .. self.source)

    return self
end

function Player:getPed()
    local target = GetPlayerPed(GetPlayerFromServerId(self.source))
    if DoesEntityExist(target) then
        return target
    end
    return nil
end

function Player:dist(vec3)
    local target = self:getPed()

    if target then
        local coords = GetEntityCoords(target)
        return #(coords - vector3(vec3.x, vec3.y, vec3.z))
    end

    return nil
end

function Player:Destroy()
    if Module:exists(self.source) then
        Module.Entities[self.source] = nil
    end

    self:shutdownAttachments()

    Shared.Utils.Print:Debug("Removed GlobalPlayer with source: " .. self.source)
end

function Player:addAttachment(attachmentName)
    if DoesEntityExist(self.attachmentHandles[attachmentName]) then return end

    local aData = Shared.AttachmentManager:get(attachmentName)
    if not aData then return end

    local modelHash = GetHashKey(aData.model)
    Client.Utils:RequestModel(modelHash)

    local targetPlayer = self:getPed()
    if not targetPlayer then return end

    local coords = GetEntityCoords(targetPlayer)
    local obj = CreateObject(modelHash, coords, false, false, false)

    AttachEntityToEntity(
        obj,
        targetPlayer,
        GetPedBoneIndex(targetPlayer, aData.boneId),
        aData.x, aData.y, aData.z,
        aData.rx, aData.ry, aData.rz,
        true, true, false, false, 2, true
    )

    self.attachmentHandles[attachmentName] = obj
end

function Player:removeAttachment(attachmentName)
    if DoesEntityExist(self.attachmentHandles[attachmentName]) then
        DeleteEntity(self.attachmentHandles[attachmentName])
    end

    self.attachmentHandles[attachmentName] = nil
end

function Player:shutdownAttachments()
    for k, v in pairs(self.attachments) do
        self:removeAttachment(k)
    end
end

function Player:initAttachments()
    for k, v in pairs(self.attachments) do
        self:addAttachment(k)
    end
end

function Player:addStream()
    if self.isStreamed then return end

    self.isStreamed = true

    self:initAttachments()

    Shared.EventManager:TriggerModuleEvent("onGlobalPlayerStreamIn", self.source)

    Shared.Utils.Print:Debug(string.format("GlobalPlayer streamed in (%s)", self.source))
end

function Player:removeStream()
    if not self.isStreamed then return end

    self.isStreamed = false

    self:shutdownAttachments()

    Shared.EventManager:TriggerModuleEvent("onGlobalPlayerStreamOut", self.source)

    Shared.Utils.Print:Debug(string.format("GlobalPlayer streamed out (%s)", self.source))
end

function Module:new(source, dimension, attachments)
    local aPlayer = Player.new(source, dimension, attachments)
    if aPlayer then
        return aPlayer
    end
end

function Module:exists(source)
    return self.Entities[source] and true or false
end

function Module:get(source)
    return self.Entities[source] or nil
end

Citizen.CreateThread(function()
    while true do

        if NetworkIsPlayerActive(PlayerId()) then
            -- Request Data from server.
            Shared.EventManager:TriggerModuleServerEvent("GlobalPlayers:RequestData")
            break
        end

        Citizen.Wait(500)
    end
end)

Citizen.CreateThread(function()
    while true do

        for k, v in pairs(Module.Entities) do
            if v.source ~= GetPlayerServerId(PlayerId()) then
                if v.dimension ~= Client.LocalPlayer.dimension then
                    v:removeStream()
                else
                    local dist = v:dist(Client.LocalPlayer.cachedPosition)
                    if type(dist) == "number" and dist < 15.0 then
                        v:addStream()
                    else
                        v:removeStream()
                    end
                end
            end
        end

        Citizen.Wait(1000)
    end
end)

Shared.EventManager:RegisterModuleNetworkEvent({
    ["GlobalPlayers:Create"] = function(source, attachments, dimension)
        Module:new(source, attachments, dimension)
    end,
    ["GlobalPlayers:Destroy"] = function(source)
        local aPlayer = Module:get(source)
        if not aPlayer then return end
        aPlayer:Destroy()
    end,
    ["GlobalPlayer:Attachment:Add"] = function(source, attachmentName)
        local aPlayer = Module:get(source)
        if not aPlayer then return end

        aPlayer.attachments[attachmentName] = true
        aPlayer:addAttachment(attachmentName)
    end,
    ["GlobalPlayer:Attachment:Remove"] = function(source, attachmentName)
        local aPlayer = Module:get(source)
        if not aPlayer then return end

        aPlayer.attachments[attachmentName] = nil
        aPlayer:removeAttachment(attachmentName)
    end,
    ["GlobalPlayer:Set:Dimension"] = function(source, dimension)
        local aPlayer = Module:get(source)
        if not aPlayer then return end
        aPlayer.dimension = dimension
    end
})

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for k, v in pairs(Module.Entities) do
        v:shutdownAttachments()
    end
end)

return Module
