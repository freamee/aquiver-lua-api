local IS_SERVER = IsDuplicityVersion()

API.ObjectManager = {}
---@type table<string, { registeredResource:string; object:CObject; }>
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

    self.data = data

    if IS_SERVER then
        self.data.remoteId = API.ObjectManager.remoteIdCount
        API.ObjectManager.remoteIdCount = (API.ObjectManager.remoteIdCount or 0) + 1
    end

    if API.ObjectManager.exists(self.data.remoteId) then
        API.Utils.Debug.Print("^1Object already exists with remoteId: " .. self.data.remoteId)
        return
    end

    if IS_SERVER then
        API.EventManager.TriggerClientLocalEvent("Object:Create", -1, self.data)

        self.SyncVariables = function()
            local validators = API.ObjectManager.GetObjectVariableValidators(self.data.model)
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

            -- // TODO: Stream in event
            -- TriggerEvent(EVENTS.CLIENT.OBJECT_STREAMED_IN, self)
        end

        self.RemoveStream = function()
            if not self.client.isStreamed then return end

            if DoesEntityExist(self.client.objectHandle) then
                DeleteEntity(self.client.objectHandle)
            end

            self.client.isStreamed = false

            -- // TODO: Streamed out event
            --     TriggerEvent(EVENTS.CLIENT.OBJECT_STREAMED_OUT, self)
        end
    end


    self.SetPosition = function(x, y, z)
        if self.data.x == x and self.data.y == y and self.data.z == z then return end

        self.data.x = x
        self.data.y = y
        self.data.z = z

        if IS_SERVER then
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

        if IS_SERVER then
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

        if IS_SERVER then
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

        if IS_SERVER then
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

        if IS_SERVER then
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

        if IS_SERVER then
            API.EventManager.TriggerClientLocalEvent("Object:Update:Dimension", -1, self.data.remoteId, dimension)
        else
            if DoesEntityExist(self.client.objectHandle) and API.LocalPlayer.dimension ~= dimension then
                self:RemoveStream()
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
            API.ObjectManager.Entities[API.InvokeResourceName() .. "-" .. self.data.remoteId] = nil
        end

        if IS_SERVER then
            API.EventManager.TriggerClientLocalEvent("Object:Destroy", -1, self.data.remoteId)
        else
            if DoesEntityExist(self.client.objectHandle) then
                DeleteEntity(self.client.objectHandle)
                self.client.objectHandle = nil
            end
        end

        API.Utils.Debug.Print("^3Removed object with remoteId: " .. self.data.remoteId)
    end

    API.ObjectManager.Entities[API.InvokeResourceName() .. "-" .. self.data.remoteId] = {
        object = self,
        registeredResource = API.InvokeResourceName()
    }

    API.Utils.Debug.Print("^3Created new object with remoteId: " .. self.data.remoteId)

    return self
end

API.ObjectManager.exists = function(id)
    if API.ObjectManager.Entities[API.InvokeResourceName() .. "-" .. id] then
        return true
    end
end

API.ObjectManager.get = function(id)
    if API.ObjectManager.exists(id) then
        return API.ObjectManager.Entities[API.InvokeResourceName() .. "-" .. id].object
    end
end

API.ObjectManager.getAll = function()
    return API.ObjectManager.Entities
end

API.ObjectManager.atHandle = function(handleId)
    if IS_SERVER then return end

    for k, v in pairs(API.ObjectManager.Entities) do
        if v.object.client.objectHandle == handleId then
            return v.object
        end
    end
end

API.ObjectManager.atRemoteId = function(remoteId)
    for k, v in pairs(API.ObjectManager.Entities) do
        if v.object.data.remoteId == remoteId then
            return v.object
        end
    end
end

API.ObjectManager.atMysqlId = function(mysqlId)
    for k, v in pairs(API.ObjectManager.Entities) do
        if v.object.data.id == mysqlId then
            return v.object
        end
    end
end

API.ObjectManager.GetNearestObject = function(vec3, model, range)
    local rangeMeter = range
    local closest

    if type(vec3) ~= "vector3" then return end

    for k, v in pairs(API.ObjectManager.Entities) do
        if v.object.data.model == model then
            local dist = #(v.object.GetPositionVector3() - vec3)

            if dist < rangeMeter then
                rangeMeter = dist
                closest = v
            end
        end
    end

    return closest
end

---@param data MysqlObjectInterface
API.ObjectManager.InsertSQL = function(data)
    if not IS_SERVER then return end

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
                ["@rx"] = data.rx,
                ["@ry"] = data.ry,
                ["@rz"] = data.rz,
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
    if not IS_SERVER then return end

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
API.ObjectManager.AddObjectVariableValidator = function(model, validatorFunction)
    if type(validatorFunction) ~= "function" then
        API.Utils.Debug.Print("^1Object validator should be a function.")
        return
    end

    if not API.ObjectManager.VariableValidators[model] then
        API.ObjectManager.VariableValidators[model] = {}
    end

    table.insert(API.ObjectManager.VariableValidators[model], validatorFunction)
end

API.ObjectManager.GetObjectVariableValidators = function(model)
    if type(API.ObjectManager.VariableValidators[model]) == "table" then
        return API.ObjectManager.VariableValidators[model]
    end
end

if IS_SERVER then
    AddEventHandler("onResourceStart", function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end

        API.EventManager.AddLocalEvent("Object:RequestData", function()
            local source = source

            for k, v in pairs(API.ObjectManager.Entities) do
                API.EventManager.TriggerClientLocalEvent("Object:Create", source, v.object.data)
            end
        end)

        API.ObjectManager.AddObjectVariableValidator("avp_wooden_barrel", function(Object)
            local vars = Object.data.variables

            vars.grinderItemAmount = API.Utils.RoundNumber(vars.grinderItemAmount or 0, 0)
        end)
    end)
else

    AddEventHandler("onResourceStop", function(resourceName)
        if resourceName ~= GetCurrentResourceName() then return end

        for k, v in pairs(API.ObjectManager.Entities) do
            v.object.Destroy()
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
                    if API.LocalPlayer.dimension == v.object.data.dimension then
                        local dist = #(playerPos - v.object.GetPositionVector3())
                        if dist < 20.0 then
                            v.object.AddStream()
                        else
                            v.object.RemoveStream()
                        end
                    end
                end

                Citizen.Wait(1000)
            end
        end)
    end)
end

-- Delete if another resource is restarted which has connections to this.
AddEventHandler("onResourceStop", function(resourceName)
    for k, v in pairs(API.ObjectManager.Entities) do
        if v.registeredResource == resourceName then
            v.object.Destroy()
        end
    end
end)
