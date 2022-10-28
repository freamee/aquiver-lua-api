if API.IsServer then
    API.ObjectManager.LoadObjectsFromSQL()
else
    API.RaycastManager.Enable(true)
end
