-- local dialogueCamera = nil

---@class CPedModule
local Module = {}
---@type { [number]: CAquiverPed }
Module.Entities = {}

---@class CAquiverPed
local Ped = {
    ---@type IPed
    data = {},
    isStreamed = false,
    pedHandle = nil
}
Ped.__index = Ped

---@param d IPed
Ped.new = function(d)
    local self = setmetatable({}, Ped)

    self.data = d
    self.isStreamed = false
    self.pedHandle = nil

    self:__init__()

    if Module:exists(self.data.remoteId) then
        Shared.Utils:Print("^1Ped already exists with remoteId: " .. self.data.remoteId)
        return
    end

    Module.Entities[self.data.remoteId] = self

    Shared.Utils:Print("^3Created new ped with remoteId: " .. self.data.remoteId)

    return self
end

function Ped:__init__()

end

function Ped:Destroy()
    if Module:exists(self.data.remoteId) then
        Module.Entities[self.data.remoteId] = nil
    end

    if DoesEntityExist(self.pedHandle) then
        DeleteEntity(self.pedHandle)
    end

    Shared.Utils:Print("^3Removed ped with remoteId: " .. self.data.remoteId)
end

function Ped:getVector3Position()
    return vector3(self.data.position.x, self.data.position.y, self.data.position.z)
end

function Ped:addStream()
    if self.isStreamed then return end

    self.isStreamed = true

    local modelHash = GetHashKey(self.data.model)
    if not IsModelValid(modelHash) then return end

    Client.Utils:RequestModel(modelHash)

    local ped = CreatePed(0, modelHash, self:getVector3Position(), self.data.heading, false, false)
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

    SetEntityCoordsNoOffset(ped, self:getVector3Position(), false, false, false)
    SetEntityHeading(ped, self.data.heading)
    FreezeEntityPosition(ped, true)

    self.pedHandle = ped

    -- Resync animation here. This is basically a set again.
    self:playAnimation(self.data.animDict, self.data.animName, self.data.animFlag)

    Shared.Utils:Print(string.format("^3Ped streamed in (%d)", self.data.remoteId))

    if self.data.questionMark or self.data.name then
        Citizen.CreateThread(function()
            while self.isStreamed do
                local dist = #(Client.LocalPlayer.cachedPosition - self:getVector3Position())

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
                        Client.Utils:DrawText3D(
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

function Ped:removeStream()
    if not self.isStreamed then return end

    self.isStreamed = false

    if DoesEntityExist(self.pedHandle) then
        DeleteEntity(self.pedHandle)
    end

    Shared.Utils:Print(string.format("^3Ped streamed out (%d)", self.data.remoteId))
end

function Ped:playAnimation(dict, name, flag)
    self.data.animDict = dict
    self.data.animName = name
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

---@param vec3 { x:number; y:number; z: number; }
function Ped:dist(vec3)
    return #(self:getVector3Position() - vector3(vec3.x, vec3.y, vec3.z))
end

---@param d IPed
function Module:new(d)
    local aPed = Ped.new(d)
    if aPed then
        return aPed
    end
end

function Module:exists(remoteId)
    return self.Entities[remoteId] and true or false
end

function Module:get(remoteId)
    return self.Entities[remoteId] or nil
end

function Module:atHandle(handleId)
    for k, v in pairs(self.Entities) do
        if v.pedHandle == handleId then
            return v
        end
    end
    return nil
end

RegisterNetEvent(GetCurrentResourceName() .. "AQUIVER:Ped:Create", function(data)
    Module:new(data)
end)
RegisterNetEvent(GetCurrentResourceName() .. "AQUIVER:Ped:Update:Animation", function(id, dict, name, flag)
    local aPed = Module:get(id)
    if not aPed then return end
    aPed:playAnimation(dict, name, flag)
end)
RegisterNetEvent(GetCurrentResourceName() .. "AQUIVER:Ped:Destroy", function(id)
    local aPed = Module:get(id)
    if not aPed then return end
    aPed:Destroy()
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for k, v in pairs(Module.Entities) do
        v:Destroy()
    end
end)

-- STREAMING HANDLER.
Citizen.CreateThread(function()
    while true do

        for k, v in pairs(Module.Entities) do
            if Client.LocalPlayer.dimension ~= v.data.dimension then
                v:removeStream()
            else
                local dist = v:dist(Client.LocalPlayer.cachedPosition)
                if dist < 10.0 then
                    v:addStream()
                else
                    v:removeStream()
                end
            end
        end

        Citizen.Wait(1000)
    end
end)

Citizen.CreateThread(function()
    while true do

        if NetworkIsPlayerActive(PlayerId()) then
            -- Request Data from server.
            TriggerServerEvent(GetCurrentResourceName() .. "AQUIVER:Ped:RequestData")
            break
        end

        Citizen.Wait(500)
    end
end)

return Module

-- ---@param data IPed
-- Manager.new = function(data)
--     ---@class ClientPed
--     local self = {}

--     self.StartDialogue = function(dialoguesData)
--         if not DoesEntityExist(self.pedHandle) then return end

--         local pedOffset = GetOffsetFromEntityInWorldCoords(self.pedHandle, 0.0, 1.6, 0.2)

--         dialogueCamera = CreateCam("DEFAULT_SCRIPTED_CAMERA", false)
--         SetCamCoord(dialogueCamera, pedOffset)
--         PointCamAtEntity(dialogueCamera, self.pedHandle, -1.0, 0, 0, true)
--         SetCamRot(dialogueCamera, 10.0, 0.0, 0.0, 2)
--         SetCamFov(dialogueCamera, 85.0)
--         SetCamActive(dialogueCamera, true)
--         ShakeCam(dialogueCamera, "HAND_SHAKE", 0.2)
--         RenderScriptCams(true, true, 900, true, true)

--         SendNUIMessage({
--             event = "StartDialogue",
--             dialoguesData = dialoguesData
--         })
--     end

--     Manager.Entities[_data.remoteId] = self

--     AQUIVER_SHARED.Utils.Print("^3Created new ped with remoteId: " .. _data.remoteId)

--     return self
-- end



-- RegisterNetEvent("AQUIVER:Ped:Start:Dialogue", function(id, dialoguesData)
--     local PedEntity = Manager.get(id)
--     if not PedEntity then return end

--     PedEntity.StartDialogue(dialoguesData)
-- end)

-- AddEventHandler("DialogueClosed", function()
--     if DoesCamExist(dialogueCamera) then
--         RenderScriptCams(false, true, 900, true, true);
--         DestroyCam(dialogueCamera, false)
--     end
-- end)

-- AQUIVER_CLIENT.PedManager = Manager
