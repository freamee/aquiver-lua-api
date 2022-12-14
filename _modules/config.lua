---@class SharedConfigModule
local Config = {
    -- Named as RoutingBucket on FiveM.
    DEFAULT_DIMENSION = 0,
    -- How often cache the player
    CACHE_PLAYER = 500,

    HELP = {
        HAS_SOUND = true
    },

    DEBUG = {
        ENABLE = true
    },

    RAYCAST = {
        -- How often check the raycast, performance++
        INTERVAL = 150,
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
    },
    -- Streaming handler intervals. (MS)
    STREAM_INTERVALS = {
        OBJECT = 1000,
        PED = 1000,
        PARTICLE = 1000,
        ACTIONSHAPE = 1000
    },
    -- Streaming distances
    STREAM_DISTANCES = {
        OBJECT = 100.0,
        PED = 100.0,
        PARTICLE = 100.0,
        ACTIONSHAPE = 100.0
    }
}

return Config
