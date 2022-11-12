local Manager = {}

---@param helpData { uid:string; message:string; key?:string; image?:string; icon?:string; }
Manager.Add = function(source, helpData)
    TriggerClientEvent("rpc-Help-Add", source, helpData)
end

Manager.Remove = function(source, uid)
    TriggerClientEvent("rpc-Help-Remove", source, uid)
end

AQUIVER_SERVER.HelpManager = Manager
