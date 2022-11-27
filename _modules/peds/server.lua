---@class IPed
---@field uid? string
---@field position { x:number; y:number; z:number; }
---@field heading number
---@field model string
---@field dimension number
---@field animDict? string
---@field animName? string
---@field animFlag? number
---@field questionMark? boolean
---@field name? string
---@field remoteId number

local remoteIdCount = 1
---@class SPedModule
local Module = {}
---@type { [number]: SAquiverPed }
Module.Entities = {}

---@class SAquiverPed
local Ped = {
    ---@type IPed
    data = {},
    ---@type fun(Player: SAquiverPlayer, Object: SAquiverObject)
    onPress = nil
}
Ped.__index = Ped

---@param d IPed
Ped.new = function(d)
    local self = setmetatable({}, Ped)

    self.data = d
    self.data.remoteId = remoteIdCount
    remoteIdCount = (remoteIdCount or 0) + 1
    self.onPress = nil

    if Module:exists(self.data.remoteId) then
        Shared.Utils:Print("^1Ped already exists with remoteID: " .. self.data.remoteId)
        return
    end

    self:__init__()

    Module.Entities[self.data.remoteId] = self
    TriggerClientEvent(GetCurrentResourceName() .. "AQUIVER:Ped:Create", -1, self.data)

    Shared.Utils:Print("^3Created new Ped with remoteID: " .. self.data.remoteId)

    return self
end

function Ped:__init__()
    self.data.dimension = type(self.data.dimension) == "number" and self.data.dimension or 0
    self.data.heading = type(self.data.heading) == "number" and self.data.heading or 0.0
end

function Ped:Destroy()
    if Module:exists(self.data.remoteId) then
        Module.Entities[self.data.remoteId] = nil
    end

    TriggerClientEvent(GetCurrentResourceName() .. "AQUIVER:Ped:Destroy", -1, self.data.remoteId)
    Shared.Utils:Print("^3Removed ped with remoteId: " .. self.data.remoteId)
end

function Ped:playAnimation(dict, anim, flag)
    self.data.animDict = dict
    self.data.animName = anim
    self.data.animFlag = flag

    TriggerClientEvent(
        GetCurrentResourceName() .. "AQUIVER:Ped:Update:Animation",
        -1,
        self.data.remoteId,
        self.data.animDict,
        self.data.animName,
        self.data.animFlag
    )
end

---@param d IPed
function Module:new(d)
    local aPed = Ped.new(d)
    if aPed then
        return aPed
    end
end

function Module:exists(remoteId)
    return self.Entities[remoteId] and true or false
end

function Module:get(remoteId)
    return self.Entities[remoteId] or nil
end

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for k, v in pairs(Module.Entities) do
        v:Destroy()
    end
end)

RegisterNetEvent(GetCurrentResourceName() .. "AQUIVER:Ped:RequestData", function()
    local source = source

    for k, v in pairs(Module.Entities) do
        TriggerClientEvent(GetCurrentResourceName() .. "AQUIVER:Ped:Create", source, v.data)
    end
end)

return Module

-- ---@param data IPed
-- Manager.new = function(data)
--     ---@class ServerPed
--     local self = {}

--     local Sync = {
--         Position = function()
--             TriggerClientEvent("AQUIVER:Ped:Update:Position", -1, _data.remoteId, _data.position)
--         end,
--         Heading = function()
--             TriggerClientEvent("AQUIVER:Ped:Update:Heading", -1, _data.remoteId, _data.heading)
--         end,
--         Model = function()
--             TriggerClientEvent("AQUIVER:Ped:Update:Model", -1, _data.remoteId, _data.model)
--         end,
--         Dimension = function()
--             TriggerClientEvent("AQUIVER:Ped:Update:Dimension", -1, _data.remoteId, _data.dimension)
--         end
--     }

--     self.Set = {
--         Position = function(vec3)
--             _data.position = vec3
--             Sync.Position()
--         end,
--         Heading = function(heading)
--             _data.heading = heading
--             Sync.Heading()
--         end,
--         Model = function(model)
--             _data.model = model
--             Sync.Model()
--         end,
--         Dimension = function(dimension)
--             _data.dimension = dimension
--             Sync.Dimension()
--         end
--     }

--     self.Get = {
--         Position = function()
--             return vector3(_data.position.x, _data.position.y, _data.position.z)
--         end,
--         Data = function()
--             return _data
--         end
--     }

--     ---@param Player ServerPlayer
--     self.StartDialogue = function(Player, DialoguesData)
--         TriggerClientEvent("AQUIVER:Ped:Start:Dialogue", Player.source, _data.remoteId, DialoguesData)
--     end

--     ---@param cb fun(Player: ServerPlayer, Ped: ServerPed)
--     self.AddPressFunction = function(cb)
--         if Citizen.GetFunctionReference(self.onPress) then
--             AQUIVER_SHARED.Utils.Print("^2Ped AddPressFunction already exists, it was overwritten. Ped: " ..
--                 _data.remoteId)
--         end

--         self.onPress = cb
--     end

--     if Manager.exists(_data.remoteId) then
--         AQUIVER_SHARED.Utils.Print("^1Ped already exists with remoteId: " .. _data.remoteId)
--         return
--     end

--     return self
-- end

-- AQUIVER_SERVER.PedManager = Manager
