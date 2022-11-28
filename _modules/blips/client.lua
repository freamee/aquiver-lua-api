---@class CBlipModule
local Module = {}
---@type { [number]: CAquiverBlip }
Module.Entities = {}

---@class CAquiverBlip
local Blip = {
    ---@type IBlip
    data = {},
    blipHandle = nil
}
Blip.__index = Blip

---@param d IBlip
Blip.new = function(d)
    local self = setmetatable({}, Blip)

    self.data = d

    if Module:exists(self.data.remoteId) then
        Shared.Utils:Print("^1Blip already exists with remoteID: " .. self.data.remoteId)
        return
    end

    self:__init__()

    Module.Entities[self.data.remoteId] = self

    Shared.Utils:Print("^3Created new Blip with remoteID: " .. self.data.remoteId)

    return self
end

function Blip:__init__()
    -- Creating the blip here.
    local blip = AddBlipForCoord(self.data.position.x, self.data.position.y, self.data.position.z)
    SetBlipSprite(blip, self.data.sprite)
    SetBlipDisplay(blip, self.data.display)
    SetBlipScale(blip, self.data.scale)
    SetBlipAlpha(blip, self.data.alpha)
    SetBlipAsShortRange(blip, self.data.shortRange)
    SetBlipColour(blip, self.data.color)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(self.data.name)
    EndTextCommandSetBlipName(blip)

    self.blipHandle = blip
end

function Blip:Destroy()
    if Module:exists(self.data.remoteId) then
        Module.Entities[self.data.remoteId] = nil
    end

    if DoesBlipExist(self.blipHandle) then
        RemoveBlip(self.blipHandle)
    end
end

---@param d IBlip
function Module:new(d)
    local aBlip = Blip.new(d)
    if aBlip then
        return aBlip
    end
end

function Module:exists(remoteId)
    return self.Entities[remoteId] and true or false
end

function Module:get(remoteId)
    return self.Entities[remoteId] or nil
end

RegisterNetEvent(GetCurrentResourceName() .. "AQUIVER:Blip:Create", function(data)
    Module:new(data)
end)
RegisterNetEvent(GetCurrentResourceName() .. "AQUIVER:Blip:Update:Color", function(remoteId, color)
    local aBlip = Module:get(remoteId)
    if not aBlip then return end

    aBlip.data.color = color

    if DoesBlipExist(aBlip.blipHandle) then
        SetBlipColour(aBlip.blipHandle, color)
    end
end)
RegisterNetEvent(GetCurrentResourceName() .. "AQUIVER:Blip:Destroy", function(remoteId)
    local aBlip = Module:get(remoteId)
    if not aBlip then return end

    aBlip:Destroy()
end)

Citizen.CreateThread(function()
    while true do

        if NetworkIsPlayerActive(PlayerId()) then
            -- Request Data from server.
            TriggerServerEvent(GetCurrentResourceName() .. "AQUIVER:Blip:RequestData")
            break
        end

        Citizen.Wait(500)
    end
end)

return Module
