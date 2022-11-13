local dialogueCamera = nil

local Manager = {}
---@type { [number]: ClientPed }
Manager.Entities = {}

---@param data IPed
Manager.new = function(data)
    ---@class ClientPed
    local self = {}

    self.data = data
    self.pedHandle = nil
    self.isStreamed = false

    self.AddStream = function()
        if self.isStreamed then return end

        self.isStreamed = true

        local modelHash = GetHashKey(self.data.model)
        if not IsModelValid(modelHash) then return end

        API.Utils.Client.requestModel(modelHash)

        local ped = CreatePed(0, modelHash, self.Get.PositionVector3(), self.data.heading, false, false)
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

        SetEntityCoordsNoOffset(ped, self.Get.PositionVector3(), false, false, false)
        SetEntityHeading(ped, self.data.heading)
        FreezeEntityPosition(ped, true)

        self.pedHandle = ped

        -- Resync animation here. This is basically a set again.
        self.Set.Animation(self.data.animDict, self.data.animName, self.data.animFlag)

        if self.data.questionMark or self.data.name then
            Citizen.CreateThread(function()
                while self.isStreamed do
                    local dist = #(AQUIVER_CLIENT.LocalPlayer.CachedPosition - self.Get.PositionVector3())

                    local onScreen = false
                    if dist < 5.0 then
                        onScreen = IsEntityOnScreen(self.pedHandle)

                        if self.data.questionMark then
                            DrawMarker(
                                32,
                                self.data.position.x, self.data.position.y, self.data.position.z + 1.35,
                                0, 0, 0,
                                0, 0, 0,
                                0.35, 0.35, 0.35,
                                255, 255, 0, 200,
                                true, false, 2, true, nil, nil, false
                            )
                        end

                        if self.data.name then
                            API.Utils.Client.DrawText3D(
                                self.data.position.x,
                                self.data.position.y,
                                self.data.position.z + 1,
                                self.data.name,
                                0.28
                            )
                        end
                    else
                        Citizen.Wait(500)
                    end

                    if not onScreen then
                        Citizen.Wait(500)
                    end

                    Citizen.Wait(1)
                end
            end)
        end
    end

    self.RemoveStream = function()
        if not self.isStreamed then return end

        self.isStreamed = false

        if DoesEntityExist(self.pedHandle) then
            DeleteEntity(self.pedHandle)
        end
    end

    self.Get = {
        PositionVector3 = function()
            return vector3(self.data.position.x, self.data.position.y, self.data.position.z)
        end
    }

    self.Set = {
        Animation = function(dict, anim, flag)
            self.data.animDict = dict
            self.data.animName = anim
            self.data.animFlag = flag

            if DoesEntityExist(self.pedHandle) then
                RequestAnimDict(self.data.animDict)
                while not HasAnimDictLoaded(self.data.animDict) do
                    Citizen.Wait(10)
                end

                TaskPlayAnim(
                    self.pedHandle,
                    self.data.animDict,
                    self.data.animName,
                    1.0,
                    1.0,
                    -1,
                    tonumber(self.data.animFlag),
                    1.0,
                    false,
                    false,
                    false
                )
            end
        end
    }

    self.StartDialogue = function(dialoguesData)
        if not DoesEntityExist(self.pedHandle) then return end

        local pedOffset = GetOffsetFromEntityInWorldCoords(self.pedHandle, 0.0, 1.6, 0.2)

        dialogueCamera = CreateCam("DEFAULT_SCRIPTED_CAMERA", false)
        SetCamCoord(dialogueCamera, pedOffset)
        PointCamAtEntity(dialogueCamera, self.pedHandle, -1.0, 0, 0, true)
        SetCamRot(dialogueCamera, 10.0, 0.0, 0.0, 2)
        SetCamFov(dialogueCamera, 85.0)
        SetCamActive(dialogueCamera, true)
        ShakeCam(dialogueCamera, "HAND_SHAKE", 0.2)
        RenderScriptCams(true, true, 900, true, true)

        SendNUIMessage({
            event = "StartDialogue",
            dialoguesData = dialoguesData
        })
    end

    self.Destroy = function()
        -- Delete from table.
        if Manager.exists(self.data.remoteId) then
            Manager.Entities[self.data.remoteId] = nil
        end

        if DoesEntityExist(self.pedHandle) then
            DeleteEntity(self.pedHandle)
        end

        API.Utils.Debug.Print("^3Removed ped with remoteId: " .. self.data.remoteId)
    end

    Manager.Entities[self.data.remoteId] = self

    API.Utils.Debug.Print("^3Created new ped with remoteId: " .. self.data.remoteId)

    return self
end

Manager.exists = function(id)
    return Manager.Entities[id] and true or false
end

Manager.get = function(id)
    return Manager.Entities[id] or nil
end

Manager.getAll = function()
    return Manager.Entities
end

Manager.atHandle = function(handleId)
    for k, v in pairs(Manager.Entities) do
        if v.pedHandle == handleId then
            return v
        end
    end
    return nil
end

RegisterNetEvent("AQUIVER:Ped:Create", function(data)
    Manager.new(data)
end)
RegisterNetEvent("AQUIVER:Ped:Update:Animation", function(id, dict, name, flag)
    local PedEntity = Manager.get(id)
    if not PedEntity then return end

    PedEntity.Set.Animation(dict, name, flag)
end)
RegisterNetEvent("AQUIVER:Ped:Update:Model", function(id, model)
    local PedEntity = Manager.get(id)
    if not PedEntity then return end

    PedEntity.data.model = model

    if PedEntity.isStreamed then
        PedEntity.RemoveStream()
        PedEntity.AddStream()
    end
end)
RegisterNetEvent("AQUIVER:Ped:Update:Heading", function(id, heading)
    local PedEntity = Manager.get(id)
    if not PedEntity then return end

    PedEntity.data.heading = heading

    if DoesEntityExist(PedEntity.pedHandle) then
        SetEntityHeading(PedEntity.pedHandle, PedEntity.data.heading)
    end
end)
RegisterNetEvent("AQUIVER:Ped:Update:Position", function(id, position)
    local PedEntity = Manager.get(id)
    if not PedEntity then return end

    PedEntity.data.position = position

    if DoesEntityExist(PedEntity.pedHandle) then
        SetEntityCoordsNoOffset(PedEntity.pedHandle, PedEntity.Get.PositionVector3(), false, false, false)
    end
end)
RegisterNetEvent("AQUIVER:Ped:Update:Dimension", function(id, dimension)
    local PedEntity = Manager.get(id)
    if not PedEntity then return end

    PedEntity.data.dimension = dimension

    if DoesEntityExist(PedEntity.pedHandle) and AQUIVER_CLIENT.LocalPlayer.dimension ~= PedEntity.data.dimension then
        PedEntity.RemoveStream()
    end
end)
RegisterNetEvent("AQUIVER:Ped:Start:Dialogue", function(id, dialoguesData)
    local PedEntity = Manager.get(id)
    if not PedEntity then return end

    PedEntity.StartDialogue(dialoguesData)
end)
RegisterNetEvent("AQUIVER:Ped:Destroy", function(id)
    local PedEntity = Manager.get(id)
    if not PedEntity then return end
    PedEntity.Destroy()
end)

AddEventHandler("DialogueClosed", function()
    if DoesCamExist(dialogueCamera) then
        RenderScriptCams(false, true, 900, true, true);
        DestroyCam(dialogueCamera, false)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for k, v in pairs(Manager.Entities) do
        v.Destroy()
    end
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

        for k, v in pairs(Manager.Entities) do
            if AQUIVER_CLIENT.LocalPlayer.dimension ~= v.data.dimension then
                v.RemoveStream()
            else
                local dist = #(AQUIVER_CLIENT.LocalPlayer.CachedPosition - v.Get.PositionVector3())
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

AQUIVER_CLIENT.PedManager = Manager
