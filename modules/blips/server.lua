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

local Manager = {}
---@type { [number]: ServerBlip }
Manager.Entities = {}

---@param data IBlip
Manager.new = function(data)
    ---@class ServerBlip
    local self = {}

    local _data = data

    _data.display = type(_data.display) == "number" and _data.display or 4
    _data.shortRange = type(_data.shortRange) == "boolean" and _data.shortRange or true
    _data.scale = type(_data.scale) == "number" and _data.scale or 1.0
    _data.alpha = type(_data.alpha) == "number" and _data.alpha or 255
    _data.remoteId = remoteIdCount
    remoteIdCount = remoteIdCount + 1
    self.invokedFromResource = AQUIVER_SHARED.Utils.GetInvokingResource()

    if Manager.exists(_data.remoteId) then
        AQUIVER_SHARED.Utils.Print("^1Blip already exists with remoteId: " .. _data.remoteId)
        return
    end

    local Sync = {
        Position = function()
            TriggerClientEvent("AQUIVER:Blip:Update:Position", -1, _data.remoteId, position)
        end,
        Name = function()
            TriggerClientEvent("AQUIVER:Blip:Update:Name", -1, _data.remoteId, name)
        end,
        Scale = function()
            TriggerClientEvent("AQUIVER:Blip:Update:Scale", -1, _data.remoteId, scale)
        end,
        ShortRange = function()
            TriggerClientEvent("AQUIVER:Blip:Update:ShortRange", -1, _data.remoteId, state)
        end,
        Display = function()
            TriggerClientEvent("AQUIVER:Blip:Update:Display", -1, _data.remoteId, displayId)
        end,
        Sprite = function()
            TriggerClientEvent("AQUIVER:Blip:Update:Sprite", -1, _data.remoteId, sprite)
        end,
        Alpha = function()
            TriggerClientEvent("AQUIVER:Blip:Update:Alpha", -1, _data.remoteId, alpha)
        end,
        Color = function()
            TriggerClientEvent("AQUIVER:Blip:Update:Color", -1, _data.remoteId, color)
        end
    }

    self.Set = {
        Position = function(position)
            _data.position = position
            Sync.Position()
        end,
        Name = function(name)
            _data.name = name
            Sync.Name()
        end,
        Scale = function(scale)
            _data.scale = scale
            Sync.Scale()
        end,
        ShortRange = function(state)
            _data.shortRange = state
            Sync.ShortRange()
        end,
        Display = function(displayId)
            _data.display = displayId
            Sync.Display()
        end,
        Sprite = function(spriteId)
            _data.sprite = spriteId
            Sync.Sprite()
        end,
        Alpha = function(alpha)
            _data.alpha = alpha
            Sync.Alpha()
        end,
        Color = function(color)
            _data.color = color
            Sync.Color()
        end
    }

    self.Get = {
        Data = function()
            return _data
        end
    }

    self.Destroy = function()
        -- Delete from table
        if Manager.exists(_data.remoteId) then
            Manager.Entities[_data.remoteId] = nil
        end

        TriggerClientEvent("AQUIVER:Blip:Destroy", -1, _data.remoteId)
    end

    TriggerClientEvent("AQUIVER:Blip:Create", -1, _data)
    Manager.Entities[_data.remoteId] = self
    AQUIVER_SHARED.Utils.Print("^3Created new blip with remoteId: " .. _data.remoteId)
    TriggerEvent("onBlipCreated", self)

    return self
end

Manager.exists = function(id)
    return Manager.Entities[id] and true or false
end

Manager.get = function(id)
    return Manager.Entities[id] or nil
end

RegisterNetEvent("AQUIVER:Blip:RequestData", function()
    local source = source

    for k, v in pairs(Manager.Entities) do
        TriggerClientEvent("AQUIVER:Blip:Create", source, v.Get.Data())
    end
end)

-- Delete if another resource is restarted which has connections to this.
AddEventHandler("onResourceStop", function(resourceName)
    for k, v in pairs(Manager.Entities) do
        if v.invokedFromResource == resourceName then
            v.Destroy()
        end
    end
end)

AQUIVER_SERVER.BlipManager = Manager
