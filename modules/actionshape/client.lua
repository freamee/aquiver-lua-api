local Manager = {}
---@type { [number]: ClientActionShape }
Manager.Entities = {}

---@param data IActionShape
Manager.new = function(data)
    ---@class ClientActionShape
    local self = {}

    local _data = data

    self.isStreamed = false
    self.isEntered = false

    self.AddStream = function()
        if self.isStreamed then return end

        self.isStreamed = true

        Citizen.CreateThread(function()
            while self.isStreamed do

                DrawMarker(
                    _data.sprite,
                    _data.position.x, _data.position.y, _data.position.z,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    1.0, 1.0, 1.0,
                    _data.color.r, _data.color.g, _data.color.b, _data.color.a,
                    false, false, 2, false, nil, nil, false
                )

                Citizen.Wait(1)
            end
        end)

        AQUIVER_SHARED.Utils.Print(string.format("^3ActionShape streamed in (%d)", _data.remoteId))
    end

    self.RemoveStream = function()
        if not self.isStreamed then return end

        self.isStreamed = false

        -- Need to trigger the onLeave here.
        self.onLeave()

        AQUIVER_SHARED.Utils.Print(string.format("^3ActionShape streamed out (%d)", _data.remoteId))
    end

    self.onEnter = function()
        if self.isEntered then return end

        self.isEntered = true

        TriggerEvent("onActionShapeEnter", _data.remoteId)
        TriggerServerEvent("onActionShapeEnter", _data.remoteId)
    end

    self.onLeave = function()
        if not self.isEntered then return end

        self.isEntered = false

        TriggerEvent("onActionShapeLeave", _data.remoteId)
        TriggerServerEvent("onActionShapeLeave", _data.remoteId)
    end

    self.Set = {
        Variables = function(vars)
            _data.variables = vars
        end,
        Variable = function(key, value)
            _data.variables[key] = value
        end,
        Position = function(vec3)
            _data.position = vec3
        end
    }

    self.Get = {
        Dimension = function()
            return _data.dimension
        end,
        PositionVector3 = function()
            return vector3(_data.position.x, _data.position.y, _data.position.z)
        end,
        Data = function()
            return _data
        end
    }

    self.Destroy = function()
        -- Delete from table.
        if Manager.exists(_data.remoteId) then
            Manager.Entities[_data.remoteId] = nil
        end

        -- Remove from stream when destroyed.
        self.RemoveStream()

        AQUIVER_SHARED.Utils.Print("^3Removed ActionShape with remoteId: " .. _data.remoteId)
    end

    Manager.Entities[_data.remoteId] = self

    AQUIVER_SHARED.Utils.Print("^3Created new actionshape with remoteId: " .. _data.remoteId)

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
RegisterNetEvent("AQUIVER:ActionShape:Update:Variables", function(remoteId, vars)
    local ActionShapeEntity = Manager.get(remoteId)
    if not ActionShapeEntity then return end

    ActionShapeEntity.Set.Variables(vars)
end)
RegisterNetEvent("AQUIVER:ActionShape:Update:Position", function(remoteId, vec3)
    local ActionShapeEntity = Manager.get(remoteId)
    if not ActionShapeEntity then return end

    ActionShapeEntity.Set.Position(vec3)
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
            if AQUIVER_CLIENT.LocalPlayer.dimension ~= v.Get.Dimension() then
                v.RemoveStream()
            else
                local dist = #(AQUIVER_CLIENT.LocalPlayer.CachedPosition - v.Get.PositionVector3())
                if dist < CONFIG.STREAM_DISTANCES.ACTIONSHAPE then
                    v.AddStream()

                    if dist <= v.Get.Data().range then
                        v.onEnter()
                    elseif dist > v.Get.Data().range then
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
