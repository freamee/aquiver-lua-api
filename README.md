# Requesting API (Install)
## fxmanifest.lua

> You have to load them first in your resource.
```lua
server_scripts {
    '@aquiver_lua/_modules/shared_lib.lua',
    '@aquiver_lua/_modules/server_lib.lua'
}

client_scripts {
    '@aquiver_lua/_modules/shared_lib.lua',
    '@aquiver_lua/_modules/client_lib.lua'
}
```

> After requesting them in the `fxmanifest.lua` file, you will be able to call and trigger the module functions.

# Events
## Client -> Server
- onActionShapeEnter (shapeRemoteId: number)
- onActionShapeLeave (shapeRemoteId: number)
- onPedInteractionPress (pedRemoteId: number)
- onObjectInteractionPress (objectRemoteId: number)

## Client
- onActionShapeEnter (shapeRemoteId: number)
- onActionShapeLeave (shapeRemoteId: number)
- onObjectStreamIn (objectRemoteId: number)
- onObjectStreamOut (objectRemoteId: number)
- onObjectRaycast (objectRemoteId: number))
- onPedRaycast (pedRemoteId: number)
- onNullRaycast ()

## Server
- onObjectCreated (objectRemoteId: number)
- onObjectDestroyed (objectData)
- onObjectVariableChange (objectRemoteId: number, key: string, value: any)
- onPedCreated (pedRemoteId: number)
- onPedDestroyed (pedData)


## EventManager
> Events registered by the module, will have a custom event name with prefixes. This way the event names will not merge with the others.
```lua
Shared.EventManager:TriggerModuleEvent
Shared.EventManager:TriggerModuleServerEvent
Shared.EventManager:TriggerModuleClientEvent
Shared.EventManager:RegisterModuleNetworkEvent
Shared.EventManager:RegisterModuleEvent
```

## Create object on serverside
```lua
local Object = Server.ObjectManager:new({
    model = "prop_veg_crop_orange",
    x = 0.0,
    y = 0.0,
    z = 0.0,
    variables = {
        isTree = true
    },
    dimension = 0
})
```
### Add press function to object
```lua
---@type fun(Player: SAquiverPlayer, Object: SAquiverObject)
Object.onPress = function(Player, Object)
    Player:freeze(true)
    Player:disableMovement(true)
    Player:progress("Progess Text...", 5000, function()
        Player:disableMovement(false)
        Player:freeze(false)
        Player:addItem("av_peach", 1)
    end)
end
```

## Create ped on serverside
```lua
local MarketPed = Server.PedManager:new({
    heading = 20.0,
    model = "csb_agent",
    position = vector3(-474, 2973, 26.5),
    uid = "market-npc",
    animDict = "amb@code_human_wander_smoking@male@idle_a",
    animName = "idle_a",
    animFlag = 49,
    questionMark = true
})
```
### Add press function to ped
```lua
---@type fun(Player: SAquiverPlayer, Ped: SAquiverPed)
MarketPed.onPress = function(Player, Ped)
    Player:notification("Ped onpress triggered.")
end
```

## Create Particle and attach it to object with offset
> You can create particles at a desired positions also.
```lua
Server.ParticleManager:new({
    toObjectRemoteId = Object.data.remoteId,
    offset = vector3(0, 0, 1.15),
    particleDict = "cut_family4",
    particleName = "cs_fam4_juice_splash",
    particleUid = "grind-splash",
    rotation = vector3(0, 0, 0),
    scale = 8.0,
    dimension = Object.data.dimension,
    timeMS = 3500
})
```

## Variable validator for objects
> This way the created object entities will have a default variables like numbers, and you do not have to mess with nils during development.
```lua
Server.ObjectManager:addVariableValidator("avp_wooden_barrel", function(Object)
    local v = Object.data.variables

    v.woodenBarrelLitre = Shared.Utils:RoundNumber(v.woodenBarrelLitre or 0, 1)
    v.woodenBarrelAlcoholPercentage = Shared.Utils:RoundNumber(v.woodenBarrelAlcoholPercentage or 0, 1)
    v.woodenBarrelAge = Shared.Utils:RoundNumber(v.woodenBarrelAge or 0, 0)

    -- Important
    v.cellar_object = true
end)
```