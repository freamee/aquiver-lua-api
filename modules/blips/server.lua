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

    self.data = data
    self.data.display = type(self.data.display) == "number" and self.data.display or 4
    self.data.shortRange = type(self.data.shortRange) == "boolean" and self.data.shortRange or true
    self.data.scale = type(self.data.scale) == "number" and self.data.scale or 1.0
    self.data.alpha = type(self.data.alpha) == "number" and self.data.alpha or 255
    self.data.remoteId = remoteIdCount
    remoteIdCount = remoteIdCount + 1
    self.invokedFromResource = API.InvokeResourceName()

    if Manager.exists(self.data.remoteId) then
        API.Utils.Debug.Print("^1Blip already exists with remoteId: " .. self.data.remoteId)
        return
    end

    self.Set = {
        Position = function(position)
            self.data.position = position
            self.Sync.Position()
        end,
        Name = function(name)
            self.data.name = name
            self.Sync.Name()
        end,
        Scale = function(scale)
            self.data.scale = scale
            self.Sync.Scale()
        end,
        ShortRange = function(state)
            self.data.shortRange = state
            self.Sync.ShortRange()
        end,
        Display = function(displayId)
            self.data.display = displayId
            self.Sync.Display()
        end,
        Sprite = function(spriteId)
            self.data.sprite = spriteId
            self.Sync.Sprite()
        end,
        Alpha = function(alpha)
            self.data.alpha = alpha
            self.Sync.Alpha()
        end,
        Color = function(color)
            self.data.color = color
            self.Sync.Color()
        end
    }

    self.Sync = {
        Position = function()
            TriggerClientEvent("AQUIVER:Blip:Update:Position", -1, self.data.remoteId, position)
        end,
        Name = function()
            TriggerClientEvent("AQUIVER:Blip:Update:Name", -1, self.data.remoteId, name)
        end,
        Scale = function()
            TriggerClientEvent("AQUIVER:Blip:Update:Scale", -1, self.data.remoteId, scale)
        end,
        ShortRange = function()
            TriggerClientEvent("AQUIVER:Blip:Update:ShortRange", -1, self.data.remoteId, state)
        end,
        Display = function()
            TriggerClientEvent("AQUIVER:Blip:Update:Display", -1, self.data.remoteId, displayId)
        end,
        Sprite = function()
            TriggerClientEvent("AQUIVER:Blip:Update:Sprite", -1, self.data.remoteId, sprite)
        end,
        Alpha = function()
            TriggerClientEvent("AQUIVER:Blip:Update:Alpha", -1, self.data.remoteId, alpha)
        end,
        Color = function()
            TriggerClientEvent("AQUIVER:Blip:Update:Color", -1, self.data.remoteId, color)
        end
    }

    self.Destroy = function()
        -- Delete from table
        if Manager.exists(self.data.remoteId) then
            Manager.Entities[self.data.remoteId] = nil
        end

        TriggerClientEvent("AQUIVER:Blip:Destroy", -1, self.data.remoteId)
    end

    TriggerClientEvent("AQUIVER:Blip:Create", -1, self.data)
    Manager.Entities[self.data.remoteId] = self
    API.Utils.Debug.Print("^3Created new blip with remoteId: " .. self.data.remoteId)
    TriggerEvent("onBlipCreated", self)

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

RegisterNetEvent("AQUIVER:Blip:RequestData", function()
    local source = source

    for k, v in pairs(Manager.Entities) do
        TriggerClientEvent("AQUIVER:Blip:Create", source, v.data)
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
