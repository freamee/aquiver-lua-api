---@class IAttachment
---@field model string
---@field boneId number
---@field x number
---@field y number
---@field z number
---@field rx number
---@field ry number
---@field rz number

local Manager = {}
---@type { [string]: { registeredResource: string; data: IAttachment; } }
Manager.Data = {}

Manager.exists = function(attachmentName)
    return Manager.Data[attachmentName] and true or false
end

Manager.get = function(attachmentName)
    return Manager.Data[attachmentName] or nil
end

Manager.getAll = function()
    return Manager.Data
end

---@param d IAttachment
Manager.registerOne = function(attachmentName, d)
    if Manager.exists(attachmentName) then
        --         API.Utils.Debug.Print("^1AttachmentManager register failed, already exists: " .. attachmentName)
        return
    end

    Manager.Data[attachmentName] = {
        registeredResource = AQUIVER_SHARED.Utils.GetInvokingResource(),
        data = d
    }

    --     API.Utils.Debug.Print("^3Registered new attachment: " .. attachmentName)
end

Manager.registerMany = function(d)
    if type(d) ~= "table" then
        --         API.Utils.Debug.Print("^1AttachmentManager registerMany should be a key-pair table.")
        return
    end

    for k, v in pairs(d) do
        Manager.registerOne(k, v)
    end
end

-- Delete if another resource is restarted which has connections to this.
AddEventHandler("onResourceStop", function(resourceName)
    for k, v in pairs(Manager.Data) do
        if v.registeredResource == resourceName then
            Manager.Data[k] = nil
        end
    end
end)

AQUIVER_SHARED.AttachmentManager = Manager
