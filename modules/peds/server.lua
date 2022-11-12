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
    self.invokedFromResource = API.InvokeResourceName()
    self.data.remoteId = remoteIdCount
    remoteIdCount = remoteIdCount + 1

    Manager.Entities[self.data.remoteId] = self

    API.Utils.Debug.Print("^3Created new ped with remoteId: " .. self.data.remoteId)

    TriggerEvent("onPedCreated", self)

    return self
end
