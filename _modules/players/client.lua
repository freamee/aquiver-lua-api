---@class CPlayerModule
local Module = {}
Module.attachments = {}
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
                0.5, 0.5, 0.5,
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

function Module:hasAttachment(attachmentName)
    if self.attachments[attachmentName] and DoesEntityExist(self.attachments[attachmentName]) then
        return true
    end
    return false
end

---@param jsonContent table
function Module:sendNuiMessageAPI(jsonContent)
    SendNUIMessage(jsonContent)
end

Shared.EventManager:RegisterModuleNetworkEvent({
    ["Player:StartIndicatorAtPosition"] = function(uid, vec3, text, timeMS)
        Module:startIndicatorAtPosition(uid, vec3, text, timeMS)
    end,
    ["Player:Freeze"] = function(state)
        Module.isFreezed = state
        FreezeEntityPosition(PlayerPedId(), state)
    end,
    ["Player:Attachment:Add"] = function(attachmentName)
        -- Return if already exists.
        if Module:hasAttachment(attachmentName) then return end

        local aData = Shared.AttachmentManager:get(attachmentName)
        if not aData then return end

        local modelHash = GetHashKey(aData.model)
        Client.Utils:RequestModel(modelHash)

        local localPlayer = PlayerPedId()
        local playerCoords = GetEntityCoords(localPlayer)
        local obj = CreateObject(modelHash, playerCoords, true, true, true)

        AttachEntityToEntity(
            obj,
            localPlayer,
            GetPedBoneIndex(localPlayer, aData.boneId),
            aData.x, aData.y, aData.z,
            aData.rx, aData.ry, aData.rz,
            true, true, false, false, 2, true
        )

        Module.attachments[attachmentName] = obj
    end,
    ["Player:Attachment:Remove"] = function(attachmentName)
        if not Manager.HasAttachment(attachmentName) then return end

        DeleteEntity(Manager.attachments[attachmentName])
        Manager.attachments[attachmentName] = nil
    end,
    ["Player:Attachment:RemoveAll"] = function()
        for attachmentName, objectHandle in pairs(Module.attachments) do
            if DoesEntityExist(objectHandle) then
                DeleteEntity(objectHandle)
            end
        end

        Module.attachments = {}
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

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for k, v in pairs(Module.attachments) do
        if DoesEntityExist(v) then
            DeleteEntity(v)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Module.cachedPosition = GetEntityCoords(PlayerPedId())
        Citizen.Wait(Shared.Config.CACHE_PLAYER_POSITION_INTERVAL)
    end
end)

return Module
