local Manager = {}

Manager.GetInvokingResource = function()
    return GetInvokingResource() or GetCurrentResourceName()
end

--- Print to console
---@param content table|string|boolean|number
---@param toJSON? boolean
Manager.Print = function(content, toJSON)
    if not CONFIG.DEBUG_ENABLED then return end

    local f = ""
    f = "[" .. Manager.GetInvokingResource() .. "]" .. "->" .. " "

    if toJSON then
        print(f .. json.encode(content))
    else
        print(f .. content)
    end
end

Manager.RoundNumber = function(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

AQUIVER_SHARED.Utils = Manager
