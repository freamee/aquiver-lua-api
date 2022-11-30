---@class CRaycastManager
local Module = {}
Module.isEnabled = false
---@type number
Module.currentHitHandle = nil
---@type CAquiverObject
Module.AimedObjectEntity = nil
---@type CAquiverPed
Module.AimedPedEntity = nil

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

function Module:setEntityHandle(handleId)
    -- Do not trigger if its the same as before...
    if self.currentHitHandle == handleId then return end

    self.currentHitHandle = handleId

    if self.currentHitHandle then
        -- Caching the class entity itself, so we do not have to loop the table always.
        if GetEntityType(self.currentHitHandle) == 1 then
            local findPed = Client.PedManager:atHandle(self.currentHitHandle)
            if findPed then
                self.AimedPedEntity = findPed
                TriggerEvent("onPedRaycast", GetCurrentResourceName(), findPed)
                Shared.Utils:Print(string.format("^3Raycast entity changed: Ped: (%d)", findPed.data.remoteId))
            end
        elseif GetEntityType(self.currentHitHandle) == 3 then
            local findObject = Client.ObjectManager:atHandle(self.currentHitHandle)
            if findObject then
                self.AimedObjectEntity = findObject
                TriggerEvent("onObjectRaycast", GetCurrentResourceName(), findObject)
                Shared.Utils:Print(string.format("^3Raycast entity changed: Object: (%d)", findObject.data.remoteId))
            end
        end

        Citizen.CreateThread(function()
            while self.currentHitHandle == handleId do

                Client.Utils:DrawSprite2D(
                    0.5,
                    0.5,
                    Shared.Config.RAYCAST.SPRITE_DICT,
                    Shared.Config.RAYCAST.SPRITE_NAME,
                    0.75,
                    0,
                    Shared.Config.RAYCAST.SPRITE_COLOR.r,
                    Shared.Config.RAYCAST.SPRITE_COLOR.g,
                    Shared.Config.RAYCAST.SPRITE_COLOR.b,
                    Shared.Config.RAYCAST.SPRITE_COLOR.a
                )

                if self.AimedPedEntity then
                    if IsDisabledControlJustPressed(0, Shared.Config.RAYCAST.INTERACTION_KEY) then
                        Shared.EventManager:TriggerModuleServerEvent(
                            "Ped:Interaction:Press",
                            self.AimedPedEntity.data.remoteId
                        )
                        TriggerServerEvent("onPedInteractionPress", GetCurrentResourceName(),
                            self.AimedPedEntity.data.remoteId)
                    end
                end

                if self.AimedObjectEntity then
                    if IsDisabledControlJustPressed(0, Shared.Config.RAYCAST.INTERACTION_KEY) then
                        Shared.EventManager:TriggerModuleServerEvent(
                            "Object:Interaction:Press",
                            self.AimedObjectEntity.data.remoteId
                        )
                        TriggerServerEvent("onObjectInteractionPress", GetCurrentResourceName(),
                            self.AimedObjectEntity.data.remoteId)
                    end
                end

                Citizen.Wait(1)
            end
        end)
    else
        self.AimedObjectEntity = nil
        self.AimedPedEntity = nil
        TriggerEvent("onNullRaycast", GetCurrentResourceName())
        Shared.Utils:Print("^3Raycast entity changed: NULL")
    end
end

function Module:enable(state)
    if self.isEnabled == state then return end

    self.isEnabled = state

    if self.isEnabled then
        Citizen.CreateThread(function()
            while self.isEnabled do

                local cameraRotation = GetGameplayCamRot(2)
                local cameraPosition = GetGameplayCamCoord()
                local direction = RotationToDirection(cameraRotation)
                local destination = vector3(
                    cameraPosition.x + direction.x * Shared.Config.RAYCAST.RAY_DISTANCE,
                    cameraPosition.y + direction.y * Shared.Config.RAYCAST.RAY_DISTANCE,
                    cameraPosition.z + direction.z * Shared.Config.RAYCAST.RAY_DISTANCE
                )

                local shapeTestHandle = StartShapeTestCapsule(
                    cameraPosition.x,
                    cameraPosition.y,
                    cameraPosition.z,
                    destination.x,
                    destination.y,
                    destination.z,
                    Shared.Config.RAYCAST.RAY_RANGE,
                    9,
                    PlayerPedId(),
                    4
                )
                local _, hit, endCoords, surfaceNormal, hitHandle = GetShapeTestResult(shapeTestHandle)

                if hit then
                    local entityType = GetEntityType(hitHandle)

                    -- Check if Object
                    if entityType == 3 then
                        local findObject = Client.ObjectManager:atHandle(hitHandle)
                        if findObject then
                            local dist = findObject:dist(Client.LocalPlayer.cachedPosition)
                            if dist < 2.5 then
                                self:setEntityHandle(hitHandle)
                                goto nextTick
                            end
                        end
                    elseif entityType == 1 then
                        local findPed = Client.PedManager:atHandle(hitHandle)
                        if findPed then
                            local dist = findPed:dist(Client.LocalPlayer.cachedPosition)
                            if dist < 2.5 then
                                self:setEntityHandle(hitHandle)
                                goto nextTick
                            end
                        end
                    end
                end

                -- Reset here if its not continued to nextTick
                self:setEntityHandle(nil)

                ::nextTick::
                Citizen.Wait(Shared.Config.RAYCAST.INTERVAL)
            end
        end)
    else
        self:setEntityHandle(nil)
    end
end

AddEventHandler("DialogueOpened", function()
    Module:enable(false)
end)
AddEventHandler("DialogueClosed", function()
    Module:enable(true)
end)

return Module
