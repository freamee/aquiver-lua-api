API.PedManager = {}
---@type table<string, { registeredResource: string; ped: CPed; }>
API.PedManager.Entities = {}

---@class IPed
---@field uid string
---@field position { x:number; y:number; z:number; }
---@field heading number
---@field model string
---@field animDict? string
---@field animName? string
---@field animFlag? number

---@param data IPed
API.PedManager.new = function(data)
    ---@class CPed
    local self = {}

    self.data = data

    if API.PedManager.exists(self.data.uid) then
        API.Utils.Debug.Print("^1Ped already exists with uid: " .. self.data.uid)
        return
    end

    if API.IsServer then
        self.server = {}

        API.EventManager.TriggerClientLocalEvent("Ped:Create", -1, self.data)

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
            API.EventManager.TriggerClientLocalEvent("Ped:Update:Position", -1, self.data.uid, position)
        else
            if DoesEntityExist(self.client.pedHandle) then
                SetEntityCoordsNoOffset(self.client.pedHandle, self:GetPositionVector3(), false, false, false)
            end
        end
    end

    self.SetHeading = function(heading)
        self.data.heading = heading

        if API.IsServer then
            API.EventManager.TriggerClientLocalEvent("Ped:Update:Heading", -1, self.data.uid, heading)
        else
            if DoesEntityExist(self.client.pedHandle) then
                SetEntityHeading(self.client.pedHandle, heading)
            end
        end
    end

    self.SetModel = function(model)
        self.data.model = model

        if API.IsServer then
            API.EventManager.TriggerClientLocalEvent("Ped:Update:Model", -1, self.data.uid, model)
        else
            if self.client.isStreamed then
                self:RemoveStream()
                self:AddStream()
            end
        end
    end

    self.SetAnimation = function(dict, anim, flag)
        self.data.animDict = dict
        self.data.animName = anim
        self.data.animFlag = flag

        if API.IsServer then
            API.EventManager.TriggerClientLocalEvent("Ped:Update:Animation",
                -1,
                self.data.uid,
                self.data.animDict,
                self.data.animName,
                self.data.animFlag
            )
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

    self.Destroy = function()
        -- Delete from table.
        if API.PedManager.Entities[self.data.uid] then
            API.PedManager.Entities[self.data.uid] = nil
        end

        if API.IsServer then
            API.EventManager.TriggerClientLocalEvent("Ped:Destroy", -1, self.data.uid)
        else
            if DoesEntityExist(self.client.pedHandle) then
                DeleteEntity(self.client.pedHandle)
                self.client.pedHandle = nil
            end
        end

        API.Utils.Debug.Print("^3Removed ped with uid: " .. self.data.uid)
    end

    API.PedManager.Entities[self.data.uid] = {
        ped = self,
        registeredResource = API.InvokeResourceName()
    }

    API.Utils.Debug.Print("^3Created new ped with uid: " .. self.data.uid)

    return self
end

API.PedManager.exists = function(id)
    if API.PedManager.Entities[id] then
        return true
    end
end

API.PedManager.get = function(id)
    if API.PedManager.exists(id) then
        return API.PedManager.Entities[id].ped
    end
end

API.PedManager.getAll = function()
    return API.PedManager.Entities
end

if API.IsServer then
    AddEventHandler("onResourceStart", function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end

        API.EventManager.AddLocalEvent("Ped:RequestData", function()
            local source = source

            for k, v in pairs(API.PedManager.Entities) do
                API.EventManager.TriggerClientLocalEvent("Ped:Create", source, v.ped.data)
            end
        end)
    end)
else

    API.PedManager.atHandle = function(handleId)
        for k, v in pairs(API.PedManager.Entities) do
            if v.ped.client.pedHandle == handleId then
                return v.ped
            end
        end
    end

    AddEventHandler("onResourceStop", function(resourceName)
        if resourceName ~= GetCurrentResourceName() then return end

        for k, v in pairs(API.PedManager.Entities) do
            v.ped.Destroy()
        end
    end)

    AddEventHandler("onClientResourceStart", function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end

        API.EventManager.AddLocalEvent({
            ["Ped:Create"] = function(data)
                API.PedManager.new(data)
            end,
            ["Ped:Update:Animation"] = function(id, dict, name, flag)
                local PedEntity = API.PedManager.get(id)
                if not PedEntity then return end
                PedEntity.SetAnimation(dict, name, flag)
            end,
            ["Ped:Update:Model"] = function(id, model)
                local PedEntity = API.PedManager.get(id)
                if not PedEntity then return end
                PedEntity.SetModel(model)
            end,
            ["Ped:Update:Heading"] = function(id, heading)
                local PedEntity = API.PedManager.get(id)
                if not PedEntity then return end
                PedEntity.SetHeading(heading)
            end,
            ["Ped:Update:Position"] = function(id, position)
                local PedEntity = API.PedManager.get(id)
                if not PedEntity then return end
                PedEntity.SetPosition(position)
            end,
            ["Ped:Destroy"] = function(id)
                local PedEntity = API.PedManager.get(id)
                if not PedEntity then return end
                PedEntity.Destroy()
            end
        })

        Citizen.CreateThread(function()
            while true do

                if NetworkIsPlayerActive(PlayerId()) then
                    -- Request Data from server.
                    API.EventManager.TriggerServerLocalEvent("Ped:RequestData")
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
                    local dist = #(playerPos - v.ped.GetPositionVector3())

                    if dist < 15.0 then
                        v.ped.AddStream()
                    else
                        v.ped.RemoveStream()
                    end
                end

                Citizen.Wait(1000)
            end
        end)
    end)
end

-- Delete if another resource is restarted which has connections to this.
AddEventHandler("onResourceStop", function(resourceName)
    for k, v in pairs(API.PedManager.Entities) do
        if v.registeredResource == resourceName then
            v.ped.Destroy()
        end
    end
end)
