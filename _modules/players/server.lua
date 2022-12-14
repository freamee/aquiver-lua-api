---@class SPlayerModule
local Module = {}
---@type { [number]: SAquiverPlayer }
Module.Entities = {}

---@class SAquiverPlayer
local Player = {
    source = nil,
    attachments = {},
    variables = {}
}
Player.__index = Player

Player.new = function(source)
    local self = setmetatable({}, Player)

    if type(source) ~= "number" then source = tonumber(source) end

    self.source = source
    self.attachments = {}
    self.variables = {}

    if Module:exists(self.source) then
        Shared.Utils.Print:Error("^1Player already exists with sourceID: " .. self.source)
        return
    end

    self:__init__()

    Module.Entities[self.source] = self

    Shared.EventManager:TriggerModuleClientEvent(
        "GlobalPlayers:Create",
        -1,
        self.source,
        self.attachments,
        self:getDimension()
    )

    Shared.Utils.Print:Debug("^3Created new player with sourceID: " .. self.source)

    return self
end

function Player:__init__()
    self:setDimension(Shared.Config.DEFAULT_DIMENSION)
end

function Player:Destroy()
    if Module:exists(self.source) then
        Module.Entities[self.source] = nil
    end

    Shared.EventManager:TriggerModuleClientEvent(
        "GlobalPlayers:Destroy",
        -1,
        self.source
    )

    Shared.Utils.Print:Debug("^3Removed player with sourceID: " .. self.source)
end

function Player:addAttachment(attachmentName)
    if not Shared.AttachmentManager:exists(attachmentName) then
        Shared.Utils.Print:Error("^1" .. attachmentName .. " not registered.")
        return
    end

    if self:hasAttachment(attachmentName) then return end

    self.attachments[attachmentName] = true
    Shared.EventManager:TriggerModuleClientEvent("GlobalPlayer:Attachment:Add", -1, self.source, attachmentName)
end

function Player:hasAttachment(attachmentName)
    return self.attachments[attachmentName] and true or false
end

function Player:removeAttachment(attachmentName)
    if not self:hasAttachment(attachmentName) then return end

    self.attachments[attachmentName] = nil
    Shared.EventManager:TriggerModuleClientEvent("GlobalPlayer:Attachment:Remove", -1, self.source, attachmentName)
end

function Player:freeze(state)
    self.variables.isFreezed = state
    Shared.EventManager:TriggerModuleClientEvent("Player:Freeze", self.source, state)
end

function Player:isFreezed()
    return self.variables.isFreezed or false
end

function Player:playAnimationPromise(dict, name, flag, timeMS)
    if self.variables.hasAnimPromise then return end

    self.variables.hasAnimPromise = true
    self:playAnimation(dict, name, flag)

    Citizen.SetTimeout(timeMS, function()
        self.variables.hasAnimPromise = false
        self:stopAnimation()
    end)
end

function Player:playAnimation(dict, name, flag)
    Shared.EventManager:TriggerModuleClientEvent("Player:Animation:Play", self.source, dict, name, flag)
end

function Player:stopAnimation()
    Shared.EventManager:TriggerModuleClientEvent("Player:Animation:Stop", self.source)
end

function Player:forceAnimation(dict, name, flag)
    Shared.EventManager:TriggerModuleClientEvent("Player:ForceAnimation:Play", self.source, dict, name, flag)
end

function Player:stopForceAnimation()
    Shared.EventManager:TriggerModuleClientEvent("Player:ForceAnimation:Stop", self.source)
end

function Player:disableMovement(state)
    Shared.EventManager:TriggerModuleClientEvent("Player:DisableMovement:State", self.source, state)
end

function Player:startIndicatorPosition(uid, vec3, text, timeMS)
    Shared.EventManager:TriggerModuleClientEvent("Player:StartIndicatorAtPosition", self.source, uid, vec3, text, timeMS)
end

function Player:setDimension(dimension)
    SetPlayerRoutingBucket(self.source, dimension)
    Shared.EventManager:TriggerModuleClientEvent("GlobalPlayer:Set:Dimension", -1, self.source, dimension)
    Shared.EventManager:TriggerModuleClientEvent("Player:Set:Dimension", self.source, dimension)
end

---@param jsonContent table
function Player:sendNuiMessageAPI(jsonContent)
    TriggerClientEvent("AQUIVER:API:Player:SendNUIMessage", self.source, jsonContent)
end

---@param type "error" | "success" | "info" | "warning"
---@param message string
function Player:notification(type, message)
    self:sendNuiMessageAPI({
        event = "Send-Notification",
        type = type,
        message = message
    })
end

function Player:getVar(key)
    return self.variables[key]
end

function Player:setVar(key, value)
    if self.variables[key] == value then return end

    self.variables[key] = value
    Shared.EventManager:TriggerModuleClientEvent("onPlayerVariableChange", self.source, key, value)
    Shared.EventManager:TriggerModuleEvent("onPlayerVariableChange", self.source, key, value)
end

--- Start progress for player.
--- Callback passes the Player after the progress is finished: cb(Player)
---@param text string
---@param time number Time in milliseconds (MS) 1000ms-1second
---@param cb fun()
function Player:progress(text, time, cb)
    if self:getVar("hasProgress") then return end

    self:setVar("hasProgress", true)

    self:sendNuiMessageAPI({
        event = "Progress-Start",
        time = time,
        text = text
    })

    Citizen.SetTimeout(time, function()
        -- No idea, if that can happen on FiveM..
        if not self then return end

        self:setVar("hasProgress", false)

        if cb then
            cb()
        end
    end)
end

---@param menuData { name:string; icon:string; eventName?:string; eventArgs?:any }[]
function Player:clickMenuOpen(menuHeader, menuData)
    self:sendNuiMessageAPI({
        event = "ClickMenu-Open",
        menuHeader = menuHeader,
        menuData = menuData
    })
end

---@param modalData { question:string; icon?:string; inputs: { id:string; placeholder:string; value?:string; }[]; buttons: { name:string; event:string; args?:any; }[] }
function Player:openModal(modalData)
    self:sendNuiMessageAPI({
        event = "ModalMenu-Open",
        modalData = modalData
    })
end

function Player:getDimension()
    return GetPlayerRoutingBucket(self.source)
end

function Module:new(source)
    local aPlayer = Player.new(source)
    if aPlayer then
        return aPlayer
    end
end

function Module:exists(source)
    if type(source) ~= "number" then source = tonumber(source) end
    if source == nil then return end

    return self.Entities[source] and true or false
end

function Module:get(source)
    if type(source) ~= "number" then source = tonumber(source) end
    if source == nil then return end

    return self.Entities[source] or nil
end

AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    local onlinePlayers = GetPlayers()
    for i = 1, #onlinePlayers do
        Module:new(onlinePlayers[i])
    end
end)

AddEventHandler("playerDropped", function()
    local source = source
    local aPlayer = Module:get(source)
    if not aPlayer then return end

    aPlayer:Destroy()
end)

AddEventHandler("playerJoining", function()
    local source = source
    Module:new(source)
end)

Shared.EventManager:RegisterModuleNetworkEvent("GlobalPlayers:RequestData", function()
    local source = source

    for k, v in pairs(Server.PlayerManager.Entities) do
        Shared.EventManager:TriggerModuleClientEvent(
            "GlobalPlayers:Create",
            source,
            v.source,
            v.attachments,
            v:getDimension()
        )
    end
end)

return Module
