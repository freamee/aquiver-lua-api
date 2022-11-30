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
    ---@type fun(Player: SAquiverPlayer, Ped: SAquiverPed)
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
    Shared.EventManager:TriggerModuleClientEvent("Ped:Create", -1, self.data)

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

    Shared.EventManager:TriggerModuleClientEvent("Ped:Destroy", -1, self.data.remoteId)
    Shared.Utils:Print("^3Removed ped with remoteId: " .. self.data.remoteId)
end

function Ped:playAnimation(dict, anim, flag)
    self.data.animDict = dict
    self.data.animName = anim
    self.data.animFlag = flag

    Shared.EventManager:TriggerModuleClientEvent(
        "Ped:Update:Animation",
        -1,
        self.data.remoteId,
        self.data.animDict,
        self.data.animName,
        self.data.animFlag
    )
end

---@param Player SAquiverPlayer
function Ped:startDialogue(Player, DialoguesData)
    Shared.EventManager:TriggerModuleClientEvent("Ped:Start:Dialogue", Player.source, self.data.remoteId, DialoguesData)
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

Shared.EventManager:RegisterModuleNetworkEvent("Ped:RequestData", function()
    local source = source

    for k, v in pairs(Module.Entities) do
        Shared.EventManager:TriggerModuleClientEvent("Ped:Create", source, v.data)
    end
end)

return Module
