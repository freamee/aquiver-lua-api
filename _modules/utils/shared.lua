---@class SharedUtilsModule
local Module = {}

--- Print to console
---@param content table|string|boolean|number
---@param toJSON? boolean
function Module:Print(content, toJSON)
    if not Shared.Config.DEBUG.ENABLE then return end

    local f = ""
    f = "[" .. GetCurrentResourceName() .. "]" .. "->" .. " "

    if toJSON then
        print(f .. json.encode(content))
    else
        print(f .. content)
    end
end

function Module:RoundNumber(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

return Module
