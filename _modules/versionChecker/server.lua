-- characters, needed for encoding
local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- decoding
local function dec(data)
    data = string.gsub(data, '[^' .. b .. '=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r, f = '', (b:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0) end
        return string.char(c)
    end))
end

---@param uri string
---@param cb fun(data: { [string]: any })
local function getGithubData(uri, cb)
    PerformHttpRequest(uri,
        function(statusCode, response, headers)
            if statusCode == 200 and type(response) == "string" then
                local encryptedData = json.decode(response)

                if encryptedData.encoding == "base64" then
                    local data = json.decode(dec(encryptedData.content))

                    cb(data)
                end
            else
                print("^1Github data failed to fetch: " .. uri)
            end
        end)
end

--- Check current resource version. (Invoked resource)
local function checkResourceVersion()
    local resourceName = GetCurrentResourceName()

    local specifiedResourceName = GetResourceMetadata(resourceName, "aquiver_resourcename", 0)
    if specifiedResourceName then
        resourceName = specifiedResourceName
    end

    getGithubData("https://api.github.com/repos/freamee/resource-versions/contents/versions.json", function(data)
        local newVersion = data.version
        local currentVersion = GetResourceMetadata(resourceName, "version", 0)
        local message = data.message

        if newVersion > currentVersion then
            print(string.format("^6There is an update available for %s.", resourceName))
            print(string.format("^6Your version: %s New version: %s", currentVersion, newVersion))
            print("^6Please download the newer version from https://keymaster.fivem.net/")
            print("^6If you have any question(s), feel free to ask on our Discord server!")
            print("^6https://discord.gg/X5XNvckuXK")
        end

        if type(message) == "string" and string.len(message) > 0 then
            print(string.format("^6------------[ %s MESSAGE ]------------", resourceName))
            print("^6" .. message)
        end
    end)
end

-- Check if there any global message coming from the API.
local function checkGlobalMessage()
    getGithubData("https://api.github.com/repos/freamee/resource-versions/contents/global_message.json",
        function(data)
            local message = data.message

            if type(message) == "string" and string.len(message) > 0 then
                print("^6------------[ GLOBAL MESSAGE ]------------")
                print("^6" .. message)
            end
        end)
end

return checkResourceVersion
