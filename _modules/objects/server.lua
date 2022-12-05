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
---@field dimension number
---@field remoteId? number
---@field resource string
---@field attachments? { [string]: boolean }

---@type { [string]: fun(Object: SAquiverObject)[] }
local variableValidators = {}

local remoteIdCount = 1
---@class SObjectModule
local Module = {}
---@type { [number]: SAquiverObject }
Module.Entities = {}

---@class SAquiverObject
local Object = {
    ---@type MysqlObjectInterface
    data = {},
    ---@type fun(Player: SAquiverPlayer, Object: SAquiverObject)
    onPress = nil,
    ---@type { [string]: boolean }
    attachments = {}
}
Object.__index = Object

---@param d MysqlObjectInterface
Object.new = function(d)
    local self = setmetatable({}, Object)

    self.data = d
    self.data.remoteId = remoteIdCount
    remoteIdCount = (remoteIdCount or 0) + 1
    self.onPress = nil
    self.data.attachments = type(self.data.attachments) == "table" and self.data.attachments or {}

    if Module:exists(self.data.remoteId) then
        Shared.Utils.Print:Error("^1Object already exists with remoteId: " .. self.data.remoteId)
        return
    end

    self:__init__()

    Module.Entities[self.data.remoteId] = self

    Shared.Utils.Print:Debug("^3Created new object with remoteId: " .. self.data.remoteId)
    Shared.EventManager:TriggerModuleClientEvent("Object:Create", -1, self.data)
    Shared.EventManager:TriggerModuleEvent("onObjectCreated", self.data.remoteId)

    return self
end

function Object:__init__()
    if type(self.data.model) ~= "string" then
        Shared.Utils.Print:Error("^1Object could not get created: model is not a string.")
        return
    end

    if type(self.data.x) ~= "number" or type(self.data.x) ~= "number" or type(self.data.z) ~= "number" then
        Shared.Utils.Print:Error("^1Object could not get created: position is not a vector3.")
        return
    end

    self.data.rx = type(self.data.rx) == "number" and self.data.rx or 0.0
    self.data.ry = type(self.data.ry) == "number" and self.data.ry or 0.0
    self.data.rz = type(self.data.rz) == "number" and self.data.rz or 0.0
    self.data.alpha = type(self.data.alpha) == "number" and self.data.alpha or 255
    self.data.hide = type(self.data.hide) == "boolean" and self.data.hide or false
    self.data.dimension = type(self.data.dimension) == "number" and self.data.dimension or
        Shared.Config.DEFAULT_DIMENSION

    if type(self.data.variables) ~= "table" then
        self.data.variables = json.decode(self.data.variables) or {}
    end

    self:setVar("hasAction", false)

    self:runValidators()
end

function Object:Destroy()
    if Module:exists(self.data.remoteId) then
        Module.Entities[self.data.remoteId] = nil
    end

    Shared.EventManager:TriggerModuleClientEvent("Object:Destroy", -1, self.data.remoteId)
    Shared.EventManager:TriggerModuleEvent("onObjectDestroyed", self.data)

    Shared.Utils.Print:Debug("^3Removed object with remoteId: " .. self.data.remoteId)

    if GetResourceState("oxmysql") == "started" then
        exports.oxmysql:query(
            "DELETE FROM avp_module_objects WHERE id = @id",
            {
                ["@id"] = self.data.id
            }
        )
    end
end

function Object:getVector3Position()
    return vector3(self.data.x, self.data.y, self.data.z)
end

function Object:getVector3Rotation()
    return vector3(self.data.rx, self.data.ry, self.data.rz)
end

function Object:setPosition(x, y, z)
    if self.data.x == x and self.data.y == y and self.data.z == z then return end

    self.data.x = x
    self.data.y = y
    self.data.z = z

    Shared.EventManager:TriggerModuleClientEvent(
        "Object:Update:Position",
        -1,
        self.data.remoteId,
        self.data.x,
        self.data.y,
        self.data.z
    )

    if GetResourceState("oxmysql") == "started" then
        exports.oxmysql:query(
            "UPDATE avp_module_objects SET x = @x, y = @y, z = @z WHERE id = @id",
            {
                ["@id"] = self.data.id,
                ["@x"] = self.data.x,
                ["@y"] = self.data.y,
                ["@z"] = self.data.z,
            }
        )
    end
end

function Object:setRotation(rx, ry, rz)
    if self.data.rx == rx and self.data.ry == ry and self.data.rz == rz then return end

    self.data.rx = rx
    self.data.ry = ry
    self.data.rz = rz

    Shared.EventManager:TriggerModuleClientEvent(
        "Object:Update:Rotation",
        -1,
        self.data.remoteId,
        self.data.rx,
        self.data.ry,
        self.data.rz
    )

    if GetResourceState("oxmysql") == "started" then
        exports.oxmysql:query(
            "UPDATE avp_module_objects SET rx = @rx, ry = @ry, rz = @rz WHERE id = @id",
            {
                ["@id"] = self.data.id,
                ["@rx"] = self.data.rx,
                ["@ry"] = self.data.ry,
                ["@rz"] = self.data.rz,
            }
        )
    end
end

function Object:setModel(model)
    if self.data.model == model then return end

    self.data.model = model

    Shared.EventManager:TriggerModuleClientEvent(
        "Object:Update:Model",
        -1,
        self.data.remoteId,
        self.data.model
    )

    if GetResourceState("oxmysql") == "started" then
        exports.oxmysql:query(
            "UPDATE avp_module_objects SET model = @model WHERE id = @id",
            {
                ["@id"] = self.data.id,
                ["@model"] = self.data.model,
            }
        )
    end
end

function Object:setAlpha(alpha)
    if self.data.alpha == alpha then return end

    self.data.alpha = alpha

    Shared.EventManager:TriggerModuleClientEvent(
        "Object:Update:Alpha",
        -1,
        self.data.remoteId,
        self.data.alpha
    )
end

function Object:setHide(state)
    if self.data.hide == state then return end

    self.data.hide = state

    Shared.EventManager:TriggerModuleClientEvent(
        "Object:Update:Hide",
        -1,
        self.data.remoteId,
        self.data.hide
    )
end

function Object:setDimension(dimension)
    if self.data.dimension == dimension then return end

    self.data.dimension = dimension

    Shared.EventManager:TriggerModuleClientEvent(
        "Object:Update:Dimension",
        -1,
        self.data.remoteId,
        self.data.dimension
    )

    if GetResourceState("oxmysql") == "started" then
        exports.oxmysql:query(
            "UPDATE avp_module_objects SET dimension = @dimension WHERE id = @id",
            {
                ["@id"] = self.data.id,
                ["@dimension"] = self.data.dimension,
            }
        )
    end
end

function Object:getVar(key)
    return self.data.variables[key]
end

function Object:setVar(key, value)
    if self.data.variables[key] == value then return end

    self.data.variables[key] = value

    -- Very, very important to run it after the variable is set, otherwise it will cause a stack overflow.
    self:runValidators()

    Shared.EventManager:TriggerModuleClientEvent(
        "Object:Update:VariableKey",
        -1,
        self.data.remoteId,
        key,
        self.data.variables[key]
    )

    Shared.EventManager:TriggerModuleEvent("onObjectVariableChange", self.data.remoteId, key, self.data.variables[key])

    if GetResourceState("oxmysql") == "started" then
        exports.oxmysql:query(
            "UPDATE avp_module_objects SET variables = @variables WHERE id = @id",
            {
                ["@id"] = self.data.id,
                ["@variables"] = json.encode(self.data.variables) or {},
            }
        )
    end
end

---@param vec3 { x:number; y:number; z: number; }
function Object:dist(vec3)
    return #(self:getVector3Position() - vector3(vec3.x, vec3.y, vec3.z))
end

function Object:addAttachment(attachmentName)
    if self:hasAttachment(attachmentName) then return end

    if not Shared.AttachmentManager:exists(attachmentName) then
        Shared.Utils.Print:Debug(string.format("^1%s AddAttachment not registered.", attachmentName))
        return
    end

    self.data.attachments[attachmentName] = true

    Shared.EventManager:TriggerModuleClientEvent("Object:Attachment:Add", -1, self.data.remoteId, attachmentName)
end

function Object:removeAttachment(attachmentName)
    if not self:hasAttachment(attachmentName) then return end

    self.data.attachments[attachmentName] = false

    Shared.EventManager:TriggerModuleClientEvent("Object:Attachment:Remove", -1, self.data.remoteId, attachmentName)
end

function Object:hasAttachment(attachmentName)
    return self.data.attachments[attachmentName] and true or false
end

function Object:runValidators()
    local validators = Module:getVariableValidators(self.data.model)
    if type(validators) ~= "table" then return end

    for i = 1, #validators, 1 do
        if type(validators[i]) == "function" then
            validators[i](self)
        end
    end
end

---@param d MysqlObjectInterface
function Module:new(d)
    local nObject = Object.new(d)
    if nObject then
        return nObject
    end
end

function Module:exists(remoteId)
    return self.Entities[remoteId] and true or false
end

function Module:get(remoteId)
    return self:exists(remoteId) and self.Entities[remoteId] or nil
end

function Module:atRemoteId(remoteId)
    for k, v in pairs(self.Entities) do
        if v.data.remoteId == remoteId then
            return v
        end
    end
end

function Module:atMysqlId(mysqlId)
    for k, v in pairs(self.Entities) do
        if v.data.id == mysqlId then
            return v
        end
    end
end

function Module:getObjectsInRange(vec3, model, range)
    local collectedObjects = {}

    if type(vec3) ~= "vector3" then return end

    for k, v in pairs(self.Entities) do
        if model then
            if v.data.model == model then
                local dist = v:dist(vec3)
                if dist < range then
                    collectedObjects[#collectedObjects + 1] = v
                end
            end
        else
            local dist = v:dist(vec3)
            if dist < range then
                collectedObjects[#collectedObjects + 1] = v
            end
        end
    end

    return collectedObjects
end

---@param model string | string[]
---@return SAquiverObject | nil
function Module:getNearestObject(vec3, model, range, dimension)
    local rangeMeter = range
    local closest

    if type(vec3) ~= "vector3" then return end

    for k, v in pairs(self.Entities) do
        if v.data.dimension == dimension then
            if model then
                if type(model) == "table" then
                    for i = 1, #model do
                        if v.data.model == model[i] then
                            local dist = v:dist(vec3)
                            if dist < rangeMeter then
                                rangeMeter = dist
                                closest = v
                            end
                        end
                    end
                elseif type(model) == "string" then
                    if v.data.model == model then
                        local dist = v:dist(vec3)
                        if dist < rangeMeter then
                            rangeMeter = dist
                            closest = v
                        end
                    end
                end
            else
                local dist = v:dist(vec3)
                if dist < rangeMeter then
                    rangeMeter = dist
                    closest = v
                end
            end
        end
    end

    return closest
end

---@param d MysqlObjectInterface
---@param cb? fun(Object: SAquiverObject)
---@async
function Module:insertSQL(d, cb)
    Citizen.CreateThread(function()
        if GetResourceState("oxmysql") == "started" then
            local insertId = exports.oxmysql:insert_async(
                "INSERT INTO avp_module_objects (model,x,y,z,rx,ry,rz,dimension,resource,variables) VALUES (@model,@x,@y,@z,@rx,@ry,@rz,@dimension,@resource,@variables)"
                ,
                {
                    ["@model"] = d.model,
                    ["@x"] = d.x,
                    ["@y"] = d.y,
                    ["@z"] = d.z,
                    ["@rx"] = type(d.rx) == "number" and d.rx or 0,
                    ["@ry"] = type(d.ry) == "number" and d.ry or 0,
                    ["@rz"] = type(d.rz) == "number" and d.rz or 0,
                    ["@dimension"] = type(d.dimension) == "number" and d.dimension or Shared.Config.DEFAULT_DIMENSION,
                    ["@resource"] = GetCurrentResourceName(),
                    ["@variables"] = json.encode(d.variables) or {}
                }
            )
            if type(insertId) == "number" then
                local dataResponse = exports.oxmysql:single_async(
                    "SELECT * FROM avp_module_objects WHERE id = @id",
                    {
                        ["@id"] = insertId
                    }
                )
                if dataResponse then
                    local aObject = Module:new(dataResponse)
                    if cb then cb(aObject) end
                end
            end
        end
    end)
end

function Module:loadObjectsFromSQL()
    if GetResourceState("oxmysql") == "started" then
        exports.oxmysql:query(
            "SELECT * FROM avp_module_objects WHERE resource = @resource",
            {
                ["@resource"] = GetCurrentResourceName()
            },
            function(response)
                if response and type(response) == "table" then
                    Shared.Utils.Print:Debug(string.format("^4Loading %d objects...", #response))

                    for i = 1, #response do
                        Module:new(response[i])
                    end

                    Shared.Utils.Print:Debug("^4Objects successfully loaded.")
                end
            end
        )
    end
end

---@param modelsTable string[]
---@param cb fun(Object: SAquiverObject)
function Module:addManyVariableValidators(modelsTable, cb)
    for i = 1, #modelsTable, 1 do
        local model = modelsTable[i]
        self:addVariableValidator(model, cb)
    end
end

---@param model string
---@param cb fun(Object: SAquiverObject)
function Module:addVariableValidator(model, cb)
    if type(cb) ~= "function" then
        Shared.Utils.Print:Error("^1Object validator should be a function.")
        return
    end

    if type(variableValidators[model]) ~= "table" then
        variableValidators[model] = {}
    end

    table.insert(variableValidators[model], cb)

    for k, v in pairs(self.Entities) do
        if v.data.model == model then
            v:runValidators()
        end
    end
end

function Module:getVariableValidators(model)
    return type(variableValidators[model]) == "table" and variableValidators[model] or nil
end

Shared.EventManager:RegisterModuleNetworkEvent("Object:RequestData", function()
    local source = source

    for k, v in pairs(Module.Entities) do
        Shared.EventManager:TriggerModuleClientEvent("Object:Create", source, v.data)
    end
end)

return Module
