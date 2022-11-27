---@class IAttachment
---@field model string
---@field boneId number
---@field x number
---@field y number
---@field z number
---@field rx number
---@field ry number
---@field rz number

---@class SharedAttachmentModule
local Module = {}
---@type { [string]: IAttachment }
Module.Data = {}

function Module:exists(attachmentName)
    return self.Data[attachmentName] and true or false
end

function Module:get(attachmentName)
    if self:exists(attachmentName) then
        return self.Data[attachmentName]
    end
    return nil
end

---@param d IAttachment
function Module:registerOne(attachmentName, d)
    if self:exists(attachmentName) then
        Shared.Utils:Print("^1AttachmentManager register failed, already exists: " .. attachmentName)
        return
    end

    self.Data[attachmentName] = d
    Shared.Utils:Print("^3Registered new attachment: " .. attachmentName)
end

---@param d { [string]: IAttachment }
function Module:registerMany(d)
    if type(d) ~= "table" then
        Shared.Utils:Print("^1AttachmentManager registerMany should be a key-pair table.")
        return
    end

    for k, v in pairs(d) do
        self:registerOne(k, v)
    end
end

return Module
