if API.IsServer then

else
    RegisterNUICallback("trigger_client", function(d)
        local event, args = d.event, d.args
        TriggerEvent(event, args)
    end)

    RegisterNUICallback("trigger_server", function(d)
        local event, args = d.event, d.args
        TriggerServerEvent(event, args)
    end)

    RegisterNUICallback("focusNUI", function(state, cb)
        SetNuiFocus(state, state)
        cb("")
    end)

    RegisterNetEvent("AQUIVER:Player:SendNUIMessage", function(jsonContent)
        SendNUIMessage(jsonContent)
    end)
end
