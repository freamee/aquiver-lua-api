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