API.ActionShapeManager = {}
---@type table<number, CActionShape>
API.ActionShapeManager.Entities = {}
API.ActionShapeManager.remoteIdCount = 1

---@class IActionShape
---@field position { x:number; y:number; z:number; }
---@field color { r:number; g:number; b:number; a:number; }
---@field sprite number
---@field range number
---@field dimension number
---@field variables table

---@param data IActionShape
API.ActionShapeManager.new = function(data)
    ---@class CActionShape
    local self = {}

    self.data = data
    self.data.variables = self.data.variables or {}

    if API.IsServer then
        self.server = {}
        self.server.keyPressFunctions = {}
        self.server.invokedFromResource = API.InvokeResourceName()
        self.data.remoteId = API.ActionShapeManager.remoteIdCount
        API.ActionShapeManager.remoteIdCount = (API.ActionShapeManager.remoteIdCount or 0) + 1

        TriggerClientEvent("AQUIVER:ActionShape:Create", -1, self.data)
    else
        self.client = {}
        self.client.isStreamed = false
        self.client.isEntered = false

        self.AddStream = function()
            if self.client.isStreamed then return end

            self.client.isStreamed = true

            Citizen.CreateThread(function()
                while self.client.isStreamed do

                    DrawMarker(
                        self.data.sprite,
                        self.data.position.x, self.data.position.y, self.data.position.z,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        1.0, 1.0, 1.0,
                        self.data.color.r, self.data.color.g, self.data.color.b, self.data.color.a,
                        false, false, 2, false, nil, nil, false
                    )

                    Citizen.Wait(1)
                end
            end)

            API.Utils.Debug.Print(string.format("^3ActionShape streamed in (%d)", self.data.remoteId))
        end

        self.RemoveStream = function()
            if not self.client.isStreamed then return end

            self.client.isStreamed = false

            -- Need to trigger the onLeave here.
            self.onLeave()

            API.Utils.Debug.Print(string.format("^3ActionShape streamed out (%d)", self.data.remoteId))
        end

        self.onEnter = function()
            if self.client.isEntered then return end

            self.client.isEntered = true

            TriggerEvent("onActionShapeEnter", self.data.remoteId)
            TriggerServerEvent("onActionShapeEnter", self.data.remoteId)
        end

        self.onLeave = function()
            if not self.client.isEntered then return end

            self.client.isEntered = false

            TriggerEvent("onActionShapeLeave", self.data.remoteId)
            TriggerServerEvent("onActionShapeLeave", self.data.remoteId)
        end
    end

    self.SetPosition = function(vec3)
        self.data.position = vec3

        if API.IsServer then
            TriggerClientEvent("AQUIVER:ActionShape:Update:Position", -1, self.data.remoteId, self.data.position)
        end
    end

    self.SetVariable = function(key, value)
        self.data.variables[key] = value

        if API.IsServer then
            TriggerClientEvent("AQUIVER:ActionShape:Update:Variable", -1, self.data.remoteId, key, value)
        end
    end

    self.GetVariable = function(key)
        return self.data.variables[key]
    end

    self.Destroy = function()
        -- Delete from table.
        if API.ActionShapeManager.Entities[self.data.remoteId] then
            API.ActionShapeManager.Entities[self.data.remoteId] = nil
        end

        if API.IsServer then
            TriggerClientEvent("AQUIVER:ActionShape:Destroy", -1, self.data.remoteId)
        else
            self.RemoveStream()
        end

        API.Utils.Debug.Print("^3Removed ActionShape with remoteId: " .. self.data.remoteId)
    end

    self.GetPositionVector3 = function()
        return vector3(self.data.position.x, self.data.position.y, self.data.position.z)
    end

    API.ActionShapeManager.Entities[self.data.remoteId] = self

    API.Utils.Debug.Print("^3Created new actionshape with remoteId: " .. self.data.remoteId)

    return self
end

API.ActionShapeManager.exists = function(remoteId)
    if API.ActionShapeManager.Entities[remoteId] then
        return true
    end
end

API.ActionShapeManager.get = function(remoteId)
    if API.ActionShapeManager.exists(remoteId) then
        return API.ActionShapeManager.Entities[remoteId]
    end
end

API.ActionShapeManager.getAll = function()
    return API.ActionShapeManager.Entities
end

if API.IsServer then
    AddEventHandler("onResourceStart", function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end

        RegisterNetEvent("AQUIVER:ActionShape:RequestData", function()
            local source = source

            for k, v in pairs(API.ActionShapeManager.Entities) do
                TriggerClientEvent("AQUIVER:ActionShape:Create", source, v.data)
            end
        end)
    end)

    AddEventHandler("onResourceStop", function(resourceName)
        for k, v in pairs(API.ActionShapeManager.Entities) do
            if v.server.invokedFromResource == resourceName then
                v.Destroy()
            end
        end
    end)
else
    AddEventHandler("onClientResourceStart", function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end

        RegisterNetEvent("AQUIVER:ActionShape:Create", function(data)
            API.ActionShapeManager.new(data)
        end)
        RegisterNetEvent("AQUIVER:ActionShape:Update:Variable", function(remoteId, key, value)
            local ActionShapeEntity = API.ActionShapeManager.get(remoteId)
            if not ActionShapeEntity then return end
            ActionShapeEntity.SetVariable(key, value)
        end)
        RegisterNetEvent("AQUIVER:ActionShape:Update:Position", function(remoteId, vec3)
            local ActionShapeEntity = API.ActionShapeManager.get(remoteId)
            if not ActionShapeEntity then return end
            ActionShapeEntity.SetPosition(vec3)
        end)
        RegisterNetEvent("AQUIVER:ActionShape:Destroy", function(remoteId)
            local ActionShapeEntity = API.ActionShapeManager.get(remoteId)
            if not ActionShapeEntity then return end
            ActionShapeEntity.Destroy()
        end)

        Citizen.CreateThread(function()
            while true do

                if NetworkIsPlayerActive(PlayerId()) then
                    -- Request Data from server.
                    TriggerServerEvent("AQUIVER:ActionShape:RequestData")
                    break
                end

                Citizen.Wait(500)
            end
        end)

        -- STREAMING HANDLER.
        Citizen.CreateThread(function()
            while true do

                for k, v in pairs(API.ActionShapeManager.Entities) do

                    -- If dimension is not equals.
                    if API.LocalPlayer.dimension ~= v.data.dimension then
                        v.RemoveStream()
                    else
                        local dist = #(API.LocalPlayer.CachedPosition - v.GetPositionVector3())
                        if dist < CONFIG.STREAM_DISTANCES.ACTIONSHAPE then
                            v.AddStream()

                            if dist <= v.data.range then
                                v.onEnter()
                            elseif dist > v.data.range then
                                v.onLeave()
                            end
                        else
                            v.RemoveStream()
                        end
                    end
                end

                Citizen.Wait(CONFIG.STREAM_INTERVALS.ACTIONSHAPE)
            end
        end)
    end)
end
