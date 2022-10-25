local IS_SERVER = IsDuplicityVersion()

if IS_SERVER then

else
    RegisterNUICallback("trigger_client", function(d)
        local event, args = d.event, d.args

        API.EventManager.TriggerClientLocalEvent(event, args)
    end)

    AddEventHandler("onClientResourceStart", function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end

        API.EventManager.AddLocalEvent("focusNUI", function(state)
            SetNuiFocus(state, state)
        end)

        API.EventManager.AddLocalEvent("Player:SendNUIMessage", function(jsonContent)
            SendNUIMessage(jsonContent)
        end)
    end)
end
