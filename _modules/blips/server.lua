---@class SBlipModule
local Module = {}
---@type { [number]: SAquiverBlip }
Module.Entities = {}

local remoteIdCount = 1

---@class IBlip
---@field position { x:number; y:number; z:number }
---@field alpha number
---@field color number
---@field sprite number
---@field display? number
---@field shortRange? boolean
---@field scale? number
---@field remoteId? number
---@field name string

---@class SAquiverBlip
local Blip = {
    ---@type IBlip
    data = {}
}
Blip.__index = Blip

---@param d IBlip
Blip.new = function(d)
    local self = setmetatable({}, Blip)

    self.data = d
    self.data.remoteId = remoteIdCount
    remoteIdCount = (remoteIdCount or 0) + 1

    if Module:exists(self.data.remoteId) then
        Shared.Utils:Print("^1Blip already exists with remoteID: " .. self.data.remoteId)
        return
    end

    self:__init__()

    Module.Entities[self.data.remoteId] = self

    Shared.EventManager:TriggerModuleClientEvent("Blip:Create", -1, self.data)

    Shared.Utils:Print("^3Created new Blip with remoteID: " .. self.data.remoteId)

    return self
end

function Blip:__init__()
    self.data.display = type(self.data.display) == "number" and self.data.display or 4
    self.data.shortRange = type(self.data.shortRange) == "boolean" and self.data.shortRange or true
    self.data.scale = type(self.data.scale) == "number" and self.data.scale or 1.0
    self.data.alpha = type(self.data.alpha) == "number" and self.data.alpha or 255
end

function Blip:Destroy()
    if Module:exists(self.data.remoteId) then
        Module.Entities[self.data.remoteId] = nil
    end

    Shared.EventManager:TriggerModuleClientEvent("Blip:Destroy", -1, self.data.remoteId)

    Shared.Utils:Print("^3Removed Blip with remoteId: " .. self.data.remoteId)
end

function Blip:setColor(colorId)
    self.data.color = colorId
    Shared.EventManager:TriggerModuleClientEvent("Blip:Update:Color", -1, self.data.remoteId, colorId)
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

Shared.EventManager:RegisterModuleNetworkEvent("Blip:RequestData", function()
    local source = source

    for k, v in pairs(Module.Entities) do
        Shared.EventManager:TriggerModuleClientEvent("Blip:Create", source, v.data)
    end
end)

-- Delete if another resource is restarted which has connections to this.
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for k, v in pairs(Module.Entities) do
        v:Destroy()
    end
end)

return Module
