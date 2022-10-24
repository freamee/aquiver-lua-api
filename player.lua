local IS_SERVER = IsDuplicityVersion()


if IS_SERVER then
    API.PlayerManager = {}
    ---@type table<number, CPlayer>
    API.PlayerManager.Entities = {}

    API.PlayerManager.new = function(srcID)
        ---@class CPlayer
        local self = {}

        if type(srcID) ~= "number" then srcID = tonumber(srcID) end

        self.srcID = srcID
        self.attachments = {}
        self.variables = {}

        if API.PlayerManager.exists(self.srcID) then
            API.Utils.Debug.Print("^1Player already exists with source: " .. self.srcID)
            return
        end

        self.AddItem = function(item, amount)
            if GetResourceState("ox_inventory") == "started" then
                if exports.ox_inventory:CanCarryItem(self.srcID, item, amount) then
                    exports.ox_inventory:AddItem(self.srcID, item, amount)
                    return true
                end
            end
        end

        self.GetItemAmount = function(item)
            if GetResourceState("ox_inventory") == "started" then
                return exports.ox_inventory:GetItem(self.srcID, item, nil, true)
            end
        end

        self.RemoveItem = function(item, amount)
            if GetResourceState("ox_inventory") == "started" then
                exports.ox_inventory:RemoveItem(self.srcID, item, amount)
            end
        end

        self.AddAttachment = function(attachmentName)
            if not API.AttachmentManager.exists(attachmentName) then
                API.Utils.Debug.Print(string.format("^1%s AddAttachment not registered.", attachmentName))
            end

            if self.HasAttachment(attachmentName) then return end

            self.attachments[attachmentName] = true
            API.EventManager.TriggerClientLocalEvent("Player:Attachment:Add", self.srcID, attachmentName)
        end

        self.RemoveAttachment = function(attachmentName)
            if not self.HasAttachment(attachmentName) then return end

            self.attachments[attachmentName] = nil
            API.EventManager.TriggerClientLocalEvent("Player:Attachment:Remove", self.srcID, attachmentName)
        end

        self.HasAttachment = function(attachmentName)
            if self.attachments[attachmentName] then
                return true
            end
        end

        self.RemoveAllAttachments = function()
            self.attachments = {}
            API.EventManager.TriggerClientLocalEvent("Player:Attachment:RemoveAll", self.srcID)
        end

        self.Freeze = function(state)
            self.variables.isFreezed = state
            API.EventManager.TriggerClientLocalEvent("Player:Freeze:State", self.srcID, state)
        end

        self.PlayAnimation = function(dict, name, flag)
            API.EventManager.TriggerClientLocalEvent("Player:Animation:Play", self.srcID, dict, name, flag)
        end

        self.StopAnimation = function()
            API.EventManager.TriggerClientLocalEvent("Player:Animation:Stop", self.srcID)
        end

        self.ForceAnimation = function(dict, name, flag)
            API.EventManager.TriggerClientLocalEvent("Player:ForceAnimation:Play", self.srcID, dict, name, flag)
        end

        self.StopForceAnimation = function()
            API.EventManager.TriggerClientLocalEvent("Player:ForceAnimation:Stop", self.srcID)
        end

        self.DisableMovement = function(state)
            API.EventManager.TriggerClientLocalEvent("Player:DisableMovement:State", self.srcID, state)
        end

        self.Destroy = function()
            -- Delete from table
            if API.PlayerManager.Entities[self.srcID] then
                API.PlayerManager.Entities[self.srcID] = nil
            end

            API.Utils.Debug.Print("^3Removed player with sourceID: " .. self.srcID)
        end

        API.PlayerManager.Entities[self.srcID] = self
        API.Utils.Debug.Print("^3Created new player with sourceID: " .. self.srcID)

        return self
    end

    API.PlayerManager.get = function(srcID)
        if type(srcID) ~= "number" then srcID = tonumber(id) end

        return API.PlayerManager.Entities[srcID]
    end

    API.PlayerManager.exists = function(srcID)
        if API.PlayerManager.Entities[srcID] then
            return true
        end
    end

    AddEventHandler("onResourceStart", function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end

        local onlinePlayers = GetPlayers()
        for i = 1, #onlinePlayers do
            local srcID = onlinePlayers[i]
            API.PlayerManager.new(srcID)
        end
    end)

    AddEventHandler("playerDropped", function()
        local srcID = source
        local PlayerEntity = API.PlayerManager.get(srcID)
        if not PlayerEntity then return end
        PlayerEntity.Destroy()
    end)

    AddEventHandler("playerJoining", function()
        local srcID = source
        API.PlayerManager.new(srcID)
    end)
else
    API.LocalPlayer = {}
    API.LocalPlayer.attachments = {}
    API.LocalPlayer.isFreezed = false
    API.LocalPlayer.forceAnimationData = {
        dict = nil,
        name = nil,
        flag = nil
    }
    API.LocalPlayer.isMovementDisabled = false

    API.LocalPlayer.HasAttachment = function(attachmentName)
        if API.LocalPlayer.attachments[attachmentName] and DoesEntityExist(API.LocalPlayer.attachments[attachmentName]) then
            return true
        end
    end

    AddEventHandler("onResourceStop", function(resourceName)
        if resourceName ~= GetCurrentResourceName() then return end

        for k, v in pairs(API.LocalPlayer.attachments) do
            if DoesEntityExist(v) then
                DeleteEntity(v)
            end
        end
    end)

    AddEventHandler("onClientResourceStart", function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end

        API.EventManager.AddLocalEvent({
            ["Player:Attachment:Add"] = function(attachmentName)
                -- Return if already exists.
                if API.LocalPlayer.HasAttachment(attachmentName) then return end

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

                API.LocalPlayer.attachments[attachmentName] = obj
            end,
            ["Player:Attachment:Remove"] = function(attachmentName)
                if not API.LocalPlayer.HasAttachment(attachmentName) then return end

                DeleteEntity(API.LocalPlayer.attachments[attachmentName])

                API.LocalPlayer.attachments[attachmentName] = nil
            end,
            ["Player:Attachment:RemoveAll"] = function()
                for attachmentName, objectHandle in pairs(API.LocalPlayer.attachments) do
                    if DoesEntityExist(objectHandle) then
                        DeleteEntity(objectHandle)
                    end
                end

                API.LocalPlayer.attachments = {}
            end,
            ["Player:Freeze:State"] = function(state)
                API.LocalPlayer.isFreezed = state
                FreezeEntityPosition(PlayerPedId(), state)
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

                API.LocalPlayer.forceAnimationData = {
                    dict = dict,
                    name = name,
                    flag = flag
                }

                Citizen.CreateThread(function()
                    while API.LocalPlayer.forceAnimationData.dict ~= nil do

                        local localPlayer = PlayerPedId()

                        if not IsEntityPlayingAnim(
                            localPlayer,
                            API.LocalPlayer.forceAnimationData.dict,
                            API.LocalPlayer.forceAnimationData.name,
                            API.LocalPlayer.forceAnimationData.flag
                        ) then
                            TaskPlayAnim(
                                localPlayer,
                                API.LocalPlayer.forceAnimationData.dict,
                                API.LocalPlayer.forceAnimationData.name,
                                4.0,
                                4.0,
                                -1,
                                tonumber(API.LocalPlayer.forceAnimationData.flag),
                                1.0,
                                false, false, false
                            )
                        end

                        Citizen.Wait(250)
                    end
                end)
            end,
            ["Player:ForceAnimation:Stop"] = function()
                API.LocalPlayer.forceAnimationData = {
                    dict = nil,
                    name = nil,
                    flag = nil
                }
                ClearPedTasks(PlayerPedId())
            end,
            ["Player:DisableMovement:State"] = function(state)
                if state then
                    if state == API.LocalPlayer.isMovementDisabled then return end

                    API.LocalPlayer.isMovementDisabled = state

                    Citizen.CreateThread(function()
                        while API.LocalPlayer.isMovementDisabled do

                            DisableAllControlActions(0)
                            EnableControlAction(0, 1, true)
                            EnableControlAction(0, 2, true)

                            Citizen.Wait(0)
                        end
                    end)
                else
                    API.LocalPlayer.isMovementDisabled = state
                end
            end
        })
    end)
end
