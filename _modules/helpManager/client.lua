---@class CHelpModule
local Module = {}
---@type { [string]: { uid:string, message:string, key?:string, image?:string; icon?:string; } }
Module.CachedHelps = {}

---@param helpData { uid:string; message:string; key?:string; image?:string; icon?:string; }
function Module:add(helpData)
    -- If help entry not exists add it.
    if not self.CachedHelps[helpData.uid] then
        self.CachedHelps[helpData.uid] = {
            image = helpData.image,
            key = helpData.key,
            message = helpData.message,
            uid = helpData.uid,
            icon = helpData.icon
        }

        Client.LocalPlayer:sendNuiMessageAPI({
            event = "Help-Add",
            uid = helpData.uid,
            message = helpData.message,
            key = helpData.key,
            image = helpData.image,
            icon = helpData.icon
        })

        if Shared.Config.HELP.HAS_SOUND then
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

            Client.LocalPlayer:sendNuiMessageAPI({
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

function Module:remove(uid)
    if not self.CachedHelps[uid] then return end

    self.CachedHelps[uid] = nil

    Client.LocalPlayer:sendNuiMessageAPI({
        event = "Help-Remove",
        uid = uid
    })
end

Shared.EventManager:RegisterModuleNetworkEvent({
    ["Help:Add"] = function(helpData)
        Module:add(helpData)
    end,
    ["Help:Remove"] = function(uid)
        Module:remove(uid)
    end
})

return Module
