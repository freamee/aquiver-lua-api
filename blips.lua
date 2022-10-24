local IS_SERVER = IsDuplicityVersion()

API.BlipManager = {}
---@type table<string, CBlip>
API.BlipManager.Entities = {}

---@class IBlip
---@field position { x:number; y:number; z:number }
---@field alpha number
---@field color number
---@field sprite number
---@field display number
---@field shortRange boolean
---@field scale number
---@field name string
---@field blipUid string

---@param data IBlip
API.BlipManager.new = function(data)
    ---@class CBlip
    local self = {}

    self.data = data

    if API.BlipManager.exists(self.data.blipUid) then
        print("^1Blip already exists with uid: " .. self.data.blipUid)
        return
    end

    if IS_SERVER then
        self.server = {}

        API.EventManager.TriggerClientLocalEvent("Blip:Create", -1, self.data)
    else
        self.client = {}
        self.client.blipHandle = nil

        local blip = AddBlipForCoord(self.data.position.x, self.data.position.y, self.data.position.z)
        SetBlipColour(blip, self.data.color)
        SetBlipSprite(blip, self.data.sprite)
        SetBlipDisplay(blip, self.data.display)
        SetBlipScale(blip, self.data.scale)
        SetBlipAsShortRange(blip, self.data.shortRange)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(self.data.name)
        EndTextCommandSetBlipName(blip)

        self.client.blipHandle = blip
    end

    self.SetColor = function(color)
        self.data.color = color

        if not IS_SERVER then
            if DoesBlipExist(self.client.blipHandle) then
                SetBlipColour(self.client.blipHandle, color)
            end
        else
            API.EventManager.TriggerClientLocalEvent("Blip:Update:Color", -1, self.data.blipUid, color)
        end
    end

    self.SetAlpha = function(alpha)
        self.data.alpha = alpha

        if not IS_SERVER then
            if DoesBlipExist(self.client.blipHandle) then
                SetBlipAlpha(self.client.blipHandle, alpha)
            end
        else
            API.EventManager.TriggerClientLocalEvent("Blip:Update:Alpha", -1, self.data.blipUid, alpha)
        end
    end

    self.SetSprite = function(sprite)
        self.data.sprite = sprite

        if not IS_SERVER then
            if DoesBlipExist(self.client.blipHandle) then
                SetBlipSprite(self.client.blipHandle, sprite)
            end
        else
            API.EventManager.TriggerClientLocalEvent("Blip:Update:Sprite", -1, self.data.blipUid, sprite)
        end

    end

    self.SetDisplay = function(displayId)
        self.data.display = displayId

        if not IS_SERVER then
            if DoesBlipExist(self.client.blipHandle) then
                SetBlipDisplay(self.client.blipHandle, displayId)
            end
        else
            API.EventManager.TriggerClientLocalEvent("Blip:Update:Display", -1, self.data.blipUid, displayId)
        end
    end

    self.SetShortRange = function(state)
        self.data.shortRange = state

        if not IS_SERVER then
            if DoesBlipExist(self.client.blipHandle) then
                SetBlipAsShortRange(self.client.blipHandle, state)
            end
        else
            API.EventManager.TriggerClientLocalEvent("Blip:Update:ShortRange", -1, self.data.blipUid, state)
        end
    end

    self.SetScale = function(scale)
        self.data.scale = scale

        if not IS_SERVER then
            if DoesBlipExist(self.client.blipHandle) then
                SetBlipScale(self.client.blipHandle, scale)
            end
        else
            API.EventManager.TriggerClientLocalEvent("Blip:Update:Scale", -1, self.data.blipUid, scale)
        end
    end

    self.SetName = function(name)
        self.data.name = name

        if not IS_SERVER then
            if DoesBlipExist(self.client.blipHandle) then
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(name)
                EndTextCommandSetBlipName(blip)
            end
        else
            API.EventManager.TriggerClientLocalEvent("Blip:Update:Name", -1, self.data.blipUid, name)
        end
    end

    self.SetPosition = function(position)
        self.data.position = position

        if not IS_SERVER then
            if DoesBlipExist(self.client.blipHandle) then
                SetBlipCoords(self.client.blipHandle, position.x, position.y, position.z)
            end
        else
            API.EventManager.TriggerClientLocalEvent("Blip:Update:Position", -1, self.data.blipUid, position)
        end
    end

    self.Destroy = function()
        -- Delete from table
        if API.BlipManager.Entities[API.InvokeResourceName() .. self.data.blipUid] then
            API.BlipManager.Entities[API.InvokeResourceName() .. self.data.blipUid] = nil
        end

        if IS_SERVER then
            API.EventManager.TriggerClientLocalEvent("Blip:Destroy", -1, self.data.blipUid)
        else
            if DoesBlipExist(self.client.blipHandle) then
                RemoveBlip(self.client.blipHandle)
            end
        end
    end

    API.BlipManager.Entities[API.InvokeResourceName() .. self.data.blipUid] = self

    return self
end

API.BlipManager.exists = function(id)
    if API.BlipManager.Entities[API.InvokeResourceName() .. id] then
        return true
    end
end

API.BlipManager.get = function(id)
    return API.BlipManager.Entities[API.InvokeResourceName() .. id]
end

API.BlipManager.getAll = function()
    return API.BlipManager.Entities
end

if IS_SERVER then
    AddEventHandler("onResourceStart", function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end

        API.EventManager.AddLocalEvent("Blip:RequestData", function()
            local source = source

            for k, v in pairs(API.BlipManager.Entities) do
                API.EventManager.TriggerClientLocalEvent("Blip:Create", source, v.data)
            end
        end)
    end)
else
    AddEventHandler("onClientResourceStart", function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end

        API.EventManager.AddLocalEvent({
            ["Blip:Create"] = function(data)
                API.BlipManager.new(data)
            end,
            ["Blip:Update:Color"] = function(uid, color)
                local BlipEntity = API.BlipManager.get(uid)
                if not BlipEntity then return end
                BlipEntity.SetColor(color)
            end,
            ["Blip:Update:Alpha"] = function(uid, alpha)
                local BlipEntity = API.BlipManager.get(uid)
                if not BlipEntity then return end
                BlipEntity.SetAlpha(alpha)
            end,
            ["Blip:Update:Sprite"] = function(uid, sprite)
                local BlipEntity = API.BlipManager.get(uid)
                if not BlipEntity then return end
                BlipEntity.SetSprite(sprite)
            end,
            ["Blip:Update:Display"] = function(uid, displayId)
                local BlipEntity = API.BlipManager.get(uid)
                if not BlipEntity then return end
                BlipEntity.SetDisplay(displayId)
            end,
            ["Blip:Update:ShortRange"] = function(uid, state)
                local BlipEntity = API.BlipManager.get(uid)
                if not BlipEntity then return end
                BlipEntity.SetShortRange(state)
            end,
            ["Blip:Update:Scale"] = function(uid, scale)
                local BlipEntity = API.BlipManager.get(uid)
                if not BlipEntity then return end
                BlipEntity.SetScale(scale)
            end,
            ["Blip:Update:Name"] = function(uid, name)
                local BlipEntity = API.BlipManager.get(uid)
                if not BlipEntity then return end
                BlipEntity.SetName(name)
            end,
            ["Blip:Update:Position"] = function(uid, position)
                local BlipEntity = API.BlipManager.get(uid)
                if not BlipEntity then return end
                BlipEntity.SetPosition(position)
            end,
            ["Blip:Destroy"] = function(uid)
                local BlipEntity = API.BlipManager.get(uid)
                if not BlipEntity then return end
                BlipEntity.Destroy()
            end
        })

        Citizen.CreateThread(function()
            while true do

                if NetworkIsPlayerActive(PlayerId()) then
                    -- Request Data from server.
                    API.EventManager.TriggerServerLocalEvent("Blip:RequestData")
                    break
                end

                Citizen.Wait(500)
            end
        end)
    end)
end
