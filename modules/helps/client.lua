API.Helps = {}
---@type table<string, { uid:string, message:string, key?:string, image?:string; icon?:string; }>
API.Helps.CachedHelps = {}
API.Helps.Config = {}
API.Helps.Config.hasSound = true

---@param helpData { uid:string; message:string; key?:string; image?:string; icon?:string; }
API.Helps.Add = function(helpData)
    local self = API.Helps

    -- If help entry not exists add it.
    if not self.CachedHelps[helpData.uid] then
        self.CachedHelps[helpData.uid] = {
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

        if self.Config.hasSound then
            PlaySoundFrontend(-1, "SELECT", "HUD_FREEMODE_SOUNDSET", true)
        end
    else
        -- If help Entry exists, we update it if it differs.
        if self.CachedHelps[helpData.uid].message ~= helpData.message or
            self.CachedHelps[helpData.uid].key ~= helpData.key or
            self.CachedHelps[helpData.uid].image ~= helpData.image or
            self.CachedHelps[helpData.uid].icon ~= helpData.icon
            then

            self.CachedHelps[helpData.uid].message = helpData.message
            self.CachedHelps[helpData.uid].key = helpData.key
            self.CachedHelps[helpData.uid].image = helpData.image
            self.CachedHelps[helpData.uid].icon = helpData.icon

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

API.Helps.Remove = function(uid)
    local self = API.Helps

    if not self.CachedHelps[uid] then return end

    self.CachedHelps[uid] = nil

    SendNUIMessage({
        event = "Help-Remove",
        uid = uid
    })
end

RegisterNetEvent("rpc-Help-Add", function(helpData)
    API.Helps.Add(helpData)
end)
RegisterNetEvent("rpc-Help-Remove", function(uid)
    API.Helps.Remove(uid)
end)