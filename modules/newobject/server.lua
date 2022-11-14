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

local remoteIdCount = 1
---@type table<string, { invokedFromResource: string; cb: fun(Object: ServerObject) }[]>
local variableValidators = {}

local Manager = {}

---@type { [number]: ServerObject }
Manager.Entities = {}

---@param data MysqlObjectInterface
Manager.new = function(data)
    ---@class ServerObject
    local self = {}

    if type(data.model) ~= "string" then
        AQUIVER_SHARED.Utils.Print("^1Object could not get created: model is not a string.")
        return
    end

    if type(data.x) ~= "number" or type(data.x) ~= "number" or type(data.z) ~= "number" then
        AQUIVER_SHARED.Utils.Print("^1Object could not get created: position is not a vector3.")
        return
    end

    data.rx = type(data.rx) == "number" and data.rx or 0.0
    data.ry = type(data.ry) == "number" and data.ry or 0.0
    data.rz = type(data.rz) == "number" and data.rz or 0.0
    data.alpha = type(data.alpha) == "number" and data.alpha or 255
    data.hide = type(data.hide) == "boolean" and data.hide or false
    data.dimension = type(data.dimension) == "number" and data.dimension or CONFIG.DEFAULT_DIMENSION

    if type(data.variables) ~= "table" then
        data.variables = json.decode(data.variables) or {}
    end

    self.data = data
    self.invokedFromResource = AQUIVER_SHARED.Utils.GetInvokingResource()
    self.data.remoteId = remoteIdCount
    self.data.variables.hasAction = false
    remoteIdCount = remoteIdCount + 1
    ---@type fun(Player: ServerPlayer, Object: ServerObject)
    self.onPress = nil

    if Manager.exists(self.data.remoteId) then
        AQUIVER_SHARED.Utils.Print("^1Object already exists with remoteId: " .. self.data.remoteId)
        return
    end

    self.Destroy = function()
        -- Delete from table.
        if Manager.exists(self.data.remoteId) then
            Manager.Entities[self.data.remoteId] = nil
        end

        TriggerClientEvent("AQUIVER:Object:Destroy", -1, self.data.remoteId)
        TriggerEvent("onObjectDestroyed", self)
        AQUIVER_SHARED.Utils.Print("^3Removed object with remoteId: " .. self.data.remoteId)

        if GetResourceState("oxmysql") == "started" then
            exports.oxmysql:query(
                "DELETE FROM av_module_objects WHERE id = @id",
                {
                    ["@id"] = self.data.id
                }
            )
        end

        AQUIVER_SHARED.Utils.Print("^3Removed object with remoteId: " .. self.data.remoteId)
    end

    self.RunValidators = function()
        local validators = Manager.GetVariableValidator(self.data.model)

        if validators then
            for i = 1, #validators, 1 do
                validators[i].cb(self)
            end
        end
    end

    self.Get = {
        Position = function()
            return vector3(self.data.x, self.data.y, self.data.z)
        end,
        Rotation = function()
            return vector3(self.data.rx, self.data.ry, self.data.rz)
        end,
        Model = function()
            return self.data.model
        end,
        Alpha = function()
            return self.data.alpha
        end,
        Hide = function()
            return self.data.hide
        end,
        Dimension = function()
            return self.data.dimension
        end,
        Variables = function()
            return self.data.variables
        end,
        Variable = function(key)
            return self.data.variables[key] or nil
        end,
        RemoteId = function()
            return self.data.remoteId
        end,
        MysqlId = function()
            return self.data.id
        end
    }

    self.Set = {
        Position = function(x, y, z)
            if self.data.x == x and self.data.y == y and self.data.z == z then return end

            self.data.x = x
            self.data.y = y
            self.data.z = z

            self.Sync.Position()
            self.Save.Position()
        end,
        Rotation = function(rx, ry, rz)
            if self.data.rx == rx and self.data.ry == ry and self.data.rz == rz then return end

            self.data.rx = rx
            self.data.ry = ry
            self.data.rz = rz

            self.Sync.Rotation()
            self.Save.Rotation()
        end,
        Model = function(model)
            if self.data.model == model then return end

            self.data.model = model

            self.Sync.Model()
            self.Save.Model()
        end,
        Alpha = function(alpha)
            if self.data.alpha == alpha then return end

            self.data.alpha = alpha

            self.Sync.Alpha()
        end,
        Hide = function(state)
            if self.data.hide == state then return end

            self.data.hide = state

            self.Sync.Hide()
        end,
        Dimension = function(dimension)
            if self.data.dimension == dimension then return end

            self.data.dimension = dimension

            self.Sync.Dimension()
            self.Save.Dimension()
        end,
        Variable = function(key, value)
            -- If its the same value do not trigger because stack overflow will happen.
            if self.data.variables[key] == value then return end

            -- self.RunValidators()

            self.data.variables[key] = value

            TriggerEvent("onObjectVariableChange", self, key, value)

            self.Sync.Variables()
            self.Save.Variables()
        end
    }

    self.Sync = {
        Position = function()
            TriggerClientEvent("AQUIVER:Object:Update:Position", -1, self.data.remoteId, self.data.x, self.data.y,
                self.data.z)
        end,
        Rotation = function()
            TriggerClientEvent("AQUIVER:Object:Update:Rotation", -1, self.data.remoteId, self.data.rx, self.data.ry,
                self.data.rz)
        end,
        Model = function()
            TriggerClientEvent("AQUIVER:Object:Update:Model", -1, self.data.remoteId, self.data.model)
        end,
        Alpha = function()
            TriggerClientEvent("AQUIVER:Object:Update:Alpha", -1, self.data.remoteId, self.data.alpha)
        end,
        Hide = function()
            TriggerClientEvent("AQUIVER:Object:Update:Hide", -1, self.data.remoteId, self.data.hide)
        end,
        Dimension = function()
            TriggerClientEvent("AQUIVER:Object:Update:Dimension", -1, self.data.remoteId, self.data.dimension)
        end,
        Variables = function()
            TriggerClientEvent("AQUIVER:Object:Update:Variables", -1, self.data.remoteId, self.data.variables)
        end
    }

    self.Save = {
        Position = function()
            if GetResourceState("oxmysql") == "started" then
                exports.oxmysql:query(
                    "UPDATE av_module_objects SET x = @x, y = @y, z = @z WHERE id = @id",
                    {
                        ["@id"] = self.data.id,
                        ["@x"] = self.data.x,
                        ["@y"] = self.data.y,
                        ["@z"] = self.data.z,
                    }
                )
            end
        end,
        Rotation = function()
            if GetResourceState("oxmysql") == "started" then
                exports.oxmysql:query(
                    "UPDATE av_module_objects SET rx = @rx, ry = @ry, rz = @rz WHERE id = @id",
                    {
                        ["@id"] = self.data.id,
                        ["@rx"] = self.data.rx,
                        ["@ry"] = self.data.ry,
                        ["@rz"] = self.data.rz,
                    }
                )
            end
        end,
        Model = function()
            if GetResourceState("oxmysql") == "started" then
                exports.oxmysql:query(
                    "UPDATE av_module_objects SET model = @model WHERE id = @id",
                    {
                        ["@id"] = self.data.id,
                        ["@model"] = self.data.model,
                    }
                )
            end
        end,
        Dimension = function()
            if GetResourceState("oxmysql") == "started" then
                exports.oxmysql:query(
                    "UPDATE av_module_objects SET dimension = @dimension WHERE id = @id",
                    {
                        ["@id"] = self.data.id,
                        ["@dimension"] = self.data.dimension,
                    }
                )
            end
        end,
        Variables = function()
            if GetResourceState("oxmysql") == "started" then
                exports.oxmysql:query(
                    "UPDATE av_module_objects SET variables = @variables WHERE id = @id",
                    {
                        ["@id"] = self.data.id,
                        ["@variables"] = json.encode(self.data.variables) or {},
                    }
                )
            end
        end
    }

    TriggerClientEvent("AQUIVER:Object:Create", -1, self.data)
    Manager.Entities[self.data.remoteId] = self

    AQUIVER_SHARED.Utils.Print("^3Created new object with remoteId: " .. self.data.remoteId)
    TriggerEvent("onObjectCreated", self)

    return self
end

---@param data MysqlObjectInterface
---@async
Manager.InsertSQL = function(data)
    AQUIVER_SHARED.Utils.Print("^4Inserting SQL Object...")

    if GetResourceState("oxmysql") == "started" then
        local insertId = exports.oxmysql:insert_async(
            "INSERT INTO av_module_objects (model,x,y,z,rx,ry,rz,dimension,variables) VALUES (@model,@x,@y,@z,@rx,@ry,@rz,@dimension,@variables)"
            ,
            {
                ["@model"] = data.model,
                ["@x"] = data.x,
                ["@y"] = data.y,
                ["@z"] = data.z,
                ["@rx"] = type(data.rx) == "number" and data.rx or 0,
                ["@ry"] = type(data.ry) == "number" and data.ry or 0,
                ["@rz"] = type(data.rz) == "number" and data.rz or 0,
                ["@dimension"] = type(data.dimension) == "number" and data.dimension or CONFIG.DEFAULT_DIMENSION,
                ["@variables"] = json.encode(data.variables) or {}
            }
        )
        if type(insertId) == "number" then
            local dataResponse = exports.oxmysql:single_async(
                "SELECT * FROM av_module_objects WHERE id = @id",
                {
                    ["@id"] = insertId
                }
            )
            if dataResponse then
                return Manager.new(dataResponse)

            end
        end
    end
end

Manager.LoadObjectsFromSQL = function()
    if GetResourceState("oxmysql") == "started" then
        exports.oxmysql:query(
            "SELECT * FROM av_module_objects",
            function(response)
                if response and type(response) == "table" then
                    AQUIVER_SHARED.Utils.Print(string.format("^4Loading %d objects...", #response))

                    for i = 1, #response do
                        Manager.new(response[i])

                    end

                    AQUIVER_SHARED.Utils.Print("^4Objects successfully loaded.")
                end
            end
        )
    end
end

---@param cb fun(Object: ServerObject)
Manager.AddVariableValidator = function(model, cb)
    if not Citizen.GetFunctionReference(cb) then
        AQUIVER_SHARED.Utils.Print("^1Object validator should be a function.")
        return
    end

    if type(variableValidators[model]) ~= "table" then
        variableValidators[model] = {}
    end

    table.insert(variableValidators[model], {
        cb = cb,
        invokedFromResource = AQUIVER_SHARED.Utils.GetInvokingResource()
    })

    for k, v in pairs(Manager.Entities) do

        if v.data.model == model then
            v.RunValidators()
        end
    end
end

Manager.GetVariableValidator = function(model)
    return type(variableValidators[model]) == "table" and variableValidators[model] or nil
end

Manager.exists = function(id)
    return Manager.Entities[id] and true or false
end

Manager.get = function(id)
    return Manager.exists(id) and Manager.Entities[id] or nil
end

Manager.getAll = function()
    return Manager.Entities
end

Manager.atRemoteId = function(remoteId)
    for k, v in pairs(Manager.Entities) do
        if v.data.remoteId == remoteId then
            return v
        end
    end
end

Manager.atMysqlId = function(mysqlId)
    for k, v in pairs(Manager.Entities) do
        if v.data.id == mysqlId then
            return v
        end
    end
end

Manager.GetObjectsInRange = function(vec3, model, range)
    local collectedObjects = {}

    if type(vec3) ~= "vector3" then return end

    for k, v in pairs(Manager.Entities) do
        if model then
            if v.Get.Model() == model then
                local dist = #(v.Get.Position() - vec3)
                if dist < range then
                    collectedObjects[#collectedObjects + 1] = v
                end
            end
        else
            local dist = #(v.Get.Position() - vec3)
            if dist < range then
                collectedObjects[#collectedObjects + 1] = v
            end
        end
    end

    return collectedObjects
end

Manager.GetNearestObject = function(vec3, model, range)
    local rangeMeter = range
    local closest

    if type(vec3) ~= "vector3" then return end

    for k, v in pairs(Manager.Entities) do
        if model then
            if v.Get.Model() == model then
                local dist = #(v.Get.Position() - vec3)

                if dist < rangeMeter then
                    rangeMeter = dist
                    closest = v
                end
            end
        else
            local dist = #(v.Get.Position() - vec3)

            if dist < rangeMeter then
                rangeMeter = dist
                closest = v
            end
        end
    end

    return closest
end

RegisterNetEvent("AQUIVER:Object:RequestData", function()
    local source = source

    for k, v in pairs(Manager.Entities) do
        TriggerClientEvent("AQUIVER:Object:Create", source, v.data)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    for k, v in pairs(Manager.Entities) do
        if v.invokedFromResource == resourceName then
            v.Destroy()
        end
    end
end)

AQUIVER_SERVER.ObjectManager = Manager
