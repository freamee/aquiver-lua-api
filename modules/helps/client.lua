local Manager = {}
---@type { [string]: { uid:string, message:string, key?:string, image?:string; icon?:string; } }
Manager.CachedHelps = {}
Manager.Config = {}
Manager.Config.hasSound = true

---@param helpData { uid:string; message:string; key?:string; image?:string; icon?:string; }
Manager.Add = function(helpData)
    -- If help entry not exists add it.
    if not Manager.CachedHelps[helpData.uid] then
        Manager.CachedHelps[helpData.uid] = {
            image = helpData.image,
            key = helpData.key,
            message = helpData.message,
            uid = helpData.uid,
            icon = helpData.icon
        }

        SendNUIMessage({
            event = "Help-Add",
            uid = helpData.uid,
            message = helpData.message,
            key = helpData.key,
            image = helpData.image,
            icon = helpData.icon
        })

        if Manager.Config.hasSound then
            PlaySoundFrontend(-1, "SELECT", "HUD_FREEMODE_SOUNDSET", true)
        end
    else
        -- If help Entry exists, we update it if it differs.
        if Manager.CachedHelps[helpData.uid].message ~= helpData.message or
            Manager.CachedHelps[helpData.uid].key ~= helpData.key or
            Manager.CachedHelps[helpData.uid].image ~= helpData.image or
            Manager.CachedHelps[helpData.uid].icon ~= helpData.icon
        then

            Manager.CachedHelps[helpData.uid].message = helpData.message
            Manager.CachedHelps[helpData.uid].key = helpData.key
            Manager.CachedHelps[helpData.uid].image = helpData.image
            Manager.CachedHelps[helpData.uid].icon = helpData.icon

            SendNUIMessage({
                event = "Help-Update",
                uid = helpData.uid,
                key = helpData.key,
                message = helpData.message,
                image = helpData.image,
                icon = helpData.icon
            })
        end
    end
end

Manager.Remove = function(uid)
    if not Manager.CachedHelps[uid] then return end

    Manager.CachedHelps[uid] = nil

    SendNUIMessage({
        event = "Help-Remove",
        uid = uid
    })
end

RegisterNetEvent("rpc-Help-Add", function(helpData)
    Manager.Add(helpData)
end)
RegisterNetEvent("rpc-Help-Remove", function(uid)
    Manager.Remove(uid)
end)

AQUIVER_CLIENT.HelpManager = Manager
