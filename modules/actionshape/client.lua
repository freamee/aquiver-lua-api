local Manager = {}
---@type { [number]: ClientActionShape }
Manager.Entities = {}

---@param data IActionShape
Manager.new = function(data)
    ---@class ClientActionShape
    local self = {}

    self.data = data
    self.isStreamed = false
    self.isEntered = false

    self.AddStream = function()
        if self.isStreamed then return end

        self.isStreamed = true

        Citizen.CreateThread(function()
            while self.isStreamed do

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
        if not self.isStreamed then return end

        self.isStreamed = false

        -- Need to trigger the onLeave here.
        self.onLeave()

        API.Utils.Debug.Print(string.format("^3ActionShape streamed out (%d)", self.data.remoteId))
    end

    self.onEnter = function()
        if self.isEntered then return end

        self.isEntered = true

        TriggerEvent("onActionShapeEnter", self.data.remoteId)
        TriggerServerEvent("onActionShapeEnter", self.data.remoteId)
    end

    self.onLeave = function()
        if not self.isEntered then return end

        self.isEntered = false

        TriggerEvent("onActionShapeLeave", self.data.remoteId)
        TriggerServerEvent("onActionShapeLeave", self.data.remoteId)
    end

    self.Destroy = function()
        -- Delete from table.
        if Manager.exists(self.data.remoteId) then
            Manager.Entities[self.data.remoteId] = nil
        end

        -- Remove from stream when destroyed.
        self.RemoveStream()

        API.Utils.Debug.Print("^3Removed ActionShape with remoteId: " .. self.data.remoteId)
    end

    Manager.Entities[self.data.remoteId] = self

    API.Utils.Debug.Print("^3Created new actionshape with remoteId: " .. self.data.remoteId)

    return self
end

Manager.exists = function(remoteId)
    return Manager.Entities[remoteId] and true or false
end

Manager.get = function(remoteId)
    return Manager.Entities[remoteId] or nil
end

Manager.getAll = function()
    return Manager.Entities
end

RegisterNetEvent("AQUIVER:ActionShape:Create", function(data)
    Manager.new(data)
end)
RegisterNetEvent("AQUIVER:ActionShape:Update:Variable", function(remoteId, key, value)
    local ActionShapeEntity = Manager.get(remoteId)
    if not ActionShapeEntity then return end

    ActionShapeEntity.data.variables[key] = value
end)
RegisterNetEvent("AQUIVER:ActionShape:Update:Position", function(remoteId, vec3)
    local ActionShapeEntity = Manager.get(remoteId)
    if not ActionShapeEntity then return end

    ActionShapeEntity.data.position = vec3
end)
RegisterNetEvent("AQUIVER:ActionShape:Destroy", function(remoteId)
    local ActionShapeEntity = Manager.get(remoteId)
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

        for k, v in pairs(Manager.Entities) do

            -- If dimension is not equals.
            if API.LocalPlayer.dimension ~= v.data.dimension then
                v.RemoveStream()
            else
                local dist = #(API.LocalPlayer.CachedPosition - v.data.position)
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

AQUIVER_CLIENT.ActionShapeManager = Manager
