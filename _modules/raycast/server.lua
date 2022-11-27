-- RegisterNetEvent("Object:Interaction:Press", function(remoteId)
--     local source = source

--     local ObjectEntity = AQUIVER_SERVER.ObjectManager.get(remoteId)
--     if not ObjectEntity then return end

--     local Player = AQUIVER_SERVER.PlayerManager.get(source)
--     if not Player then return end

--     if Citizen.GetFunctionReference(ObjectEntity.onPress) then
--         ObjectEntity.onPress(Player, ObjectEntity)
--     end
-- end)

-- RegisterNetEvent("Ped:Interaction:Press", function(remoteId)
--     local source = source

--     local PedEntity = AQUIVER_SERVER.PedManager.get(remoteId)
--     if not PedEntity then return end

--     local Player = AQUIVER_SERVER.PlayerManager.get(source)
--     if not Player then return end

--     if Citizen.GetFunctionReference(PedEntity.onPress) then
--         PedEntity.onPress(Player, PedEntity)
--     end
-- end)
