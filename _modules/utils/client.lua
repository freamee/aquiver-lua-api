---@class CUtilsModule
local Module = {}

---@type { x:number|nil;y:number|nil; }
local CACHED_RESOLUTION = { x = nil, y = nil }
---@type { [string]: { x:number; y:number; }}
local CACHED_TEXTURE_RESOLUTIONS = {}

-- Caching screen resolution.
local function CacheScreenResolution()
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
local function CacheTextureResolution(textureDict, textureName)
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
local function GetSpriteSize(scale, textureDict, textureName)
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
function Module:DrawSprite3D(worldX, worldY, worldZ, textureDict, textureName, scale, r, g, b, a)
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
function Module:DrawSprite2D(screenX, screenY, textureDict, textureName, scale, rotation, r, g, b, a)
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
function Module:RequestModel(modelHash)
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
function Module:DrawText3D(x, y, z, text, size, font)
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
function Module:DrawText2D(x, y, text, size, font)
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

--- Print to console
---@param content table|string|boolean|number
---@param toJSON? boolean
function Module:Print(content, toJSON)
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
