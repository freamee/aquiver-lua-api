local IS_SERVER = IsDuplicityVersion()

API.EventManager = {}
API.EventManager.LocalEvents = {}

--- Registering local events. (These events are only reachable inside this resource.)
---@param eventName string | table<string, fun(...):nil>
---@param func? fun(...):nil
API.EventManager.AddLocalEvent = function(eventName, func)
    local invokeResource = API.InvokeResourceName()

    if type(eventName) == "table" then
        for k, v in pairs(eventName) do
            API.EventManager.LocalEvents[invokeResource .. "-" .. k] = v
        end
    elseif type(eventName) == "string" then
        API.EventManager.LocalEvents[invokeResource .. "-" .. eventName] = func
    else
        API.Utils.Debug.Print("AddLocalEvent failed.")
    end
end

--- Triggering an event locally. (This means this event can only be triggered from this resource.)
---@param eventName any
---@param ... unknown Arguments...
API.EventManager.TriggerServerLocalEvent = function(eventName, ...)
    local invokeResource = API.InvokeResourceName()
    if invokeResource == nil then
        invokeResource = "api"
    end

    if IS_SERVER and not API.EventManager.LocalEvents[invokeResource .. "-" .. eventName] then
        API.Utils.Debug.Print("^1&LocalEvent is not registered: " .. eventName)
        return
    end

    if IS_SERVER then
        API.EventManager.LocalEvents[invokeResource .. "-" .. eventName](...)
    else
        TriggerServerEvent("client-to-server-local", eventName, table.pack(...))
    end
end

--- Triggering an event locally. (This means this event can only be triggered from this resource.)
---@param eventName any
---@param ... unknown Arguments... First argument is always the source if there is any.
API.EventManager.TriggerClientLocalEvent = function(eventName, ...)
    local invokeResource = API.InvokeResourceName()
    if invokeResource == nil then
        invokeResource = "api"
    end

    if not IS_SERVER and not API.EventManager.LocalEvents[invokeResource .. "-" .. eventName] then
        API.Utils.Debug.Print("^1LocalEvent is not registered: " .. eventName)
        return
    end

    if IS_SERVER then
        -- Here important to remove source.
        local args = table.pack(...)
        local onSource = args[1] or -1
        if args[1] then table.remove(args, 1) end

        TriggerClientEvent("server-to-client-local", onSource, eventName, args)
    else
        API.EventManager.LocalEvents[invokeResource .. "-" .. eventName](...)
    end
end

if IS_SERVER then
    RegisterNetEvent("client-to-server-local", function(eventName, args)
        local source = source
        API.EventManager.TriggerServerLocalEvent(eventName, table.unpack(args))
    end)
else
    RegisterNetEvent("server-to-client-local", function(eventName, args)
        API.EventManager.TriggerClientLocalEvent(eventName, table.unpack(args))
    end)
end
