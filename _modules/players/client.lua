---@class CPlayerModule
local Module = {}
Module.isFreezed = false
Module.forceAnimationData = {
    dict = nil,
    name = nil,
    flag = nil
}
Module.isMovementDisabled = false
Module.dimension = Shared.Config.DEFAULT_DIMENSION
Module.cachedPosition = GetEntityCoords(PlayerPedId())

---@type { [string]: { position: {x:number; y:number; z:number; }; text:string; }}
Module.indicators = {}

function Module:startIndicatorAtPosition(uid, vec3, text, timeMS)
    if self:hasIndicator(uid) then return end

    local run = true

    Citizen.SetTimeout(timeMS, function()
        run = false
    end)

    Citizen.CreateThread(function()
        while run do

            DrawMarker(
                2,
                vec3.x, vec3.y, vec3.z + 0.5,
                0.0, 0.0, 0.0,
                180.0, 0.0, 0.0,
                0.35, 0.35, 0.35,
                255, 255, 0, 155,
                true, false, 2, true, nil, nil, false
            )

            Client.Utils:DrawText3D(vec3.x, vec3.y, vec3.z, text)

            Citizen.Wait(1)
        end
    end)
end

function Module:hasIndicator(uid)
    return self.indicators[uid] and true or false
end

---@param jsonContent table
function Module:sendNuiMessageAPI(jsonContent)
    TriggerEvent("AQUIVER:API:Player:SendNUIMessage", jsonContent)
end

Shared.EventManager:RegisterModuleNetworkEvent({
    ["Player:StartIndicatorAtPosition"] = function(uid, vec3, text, timeMS)
        Module:startIndicatorAtPosition(uid, vec3, text, timeMS)
    end,
    ["Player:Freeze"] = function(state)
        Module.isFreezed = state
        FreezeEntityPosition(PlayerPedId(), state)
    end,
    ["Player:Set:Dimension"] = function(dimension)
        Module.dimension = dimension
    end,
    ["Player:Animation:Play"] = function(dict, name, flag)
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Citizen.Wait(10)
        end
        TaskPlayAnim(PlayerPedId(), dict, name, 4.0, 4.0, -1, tonumber(flag), 1.0, false, false, false)
    end,
    ["Player:Animation:Stop"] = function()
        ClearPedTasks(PlayerPedId())
    end,
    ["Player:ForceAnimation:Play"] = function(dict, name, flag)
        RequestAnimDict(dict)

        while not HasAnimDictLoaded(dict) do
            Citizen.Wait(10)
        end

        Module.forceAnimationData = {
            dict = dict,
            name = name,
            flag = flag
        }

        Citizen.CreateThread(function()
            while Module.forceAnimationData.dict ~= nil do

                local localPlayer = PlayerPedId()

                if not IsEntityPlayingAnim(
                    localPlayer,
                    Module.forceAnimationData.dict,
                    Module.forceAnimationData.name,
                    Module.forceAnimationData.flag
                ) then
                    TaskPlayAnim(
                        localPlayer,
                        Module.forceAnimationData.dict,
                        Module.forceAnimationData.name,
                        4.0,
                        4.0,
                        -1,
                        tonumber(Module.forceAnimationData.flag),
                        1.0,
                        false, false, false
                    )
                end

                Citizen.Wait(1000)
            end
        end)
    end,
    ["Player:DisableMovement:State"] = function(state)
        if state then
            if state == Module.isMovementDisabled then return end

            Module.isMovementDisabled = state

            Citizen.CreateThread(function()
                while Module.isMovementDisabled do

                    DisableAllControlActions(0)
                    EnableControlAction(0, 1, true)
                    EnableControlAction(0, 2, true)

                    Citizen.Wait(0)
                end
            end)
        else
            Module.isMovementDisabled = state
        end
    end,
    ["Player:ForceAnimation:Stop"] = function()
        Module.forceAnimationData = {
            dict = nil,
            name = nil,
            flag = nil
        }
        ClearPedTasks(PlayerPedId())
    end,
})

Citizen.CreateThread(function()
    while true do
        Module.cachedPosition = GetEntityCoords(PlayerPedId())
        Citizen.Wait(Shared.Config.CACHE_PLAYER_POSITION_INTERVAL)
    end
end)

return Module
