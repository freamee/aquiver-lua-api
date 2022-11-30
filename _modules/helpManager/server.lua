---@class SHelpModule
local Module = {}

---@param helpData { uid:string; message:string; key?:string; image?:string; icon?:string; }
function Module:add(source, helpData)
    Shared.EventManager:TriggerModuleClientEvent("Help:Add", source, helpData)
end

function Module:remove(source, uid)
    Shared.EventManager:TriggerModuleClientEvent("Help:Remove", source, uid)
end

return Module
