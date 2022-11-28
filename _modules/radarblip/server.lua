---@class SRadarBlipModule
local Module = {}
---@type { [number]: SAquiverRadarBlip }
Module.Entities = {}

local remoteIdCount = 1

---@class IRadarBlip
---@field position { x:number; y:number; z:number }
---@field radius number
---@field alpha number
---@field color number
---@field isFlashing? boolean
---@field remoteId number

---@class SAquiverRadarBlip
local RadarBlip = {
    ---@type IRadarBlip
    data = {}
}
RadarBlip.__index = RadarBlip

---@param d IRadarBlip
RadarBlip.new = function(d)
    local self = setmetatable({}, RadarBlip)

    self.data = d
    self.data.remoteId = remoteIdCount
    remoteIdCount = (remoteIdCount or 0) + 1

    if Module:exists(self.data.remoteId) then
        Shared.Utils:Print("^1RadarBlip already exists with remoteID: " .. self.data.remoteId)
        return
    end

    self:__init__()

    Module.Entities[self.data.remoteId] = self

    TriggerClientEvent(GetCurrentResourceName() .. "AQUIVER:RadarBlip:Create", -1, self.data)

    Shared.Utils:Print("^3Created new RadarBlip with remoteID: " .. self.data.remoteId)

    return self
end

function RadarBlip:__init__()

end

function RadarBlip:Destroy()
    if Module:exists(self.data.remoteId) then
        Module.Entities[self.data.remoteId] = nil
    end

    TriggerClientEvent(GetCurrentResourceName() .. "AQUIVER:RadarBlip:Destroy", -1, self.data.remoteId)
end

function RadarBlip:setRadius(radius)
    self.data.radius = radius
    TriggerClientEvent(GetCurrentResourceName() .. "AQUIVER:RadarBlip:Update:Radius", -1, self.data.remoteId, radius)
end

function RadarBlip:setColor(colorId)
    self.data.color = colorId
    TriggerClientEvent(GetCurrentResourceName() .. "AQUIVER:RadarBlip:Update:Color", -1, self.data.remoteId, colorId)
end

function RadarBlip:setFlashing(state)
    self.data.isFlashing = state
    TriggerClientEvent(GetCurrentResourceName() .. "AQUIVER:RadarBlip:Update:Flashing", -1, self.data.remoteId, state)
end

function RadarBlip:setAlpha(alpha)
    self.data.alpha = alpha
    TriggerClientEvent(GetCurrentResourceName() .. "AQUIVER:RadarBlip:Update:Alpha", -1, self.data.remoteId, alpha)
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

RegisterNetEvent(GetCurrentResourceName() .. "AQUIVER:RadarBlip:RequestData", function()
    local source = source

    for k, v in pairs(Module.Entities) do
        TriggerClientEvent(GetCurrentResourceName() .. "AQUIVER:RadarBlip:Create", source, v.data)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for k, v in pairs(Module.Entities) do
        v:Destroy()
    end
end)

return Module