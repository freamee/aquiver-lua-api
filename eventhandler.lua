API.EventManager = {}
---@type table<string, { registeredResource: string; func: fun(...) }>
API.EventManager.LocalEvents = {}

--- Registering local events. (These events are only reachable inside this resource.)
---@param eventName string | table<string, fun(...)>
---@param func? fun(...)
API.EventManager.AddLocalEvent = function(eventName, func)
    local invokeResource = API.InvokeResourceName()

    if type(eventName) == "table" then
        for k, v in pairs(eventName) do
            API.EventManager.LocalEvents[invokeResource .. "-" .. k] = {
                registeredResource = invokeResource,
                func = v
            }
        end
    elseif type(eventName) == "string" and func then
        API.EventManager.LocalEvents[invokeResource .. "-" .. eventName] = {
            registeredResource = invokeResource,
            func = func
        }
    else
        API.Utils.Debug.Print("AddLocalEvent failed.")
    end
end

--- Triggering an event locally. (This means this event can only be triggered from this resource.)
---@param eventName any
---@param ... unknown Arguments...
API.EventManager.TriggerServerLocalEvent = function(eventName, ...)
    local invokeResource = API.InvokeResourceName()

    if API.IsServer and not API.EventManager.LocalEvents[invokeResource .. "-" .. eventName] then
        API.Utils.Debug.Print("^1&LocalEvent is not registered: " .. eventName)
        return
    end

    if API.IsServer then
        local Event = API.EventManager.LocalEvents[invokeResource .. "-" .. eventName]
        if Event.registeredResource ~= invokeResource then
            API.Utils.Debug.Print("^1&Can not trigger this function from another resource: " .. eventName)
            return
        end

        Event.func(...)
    else
        TriggerServerEvent("client-to-server-local", eventName, table.pack(...))
    end
end

--- Triggering an event locally. (This means this event can only be triggered from this resource.)
---@param eventName any
---@param ... unknown Arguments... First argument is always the source if there is any.
API.EventManager.TriggerClientLocalEvent = function(eventName, ...)
    local invokeResource = API.InvokeResourceName()

    if not API.IsServer and not API.EventManager.LocalEvents[invokeResource .. "-" .. eventName] then
        API.Utils.Debug.Print("^1LocalEvent is not registered: " .. eventName)
        return
    end

    if API.IsServer then
        -- Here important to remove source.
        local args = table.pack(...)
        local onSource = args[1] or -1
        if args[1] then table.remove(args, 1) end

        TriggerClientEvent("server-to-client-local", onSource, eventName, args)
    else
        local Event = API.EventManager.LocalEvents[invokeResource .. "-" .. eventName]
        if Event.registeredResource ~= invokeResource then
            API.Utils.Debug.Print("^1&Can not trigger this function from another resource: " .. eventName)
            return
        end

        Event.func(...)
    end
end

if API.IsServer then
    RegisterNetEvent("client-to-server-local", function(eventName, args)
        local source = source
        API.EventManager.TriggerServerLocalEvent(eventName, table.unpack(args))
    end)
else
    RegisterNetEvent("server-to-client-local", function(eventName, args)
        API.EventManager.TriggerClientLocalEvent(eventName, table.unpack(args))
    end)
end

-- Delete events if another resource is restarted which has connections to this.
AddEventHandler("onResourceStop", function(resourceName)
    for k, v in pairs(API.EventManager.LocalEvents) do
        if v.registeredResource == resourceName then
            API.EventManager.LocalEvents[k] = nil
        end
    end
end)
