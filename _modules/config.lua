---@class SharedConfigModule
local Config = {
    RAYCAST = {
        INTERVAL = 300,
        -- Distance to find targets (Measured from the gameplay camera coords, and depends on the which camera you use, if you use the far one, maybe 10 will be small.)
        RAY_DISTANCE = 10.0,
        -- Raycast range, the lower the value is the harder it will be to aim on targets.
        RAY_RANGE = 0.15,
        -- Old ray range. (neeeded .15 for the barrels.)
        -- RAY_RANGE = 0.05,
        -- This is MS, reduce this, will become easier to target the entities. (Higher = More Performance) [PERFORMANCE]
        REFRESH_MS = 100,
        SPRITE_DICT = "mphud",
        SPRITE_NAME = "spectating",
        SPRITE_COLOR = { r = 255, g = 255, b = 255, a = 200 },
        INTERACTION_KEY = 38
    }
}

return Config