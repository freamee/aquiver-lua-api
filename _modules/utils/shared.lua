---@class SharedUtilsModule
local Module = {}
Module.Print = {}

--- Print to console (ERROR)
---@param content table|string|boolean|number
---@param toJSON? boolean
function Module.Print:Error(content, toJSON)
    local f = ""
    f = "[" .. GetCurrentResourceName() .. "]" .. "->" .. " ^1"

    if toJSON then
        print(f .. json.encode(content))
    else
        print(f .. content)
    end
end

--- Print to console (ERROR)
---@param content table|string|boolean|number
---@param toJSON? boolean
function Module.Print:Debug(content, toJSON)
    if not Shared.Config.DEBUG.ENABLE then return end

    local f = ""
    f = "[" .. GetCurrentResourceName() .. "]" .. "->" .. " ^3"

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
