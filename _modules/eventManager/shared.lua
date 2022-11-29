---@class SharedEventManager
local Module = {}

local _cachedResourceName = GetCurrentResourceName()
local _isServer = IsDuplicityVersion()

local function eventNameFormat(eventName)
    return string.format("module:%s:%s", _cachedResourceName, eventName)
end

---@param eventName string | { [string]: fun(...) }
---@param cb? fun(...)
function Module:RegisterModuleNetworkEvent(eventName, cb)
    if type(eventName) == "table" then
        for k, v in pairs(eventName) do
            RegisterNetEvent(eventNameFormat(k), v)
        end
    else
        if type(cb) ~= "function" then return end
        RegisterNetEvent(eventNameFormat(eventName), cb)
    end
end

---@param eventName string | { [string]: fun(...) }
---@param cb fun(...)
function Module:RegisterModuleEvent(eventName, cb)
    if type(eventName) == "table" then
        for k, v in pairs(eventName) do
            RegisterNetEvent(eventNameFormat(k), v)
        end
    else
        if type(cb) ~= "function" then return end
        AddEventHandler(eventNameFormat(eventName), cb)
    end
end

function Module:TriggerModuleEvent(eventName, ...)
    TriggerEvent(eventNameFormat(eventName), ...)
end

function Module:TriggerModuleServerEvent(eventName, ...)
    if _isServer then print("^1TriggerModuleServerEvent triggered from serverside.") return end
    TriggerServerEvent(eventNameFormat(eventName), ...)
end

function Module:TriggerModuleClientEvent(eventName, ...)
    if not _isServer then print("^1TriggerModuleClientEvent triggered from clientside.") return end
    TriggerClientEvent(eventNameFormat(eventName), ...)
end

return Module
