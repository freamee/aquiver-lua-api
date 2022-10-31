API.AttachmentManager = {}
---@type table<string, { registeredResource:string; data: IAttachment; }>
API.AttachmentManager.Data = {}

---@class IAttachment
---@field model string
---@field boneId number
---@field x number
---@field y number
---@field z number
---@field rx number
---@field ry number
---@field rz number

API.AttachmentManager.get = function(attachmentName)
    if API.AttachmentManager.exists(attachmentName) then
        return API.AttachmentManager.Data[attachmentName].data
    end
end

API.AttachmentManager.getAll = function()
    return API.AttachmentManager.Data
end

API.AttachmentManager.exists = function(attachmentName)
    if API.AttachmentManager.Data[attachmentName] then
        return true
    end
end

---@param d IAttachment
API.AttachmentManager.registerOne = function(attachmentName, d)
    if API.AttachmentManager.exists(attachmentName) then
        API.Utils.Debug.Print("^1AttachmentManager register failed, already exists: " .. attachmentName)
        return
    end

    API.AttachmentManager.Data[attachmentName] = {
        data = d,
        registeredResource = API.InvokeResourceName()
    }

    API.Utils.Debug.Print("^3Registered new attachment: " .. attachmentName)
end

API.AttachmentManager.registerMany = function(d)
    if type(d) ~= "table" then
        API.Utils.Debug.Print("^1AttachmentManager registerMany should be a key-pair table.")
        return
    end

    for k, v in pairs(d) do
        API.AttachmentManager.registerOne(k, v)
    end
end

-- Delete if another resource is restarted which has connections to this.
AddEventHandler("onResourceStop", function(resourceName)
    for k, v in pairs(API.AttachmentManager.Data) do
        if v.registeredResource == resourceName then
            API.AttachmentManager.Data[k] = nil
        end
    end
end)
