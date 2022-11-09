API.Players = {}
---@type table<number, SPlayer>
API.Players.Entities = {}

function API.Players.get(source)
    if type(source) ~= "number" then
        source = tonumber(source)
    end
    if source == nil then return end

    if not API.Players.Entities[source] then
        return
    end

    return API.Players.Entities[source]
end

function API.Players.new(source)
    if type(source) ~= "number" then
        source = tonumber(source)
    end
    if source == nil then return end

    ---@class SPlayer
    local class = {
        variables = {},
        attachments = {}
    }

    API.Players.Entities[source] = class

    API.Players.SetDimension(source, CONFIG.DEFAULT_DIMENSION)

    API.Utils.Debug.Print("^3Created new player with sourceID: " .. source)
end

function API.Players.GetVariable(source, key)
    local ref = API.Players.get(source)
    if not ref then return end

    return ref.variables[key]
end

function API.Players.GetVariables(source)
    local ref = API.Players.get(source)
    if not ref then return end

    return ref.variables
end

function API.Players.RemoveVariable(source, key)
    local ref = API.Players.get(source)
    if not ref then return end

    ref.variables[key] = nil
end

function API.Players.RemoveVariables(source, vars)
    local ref = API.Players.get(source)
    if not ref then return end

    if type(vars) ~= "table" then
        API.Utils.Debug.Print("^Player SetVariables failed: vars should be a array table.")
        return
    end

    for i = 1, #vars, 1 do
        ref.variables[vars[i]] = nil
    end
end

function API.Players.SetVariables(source, vars)
    local ref = API.Players.get(source)
    if not ref then return end

    if type(vars) ~= "table" then
        API.Utils.Debug.Print("^Player SetVariables failed: vars should be a key-value table.")
        return
    end

    for k, v in pairs(vars) do
        ref.variables[k] = v
    end
end

function API.Players.SetVariable(source, key, value)
    local ref = API.Players.get(source)
    if not ref then return end

    ref.variables[key] = value
end

function API.Players.AddItem(source, item, amount)
    if GetResourceState("ox_inventory") == "started" then
        if exports.ox_inventory:CanCarryItem(source, item, amount) then
            exports.ox_inventory:AddItem(source, item, amount)
            return true
        end
    end
end

function API.Players.GetItemAmount(source, item)
    if GetResourceState("ox_inventory") == "started" then
        return exports.ox_inventory:GetItem(source, item, nil, true)
    end
end

function API.Players.RemoveItem(source, item, amount)
    if GetResourceState("ox_inventory") == "started" then
        exports.ox_inventory:RemoveItem(source, item, amount)
    end
end

function API.Players.AddAttachment(source, attachmentName)
    if not API.AttachmentManager.exists(attachmentName) then
        API.Utils.Debug.Print(string.format("^1%s AddAttachment not registered.", attachmentName))
    end

    if API.Players.HasAttachment(source, attachmentName) then return end

    local ref = API.Players.get(source)
    if not ref then return end

    ref.attachments[attachmentName] = true

    TriggerClientEvent("AQUIVER:Player:Attachment:Add", source, attachmentName)
end

function API.Players.RemoveAttachment(source, attachmentName)
    if not API.Players.HasAttachment(source, attachmentName) then return end

    local ref = API.Players.get(source)
    if not ref then return end

    ref.attachments[attachmentName] = nil

    TriggerClientEvent("AQUIVER:Player:Attachment:Remove", source, attachmentName)
end

function API.Players.HasAttachment(source, attachmentName)
    local ref = API.Players.get(source)
    if not ref then return end

    return ref.attachments[attachmentName] and true or false
end

function API.Players.RemoveAllAttachments(source)
    local ref = API.Players.get(source)
    if not ref then return end

    ref.attachments = {}

    TriggerClientEvent("AQUIVER:Player:Attachment:RemoveAll", source)
end

function API.Players.Freeze(source, state)
    local ref = API.Players.get(source)
    if not ref then return end

    ref.variables.isFreezed = state

    TriggerClientEvent("AQUIVER:Player:Freeze:State", source, state)
end

function API.Players.PlayAnimation(source, dict, name, flag)
    TriggerClientEvent("AQUIVER:Player:Animation:Play", source, dict, name, flag)
end

function API.Players.StopAnimation(source)
    TriggerClientEvent("AQUIVER:Player:Animation:Stop", source)
end

function API.Players.ForceAnimation(source, dict, name, flag)
    TriggerClientEvent("AQUIVER:Player:ForceAnimation:Play", source, dict, name, flag)
end

function API.Players.StopForceAnimation(source)
    TriggerClientEvent("AQUIVER:Player:ForceAnimation:Stop", source)
end

function API.Players.DisableMovement(source, state)
    TriggerClientEvent("AQUIVER:Player:DisableMovement:State", source, state)
end

---@param jsonContent table
function API.Players.SendNUIMessage(source, jsonContent)
    TriggerClientEvent("AQUIVER:Player:SendNUIMessage", source, jsonContent)
end

---@param type "error" | "success" | "info" | "warning"
---@param message string
function API.Players.Notification(source, type, message)
    API.Players.SendNUIMessage(source, {
        event = "Send-Notification",
        type = type,
        message = message
    })
end

function API.Players.GetDimension(source)
    return GetPlayerRoutingBucket(source)
end

function API.Players.SetDimension(source, dimension)
    local ref = API.Players.get(source)
    if not ref then return end

    local attaches = json.decode(json.encode(ref.attachments))

    API.Players.RemoveAllAttachments(source)

    SetPlayerRoutingBucket(source, dimension)
    TriggerClientEvent("AQUIVER:Player:Set:Dimension", source, dimension)

    TriggerEvent("onPlayerDimensionChange", source, dimension)
    TriggerClientEvent("onPlayerDimensionChange", source, dimension)

    for k, v in pairs(attaches) do
        API.Players.AddAttachment(source, k)
    end
end

function API.Players.GetIdentifier(source)
    for k, v in pairs(GetPlayerIdentifiers(source)) do
        if string.sub(v, 1, string.len('license:')) == 'license:' then
            return v
        end
    end
    return nil
end

function API.Players.GetName(source)
    return GetPlayerName(source)
end

--- Start progress for player.
--- Callback passes the player's source ID.
---@param text string
---@param time number Time in milliseconds (MS) 1000ms-1second
---@param cb fun(source:number)
function API.Players.Progress(source, text, time, cb)
    local ref = API.Players.get(source)
    if not ref then return end

    if ref.variables.hasProgress then return end

    ref.variables.hasProgress = true

    API.Players.SendNUIMessage(source, {
        event = "Progress-Start",
        time = time,
        text = text
    })

    Citizen.SetTimeout(time, function()
        ref = API.Players.get(source)
        if not ref then return end

        ref.variables.hasProgress = false

        if Citizen.GetFunctionReference(cb) then
            cb(source)
        end
    end)
end

---@class IClickMenuEntry
---@field name string
---@field icon string
---@field eventName? string
---@field eventArgs any

---@param menuData IClickMenuEntry[]
function API.Players.ClickMenuOpen(source, menuHeader, menuData)
    API.Players.SendNUIMessage(source, {
        event = "ClickMenu-Open",
        menuHeader = menuHeader,
        menuData = menuData
    })
end

function API.Players.Destroy(source)
    -- Delete from table
    if API.Players.Entities[source] then
        API.Players.Entities[source] = nil
    end

    API.Utils.Debug.Print("^3Removed player with sourceID: " .. source)
end

AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    local onlinePlayers = GetPlayers()
    for i = 1, #onlinePlayers do
        local source = onlinePlayers[i]
        API.Players.new(source)
    end
end)

AddEventHandler("playerDropped", function()
    local source = source
    API.Players.Destroy(source)
end)

AddEventHandler("playerJoining", function()
    local source = source
    API.Players.new(source)
end)