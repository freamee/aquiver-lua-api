local IS_SERVER = IsDuplicityVersion()

API.EventManager = {}
API.EventManager.LocalEvents = {}

--- Registering local events.
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
        print("AddLocalEvent failed.")
    end
end

API.EventManager.TriggerServerLocalEvent = function(eventName, ...)
    local invokeResource = API.InvokeResourceName()
    if invokeResource == nil then
        invokeResource = "api"
    end

    if IS_SERVER and not API.EventManager.LocalEvents[invokeResource .. "-" .. eventName] then
        print("^1&LocalEvent is not registered: " .. eventName)
        return
    end

    if IS_SERVER then
        API.EventManager.LocalEvents[invokeResource .. "-" .. eventName](...)
    else
        TriggerServerEvent("client-to-server-local", eventName, table.pack(...))
    end
end

API.EventManager.TriggerClientLocalEvent = function(eventName, ...)
    local invokeResource = API.InvokeResourceName()
    if invokeResource == nil then
        invokeResource = "api"
    end

    if not IS_SERVER and not API.EventManager.LocalEvents[invokeResource .. "-" .. eventName] then
        print("^1LocalEvent is not registered: " .. eventName)
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

    Citizen.CreateThread(function()
        while true do
            for k, v in pairs(API.EventManager.LocalEvents) do
                print(k)
            end

            Citizen.Wait(3000)
        end
    end)
else
    RegisterNetEvent("server-to-client-local", function(eventName, args)
        API.EventManager.TriggerClientLocalEvent(eventName, table.unpack(args))
    end)

    Citizen.CreateThread(function()
        while true do
            for k, v in pairs(API.EventManager.LocalEvents) do
                print(k)
            end

            Citizen.Wait(3000)
        end
    end)
end
