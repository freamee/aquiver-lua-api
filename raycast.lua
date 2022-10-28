API.RaycastManager = {}
API.RaycastManager.isEnabled = false
API.RaycastManager.Config = {
    -- Distance to find targets (Measured from the gameplay camera coords, and depends on the which camera you use, if you use the far one, maybe 10 will be small.)
    ["rayDistance"] = 10.0,
    -- Raycast range, the lower the value is the harder it will be to aim on targets.
    ["rayRange"] = 0.15,
    -- Old ray range. (neeeded .15 for the barrels.)
    -- ["rayRange"] = 0.05,
    -- This is MS, reduce this, will become easier to target the entities. (Higher = More Performance) [PERFORMANCE]
    ["refreshMs"] = 100,
    ["spriteDict"] = "mphud",
    ["spriteName"] = "spectating",
    ["spriteColor"] = { r = 255, g = 255, b = 255, a = 200 },
    ["interactionKey"] = 38
}

---@param rotation { x:number; y:number; z:number; }
local function RotationToDirection(rotation)
    local pi = math.pi / 180
    local adjustedRotation = vector3(pi * rotation.x, pi * rotation.y, pi * rotation.z)
    local direction = vector3(
        -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.sin(adjustedRotation.x)
    )
    return direction
end

-- ---@param Object ClientObjectClass
-- AddEventHandler(EVENTS.CLIENT.RAYCAST_AIMED_OBJECT, function(Object)
--     local header = "UNDEFINED_NAME"
--     ---@type InfoMenuEntry[]
--     local infos = {}

--     local refVars = Object.data.variables

--     if Object.data.model == "avp_distillery" then
--         header = "Distillery"

--         infos[#infos + 1] = {
--             icon = "fa-solid fa-power-off",
--             name = "Power",
--             value = refVars.distilleryPower and "On" or "Off"
--         }

--         infos[#infos + 1] = {
--             icon = "fa-solid fa-temperature-high",
--             name = "Desired temperature",
--             value = refVars.distillerySetTemperature .. " c°"
--         }

--         infos[#infos + 1] = {
--             icon = "fa-solid fa-thermometer",
--             isProgress = true,
--             name = "Current temperature",
--             progressPercentage = refVars.distilleryCurrentTemperature,
--             value = refVars.distilleryCurrentTemperature .. " c°",
--             progressColor = { 255, 100, 0, 0.5 }
--         }

--         infos[#infos + 1] = {
--             icon = "fa-solid fa-apple-whole",
--             name = "Fruit",
--             value = refVars.distilleryItem and GetItemLabel(refVars.distilleryItem) or "-"
--         }

--         infos[#infos + 1] = {
--             icon = "fa-solid fa-box",
--             name = "Fruit litre",
--             value = refVars.distilleryLitre .. " l."
--         }

--         infos[#infos + 1] = {
--             icon = "fa-solid fa-repeat",
--             name = "Process",
--             value = refVars.distilleryProcessStarted and "Yes" or "No",
--             description = "If process is started then you can not add more fruits into the distillery."
--         }

--         ClientAPI.LocalPlayer:InfoMenuOpen({
--             infos = infos,
--             header = header
--         })
--     elseif Object.data.model == "avp_fruit_grinder" then
--         header = "Grinder"

--         infos[#infos + 1] = {
--             icon = "fa-solid fa-apple-whole",
--             name = "Fruit",
--             value = refVars.grinderItem and GetItemLabel(refVars.grinderItem) or "-"
--         }

--         infos[#infos + 1] = {
--             icon = "fa-solid fa-box",
--             name = "Amount",
--             value = refVars.grinderItemAmount
--         }

--         infos[#infos + 1] = {
--             name = "",
--             value = "",
--             description = "You have to place a opened barrel near the grinder."
--         }
--     elseif Object.data.model == "prop_barrel_02a" or Object.data.model == "avp_barrel_open_empty" then
--         header = "Barrel"

--         infos[#infos + 1] = {
--             icon = "fa-solid fa-apple-whole",
--             name = "Fruit",
--             value = refVars.barrelGrindedItem and GetItemLabel(refVars.barrelGrindedItem) or "-"
--         }

--         infos[#infos + 1] = {
--             icon = "fa-solid fa-box",
--             name = "Fruit litre",
--             value = string.format("%s/%d l.", refVars.barrelGrindedLitre, Config.MaximumBarrelGrindedLitre)
--         }

--         if refVars.barrelGrindedItem then
--             infos[#infos + 1] = {
--                 icon = "fa-solid fa-percentage",
--                 name = "Progress",
--                 value = refVars.barrelGrindedProgress .. "%"
--             }
--         end

--     elseif Object.data.model == "prop_bucket_02a" then
--         header = "Bucket"

--         infos[#infos + 1] = {
--             icon = "fa-solid fa-apple-whole",
--             name = "Fruit",
--             value = refVars.bucketItem and GetItemLabel(refVars.bucketItem) or "-"
--         }

--         infos[#infos + 1] = {
--             icon = "fa-solid fa-box",
--             name = "Litre",
--             value = refVars.bucketItem and refVars.bucketLitre .. " l." or "-"
--         }

--         infos[#infos + 1] = {
--             icon = "fa-solid fa-percent",
--             name = "Alcohol percentage",
--             value = refVars.bucketItem and refVars.bucketAlcoholPercentage .. "%" or "-"
--         }
--     elseif Object.data.model == "avp_wooden_barrel" then
--         header = "Wooden Barrel"

--         infos[#infos + 1] = {
--             icon = "fa-solid fa-apple-whole",
--             name = "Fruit",
--             value = refVars.woodenBarrelItem and GetItemLabel(refVars.woodenBarrelItem) or "-"
--         }

--         infos[#infos + 1] = {
--             icon = "fa-solid fa-box",
--             name = "Litre",
--             value = string.format("%s/%d l.", refVars.woodenBarrelLitre, 666)
--         }

--         infos[#infos + 1] = {
--             icon = "fa-solid fa-percent",
--             name = "Alcohol percentage",
--             value = refVars.woodenBarrelItem and refVars.woodenBarrelAlcoholPercentage .. "%" or "-"
--         }

--         infos[#infos + 1] = {
--             icon = "fa-solid fa-leaf",
--             name = "Age",
--             value = refVars.woodenBarrelItem and refVars.woodenBarrelAge .. " yrs." or "-"
--         }

--         infos[#infos + 1] = {
--             name = "",
--             value = "",
--             description = "By mixing the barrel contents the age will reset to zero."
--         }
--     end

--     if #infos > 0 then
--         ClientAPI.LocalPlayer:InfoMenuOpen({
--             infos = infos,
--             header = header
--         })
--     end
-- end)

API.RaycastManager.SetEntityHandle = function(handle)
    -- Do not trigger if its the same as before...
    if API.RaycastManager.entityHitHandle == handle then return end

    API.RaycastManager.entityHitHandle = handle

    if API.RaycastManager.entityHitHandle then
        --         local hitObject = self:GetHitObject()
        --         if hitObject then
        --             TriggerEvent(EVENTS.CLIENT.RAYCAST_AIMED_OBJECT, hitObject)
        --         end

        -- Caching the class entity itself, so we do not have to loop the table always.
        if GetEntityType(API.RaycastManager.entityHitHandle) == 1 then
            local at = API.PedManager.atHandle(API.RaycastManager.entityHitHandle)
            if at then
                API.RaycastManager.AimedPedEntity = at
            end
        elseif GetEntityType(API.RaycastManager.entityHitHandle) == 3 then
            local at = API.ObjectManager.atHandle(API.RaycastManager.entityHitHandle)
            if at then
                API.RaycastManager.AimedObjectEntity = at
            end
        end

        Citizen.CreateThread(function()
            while API.RaycastManager.entityHitHandle == handle do

                API.Utils.Client.DrawSprite2D(
                    0.5,
                    0.5,
                    API.RaycastManager.Config.spriteDict,
                    API.RaycastManager.Config.spriteName,
                    0.75,
                    0,
                    API.RaycastManager.Config.spriteColor.r,
                    API.RaycastManager.Config.spriteColor.g,
                    API.RaycastManager.Config.spriteColor.b,
                    API.RaycastManager.Config.spriteColor.a
                )

                local Ped = API.RaycastManager.AimedPedEntity
                if Ped then
                    API.Utils.Client.DrawText2D(0.5, 0.505, Ped.data.model)

                    if IsDisabledControlJustPressed(0, API.RaycastManager.Config.interactionKey) then
                        API.EventManager.TriggerServerLocalEvent("Ped:Interaction:Press", Ped.data.uid)
                    end
                end

                local Object = API.RaycastManager.AimedObjectEntity
                if Object then
                    API.Utils.Client.DrawText2D(0.5, 0.505, Object.data.model)

                    if IsDisabledControlJustPressed(0, API.RaycastManager.Config.interactionKey) then
                        API.EventManager.TriggerServerLocalEvent("Object:Interaction:Press", Object.data.remoteId)
                    end
                end

                Citizen.Wait(1)
            end
        end)
    else
        API.RaycastManager.AimedObjectEntity = nil
        API.RaycastManager.AimedPedEntity = nil
    end
end

API.RaycastManager.Enable = function(state)
    if API.RaycastManager.isEnabled == state then return end

    API.RaycastManager.isEnabled = state

    if API.RaycastManager.isEnabled then
        Citizen.CreateThread(function()
            while API.RaycastManager.isEnabled do

                local cameraRotation = GetGameplayCamRot(2)
                local cameraPosition = GetGameplayCamCoord()
                local direction = RotationToDirection(cameraRotation)
                local destination = vector3(
                    cameraPosition.x + direction.x * API.RaycastManager.Config.rayDistance,
                    cameraPosition.y + direction.y * API.RaycastManager.Config.rayDistance,
                    cameraPosition.z + direction.z * API.RaycastManager.Config.rayDistance
                )

                local shapeTestHandle = StartShapeTestCapsule(
                    cameraPosition.x,
                    cameraPosition.y,
                    cameraPosition.z,
                    destination.x,
                    destination.y,
                    destination.z,
                    API.RaycastManager.Config.rayRange,
                    9,
                    PlayerPedId(),
                    4
                )
                local _, hit, endCoords, surfaceNormal, hitHandle = GetShapeTestResult(shapeTestHandle)

                if hit then
                    local entityType = GetEntityType(hitHandle)

                    -- Check if Object.
                    if entityType == 3 then
                        local Object = API.ObjectManager.atHandle(hitHandle)
                        if Object then
                            local objDistance = #(Object.GetPositionVector3() - GetEntityCoords(PlayerPedId()))
                            if objDistance < 2.5 then
                                API.RaycastManager.SetEntityHandle(hitHandle)
                                goto nextTick
                            end
                        end
                    elseif entityType == 1 then
                        local Ped = API.PedManager.atHandle(hitHandle)
                        if Ped then
                            local pedDistance = #(Ped.GetPositionVector3() - GetEntityCoords(PlayerPedId()))
                            if pedDistance < 2.5 then
                                API.RaycastManager.SetEntityHandle(hitHandle)
                                goto nextTick
                            end
                        end
                    end
                end

                -- Reset here if its not continued to nextTick
                API.RaycastManager.SetEntityHandle(nil)

                ::nextTick::
                Citizen.Wait(10)
            end
        end)
    end
end

if API.IsServer then
    AddEventHandler("onResourceStart", function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end

        API.EventManager.AddLocalEvent({
            ["Object:Interaction:Press"] = function(remoteId)
                local srcID = source

                local ObjectEntity = API.ObjectManager.get(remoteId)
                if not ObjectEntity then return end

                local Player = API.PlayerManager.get(srcID)
                if not Player then return end

                if Citizen.GetFunctionReference(ObjectEntity.server.onPress) then
                    ObjectEntity.server.onPress(Player, ObjectEntity)
                end
            end,
            ["Ped:Interaction:Press"] = function(uid)
                local srcID = source

                local PedEntity = API.PedManager.get(uid)
                if not PedEntity then return end

                local Player = API.PlayerManager.get(srcID)
                if not Player then return end

                if Citizen.GetFunctionReference(PedEntity.server.onPress) then
                    PedEntity.server.onPress(Player, PedEntity)
                end
            end
        })
    end)
else

end
