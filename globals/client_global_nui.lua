RegisterNUICallback("trigger_client", function(d, cb)
    local event, args = d.event, d.args
    TriggerEvent(event, args)

    cb({})
end)

RegisterNUICallback("trigger_server", function(d, cb)
    local event, args = d.event, d.args
    TriggerServerEvent(event, args)

    cb({})
end)

RegisterNUICallback("focusNUI", function(state, cb)
    SetNuiFocus(state, state)
    cb({})
end)

RegisterNetEvent("AQUIVER:API:Player:SendNUIMessage", function(jsonContent)
    SendNUIMessage(jsonContent)
end)
