AQUIVER_SERVER.CheckResourceVersion = function()
    local resourceName = GetInvokingResource()

    if resourceName == nil then
        resourceName = GetCurrentResourceName()
    else
        local specifiedResourceName = GetResourceMetadata(resourceName, "av_resourcename", 0)
        if specifiedResourceName then
            resourceName = specifiedResourceName
        end
    end

    PerformHttpRequest("http://54.38.164.215:8097/scriptversion/" .. resourceName,
        function(statusCode, response, headers)
            if statusCode == 200 then
                if not type(response) == "string" then return end
                local data = json.decode(response)
                if not data.version then return end

                local newVersion = data.version
                local currentVersion = GetResourceMetadata(resourceName, "version", 0)

                if newVersion > currentVersion then
                    print(string.format("^6There is an update available for %s.", resourceName));
                    print(string.format("^6Your version: %s New version: %s", currentVersion, newVersion))
                    print("^6Please download the newer version from https://keymaster.fivem.net/");
                    print("^6If you have any question(s), feel free to ask on our Discord server!");
                    print("^6https://discord.gg/X5XNvckuXK");
                end
            else
                print("^1Aquiver API failed to fetch resource version for: " .. resourceName)
            end
        end
    )
end
