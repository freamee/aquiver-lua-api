Shared.EventManager:RegisterModuleNetworkEvent({
    ["Object:Interaction:Press"] = function(remoteId)
        local source = source

        local aObject = Server.ObjectManager:get(remoteId)
        local Player = Server.PlayerManager:get(source)
        if not (Player and aObject) then return end

        if type(aObject.onPress) == "function" then
            aObject.onPress(Player, aObject)
        end
    end,
    ["Ped:Interaction:Press"] = function(remoteId)
        local source = source

        local aPed = Server.PedManager:get(remoteId)
        local Player = Server.PlayerManager:get(source)
        if not (Player and aPed) then return end

        if type(aPed.onPress) == "function" then
            aPed.onPress(Player, aPed)
        end
    end,
})
