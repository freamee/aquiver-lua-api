API.ObjectManager = {}
---@type table<string, CObject>
API.ObjectManager.Entities = {}
---@type table<string, table<string, fun(Object:CObject)>>
API.ObjectManager.VariableValidators = {}
API.ObjectManager.remoteIdCount = 1

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

---@param data MysqlObjectInterface
API.ObjectManager.new = function(data)
    ---@class CObject
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

    if API.IsServer then
        self.server = {}
        self.server.invokedFromResource = API.InvokeResourceName()
        self.data.remoteId = API.ObjectManager.remoteIdCount
        API.ObjectManager.remoteIdCount = (API.ObjectManager.remoteIdCount or 0) + 1
    end

    if API.ObjectManager.exists(self.data.remoteId) then
        API.Utils.Debug.Print("^1Object already exists with remoteId: " .. self.data.remoteId)
        return
    end

    if API.IsServer then
        API.EventManager.TriggerClientLocalEvent("Object:Create", -1, self.data)

        ---@param cb fun(Player:CPlayer, Object:CObject)
        self.AddPressFunction = function(cb)
            if not Citizen.GetFunctionReference(cb) then
                API.Utils.Debug.Print("^1Object AddPressFunction failed, cb should be a function reference.")
                return
            end

            self.server.onPress = cb
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
        end

        self.SyncVariables = function()
            local validators = API.ObjectManager.GetVariableValidator(self.data.model)
            if validators then
                for i = 1, #validators, 1 do
                    validators[i](self)
                end
            end

            API.EventManager.TriggerClientLocalEvent("Object:Update:Variables", -1, self.data.remoteId,
                self.data.variables)

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

        -- Sync variables immediately here. This is a double query after it created, so yeah here we can increase performance if we want.
        self.SyncVariables()
    else
        self.client = {}
        self.client.isStreamed = false
        self.client.objectHandle = nil

        self.AddStream = function()
            if self.client.isStreamed then return end

            self.client.isStreamed = true

            local modelHash = GetHashKey(self.data.model)
            if not IsModelValid(modelHash) then return end

            API.Utils.Client.requestModel(modelHash)

            local obj = CreateObjectNoOffset(modelHash, self.GetPositionVector3(), false, false, false)
            SetEntityCoordsNoOffset(obj, self.GetPositionVector3(), false, false, false)
            SetEntityRotation(obj, self.GetRotationVector3(), 2, false)
            FreezeEntityPosition(obj, true)

            self.client.objectHandle = obj

            API.EventManager.TriggerClientGlobalEvent("onObjectStreamIn", self)

            API.Utils.Debug.Print(string.format("^3Object streamed in (%d, %s)", self.data.remoteId, self.data.model))
        end

        self.RemoveStream = function()
            if not self.client.isStreamed then return end

            if DoesEntityExist(self.client.objectHandle) then
                DeleteEntity(self.client.objectHandle)
            end

            self.client.isStreamed = false

            API.EventManager.TriggerClientGlobalEvent("onObjectStreamOut", self)

            API.Utils.Debug.Print(string.format("^3Object streamed out (%d, %s)", self.data.remoteId, self.data.model))
        end
    end

    self.GetVariables = function()
        return self.data.variables
    end

    self.GetVariable = function(key)
        return self.data.variables[key]
    end

    self.SetPosition = function(x, y, z)
        if self.data.x == x and self.data.y == y and self.data.z == z then return end

        self.data.x = x
        self.data.y = y
        self.data.z = z

        if API.IsServer then
            API.EventManager.TriggerClientLocalEvent("Object:Update:Position", -1, self.data.remoteId, x, y, z)

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
        else
            if DoesEntityExist(self.client.objectHandle) then
                SetEntityCoordsNoOffset(self.client.objectHandle, self.GetPositionVector3(), false, false, false)
            end
        end
    end

    self.SetRotation = function(rx, ry, rz)
        if self.data.rx == rx and self.data.ry == ry and self.data.rz == rz then return end

        self.data.rx = rx
        self.data.ry = ry
        self.data.rz = rz

        if API.IsServer then
            API.EventManager.TriggerClientLocalEvent("Object:Update:Rotation", -1, self.data.remoteId, rx, ry, rz)

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
        else
            if DoesEntityExist(self.client.objectHandle) then
                SetEntityRotation(self.client.objectHandle, self.GetRotationVector3(), 2, false)
            end
        end
    end

    self.SetModel = function(model)
        if self.data.model == model then return end

        self.data.model = model

        if API.IsServer then
            API.EventManager.TriggerClientLocalEvent("Object:Update:Model", -1, self.data.remoteId, model)

            if GetResourceState("oxmysql") == "started" then
                exports.oxmysql:query(
                    "UPDATE av_module_objects SET model = @model WHERE id = @id",
                    {
                        ["@id"] = self.data.id,
                        ["@model"] = self.data.model,
                    }
                )
            end
        else
            --Restream object, since we can not change the model directly on FiveM.
            self.RemoveStream()
            self.AddStream()
        end
    end

    self.SetAlpha = function(alpha)
        if self.data.alpha == alpha then return end

        self.data.alpha = alpha

        if API.IsServer then
            API.EventManager.TriggerClientLocalEvent("Object:Update:Alpha", -1, self.data.remoteId, alpha)
        else
            if DoesEntityExist(self.client.objectHandle) then
                SetEntityAlpha(self.client.objectHandle, alpha, false)
            end
        end
    end

    self.SetHide = function(state)
        if self.data.hide == state then return end

        self.data.hide = state

        if API.IsServer then
            API.EventManager.TriggerClientLocalEvent("Object:Update:Hide", -1, self.data.remoteId, state)
        else
            if DoesEntityExist(self.client.objectHandle) then
                SetEntityVisible(self.client.objectHandle, not state, 0)
                SetEntityCollision(self.client.objectHandle, not state, true)
            end
        end
    end

    self.SetDimension = function(dimension)
        if self.data.dimension == dimension then return end

        self.data.dimension = dimension

        if API.IsServer then
            API.EventManager.TriggerClientLocalEvent("Object:Update:Dimension", -1, self.data.remoteId, dimension)

            if GetResourceState("oxmysql") == "started" then
                exports.oxmysql:query(
                    "UPDATE av_module_objects SET dimension = @dimension WHERE id = @id",
                    {
                        ["@id"] = self.data.id,
                        ["@dimension"] = self.data.dimension,
                    }
                )
            end
        else
            if DoesEntityExist(self.client.objectHandle) and API.LocalPlayer.dimension ~= dimension then
                self.RemoveStream()
            end
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
        if API.ObjectManager.exists(self.data.remoteId) then
            API.ObjectManager.Entities[self.data.remoteId] = nil
        end

        if API.IsServer then
            API.EventManager.TriggerClientLocalEvent("Object:Destroy", -1, self.data.remoteId)
        else
            if DoesEntityExist(self.client.objectHandle) then
                DeleteEntity(self.client.objectHandle)
                self.client.objectHandle = nil
            end
        end

        API.Utils.Debug.Print("^3Removed object with remoteId: " .. self.data.remoteId)
    end

    API.ObjectManager.Entities[self.data.remoteId] = self

    API.Utils.Debug.Print("^3Created new object with remoteId: " .. self.data.remoteId)

    return self
end

API.ObjectManager.exists = function(id)
    if API.ObjectManager.Entities[id] then
        return true
    end
end

API.ObjectManager.get = function(id)
    if API.ObjectManager.exists(id) then
        return API.ObjectManager.Entities[id]
    end
end

API.ObjectManager.getAll = function()
    return API.ObjectManager.Entities
end

API.ObjectManager.atRemoteId = function(remoteId)
    for k, v in pairs(API.ObjectManager.Entities) do
        if v.data.remoteId == remoteId then
            return v
        end
    end
end

API.ObjectManager.atMysqlId = function(mysqlId)
    for k, v in pairs(API.ObjectManager.Entities) do
        if v.data.id == mysqlId then
            return v
        end
    end
end

API.ObjectManager.GetNearestObject = function(vec3, model, range)
    local rangeMeter = range
    local closest

    if type(vec3) ~= "vector3" then return end

    for k, v in pairs(API.ObjectManager.Entities) do
        if v.data.model == model then
            local dist = #(v.GetPositionVector3() - vec3)

            if dist < rangeMeter then
                rangeMeter = dist
                closest = v
            end
        end
    end

    return closest
end

if API.IsServer then

    ---@param data MysqlObjectInterface
    ---@async
    API.ObjectManager.InsertSQL = function(data)
        if not API.IsServer then return end

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
                    return API.ObjectManager.new(dataResponse)
                end
            end
        end
    end

    API.ObjectManager.LoadObjectsFromSQL = function()
        if not API.IsServer then return end

        if GetResourceState("oxmysql") == "started" then
            exports.oxmysql:query(
                "SELECT * FROM av_module_objects",
                function(response)
                    if response and type(response) == "table" then
                        API.Utils.Debug.Print(string.format("^4Loading %d objects...", #response))

                        for i = 1, #response do
                            API.ObjectManager.new(response[i])
                        end

                        API.Utils.Debug.Print("^4Objects successfully loaded.")
                    end
                end
            )
        end
    end

    ---@param validatorFunction fun(Object:CObject)
    API.ObjectManager.AddVariableValidator = function(model, validatorFunction)
        if type(validatorFunction) ~= "function" then
            API.Utils.Debug.Print("^1Object validator should be a function.")
            return
        end

        if not API.ObjectManager.VariableValidators[model] then
            API.ObjectManager.VariableValidators[model] = {}
        end

        table.insert(API.ObjectManager.VariableValidators[model], validatorFunction)
    end

    API.ObjectManager.GetVariableValidator = function(model)
        if type(API.ObjectManager.VariableValidators[model]) == "table" then
            return API.ObjectManager.VariableValidators[model]
        end
    end

    AddEventHandler("onResourceStart", function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end

        API.EventManager.AddLocalEvent("Object:RequestData", function()
            local source = source

            for k, v in pairs(API.ObjectManager.Entities) do
                API.EventManager.TriggerClientLocalEvent("Object:Create", source, v.data)
            end
        end)

        API.ObjectManager.AddVariableValidator("avp_wooden_barrel", function(Object)
            local vars = Object.data.variables

            vars.woodenBarrelLitre = API.Utils.RoundNumber((vars.woodenBarrelLitre or 0), 1)
            vars.woodenBarrelAlcoholPercentage = API.Utils.RoundNumber((vars.woodenBarrelAlcoholPercentage or 0), 1)
            vars.woodenBarrelAge = API.Utils.RoundNumber((vars.woodenBarrelAge or 0), 0)

            -- Reset if the litre is less then zero.
            if vars.woodenBarrelLitre <= 0 then
                vars.woodenBarrelItem = nil
                vars.woodenBarrelAlcoholPercentage = 0
                vars.woodenBarrelAge = 0
            end
        end)
    end)

    AddEventHandler("onResourceStop", function(resourceName)
        for k, v in pairs(API.ObjectManager.Entities) do
            if v.server.invokedFromResource == resourceName then
                v.Destroy()
            end
        end
    end)
else

    API.ObjectManager.atHandle = function(handleId)
        if API.IsServer then return end

        for k, v in pairs(API.ObjectManager.Entities) do
            if v.client.objectHandle == handleId then
                return v
            end
        end
    end

    AddEventHandler("onResourceStop", function(resourceName)
        if resourceName ~= GetCurrentResourceName() then return end

        for k, v in pairs(API.ObjectManager.Entities) do
            v.Destroy()
        end
    end)

    AddEventHandler("onClientResourceStart", function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end

        API.EventManager.AddLocalEvent({
            ["Object:Create"] = function(data)
                API.ObjectManager.new(data)
            end,
            ["Object:Update:Position"] = function(remoteId, x, y, z)
                local ObjectEntity = API.ObjectManager.get(remoteId)
                if not ObjectEntity then return end
                ObjectEntity.SetPosition(x, y, z)
            end,
            ["Object:Update:Rotation"] = function(remoteId, rx, ry, rz)
                local ObjectEntity = API.ObjectManager.get(remoteId)
                if not ObjectEntity then return end
                ObjectEntity.SetRotation(rx, ry, rz)
            end,
            ["Object:Update:Model"] = function(remoteId, model)
                local ObjectEntity = API.ObjectManager.get(remoteId)
                if not ObjectEntity then return end
                ObjectEntity.SetModel(model)
            end,
            ["Object:Update:Alpha"] = function(remoteId, alpha)
                local ObjectEntity = API.ObjectManager.get(remoteId)
                if not ObjectEntity then return end
                ObjectEntity.SetAlpha(alpha)
            end,
            ["Object:Update:Variables"] = function(remoteId, variables)
                local ObjectEntity = API.ObjectManager.get(remoteId)
                if not ObjectEntity then return end
                ObjectEntity.data.variables = variables
            end,
            ["Object:Update:Hide"] = function(remoteId, state)
                local ObjectEntity = API.ObjectManager.get(remoteId)
                if not ObjectEntity then return end
                ObjectEntity.SetHide(state)
            end,
            ["Object:Update:Dimension"] = function(remoteId, dimension)
                local ObjectEntity = API.ObjectManager.get(remoteId)
                if not ObjectEntity then return end
                ObjectEntity.SetDimension(dimension)
            end,
            ["Object:Destroy"] = function(remoteId)
                local ObjectEntity = API.ObjectManager.get(remoteId)
                if not ObjectEntity then return end
                ObjectEntity.Destroy()
            end
        })

        Citizen.CreateThread(function()
            while true do

                if NetworkIsPlayerActive(PlayerId()) then
                    -- Request Data from server.
                    API.EventManager.TriggerServerLocalEvent("Object:RequestData")
                    break
                end

                Citizen.Wait(500)
            end
        end)

        -- STREAMING HANDLER.
        Citizen.CreateThread(function()
            while true do

                local playerPos = GetEntityCoords(PlayerPedId())

                for k, v in pairs(API.ObjectManager.Entities) do

                    -- If dimension is not equals.
                    if API.LocalPlayer.dimension ~= v.data.dimension then
                        v.RemoveStream()
                    else
                        local dist = #(playerPos - v.GetPositionVector3())
                        if dist < CONFIG.STREAM_DISTANCES.OBJECT then
                            v.AddStream()
                        else
                            v.RemoveStream()
                        end
                    end
                end

                Citizen.Wait(CONFIG.STREAM_INTERVALS.OBJECT)
            end
        end)
    end)
end
