## Client global events
- onObjectStreamIn (Object: CObject)
- onObjectStreamOut (Object: CObject)
- onPedRaycast (Ped: CPed)
- onObjectRaycast (Object: CObject)
- onNullRaycast ()

Register them on clientside with the api via:
```lua
api.EventManager.AddGlobalEvent("onPedRaycast", function(Ped)
    print(json.encode(Ped.data))
end)
```

## Create object on serverside
```lua
local Object = api.ObjectManager.new({
    model = "prop_veg_crop_orange",
    x = -464.7,
    y = 2970.5,
    z = 25.2,
    variables = {
        fruitAmount = 50,
        isTree = true
    },
    dimension = 0
})
```
### Add press function to object
```lua
Object.AddPressFunction(function(Player, Object)
    if Object.GetVariable("fruitAmount") < 1 then return end

    Player.Freeze(true)
    Player.DisableMovement(true)
    Player.Progress("Gathering fruits...", 5000, function()
        if Object.GetVariable("fruitAmount") < 1 then return end

        Object.SetVariable("fruitAmount", (Object.GetVariable("fruitAmount") or 0) - 1)
        Player.DisableMovement(false)
        Player.Freeze(false)
        Player.AddItem("av_peach", 1)
    end)
end)
```

## Create Ped on serverside
```lua
local Ped = api.PedManager.new({
    uid = "market-npc",
    position = vector3(-465, 2965, 25.5),
    model = "csb_agent",
    heading = 50.0
})
```
### Add press function to ped
```lua
Ped.AddPressFunction(function(Player, Ped)
    Player.Notification("info", "i am pressed.")
end)
```

## Create Particle and attach it to object with offset
```lua
api.ParticleManager.new({
    toObjectRemoteId = Object.data.remoteId,
    offset = vector3(0, 0, 1.15),
    particleDict = "cut_family4",
    particleName = "cs_fam4_juice_splash",
    particleUid = "grind-splash",
    rotation = vector3(0, 0, 0),
    scale = 8.0,
    dimension = 0,
})
```

## Variable validator with mysql created objects
> This way the created object entities will have a default variables like numbers, and you do not have to mess with nils during development.
```lua
api.ObjectManager.AddVariableValidator("avp_wooden_barrel", function(Object)
    local vars = Object.data.variables

    vars.grinderItemAmount = API.Utils.RoundNumber(vars.grinderItemAmount or 0, 0)
end)
```

## Adding local event listeners.
```lua
API.EventManager.AddLocalEvent({
    ["EVENT_ONE"] = function(arg1)
        print(arg1)
    end,
    ["EVENT_TWO"] = function(arg1, arg2)
        print(arg1, arg2)
    end
})

-- OR

api.EventManager.AddLocalEvent("EVENT_ONE", function(arg1)
    print(arg1)
end)
```