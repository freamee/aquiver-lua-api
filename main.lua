if API.IsServer then
    AQUIVER_SERVER.ObjectManager.LoadObjectsFromSQL()
else
    AQUIVER_CLIENT.RaycastManager.Enable(true)
end
