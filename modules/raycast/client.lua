local Manager = {}
Manager.isEnabled = false
---@type number
Manager.currentHitHandle = nil
---@type ClientObject
Manager.AimedObjectEntity = nil
---@type ClientPed
Manager.AimedPedEntity = nil

---@param rotation { x:number; y:number; z:number; }
local function RotationToDirection(rotation)
    local pi = math.pi / 180
    local adjustedRotation = vector3(pi * rotation.x, pi * rotation.y, pi * rotation.z)
    local direction = vector3(
        -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.sin(adjustedRotation.x)
    )
    return direction
end

Manager.SetEntityHandle = function(handleId)
    -- Do not trigger if its the same as before...
    if Manager.currentHitHandle == handleId then return end

    Manager.currentHitHandle = handleId

    if Manager.currentHitHandle then
        -- Caching the class entity itself, so we do not have to loop the table always.
        if GetEntityType(Manager.currentHitHandle) == 1 then
            local findPed = AQUIVER_CLIENT.PedManager.atHandle(Manager.currentHitHandle)
            if findPed then
                Manager.AimedPedEntity = findPed
                TriggerEvent("onPedRaycast", findPed)

                AQUIVER_SHARED.Utils.Print(
                    string.format("^3Raycast entity changed: Ped: (%d)", findPed.Get.RemoteId())
                )
            end
        elseif GetEntityType(Manager.currentHitHandle) == 3 then
            local findObject = AQUIVER_CLIENT.ObjectManager.atHandle(Manager.currentHitHandle)
            if findObject then
                Manager.AimedObjectEntity = findObject
                TriggerEvent("onObjectRaycast", findObject)

                AQUIVER_SHARED.Utils.Print(
                    string.format("^3Raycast entity changed: Object: (%d)", findObject.Get.RemoteId())
                )
            end
        end

        Citizen.CreateThread(function()
            while Manager.currentHitHandle == handleId do

                AQUIVER_CLIENT.Utils.DrawSprite2D(
                    0.5,
                    0.5,
                    CONFIG.RAYCAST.SPRITE_DICT,
                    CONFIG.RAYCAST.SPRITE_NAME,
                    0.75,
                    0,
                    CONFIG.RAYCAST.SPRITE_COLOR.r,
                    CONFIG.RAYCAST.SPRITE_COLOR.g,
                    CONFIG.RAYCAST.SPRITE_COLOR.b,
                    CONFIG.RAYCAST.SPRITE_COLOR.a
                )

                if Manager.AimedPedEntity then
                    if IsDisabledControlJustPressed(0, CONFIG.RAYCAST.INTERACTION_KEY) then
                        TriggerServerEvent("Ped:Interaction:Press", Manager.AimedPedEntity.Get.RemoteId())
                        TriggerServerEvent("onPedInteractionPress", Manager.AimedPedEntity.Get.RemoteId())
                    end
                end

                if Manager.AimedObjectEntity then
                    if IsDisabledControlJustPressed(0, CONFIG.RAYCAST.INTERACTION_KEY) then
                        TriggerServerEvent("Object:Interaction:Press", Manager.AimedObjectEntity.Get.RemoteId())
                        TriggerServerEvent("onObjectInteractionPress", Manager.AimedObjectEntity.Get.RemoteId())
                    end
                end

                Citizen.Wait(1)
            end
        end)
    else
        Manager.AimedObjectEntity = nil
        Manager.AimedPedEntity = nil
        TriggerEvent("onNullRaycast")
        AQUIVER_SHARED.Utils.Print("^3Raycast entity changed: NULL")
    end
end

Manager.Enable = function(state)
    if Manager.isEnabled == state then return end

    Manager.isEnabled = state

    if Manager.isEnabled then
        Citizen.CreateThread(function()
            while Manager.isEnabled do

                local cameraRotation = GetGameplayCamRot(2)
                local cameraPosition = GetGameplayCamCoord()
                local direction = RotationToDirection(cameraRotation)
                local destination = vector3(
                    cameraPosition.x + direction.x * CONFIG.RAYCAST.RAY_DISTANCE,
                    cameraPosition.y + direction.y * CONFIG.RAYCAST.RAY_DISTANCE,
                    cameraPosition.z + direction.z * CONFIG.RAYCAST.RAY_DISTANCE
                )

                local shapeTestHandle = StartShapeTestCapsule(
                    cameraPosition.x,
                    cameraPosition.y,
                    cameraPosition.z,
                    destination.x,
                    destination.y,
                    destination.z,
                    CONFIG.RAYCAST.RAY_RANGE,
                    9,
                    PlayerPedId(),
                    4
                )
                local _, hit, endCoords, surfaceNormal, hitHandle = GetShapeTestResult(shapeTestHandle)

                if hit then
                    local entityType = GetEntityType(hitHandle)

                    -- Check if Object
                    if entityType == 3 then
                        local findObject = AQUIVER_CLIENT.ObjectManager.atHandle(hitHandle)
                        if findObject then
                            local dist = #(findObject.Get.Position() - AQUIVER_CLIENT.LocalPlayer.CachedPosition)
                            if dist < 2.5 then
                                Manager.SetEntityHandle(hitHandle)
                                goto nextTick
                            end
                        end
                    elseif entityType == 1 then
                        local findPed = AQUIVER_CLIENT.PedManager.atHandle(hitHandle)
                        if findPed then
                            local dist = #(findPed.Get.PositionVector3() - AQUIVER_CLIENT.LocalPlayer.CachedPosition)
                            if dist < 2.5 then
                                Manager.SetEntityHandle(hitHandle)
                                goto nextTick
                            end
                        end
                    end
                end

                -- Reset here if its not continued to nextTick
                Manager.SetEntityHandle(nil)

                ::nextTick::
                Citizen.Wait(CONFIG.RAYCAST_INTERVAL)
            end
        end)
    else
        Manager.SetEntityHandle(nil)
    end
end

AddEventHandler("DialogueOpened", function()
    Manager.Enable(false)
end)
AddEventHandler("DialogueClosed", function()
    Manager.Enable(true)
end)

AQUIVER_CLIENT.RaycastManager = Manager
