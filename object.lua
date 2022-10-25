local IS_SERVER = IsDuplicityVersion()

API.ObjectManager = {}
API.ObjectManager.Entities = {}

---@class MysqlObjectInterface
---@field id? number
---@field model string
---@field x number
---@field y number
---@field z number
---@field rx number
---@field ry number
---@field rz number
---@field variables table
---@field alpha number
---@field hide boolean

API.ObjectManager.new = function(data)
    ---@class CObject
    local self = {}

    self.data = data


    return self
end

API.ObjectManager.exists = function(id)
    if API.ObjectManager.Entities[id] then
        return true
    end
end

API.ObjectManager.get = function(id)
    return API.ObjectManager.Entities[id]
end

API.ObjectManager.getAll = function()
    return API.ObjectManager.Entities
end
