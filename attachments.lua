local IS_SERVER = IsDuplicityVersion()

API.AttachmentManager = {}
---@type table<string, IAttachment>
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

API.AttachmentManager.Data["bucket"] = {
    model = "prop_bucket_02a",
    boneId = 57005,
    x = 0.65,
    y = -0.1,
    z = 0.0,
    rx = 208.0,
    ry = -85.0,
    rz = -7.0
}

API.AttachmentManager.Data["player-barrel-hand"] = {
    model = "prop_barrel_02a",
    boneId = 0,
    x = 0.0,
    y = 0.45,
    z = 0.5,
    rx = 0.0,
    ry = 0.0,
    rz = 0.0
}

API.AttachmentManager.Data["player-wooden-barrel-hand"] = {
    model = "avp_wooden_barrel",
    boneId = 0,
    x = 0.0,
    y = 0.45,
    z = 0.5,
    rx = 0.0,
    ry = 0.0,
    rz = 0.0
}

API.AttachmentManager.Data["player-grinder-hand"] = {
    model = "avp_fruit_grinder",
    boneId = 0,
    x = 0.0,
    y = 0.45,
    z = -0.75,
    rx = 0.0,
    ry = 0.0,
    rz = 0.0
}

API.AttachmentManager.Data["player-distillery-hand"] = {
    model = "prop_cardbordbox_04a",
    boneId = 0,
    x = 0.0,
    y = 0.5,
    z = 0.1,
    rx = 0.0,
    ry = 0.0,
    rz = 0.0
}

API.AttachmentManager.get = function(attachmentName)
    return API.AttachmentManager.Data[attachmentName]
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

    API.AttachmentManager.Data[attachmentName] = d
end
