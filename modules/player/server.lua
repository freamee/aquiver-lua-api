local Manager = {}
---@type { [number]: ServerPlayer }
Manager.Entities = {}

Manager.new = function(source)
    ---@class ServerPlayer
    local self = {}

    if type(source) ~= "number" then source = tonumber(source) end

    self.source = source
    self.attachments = {}
    self.variables = {}

    self.Get = {
        Variable = function(key)
            return self.variables[key]
        end,
        Variables = function()
            return self.variables
        end,
        Dimension = function()
            return GetPlayerRoutingBucket(self.source)
        end,
        Identifier = function()
            for k, v in pairs(GetPlayerIdentifiers(self.source)) do
                if string.sub(v, 1, string.len('license:')) == 'license:' then
                    return v
                end
            end
            return nil
        end,
        Name = function()
            return GetPlayerName(self.source)
        end
    }

    self.Set = {
        Variable = function(key, value)
            if self.variables[key] == value then return end

            self.variables[key] = value
            TriggerEvent("onPlayerVariableChange", self, key, value)
            TriggerClientEvent("onPlayerVariableChange", self.source, key, value)
        end,
        Dimension = function(dimension)
            local attaches = json.decode(json.encode(self.attachments))

            self.RemoveAllAttachments()

            SetPlayerRoutingBucket(self.source, dimension)
            TriggerClientEvent("AQUIVER:Player:Set:Dimension", self.source, dimension)

            TriggerEvent("onPlayerDimensionChange", self.source, dimension)
            TriggerClientEvent("onPlayerDimensionChange", self.source, dimension)

            for k, v in pairs(attaches) do
                self.AddAttachment(k)
            end
        end
    }

    self.AddItem = function(item, amount)
        if GetResourceState("ox_inventory") == "started" then
            if exports.ox_inventory:CanCarryItem(self.source, item, amount) then
                exports.ox_inventory:AddItem(self.source, item, amount)
                return true
            end
        end
    end

    self.GetItemAmount = function(item)
        if GetResourceState("ox_inventory") == "started" then
            return exports.ox_inventory:GetItem(self.source, item, nil, true)
        end
    end

    self.RemoveItem = function(item, amount)
        if GetResourceState("ox_inventory") == "started" then
            exports.ox_inventory:RemoveItem(self.source, item, amount)
        end
    end

    self.AddAttachment = function(attachmentName)
        if not AQUIVER_SHARED.AttachmentManager.exists(attachmentName) then
            AQUIVER_SHARED.Utils.Print(string.format("^1%s AddAttachment not registered.", attachmentName))
            return
        end

        if self.HasAttachment(attachmentName) then return end

        self.attachments[attachmentName] = true
        TriggerClientEvent("AQUIVER:Player:Attachment:Add", self.source, attachmentName)
    end

    self.RemoveAttachment = function(attachmentName)
        if not self.HasAttachment(attachmentName) then return end

        self.attachments[attachmentName] = nil
        TriggerClientEvent("AQUIVER:Player:Attachment:Remove", self.source, attachmentName)
    end

    self.HasAttachment = function(attachmentName)
        return self.attachments[attachmentName] and true or false
    end

    self.RemoveAllAttachments = function()
        self.attachments = {}
        TriggerClientEvent("AQUIVER:Player:Attachment:RemoveAll", self.source)
    end

    self.Freeze = function(state)
        self.Set.Variable("isFreezed", state)
    end

    self.PlayAnimation = function(dict, name, flag)
        TriggerClientEvent("AQUIVER:Player:Animation:Play", self.source, dict, name, flag)
    end

    self.StopAnimation = function()
        TriggerClientEvent("AQUIVER:Player:Animation:Stop", self.source)
    end

    self.ForceAnimation = function(dict, name, flag)
        TriggerClientEvent("AQUIVER:Player:ForceAnimation:Play", self.source, dict, name, flag)
    end

    self.StopForceAnimation = function()
        TriggerClientEvent("AQUIVER:Player:ForceAnimation:Stop", self.source)
    end

    self.DisableMovement = function(state)
        TriggerClientEvent("AQUIVER:Player:DisableMovement:State", self.source, state)
    end

    self.StartIndicatorAtPosition = function(uid, vec3, text, timeMS)
        TriggerClientEvent("AQUIVER:Player:StartIndicatorAtPosition", self.source, uid, vec3, text, timeMS)
    end

    ---@param type "error" | "success" | "info" | "warning"
    ---@param message string
    self.Notification = function(type, message)
        self.SendNUIMessage({
            event = "Send-Notification",
            type = type,
            message = message
        })
    end

    --- Start progress for player.
    --- Callback passes the Player after the progress is finished: cb(Player)
    ---@param text string
    ---@param time number Time in milliseconds (MS) 1000ms-1second
    ---@param cb fun()
    self.Progress = function(text, time, cb)
        if self.Get.Variable("hasProgress") then return end

        self.Set.Variable("hasProgress", true)

        self.SendNUIMessage({
            event = "Progress-Start",
            time = time,
            text = text
        })

        Citizen.SetTimeout(time, function()
            -- No idea, if that can happen on FiveM..
            if not self then return end

            self.Set.Variable("hasProgress", false)

            if Citizen.GetFunctionReference(cb) then
                cb()
            end
        end)
    end

    ---@param menuData { name:string; icon:string; eventName?:string; eventArgs?:any }[]
    self.ClickMenuOpen = function(menuHeader, menuData)
        self.SendNUIMessage({
            event = "ClickMenu-Open",
            menuHeader = menuHeader,
            menuData = menuData
        })
    end

    ---@param jsonContent table
    self.SendNUIMessage = function(jsonContent)
        TriggerClientEvent("AQUIVER:Player:SendNUIMessage", self.source, jsonContent)
    end

    self.Destroy = function()
        -- Delete from table
        if Manager.exists(self.source) then
            Manager.Entities[self.source] = nil
        end

        AQUIVER_SHARED.Utils.Print("^3Removed player with sourceID: " .. self.source)
    end

    if Manager.exists(self.source) then
        AQUIVER_SHARED.Utils.Print("^1Player already exists with source: " .. self.source)
        return
    end

    Manager.Entities[self.source] = self

    --         self.SetDimension(CONFIG.DEFAULT_DIMENSION)
    AQUIVER_SHARED.Utils.Print("^3Created new player with sourceID: " .. self.source)

    return self
end

Manager.exists = function(source)
    if type(source) ~= "number" then source = tonumber(source) end
    if source == nil then return end

    return Manager.Entities[source] and true or false
end

Manager.get = function(source)
    if type(source) ~= "number" then source = tonumber(source) end
    if source == nil then return end

    return Manager.Entities[source] or nil
end

Manager.getAll = function()
    return Manager.Entities
end

AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    local onlinePlayers = GetPlayers()
    for i = 1, #onlinePlayers do
        Manager.new(onlinePlayers[i])
    end
end)

AddEventHandler("playerDropped", function()
    local source = source

    local PlayerEntity = Manager.get(source)
    if not PlayerEntity then return end

    PlayerEntity.Destroy()
end)

AddEventHandler("playerJoining", function()
    local source = source
    Manager.new(source)
end)


AQUIVER_SERVER.PlayerManager = Manager
