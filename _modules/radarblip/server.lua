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
        Shared.Utils.Print:Error("^1RadarBlip already exists with remoteID: " .. self.data.remoteId)
        return
    end

    self:__init__()

    Module.Entities[self.data.remoteId] = self

    Shared.EventManager:TriggerModuleClientEvent("RadarBlip:Create", -1, self.data)

    Shared.Utils.Print:Debug("^3Created new RadarBlip with remoteID: " .. self.data.remoteId)

    return self
end

function RadarBlip:__init__()

end

function RadarBlip:Destroy()
    if Module:exists(self.data.remoteId) then
        Module.Entities[self.data.remoteId] = nil
    end

    Shared.EventManager:TriggerModuleClientEvent("RadarBlip:Destroy", -1, self.data.remoteId)
end

function RadarBlip:setRadius(radius)
    self.data.radius = radius
    Shared.EventManager:TriggerModuleClientEvent("RadarBlip:Update:Radius", -1, self.data.remoteId, radius)
end

function RadarBlip:setColor(colorId)
    self.data.color = colorId
    Shared.EventManager:TriggerModuleClientEvent("RadarBlip:Update:Color", -1, self.data.remoteId, colorId)
end

function RadarBlip:setFlashing(state)
    self.data.isFlashing = state
    Shared.EventManager:TriggerModuleClientEvent("RadarBlip:Update:Flashing", -1, self.data.remoteId, state)
end

function RadarBlip:setAlpha(alpha)
    self.data.alpha = alpha
    Shared.EventManager:TriggerModuleClientEvent("RadarBlip:Update:Alpha", -1, self.data.remoteId, alpha)
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

Shared.EventManager:RegisterModuleNetworkEvent("RadarBlip:RequestData", function()
    local source = source

    for k, v in pairs(Module.Entities) do
        Shared.EventManager:TriggerModuleClientEvent("RadarBlip:Create", source, v.data)
    end
end)

return Module
