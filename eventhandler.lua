API.EventManager = {}
---@type table<string, { registeredResource: string; func: fun(...) }>
API.EventManager.LocalEvents = {}
---@type table<string, { invokedFromResource: string; func: fun(...) }[]>
API.EventManager.GlobalEvents = {}

--- Registering global events.
---@param eventName string | table<string, fun(...)>
---@param func? fun(...)
API.EventManager.AddGlobalEvent = function(eventName, func)
    if type(eventName) == "table" then
        for k, v in pairs(eventName) do
            if Citizen.GetFunctionReference(v) then
                if type(API.EventManager.GlobalEvents[k]) ~= "table" then
                    API.EventManager.GlobalEvents[k] = {}
                end

                table.insert(API.EventManager.GlobalEvents[k], {
                    func = v,
                    invokedFromResource = API.InvokeResourceName()
                })
            end
        end
    elseif type(eventName) == "string" and func and Citizen.GetFunctionReference(func) then
        if type(API.EventManager.GlobalEvents[eventName]) ~= "table" then
            API.EventManager.GlobalEvents[eventName] = {}
        end

        table.insert(API.EventManager.GlobalEvents[eventName], {
            func = func,
            invokedFromResource = API.InvokeResourceName()
        })
    else
        API.Utils.Debug.Print("AddGlobalEvent failed.")
    end
end

--- Triggering a global event.
---@param eventName string
---@param ... unknown Arguments...
API.EventManager.TriggerServerGlobalEvent = function(eventName, ...)
    if API.IsServer and not API.EventManager.GlobalEvents[eventName] then
        API.Utils.Debug.Print("^1GlobalEvent is not registered: " .. eventName)
        return
    end

    if API.IsServer then
        local Events = API.EventManager.GlobalEvents[eventName]
        if type(Events) == "table" then
            for i = 1, #Events, 1 do
                Events[i].func(...)
            end
        end
    else
        TriggerServerEvent("", eventName, table.pack(...))
    end
end

API.EventManager.TriggerClientGlobalEvent = function(eventName, ...)
    if not API.IsServer and not API.EventManager.GlobalEvents[eventName] then
        API.Utils.Debug.Print("^1GlobalEvent is not registered: " .. eventName)
        return
    end

    if API.IsServer then
        -- Here important to remove source.
        local args = table.pack(...)
        local onSource = args[1] or -1
        if args[1] then table.remove(args, 1) end

        TriggerClientEvent("server-to-client-global", onSource, eventName, args)
    else
        local Events = API.EventManager.GlobalEvents[eventName]
        if type(Events) == "table" then
            for i = 1, #Events, 1 do
                Events[i].func(...)
            end
        end
    end
end

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
        API.EventManager.TriggerServerLocalEvent(eventName, table.unpack(args))
    end)

    RegisterNetEvent("client-to-server-global", function(eventName, args)
        API.EventManager.TriggerServerGlobalEvent(eventName, table.unpack(args))
    end)
else
    RegisterNetEvent("server-to-client-local", function(eventName, args)
        API.EventManager.TriggerClientLocalEvent(eventName, table.unpack(args))
    end)

    RegisterNetEvent("server-to-client-global", function(eventName, args)
        API.EventManager.TriggerClientGlobalEvent(eventName, table.unpack(args))
    end)
end

-- Delete events if another resource is restarted which has connections to this.
AddEventHandler("onResourceStop", function(resourceName)

    -- Delete local events cache.
    for k, v in pairs(API.EventManager.LocalEvents) do
        if v.registeredResource == resourceName then
            API.EventManager.LocalEvents[k] = nil
        end
    end

    -- Delete global events cache.
    for eventName, events in pairs(API.EventManager.GlobalEvents) do
        if type(events) == "table" then
            for i = 1, #events, 1 do
                if events[i].invokedFromResource == resourceName then
                    table.remove(API.EventManager.GlobalEvents[eventName], i)
                end
            end
        end
    end
end)
