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

    AddEventHandler("onClientResourceStart", function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end

        AddEventHandler("focusNUI", function(state)
            SetNuiFocus(state, state)
        end)

        RegisterNetEvent("AQUIVER:Player:SendNUIMessage", function(jsonContent)
            SendNUIMessage(jsonContent)
        end)
    end)
end
