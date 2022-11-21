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
---@field attachments { [string]: boolean }

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
    data.attachments = type(data.attachments) == "table" and data.attachments or {}

    if type(data.variables) ~= "table" then
        data.variables = json.decode(data.variables) or {}
    end

    local _data = data
    _data.remoteId = remoteIdCount
    _data.variables.hasAction = false

    remoteIdCount = remoteIdCount + 1

    self.invokedFromResource = AQUIVER_SHARED.Utils.GetInvokingResource()
    ---@type fun(Player: ServerPlayer, Object: ServerObject)
    self.onPress = nil

    if Manager.exists(_data.remoteId) then
        AQUIVER_SHARED.Utils.Print("^1Object already exists with remoteId: " .. _data.remoteId)
        return
    end

    self.AddAttachment = function(attachmentName)
        if self.HasAttachment(attachmentName) then return end

        if not AQUIVER_SHARED.AttachmentManager.exists(attachmentName) then
            AQUIVER_SHARED.Utils.Print(string.format("^1%s AddAttachment not registered.", attachmentName))
            return
        end

        _data.attachments[attachmentName] = true

        TriggerClientEvent("AQUIVER:Object:Attachment:Add", -1, _data.remoteId, attachmentName)
    end

    self.HasAttachment = function(attachmentName)
        return _data.attachments[attachmentName] and true or false
    end

    self.RemoveAttachment = function(attachmentName)
        if not self.HasAttachment(attachmentName) then return end

        _data.attachments[attachmentName] = false

        TriggerClientEvent("AQUIVER:Object:Attachment:Remove", -1, _data.remoteId, attachmentName)
    end

    ---@param cb fun(Player: ServerPlayer, Object: ServerObject)
    self.AddPressFunction = function(cb)
        if Citizen.GetFunctionReference(self.onPress) then
            AQUIVER_SHARED.Utils.Print("^Object AddPressFunction already exists, it was overwritten.")
        end

        self.onPress = cb
    end

    self.Destroy = function()
        -- Delete from table.
        if Manager.exists(_data.remoteId) then
            Manager.Entities[_data.remoteId] = nil
        end

        TriggerClientEvent("AQUIVER:Object:Destroy", -1, _data.remoteId)
        TriggerEvent("onObjectDestroyed", self)
        AQUIVER_SHARED.Utils.Print("^3Removed object with remoteId: " .. _data.remoteId)

        if GetResourceState("oxmysql") == "started" then
            exports.oxmysql:query(
                "DELETE FROM avp_module_objects WHERE id = @id",
                {
                    ["@id"] = _data.id
                }
            )
        end

        AQUIVER_SHARED.Utils.Print("^3Removed object with remoteId: " .. _data.remoteId)
    end

    self.RunValidators = function()
        local validators = Manager.GetVariableValidator(_data.model)

        if type(validators) == "table" then
            for k, v in pairs(validators) do
                v.cb(self)
            end
        end
    end

    self.Get = {
        Position = function()
            return vector3(_data.x, _data.y, _data.z)
        end,
        Rotation = function()
            return vector3(_data.rx, _data.ry, _data.rz)
        end,
        Model = function()
            return _data.model
        end,
        Alpha = function()
            return _data.alpha
        end,
        Hide = function()
            return _data.hide
        end,
        Dimension = function()
            return _data.dimension
        end,
        Variables = function()
            return _data.variables
        end,
        Variable = function(key)
            return _data.variables[key] or nil
        end,
        RemoteId = function()
            return _data.remoteId
        end,
        MysqlId = function()
            return _data.id
        end,
        Data = function()
            return _data
        end
    }

    local Sync = {
        Position = function()
            TriggerClientEvent("AQUIVER:Object:Update:Position", -1, _data.remoteId, _data.x, _data.y, _data.z)
        end,
        Rotation = function()
            TriggerClientEvent("AQUIVER:Object:Update:Rotation", -1, _data.remoteId, _data.rx, _data.ry, _data.rz)
        end,
        Model = function()
            TriggerClientEvent("AQUIVER:Object:Update:Model", -1, _data.remoteId, _data.model)
        end,
        Alpha = function()
            TriggerClientEvent("AQUIVER:Object:Update:Alpha", -1, _data.remoteId, _data.alpha)
        end,
        Hide = function()
            TriggerClientEvent("AQUIVER:Object:Update:Hide", -1, _data.remoteId, _data.hide)
        end,
        Dimension = function()
            TriggerClientEvent("AQUIVER:Object:Update:Dimension", -1, _data.remoteId, _data.dimension)
        end,
        Variables = function()
            TriggerClientEvent("AQUIVER:Object:Update:Variables", -1, _data.remoteId, _data.variables)
        end
    }

    self.Set = {
        Position = function(x, y, z)
            if _data.x == x and _data.y == y and _data.z == z then return end

            _data.x = x
            _data.y = y
            _data.z = z

            Sync.Position()
            self.Save.Position()
        end,
        Rotation = function(rx, ry, rz)
            if _data.rx == rx and _data.ry == ry and _data.rz == rz then return end

            _data.rx = rx
            _data.ry = ry
            _data.rz = rz

            Sync.Rotation()
            self.Save.Rotation()
        end,
        Model = function(model)
            if _data.model == model then return end

            _data.model = model

            Sync.Model()
            self.Save.Model()
        end,
        Alpha = function(alpha)
            if _data.alpha == alpha then return end

            _data.alpha = alpha

            Sync.Alpha()
        end,
        Hide = function(state)
            if _data.hide == state then return end

            _data.hide = state

            Sync.Hide()
        end,
        Dimension = function(dimension)
            if _data.dimension == dimension then return end

            _data.dimension = dimension

            Sync.Dimension()
            self.Save.Dimension()
        end,
        Variable = function(key, value)
            -- If its the same value do not trigger because stack overflow will happen.
            if _data.variables[key] == value then return end

            _data.variables[key] = value

            -- Very, very important to run it after the variable is set, otherwise it will cause a stack overflow.
            self.RunValidators()

            TriggerEvent("onObjectVariableChange", self, key, value)

            Sync.Variables()
            self.Save.Variables()
        end
    }

    self.Save = {
        Position = function()
            if GetResourceState("oxmysql") == "started" then
                exports.oxmysql:query(
                    "UPDATE avp_module_objects SET x = @x, y = @y, z = @z WHERE id = @id",
                    {
                        ["@id"] = _data.id,
                        ["@x"] = _data.x,
                        ["@y"] = _data.y,
                        ["@z"] = _data.z,
                    }
                )
            end
        end,
        Rotation = function()
            if GetResourceState("oxmysql") == "started" then
                exports.oxmysql:query(
                    "UPDATE avp_module_objects SET rx = @rx, ry = @ry, rz = @rz WHERE id = @id",
                    {
                        ["@id"] = _data.id,
                        ["@rx"] = _data.rx,
                        ["@ry"] = _data.ry,
                        ["@rz"] = _data.rz,
                    }
                )
            end
        end,
        Model = function()
            if GetResourceState("oxmysql") == "started" then
                exports.oxmysql:query(
                    "UPDATE avp_module_objects SET model = @model WHERE id = @id",
                    {
                        ["@id"] = _data.id,
                        ["@model"] = _data.model,
                    }
                )
            end
        end,
        Dimension = function()
            if GetResourceState("oxmysql") == "started" then
                exports.oxmysql:query(
                    "UPDATE avp_module_objects SET dimension = @dimension WHERE id = @id",
                    {
                        ["@id"] = _data.id,
                        ["@dimension"] = _data.dimension,
                    }
                )
            end
        end,
        Variables = function()
            if GetResourceState("oxmysql") == "started" then
                exports.oxmysql:query(
                    "UPDATE avp_module_objects SET variables = @variables WHERE id = @id",
                    {
                        ["@id"] = _data.id,
                        ["@variables"] = json.encode(_data.variables) or {},
                    }
                )
            end
        end
    }

    -- Run validators on create.
    self.RunValidators()

    TriggerClientEvent("AQUIVER:Object:Create", -1, _data)
    Manager.Entities[_data.remoteId] = self

    AQUIVER_SHARED.Utils.Print("^3Created new object with remoteId: " .. _data.remoteId)
    TriggerEvent("onObjectCreated", self)

    return self
end

---@param data MysqlObjectInterface
---@async
Manager.InsertSQL = function(data)
    AQUIVER_SHARED.Utils.Print("^4Inserting SQL Object...")

    if GetResourceState("oxmysql") == "started" then
        local insertId = exports.oxmysql:insert_async(
            "INSERT INTO avp_module_objects (model,x,y,z,rx,ry,rz,dimension,variables) VALUES (@model,@x,@y,@z,@rx,@ry,@rz,@dimension,@variables)"
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
                "SELECT * FROM avp_module_objects WHERE id = @id",
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
            "SELECT * FROM avp_module_objects",
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

---@param modelsTable string[]
---@param cb fun(Object: ServerObject)
Manager.AddManyVariableValidators = function(modelsTable, cb)
    for i = 1, #modelsTable do
        local model = modelsTable[i]
        Manager.AddVariableValidator(model, cb)
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
        if v.Get.Model() == model then
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

Manager.atRemoteId = function(remoteId)
    for k, v in pairs(Manager.Entities) do
        if v.Get.RemoteId() == remoteId then
            return v
        end
    end
end

Manager.atMysqlId = function(mysqlId)
    for k, v in pairs(Manager.Entities) do
        if v.Get.MysqlId() == mysqlId then
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
        TriggerClientEvent("AQUIVER:Object:Create", source, v.Get.Data())
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    for k, v in pairs(Manager.Entities) do
        if v.invokedFromResource == resourceName then
            v.Destroy()
        end
    end

    -- Remove variable validators when the specified resource is stopped.
    for _k, _v in pairs(variableValidators) do
        for k, v in pairs(_v) do
            if v.invokedFromResource == resourceName then
                table.remove(variableValidators[_k], k)
            end
        end
    end
end)

AQUIVER_SERVER.ObjectManager = Manager
