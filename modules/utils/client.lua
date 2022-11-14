local Manager = {}

---@type { x:number|nil;y:number|nil; }
local CACHED_RESOLUTION = { x = nil, y = nil }
---@type { [string]: { x:number; y:number; }}
local CACHED_TEXTURE_RESOLUTIONS = {}

-- Caching screen resolution.
local CacheScreenResolution = function()
    if CACHED_RESOLUTION.x == nil or CACHED_RESOLUTION.y == nil then
        local rX, rY = GetActiveScreenResolution()
        CACHED_RESOLUTION = {
            x = rX,
            y = rY
        }
    end
end

--- Caching texture resolutions.
---@param textureDict string
---@param textureName string
local CacheTextureResolution = function(textureDict, textureName)
    if not CACHED_TEXTURE_RESOLUTIONS[textureDict .. textureName] then
        local textureResolutionVector2 = GetTextureResolution(textureDict, textureName)

        CACHED_TEXTURE_RESOLUTIONS[textureDict .. textureName] = {
            x = textureResolutionVector2.x,
            y = textureResolutionVector2.y
        }
    end
end

--- Get sprite normal size fit to the screen resolution.
---@param scale number
---@param textureDict string
---@param textureName string
local GetSpriteSize = function(scale, textureDict, textureName)
    return {
        scaleX = scale * CACHED_TEXTURE_RESOLUTIONS[textureDict .. textureName].x / CACHED_RESOLUTION.x,
        scaleY = scale * CACHED_TEXTURE_RESOLUTIONS[textureDict .. textureName].y / CACHED_RESOLUTION.y
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
Manager.DrawSprite3D = function(worldX, worldY, worldZ, textureDict, textureName, scale, r, g, b, a)
    RequestStreamedTextureDict(textureDict, false)
    while not HasStreamedTextureDictLoaded(textureDict) do
        Citizen.Wait(10)
    end

    CacheScreenResolution()
    CacheTextureResolution(textureDict, textureName)

    local size = GetSpriteSize(scale, textureDict, textureName)
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
Manager.DrawSprite2D = function(screenX, screenY, textureDict, textureName, scale, rotation, r, g, b, a)
    RequestStreamedTextureDict(textureDict, false)
    while not HasStreamedTextureDictLoaded(textureDict) do
        Citizen.Wait(10)
    end

    CacheScreenResolution()
    CacheTextureResolution(textureDict, textureName)

    local size = GetSpriteSize(scale, textureDict, textureName)

    DrawSprite(textureDict, textureName, screenX, screenY, size.scaleX, size.scaleY, rotation, r, g, b, a)
end

--- Request model.
---@param modelHash string
---@async
Manager.RequestModel = function(modelHash)
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
Manager.DrawText3D = function(x, y, z, text, size, font)
    size = type(size) == "number" and size or 0.25
    font = type(font) == "number" and font or 0

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
Manager.DrawText2D = function(x, y, text, size, font)
    size = type(size) == "number" and size or 0.25
    font = type(font) == "number" and font or 0

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

AQUIVER_CLIENT.Utils = Manager
