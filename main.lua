local IS_SERVER = IsDuplicityVersion()

-- if IS_SERVER then

--     AddEventHandler("onResourceStop", function(resourceName)
--         if resourceName ~= GetCurrentResourceName() then return end

--     end)

-- else
--     AddEventHandler("onClientResourceStart", function(resourceName)
--         if resourceName ~= GetCurrentResourceName() then return end

--     end)
-- end
if IS_SERVER then
    API.ObjectManager.LoadObjectsFromSQL()
else
    API.RaycastManager.Enable(true)
end
