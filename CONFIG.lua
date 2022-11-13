CONFIG = {}

-- Streaming handler intervals. (MS)
CONFIG.STREAM_INTERVALS = {
    OBJECT = 1000,
    PED = 1000,
    PARTICLE = 1000,
    ACTIONSHAPE = 1000
}

-- Streaming distances
CONFIG.STREAM_DISTANCES = {
    OBJECT = 100.0,
    PED = 100.0,
    PARTICLE = 100.0,
    ACTIONSHAPE = 100.0
}

-- How often check if the player plays the animation or not. (MS)
CONFIG.FORCE_ANIMATION_INTERVAL = 500
-- How often check the raycast, performance++
CONFIG.RAYCAST_INTERVAL = 30

CONFIG.SERVER_DEBUG_ENABLED = true
CONFIG.CLIENT_DEBUG_ENABLED = true

-- Named as RoutingBucket on FiveM.
CONFIG.DEFAULT_DIMENSION = 0

-- How often cache the player position with GetEntityCoords.
CONFIG.CACHE_PLAYER_POSITION_INTERVAL = 500

CONFIG.RAYCAST = {
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
