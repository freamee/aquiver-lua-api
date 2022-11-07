API.Helps = {}

---@param helpData { uid:string; message:string; key?:string; image?:string; icon?:string; }
API.Helps.Add = function(source, helpData)
    TriggerClientEvent("rpc-Help-Add", source, helpData)
end

API.Helps.Remove = function(source, uid)
    TriggerClientEvent("rpc-Help-Remove", source, uid)
end