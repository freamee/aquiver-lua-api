API.PedManager = {}
---@type table<string, CPed>
API.PedManager.Entities = {}

---@class IPed
---@field uid string
---@field position { x:number; y:number; z:number; }
---@field heading number
---@field model string
---@field dimension number
---@field animDict? string
---@field animName? string
---@field animFlag? number

---@param data IPed
API.PedManager.new = function(data)
    ---@class CPed
    local self = {}

    if type(data.dimension) ~= "number" then
        data.dimension = CONFIG.DEFAULT_DIMENSION
    end

    self.data = data

    if API.PedManager.exists(self.data.uid) then
        API.Utils.Debug.Print("^1Ped already exists with uid: " .. self.data.uid)
        return
    end

    if API.IsServer then
        self.server = {}
        self.server.invokedFromResource = API.InvokeResourceName()

        TriggerClientEvent("AQUIVER:Ped:Create", -1, self.data)

        ---@param cb fun(Player:CPlayer, Ped:CPed)
        self.AddPressFunction = function(cb)
            if not Citizen.GetFunctionReference(cb) then
                API.Utils.Debug.Print("^1Ped AddPressFunction failed, cb should be a function reference.")
                return
            end

            self.server.onPress = cb
        end
    else
        self.client = {}
        self.client.pedHandle = nil
        self.client.isStreamed = false

        self.AddStream = function()
            if self.client.isStreamed then return end

            self.client.isStreamed = true

            local modelHash = GetHashKey(self.data.model)
            if not IsModelValid(modelHash) then return end

            API.Utils.Client.requestModel(modelHash)

            local ped = CreatePed(0, modelHash, self.GetPositionVector3(), self.data.heading, false, false)
            SetEntityCanBeDamaged(ped, false)
            SetPedAsEnemy(ped, false)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetPedResetFlag(ped, 249, 1)
            SetPedConfigFlag(ped, 185, true)
            SetPedConfigFlag(ped, 108, true)
            SetPedConfigFlag(ped, 208, true)
            SetPedCanEvasiveDive(ped, false)
            SetPedCanRagdollFromPlayerImpact(ped, false)
            SetPedCanRagdoll(ped, false)
            SetPedDefaultComponentVariation(ped)

            SetEntityCoordsNoOffset(ped, self.GetPositionVector3(), false, false, false)
            SetEntityHeading(ped, self.data.heading)
            FreezeEntityPosition(ped, true)

            -- Resync animation here. This is basically a set again.
            self.SetAnimation(self.data.animDict, self.data.animName, self.data.animFlag)

            self.client.pedHandle = ped
        end

        self.RemoveStream = function()
            if not self.client.isStreamed then return end

            if DoesEntityExist(self.client.pedHandle) then
                DeleteEntity(self.client.pedHandle)
            end

            self.client.isStreamed = false
        end
    end

    self.GetPositionVector3 = function()
        return vector3(self.data.position.x, self.data.position.y, self.data.position.z)
    end

    self.SetPosition = function(position)
        self.data.position = position

        if API.IsServer then
            TriggerClientEvent("AQUIVER:Ped:Update:Position", -1, self.data.uid, position)
        else
            if DoesEntityExist(self.client.pedHandle) then
                SetEntityCoordsNoOffset(self.client.pedHandle, self.GetPositionVector3(), false, false, false)
            end
        end
    end

    self.SetHeading = function(heading)
        self.data.heading = heading

        if API.IsServer then
            TriggerClientEvent("AQUIVER:Ped:Update:Heading", -1, self.data.uid, heading)
        else
            if DoesEntityExist(self.client.pedHandle) then
                SetEntityHeading(self.client.pedHandle, heading)
            end
        end
    end

    self.SetModel = function(model)
        self.data.model = model

        if API.IsServer then
            TriggerClientEvent("AQUIVER:Ped:Update:Model", -1, self.data.uid, model)
        else
            if self.client.isStreamed then
                self.RemoveStream()
                self.AddStream()
            end
        end
    end

    self.SetAnimation = function(dict, anim, flag)
        self.data.animDict = dict
        self.data.animName = anim
        self.data.animFlag = flag

        if API.IsServer then
            TriggerClientEvent("AQUIVER:Ped:Update:Animation", -1, self.data.uid, self.data.animDict, self.data.animName, self.data.animFlag)
        else
            if DoesEntityExist(self.client.pedHandle) then
                RequestAnimDict(self.data.animDict)
                while not HasAnimDictLoaded(self.data.animDict) do
                    Citizen.Wait(10)
                end

                TaskPlayAnim(self.client.pedHandle, self.data.animDict, self.data.animName, 1.0, 1.0, -1,
                    tonumber(self.data.animFlag), 1.0, false, false, false)
            end
        end
    end


    self.SetDimension = function(dimension)
        if self.data.dimension == dimension then return end

        self.data.dimension = dimension

        if API.IsServer then
            TriggerClientEvent("AQUIVER:Ped:Update:Dimension", -1, self.data.uid, dimension)
        else
            if DoesEntityExist(self.client.pedHandle) and API.LocalPlayer.dimension ~= dimension then
                self.RemoveStream()
            end
        end
    end

    self.Destroy = function()
        -- Delete from table.
        if API.PedManager.Entities[self.data.uid] then
            API.PedManager.Entities[self.data.uid] = nil
        end

        if API.IsServer then
            TriggerClientEvent("AQUIVER:Ped:Destroy", -1, self.data.uid)
            TriggerEvent("onPedDestroyed", self)
        else
            if DoesEntityExist(self.client.pedHandle) then
                DeleteEntity(self.client.pedHandle)
                self.client.pedHandle = nil
            end
        end

        API.Utils.Debug.Print("^3Removed ped with uid: " .. self.data.uid)
    end

    API.PedManager.Entities[self.data.uid] = self

    API.Utils.Debug.Print("^3Created new ped with uid: " .. self.data.uid)

    if API.IsServer then
        TriggerEvent("onPedCreated", self)
    end

    return self
end

API.PedManager.exists = function(id)
    if API.PedManager.Entities[id] then
        return true
    end
end

API.PedManager.get = function(id)
    if API.PedManager.exists(id) then
        return API.PedManager.Entities[id]
    end
end

API.PedManager.getAll = function()
    return API.PedManager.Entities
end

if API.IsServer then
    AddEventHandler("onResourceStart", function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end

        RegisterNetEvent("AQUIVER:Ped:RequestData", function()
            local source = source

            for k, v in pairs(API.PedManager.Entities) do
                TriggerClientEvent("AQUIVER:Ped:Create", source, v.data)
            end
        end)
    end)

    AddEventHandler("onResourceStop", function(resourceName)
        for k, v in pairs(API.PedManager.Entities) do
            if v.server.invokedFromResource == resourceName then
                v.Destroy()
            end
        end
    end)
else

    API.PedManager.atHandle = function(handleId)
        for k, v in pairs(API.PedManager.Entities) do
            if v.client.pedHandle == handleId then
                return v
            end
        end
    end

    AddEventHandler("onResourceStop", function(resourceName)
        if resourceName ~= GetCurrentResourceName() then return end

        for k, v in pairs(API.PedManager.Entities) do
            v.Destroy()
        end
    end)

    AddEventHandler("onClientResourceStart", function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end

        RegisterNetEvent("AQUIVER:Ped:Create", function(data)
            API.PedManager.new(data)
        end)
        RegisterNetEvent("AQUIVER:Ped:Update:Animation", function(id, dict, name, flag)
            local PedEntity = API.PedManager.get(id)
            if not PedEntity then return end
            PedEntity.SetAnimation(dict, name, flag)
        end)
        RegisterNetEvent("AQUIVER:Ped:Update:Model", function(id,model)
            local PedEntity = API.PedManager.get(id)
            if not PedEntity then return end
            PedEntity.SetModel(model)
        end)
        RegisterNetEvent("AQUIVER:Ped:Update:Heading", function(id, heading)
            local PedEntity = API.PedManager.get(id)
            if not PedEntity then return end
            PedEntity.SetHeading(heading)
        end)
        RegisterNetEvent("AQUIVER:Ped:Update:Position", function(id, position)
            local PedEntity = API.PedManager.get(id)
            if not PedEntity then return end
            PedEntity.SetPosition(position)
        end)
        RegisterNetEvent("AQUIVER:Ped:Update:Dimension", function(id, dimension)
            local PedEntity = API.PedManager.get(id)
            if not PedEntity then return end
            PedEntity.SetDimension(dimension)
        end)
        RegisterNetEvent("AQUIVER:Ped:Destroy", function(id)
            local PedEntity = API.PedManager.get(id)
            if not PedEntity then return end
            PedEntity.Destroy()
        end)

        Citizen.CreateThread(function()
            while true do

                if NetworkIsPlayerActive(PlayerId()) then
                    -- Request Data from server.
                    TriggerServerEvent("AQUIVER:Ped:RequestData")
                    break
                end

                Citizen.Wait(500)
            end
        end)

        -- STREAMING HANDLER.
        Citizen.CreateThread(function()
            while true do

                local playerPos = GetEntityCoords(PlayerPedId())

                for k, v in pairs(API.PedManager.Entities) do

                    if API.LocalPlayer.dimension ~= v.data.dimension then
                        v.RemoveStream()
                    else
                        local dist = #(playerPos - v.GetPositionVector3())
                        if dist < CONFIG.STREAM_DISTANCES.PED then
                            v.AddStream()
                        else
                            v.RemoveStream()
                        end
                    end
                end

                Citizen.Wait(CONFIG.STREAM_INTERVALS.PED)
            end
        end)
    end)
end
