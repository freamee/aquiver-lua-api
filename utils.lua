API.Utils = {}
-- Client table & functions only exists on the clientside.
API.Utils.Client = {}
-- Server table & functions only exists on the serverside.
API.Utils.Server = {}
API.Utils.Debug = {}

--- Print to console
---@param content table|string|boolean|number
---@param toJSON? boolean
API.Utils.Debug.Print = function(content, toJSON)
    if API.IsServer and not CONFIG.SERVER_DEBUG_ENABLED then return end
    if not API.IsServer and not CONFIG.CLIENT_DEBUG_ENABLED then return end

    local f = ""
    if API.IsServer then
        f = "[" .. os.date("%X") .. "]" .. "->" .. " "
    else
        f = "->" .. " "
    end


    if toJSON then
        print(f .. json.encode(content))
    else
        print(f .. content)
    end
end

API.Utils.RoundNumber = function(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

if not API.IsServer then
    ---@type { X:number|nil; Y:number|nil; }
    API.Utils.Client.CACHED_RESOLUTION = {
        X = nil,
        Y = nil
    }
    ---@type table<string, {X:number; Y:number;}>
    API.Utils.Client.CACHED_TEXTURE_RESOLUTIONS = {}

    -- Caching screen resolution.
    API.Utils.Client.CacheScreenResolution = function()
        if API.Utils.Client.CACHED_RESOLUTION.X == nil or API.Utils.Client.CACHED_RESOLUTION.Y == nil then
            local rX, rY = GetActiveScreenResolution()
            API.Utils.Client.CACHED_RESOLUTION = {
                X = rX,
                Y = rY
            }
        end
    end

    --- Caching texture resolutions.
    ---@param textureDict string
    ---@param textureName string
    API.Utils.Client.CacheTextureResolution = function(textureDict, textureName)
        if not API.Utils.Client.CACHED_TEXTURE_RESOLUTIONS[textureDict .. textureName] then
            local textureResolutionVector = GetTextureResolution(textureDict, textureName)

            API.Utils.Client.CACHED_TEXTURE_RESOLUTIONS[textureDict .. textureName] = {
                X = textureResolutionVector.x,
                Y = textureResolutionVector.y
            }
        end
    end

    --- Get sprite normal size fit to the screen resolution.
    ---@param scale number
    ---@param textureDict string
    ---@param textureName string
    API.Utils.Client.GetSpriteSize = function(scale, textureDict, textureName)
        return {
            scaleX = scale * API.Utils.Client.CACHED_TEXTURE_RESOLUTIONS[textureDict .. textureName].X /
                API.Utils.Client.CACHED_RESOLUTION.X,

            scaleY = scale * API.Utils.Client.CACHED_TEXTURE_RESOLUTIONS[textureDict .. textureName].Y /
                API.Utils.Client.CACHED_RESOLUTION.Y
        }
    end

    --- Render sprite on screen, it transforms the 3d vector to screen coordinates and renders it.
    ---@param worldX number
    ---@param worldY number
    ---@param worldZ number
    ---@param textureDict string
    ---@param textureName string
    ---@param scale number
    ---@param r number
    ---@param g number
    ---@param b number
    ---@param a number
    ---@async
    API.Utils.Client.DrawSprite3D = function(worldX, worldY, worldZ, textureDict, textureName, scale, r, g, b, a)
        RequestStreamedTextureDict(textureDict, false)
        while not HasStreamedTextureDictLoaded(textureDict) do
            Citizen.Wait(10)
        end

        API.Utils.Client.CacheScreenResolution()
        API.Utils.Client.CacheTextureResolution(textureDict, textureName)

        local size = API.Utils.Client.GetSpriteSize(scale, textureDict, textureName)

        local _, sX, sY = GetScreenCoordFromWorldCoord(worldX, worldY, worldZ)

        DrawSprite(textureDict, textureName, sX, sY, size.scaleX, size.scaleY, 0.0, r, g, b, a)
    end

    --- Render sprite on a 2d Vector screen coordinates
    ---@param screenX number
    ---@param screenY number
    ---@param textureDict string
    ---@param textureName string
    ---@param scale number
    ---@param rotation number
    ---@param r number
    ---@param g number
    ---@param b number
    ---@param a number
    ---@async
    API.Utils.Client.DrawSprite2D = function(screenX, screenY, textureDict, textureName, scale, rotation, r, g, b, a)
        RequestStreamedTextureDict(textureDict, false)
        while not HasStreamedTextureDictLoaded(textureDict) do
            Citizen.Wait(10)
        end

        API.Utils.Client.CacheScreenResolution()
        API.Utils.Client.CacheTextureResolution(textureDict, textureName)

        local size = API.Utils.Client.GetSpriteSize(scale, textureDict, textureName)

        DrawSprite(textureDict, textureName, screenX, screenY, size.scaleX, size.scaleY, rotation, r, g, b, a)
    end

    --- Request model.
    ---@param modelHash string
    ---@async
    API.Utils.Client.requestModel = function(modelHash)
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Citizen.Wait(10)
        end
    end

    ---@param x number
    ---@param y number
    ---@param z number
    ---@param text string
    ---@param size? number Default: 0.25
    ---@param font? number Default: 0
    API.Utils.Client.DrawText3D = function(x, y, z, text, size, font)
        if type(size) ~= "number" then
            size = 0.25
        end
        if type(font) ~= "number" then
            font = 0
        end

        SetTextScale(size, size)
        SetTextFont(font)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 100)
        -- SetTextDropShadow()
        SetTextOutline()
        SetTextCentre(true)
        SetDrawOrigin(x, y, z, 0)
        BeginTextCommandDisplayText('STRING')
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayText(0.0, 0.0)
        ClearDrawOrigin()
    end

    ---@param x number
    ---@param y number
    ---@param text string
    ---@param size? number Default: 0.25
    ---@param font? number Default: 0
    API.Utils.Client.DrawText2D = function(x, y, text, size, font)
        if type(size) ~= "number" then
            size = 0.25
        end
        if type(font) ~= "number" then
            font = 0
        end

        SetTextFont(font)
        SetTextProportional(false)
        SetTextScale(size, size)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 100)
        SetTextDropShadow()
        SetTextCentre(true)
        SetTextEntry('STRING')
        AddTextComponentString(text)
        DrawText(x, y)
    end
else

end
