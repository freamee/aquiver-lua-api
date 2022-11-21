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

    local _data = data
    _data.remoteId = remoteIdCount
    remoteIdCount = remoteIdCount + 1
    self.invokedFromResource = AQUIVER_SHARED.Utils.GetInvokingResource()
    ---@type fun(Player: ServerPlayer, Ped: ServerPed)
    self.onPress = nil

    local Sync = {
        Position = function()
            TriggerClientEvent("AQUIVER:Ped:Update:Position", -1, _data.remoteId, _data.position)
        end,
        Heading = function()
            TriggerClientEvent("AQUIVER:Ped:Update:Heading", -1, _data.remoteId, _data.heading)
        end,
        Model = function()
            TriggerClientEvent("AQUIVER:Ped:Update:Model", -1, _data.remoteId, _data.model)
        end,
        Dimension = function()
            TriggerClientEvent("AQUIVER:Ped:Update:Dimension", -1, _data.remoteId, _data.dimension)
        end,
        Animation = function()
            TriggerClientEvent(
                "AQUIVER:Ped:Update:Animation",
                -1,
                _data.remoteId,
                _data.animDict,
                _data.animName,
                _data.animFlag
            )
        end
    }

    self.Set = {
        Position = function(vec3)
            _data.position = vec3
            Sync.Position()
        end,
        Heading = function(heading)
            _data.heading = heading
            Sync.Heading()
        end,
        Model = function(model)
            _data.model = model
            Sync.Model()
        end,
        Dimension = function(dimension)
            _data.dimension = dimension
            Sync.Dimension()
        end,
        Animation = function(dict, anim, flag)
            _data.animDict = dict
            _data.animName = anim
            _data.animFlag = flag
            Sync.Animation()
        end
    }

    self.Get = {
        Position = function()
            return vector3(_data.position.x, _data.position.y, _data.position.z)
        end,
        Data = function()
            return _data
        end
    }

    ---@param Player ServerPlayer
    self.StartDialogue = function(Player, DialoguesData)
        TriggerClientEvent("AQUIVER:Ped:Start:Dialogue", Player.source, _data.remoteId, DialoguesData)
    end

    ---@param cb fun(Player: ServerPlayer, Ped: ServerPed)
    self.AddPressFunction = function(cb)
        if Citizen.GetFunctionReference(self.onPress) then
            AQUIVER_SHARED.Utils.Print("^2Ped AddPressFunction already exists, it was overwritten. Ped: " ..
                _data.remoteId)
        end

        self.onPress = cb
    end

    self.Destroy = function()
        -- Delete from table.
        if Manager.exists(_data.remoteId) then
            Manager.Entities[_data.remoteId] = nil
        end

        TriggerClientEvent("AQUIVER:Ped:Destroy", -1, _data.remoteId)
        TriggerEvent("onPedDestroyed", self)

        AQUIVER_SHARED.Utils.Print("^3Removed ped with remoteId: " .. _data.remoteId)
    end

    if Manager.exists(_data.remoteId) then
        AQUIVER_SHARED.Utils.Print("^1Ped already exists with remoteId: " .. _data.remoteId)
        return
    end

    Manager.Entities[_data.remoteId] = self

    TriggerClientEvent("AQUIVER:Ped:Create", -1, _data)

    AQUIVER_SHARED.Utils.Print("^3Created new ped with remoteId: " .. _data.remoteId)

    TriggerEvent("onPedCreated", self)

    return self
end

Manager.exists = function(id)
    return Manager.Entities[id] and true or false
end

Manager.get = function(id)
    return Manager.Entities[id] or nil
end

RegisterNetEvent("AQUIVER:Ped:RequestData", function()
    local source = source

    for k, v in pairs(Manager.Entities) do
        TriggerClientEvent("AQUIVER:Ped:Create", source, v.Get.Data())
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
