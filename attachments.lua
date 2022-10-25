local IS_SERVER = IsDuplicityVersion()

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
API.AttachmentManager.register = function(attachmentName, d)
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

-- Default examples
API.AttachmentManager.register("bucket", {
    model = "prop_bucket_02a",
    boneId = 57005,
    x = 0.65,
    y = -0.1,
    z = 0.0,
    rx = 208.0,
    ry = -85.0,
    rz = -7.0
})

-- Delete if another resource is restarted which has connections to this.
AddEventHandler("onResourceStop", function(resourceName)
    for k, v in pairs(API.AttachmentManager.Data) do
        if v.registeredResource == resourceName then
            API.AttachmentManager.Data[k] = nil
        end
    end
end)
