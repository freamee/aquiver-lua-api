if API.IsServer then
    AQUIVER_SERVER.ObjectManager.LoadObjectsFromSQL()
else
    API.RaycastManager.Enable(true)
end
