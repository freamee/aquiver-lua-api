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

local Manager = {}
---@type { [number]: ServerPed }
Manager.Entities = {}

---@param data IPed
Manager.new = function(data)
    ---@class ServerPed
    local self = {}

    data.dimension = type(data.dimension) == "number" and data.dimension or CONFIG.DEFAULT_DIMENSION
    data.heading = type(data.heading) == "number" and data.heading or 0.0

    self.data = data
    self.invokedFromResource = AQUIVER_SHARED.Utils.GetInvokingResource()
    self.data.remoteId = remoteIdCount
    remoteIdCount = remoteIdCount + 1
    ---@type fun(Player: ServerPlayer, Ped: ServerPed)
    self.onPress = nil

    self.Set = {
        Position = function(vec3)
            self.data.position = vec3
            self.Sync.Position()
        end,
        Heading = function(heading)
            self.data.heading = heading
            self.Sync.Heading()
        end,
        Model = function(model)
            self.data.model = model
            self.Sync.Model()
        end,
        Dimension = function(dimension)
            self.data.dimension = dimension
            self.Sync.Dimension()
        end,
        Animation = function(dict, anim, flag)
            self.data.animDict = dict
            self.data.animName = anim
            self.data.animFlag = flag
            self.Sync.Animation()
        end
    }

    self.Sync = {
        Position = function()
            TriggerClientEvent("AQUIVER:Ped:Update:Position", -1, self.data.remoteId, self.data.position)
        end,
        Heading = function()
            TriggerClientEvent("AQUIVER:Ped:Update:Heading", -1, self.data.remoteId, self.data.heading)
        end,
        Model = function()
            TriggerClientEvent("AQUIVER:Ped:Update:Model", -1, self.data.remoteId, self.data.model)
        end,
        Dimension = function()
            TriggerClientEvent("AQUIVER:Ped:Update:Dimension", -1, self.data.remoteId, self.data.dimension)
        end,
        Animation = function()
            TriggerClientEvent(
                "AQUIVER:Ped:Update:Animation",
                -1,
                self.data.remoteId,
                self.data.animDict,
                self.data.animName,
                self.data.animFlag
            )
        end
    }

    self.Get = {
        Position = function()
            return vector3(self.data.position.x, self.data.position.y, self.data.position.z)
        end,
        GetData = function()
            return self.data
        end
    }

    ---@param Player ServerPlayer
    self.StartDialogue = function(Player, DialoguesData)
        TriggerClientEvent("AQUIVER:Ped:Start:Dialogue", Player.source, self.data.remoteId, DialoguesData)
    end

    self.Destroy = function()
        -- Delete from table.
        if Manager.exists(self.data.remoteId) then
            Manager.Entities[self.data.remoteId] = nil
        end

        TriggerClientEvent("AQUIVER:Ped:Destroy", -1, self.data.remoteId)
        TriggerEvent("onPedDestroyed", self)

        AQUIVER_SHARED.Utils.Print("^3Removed ped with remoteId: " .. self.data.remoteId)
    end

    if Manager.exists(self.data.remoteId) then
        AQUIVER_SHARED.Utils.Print("^1Ped already exists with remoteId: " .. self.data.remoteId)
        return
    end

    Manager.Entities[self.data.remoteId] = self

    AQUIVER_SHARED.Utils.Print("^3Created new ped with remoteId: " .. self.data.remoteId)

    TriggerEvent("onPedCreated", self)

    return self
end

Manager.exists = function(id)
    return Manager.Entities[id] and true or false
end

Manager.get = function(id)
    return Manager.Entities[id] or nil
end

Manager.getAll = function()
    return Manager.Entities
end

RegisterNetEvent("AQUIVER:Ped:RequestData", function()
    local source = source

    for k, v in pairs(Manager.Entities) do
        TriggerClientEvent("AQUIVER:Ped:Create", source, v.data)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    for k, v in pairs(Manager.Entities) do
        if v.invokedFromResource == resourceName then
            v.Destroy()
        end
    end
end)

AQUIVER_SERVER.PedManager = Manager
