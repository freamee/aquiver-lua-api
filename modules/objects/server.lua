local remoteIdCount = 1
---@type table<string, { invokedFromResource: string; cb: fun(Object:SObject) }[]>
local VariableValidators = {}

---@param data MysqlObjectInterface
API.Objects.new = function(data)
    ---@class SObject
    local self = {}

    if type(data.model) ~= "string" then
        API.Utils.Debug.Print("^1Object could not get created: model is not a string.")
        return
    end

    if type(data.x) ~= "number" or type(data.x) ~= "number" or type(data.z) ~= "number" then
        API.Utils.Debug.Print("^1Object could not get created: position is not a vector3.")
        return
    end

    if type(data.rx) ~= "number" or type(data.ry) ~= "number" or type(data.rz) ~= "number" then
        data.rx = 0.0
        data.ry = 0.0
        data.rz = 0.0
    end

    if type(data.variables) ~= "table" then
        data.variables = json.decode(data.variables) or {}
    end

    if type(data.alpha) ~= "number" then
        data.alpha = 255
    end

    if type(data.hide) ~= "boolean" then
        data.hide = false
    end

    if type(data.dimension) ~= "number" then
        data.dimension = CONFIG.DEFAULT_DIMENSION
    end

    self.data = data

    self.invokedFromResource = API.InvokeResourceName()
    self.data.remoteId = remoteIdCount
    remoteIdCount = (remoteIdCount or 0) + 1

    if API.Objects.exists(self.data.remoteId) then
        API.Utils.Debug.Print("^1Object already exists with remoteId: " .. self.data.remoteId)
        return
    end

    self.SetVariables = function(vars)
        if type(vars) ~= "table" then
            API.Utils.Debug.Print("^1Object SetVariables failed: vars should be a key-value table.")
            return
        end

        for k, v in pairs(vars) do
            self.data.variables[k] = v
        end

        self.SyncVariables()
    end

    self.SetVariable = function(key, value)
        self.data.variables[key] = value
        self.SyncVariables()
        TriggerEvent("onObjectVariableChange", self, key, value)
    end

    self.RemoveVariable = function(key)
        self.data.variables[key] = nil
        self.SyncVariables()
        TriggerEvent("onObjectVariableChange", self, key, value)
    end

    self.SyncVariables = function()
        local validators = API.Objects.GetVariableValidator(self.data.model)
        if validators then
            for i = 1, #validators, 1 do
                validators[i].cb(self)
            end
        end

        TriggerClientEvent("AQUIVER:Object:Update:Variables", -1, self.data.remoteId, self.data.variables)

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

    self.SetPosition = function(x, y, z)
        if self.data.x == x and self.data.y == y and self.data.z == z then return end

        self.data.x = x
        self.data.y = y
        self.data.z = z

        TriggerClientEvent("AQUIVER:Object:Update:Position", -1, self.data.remoteId, x, y, z)

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
    end

    self.SetRotation = function(rx, ry, rz)
        if self.data.rx == rx and self.data.ry == ry and self.data.rz == rz then return end

        self.data.rx = rx
        self.data.ry = ry
        self.data.rz = rz

        TriggerClientEvent("AQUIVER:Object:Update:Rotation", -1, self.data.remoteId, rx, ry, rz)

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
    end

    self.SetModel = function(model)
        if self.data.model == model then return end

        self.data.model = model

        TriggerClientEvent("AQUIVER:Object:Update:Model", -1, self.data.remoteId, model)

        if GetResourceState("oxmysql") == "started" then
            exports.oxmysql:query(
                "UPDATE av_module_objects SET model = @model WHERE id = @id",
                {
                    ["@id"] = self.data.id,
                    ["@model"] = self.data.model,
                }
            )
        end
    end

    self.SetAlpha = function(alpha)
        if self.data.alpha == alpha then return end

        self.data.alpha = alpha

        TriggerClientEvent("AQUIVER:Object:Update:Alpha", -1, self.data.remoteId, alpha)
    end

    self.SetHide = function(state)
        if self.data.hide == state then return end

        self.data.hide = state

        TriggerClientEvent("AQUIVER:Object:Update:Hide", -1, self.data.remoteId, state)
    end

    self.GetDimension = function()
        return self.data.dimension
    end

    self.SetDimension = function(dimension)
        if self.data.dimension == dimension then return end

        self.data.dimension = dimension

        TriggerClientEvent("AQUIVER:Object:Update:Dimension", -1, self.data.remoteId, dimension)

        if GetResourceState("oxmysql") == "started" then
            exports.oxmysql:query(
                "UPDATE av_module_objects SET dimension = @dimension WHERE id = @id",
                {
                    ["@id"] = self.data.id,
                    ["@dimension"] = self.data.dimension,
                }
            )
        end
    end

    self.GetRotationVector3 = function()
        return vector3(self.data.rx, self.data.ry, self.data.rz)
    end

    self.GetPositionVector3 = function()
        return vector3(self.data.x, self.data.y, self.data.z)
    end

    self.Destroy = function()
        -- Delete from table.
        if API.Objects.exists(self.data.remoteId) then
            API.Objects.Entities[self.data.remoteId] = nil
        end

        TriggerClientEvent("AQUIVER:Object:Destroy", -1, self.data.remoteId)
        TriggerEvent("onObjectDestroyed", self)

        if GetResourceState("oxmysql") == "started" then
            exports.oxmysql:query(
                "DELETE FROM av_module_objects WHERE id = @id",
                {
                    ["@id"] = self.data.id
                }
            )
        end

        API.Utils.Debug.Print("^3Removed object with remoteId: " .. self.data.remoteId)
    end

    TriggerClientEvent("AQUIVER:Object:Create", -1, self.data)

    API.Objects.Entities[self.data.remoteId] = self

    API.Utils.Debug.Print("^3Created new object with remoteId: " .. self.data.remoteId)

    TriggerEvent("onObjectCreated", self)

    return self
end

---@param data MysqlObjectInterface
---@async
API.Objects.InsertSQL = function(data)
    API.Utils.Debug.Print("^4Inserting SQL Object...")

    if GetResourceState("oxmysql") == "started" then
        local insertId = exports.oxmysql:insert_async(
            "INSERT INTO av_module_objects (model,x,y,z,rx,ry,rz,variables) VALUES (@model,@x,@y,@z,@rx,@ry,@rz,@variables)"
            ,
            {
                ["@model"] = data.model,
                ["@x"] = data.x,
                ["@y"] = data.y,
                ["@z"] = data.z,
                ["@rx"] = data.rx or 0,
                ["@ry"] = data.ry or 0,
                ["@rz"] = data.rz or 0,
                ["@dimension"] = data.dimension or CONFIG.DEFAULT_DIMENSION,
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
                return API.Objects.new(dataResponse)
            end
        end
    end
end

API.Objects.LoadObjectsFromSQL = function()
    if GetResourceState("oxmysql") == "started" then
        exports.oxmysql:query(
            "SELECT * FROM av_module_objects",
            function(response)
                if response and type(response) == "table" then
                    API.Utils.Debug.Print(string.format("^4Loading %d objects...", #response))

                    for i = 1, #response do
                        API.Objects.new(response[i])
                    end

                    API.Utils.Debug.Print("^4Objects successfully loaded.")
                end
            end
        )
    end
end


---@param validatorFunction fun(Object:CObject)
API.Objects.AddVariableValidator = function(model, validatorFunction)
    if not Citizen.GetFunctionReference(validatorFunction) then
        API.Utils.Debug.Print("^1Object validator should be a function.")
        return
    end

    if type(VariableValidators[model]) ~= "table" then
        VariableValidators[model] = {}
    end

    table.insert(VariableValidators[model], {
        cb = validatorFunction,
        invokedFromResource = API.InvokeResourceName()
    })

    for k,v in pairs(API.Objects.Entities) do
        if v.data.model == model then
            v.SyncVariables()
        end
    end
end

API.Objects.GetVariableValidator = function(model)
    if type(VariableValidators[model]) == "table" then
        return VariableValidators[model]
    end
end

RegisterNetEvent("AQUIVER:Object:RequestData", function()
    local source = source

    for k, v in pairs(API.Objects.Entities) do
        TriggerClientEvent("AQUIVER:Object:Create", source, v.data)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    -- Destroy objects.
    for k, v in pairs(API.Objects.Entities) do
        if v.invokedFromResource == resourceName then
            v.Destroy()
        end
    end

    -- Remove variable validators when the specified resource is stopped.
    for k,v in pairs(VariableValidators) do
        for i = 1, #v, 1 do
            if v[i].invokedFromResource == resourceName then
                table.remove(VariableValidators[k], i)
            end
        end
    end
end)