---@class CRadarBlipModule
local Module = {}
---@type { [number]: CAquiverRadarBlip }
Module.Entities = {}

---@class CAquiverRadarBlip
local RadarBlip = {
    ---@type IRadarBlip
    data = {},
    blipHandle = nil
}
RadarBlip.__index = RadarBlip

---@param d IRadarBlip
RadarBlip.new = function(d)
    local self = setmetatable({}, RadarBlip)

    self.data = d
    self.blipHandle = nil

    if Module:exists(self.data.remoteId) then
        Shared.Utils.Print:Error("^1RadarBlip already exists with remoteID: " .. self.data.remoteId)
        return
    end

    self:__init__()

    Module.Entities[self.data.remoteId] = self

    Shared.Utils.Print:Debug("^3Created new RadarBlip with remoteID: " .. self.data.remoteId)

    return self
end

function RadarBlip:__init__()
    local blip = AddBlipForRadius(self.data.position, self.data.radius)
    SetBlipRotation(blip, 0)
    SetBlipAlpha(blip, self.data.alpha)
    SetBlipColour(blip, self.data.color)
    SetBlipFlashes(blip, self.data.isFlashing)

    self.blipHandle = blip
end

function RadarBlip:Destroy()
    if Module:exists(self.data.remoteId) then
        Module.Entities[self.data.remoteId] = nil
    end

    if DoesBlipExist(self.blipHandle) then
        RemoveBlip(self.blipHandle)
    end
end

---@param d IRadarBlip
function Module:new(d)
    local aRadarBlip = RadarBlip.new(d)
    if aRadarBlip then
        return aRadarBlip
    end
end

function Module:exists(remoteId)
    return self.Entities[remoteId] and true or false
end

function Module:get(remoteId)
    return self.Entities[remoteId] or nil
end

Shared.EventManager:RegisterModuleNetworkEvent({
    ["RadarBlip:Create"] = function(data)
        Module:new(data)
    end,
    ["RadarBlip:Destroy"] = function(remoteId)
        local aRadarBlip = Module:get(remoteId)
        if not aRadarBlip then return end
        aRadarBlip:Destroy()
    end,
    ["RadarBlip:Update:Color"] = function(remoteId, color)
        local aRadarBlip = Module:get(remoteId)
        if not aRadarBlip then return end

        aRadarBlip.data.color = color

        if DoesBlipExist(aRadarBlip.blipHandle) then
            SetBlipColour(aRadarBlip.blipHandle, color)
        end
    end,
    ["RadarBlip:Update:Radius"] = function(remoteId, radius)
        local aRadarBlip = Module:get(remoteId)
        if not aRadarBlip then return end

        aRadarBlip.data.radius = radius

        if DoesBlipExist(aRadarBlip.blipHandle) then
            SetBlipScale(aRadarBlip.blipHandle, radius)
        end
    end,
    ["RadarBlip:Update:Alpha"] = function(remoteId, alpha)
        local aRadarBlip = Module:get(remoteId)
        if not aRadarBlip then return end

        aRadarBlip.data.alpha = alpha

        if DoesBlipExist(aRadarBlip.blipHandle) then
            SetBlipAlpha(aRadarBlip.blipHandle, alpha)
        end
    end,
    ["RadarBlip:Update:Flashing"] = function(remoteId, state)
        local aRadarBlip = Module:get(remoteId)
        if not aRadarBlip then return end

        aRadarBlip.data.isFlashing = state

        if DoesBlipExist(aRadarBlip.blipHandle) then
            SetBlipFlashes(aRadarBlip.blipHandle, state)
        end
    end,
})

AddEventHandler("onResouceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for k, v in pairs(Module.Entities) do
        v:Destroy()
    end
end)

Citizen.CreateThread(function()
    while true do

        if NetworkIsPlayerActive(PlayerId()) then
            -- Request Data from server.
            Shared.EventManager:TriggerModuleServerEvent("RadarBlip:RequestData")
            break
        end

        Citizen.Wait(500)
    end
end)

return Module
