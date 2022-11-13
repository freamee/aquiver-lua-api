local Manager = {}
Manager.attachments = {}
Manager.isFreezed = false
Manager.forceAnimationData = {
    dict = nil,
    name = nil,
    flag = nil
}
Manager.isMovementDisabled = false
Manager.dimension = CONFIG.DEFAULT_DIMENSION
Manager.CachedPosition = GetEntityCoords(PlayerPedId())


Manager.HasAttachment = function(attachmentName)
    if Manager.attachments[attachmentName] and DoesEntityExist(Manager.attachments[attachmentName]) then
        return true
    end
    return false
end

RegisterNetEvent("AQUIVER:Player:Attachment:Add", function(attachmentName)
    -- Return if already exists.
    if Manager.HasAttachment(attachmentName) then return end

    local aData = API.AttachmentManager.get(attachmentName)
    if not aData then return end

    local modelHash = GetHashKey(aData.model)
    API.Utils.Client.requestModel(modelHash)

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

    Manager.attachments[attachmentName] = obj
end)
RegisterNetEvent("AQUIVER:Player:Attachment:Remove", function(attachmentName)
    if not Manager.HasAttachment(attachmentName) then return end

    DeleteEntity(Manager.attachments[attachmentName])
    Manager.attachments[attachmentName] = nil
end)
RegisterNetEvent("AQUIVER:Player:Attachment:RemoveAll", function()
    for attachmentName, objectHandle in pairs(Manager.attachments) do
        if DoesEntityExist(objectHandle) then
            DeleteEntity(objectHandle)
        end
    end

    Manager.attachments = {}
end)
RegisterNetEvent("AQUIVER:Player:Freeze:State", function(state)
    Manager.isFreezed = state
    FreezeEntityPosition(PlayerPedId(), state)
end)
RegisterNetEvent("AQUIVER:Player:Animation:Play", function(dict, name, flag)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(10)
    end
    TaskPlayAnim(PlayerPedId(), dict, name, 4.0, 4.0, -1, tonumber(flag), 1.0, false, false, false)
end)
RegisterNetEvent("AQUIVER:Player:Animation:Stop", function()
    ClearPedTasks(PlayerPedId())
end)
RegisterNetEvent("AQUIVER:Player:ForceAnimation:Play", function(dict, name, flag)
    RequestAnimDict(dict)

    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(10)
    end

    Manager.forceAnimationData = {
        dict = dict,
        name = name,
        flag = flag
    }

    Citizen.CreateThread(function()
        while Manager.forceAnimationData.dict ~= nil do

            local localPlayer = PlayerPedId()

            if not IsEntityPlayingAnim(
                localPlayer,
                Manager.forceAnimationData.dict,
                Manager.forceAnimationData.name,
                Manager.forceAnimationData.flag
            ) then
                TaskPlayAnim(
                    localPlayer,
                    Manager.forceAnimationData.dict,
                    Manager.forceAnimationData.name,
                    4.0,
                    4.0,
                    -1,
                    tonumber(Manager.forceAnimationData.flag),
                    1.0,
                    false, false, false
                )
            end

            Citizen.Wait(CONFIG.FORCE_ANIMATION_INTERVAL)
        end
    end)
end)
RegisterNetEvent("AQUIVER:Player:ForceAnimation:Stop", function()
    Manager.forceAnimationData = {
        dict = nil,
        name = nil,
        flag = nil
    }
    ClearPedTasks(PlayerPedId())
end)
RegisterNetEvent("AQUIVER:Player:DisableMovement:State", function(state)
    if state then
        if state == Manager.isMovementDisabled then return end

        Manager.isMovementDisabled = state

        Citizen.CreateThread(function()
            while Manager.isMovementDisabled do

                DisableAllControlActions(0)
                EnableControlAction(0, 1, true)
                EnableControlAction(0, 2, true)

                Citizen.Wait(0)
            end
        end)
    else
        Manager.isMovementDisabled = state
    end
end)
RegisterNetEvent("AQUIVER:Player:Set:Dimension", function(dimension)
    Manager.dimension = dimension
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for k, v in pairs(Manager.attachments) do
        if DoesEntityExist(v) then
            DeleteEntity(v)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Manager.CachedPosition = GetEntityCoords(PlayerPedId())
        Citizen.Wait(CONFIG.CACHE_PLAYER_POSITION_INTERVAL)
    end
end)

AQUIVER_CLIENT.LocalPlayer = Manager
