---@class AQUIVER_API
API = {}
API.IsServer = IsDuplicityVersion()

API.InvokeResourceName = function()
    return GetInvokingResource() or "api"
end

exports('getApi', function()
    return API
end)
