---@class SActionShapeModule
local Module = {}
---@type { [number]: SAquiverActionShape }
Module.Entities = {}

local remoteIdCount = 1

---@class IActionShape
---@field position { x:number; y:number; z:number; }
---@field color { r:number; g:number; b:number; a:number; }
---@field sprite number
---@field range number
---@field dimension number
---@field variables table
---@field remoteId number

---@class SAquiverActionShape
local ActionShape = {
    ---@type IActionShape
    data = {}
}
ActionShape.__index = ActionShape

---@param d IActionShape
ActionShape.new = function(d)
    local self = setmetatable({}, ActionShape)

    self.data = d
    self.data.remoteId = remoteIdCount
    remoteIdCount = (remoteIdCount or 0) + 1

    if Module:exists(self.data.remoteId) then
        Shared.Utils:Print("^1ActionShape already exists with remoteID: " .. self.data.remoteId)
        return
    end

    self:__init__()

    Module.Entities[self.data.remoteId] = self
    Shared.EventManager:TriggerModuleClientEvent("ActionShape:Create", -1, self.data)

    Shared.Utils:Print("^3Created new ActionShape with remoteID: " .. self.data.remoteId)

    return self
end

function ActionShape:__init__()
    self.data.variables = type(self.data.variables) == "table" and self.data.variables or {}
end

function ActionShape:Destroy()
    if Module:exists(self.data.remoteId) then
        Module.Entities[self.data.remoteId] = nil
    end

    Shared.EventManager:TriggerModuleClientEvent("ActionShape:Destroy", -1, self.data.remoteId)

    Shared.Utils:Print("^3Removed ActionShape with remoteId: " .. self.data.remoteId)
end

---@param d IActionShape
function Module:new(d)
    local aActionShape = ActionShape.new(d)
    if aActionShape then
        return aActionShape
    end
end

function Module:exists(remoteId)
    return self.Entities[remoteId] and true or false
end

function Module:get(remoteId)
    return self.Entities[remoteId] or nil
end

Shared.EventManager:RegisterModuleNetworkEvent("ActionShape:RequestData", function()
    local source = source

    for k, v in pairs(Module.Entities) do
        Shared.EventManager:TriggerModuleClientEvent("ActionShape:Create", source, v.data)
    end
end)

return Module
