local function loadModule(path)
    local code = LoadResourceFile("aquiver_lua", path)
    if code then
        local f, err = load(code)

        local rets = table.pack(xpcall(f, debug.traceback))
        if rets[1] then
            print(string.format("^1[%s]-> ^6Loaded module (server): %s", GetCurrentResourceName(), path))
            return table.unpack(rets, 2, rets.n)
        end
    end
end

Server = {}

---@type SUtilsModule
Server.Utils = loadModule("_modules/utils/server.lua")
---@type SObjectModule
Server.ObjectManager = loadModule("_modules/objects/server.lua")
---@type SPlayerModule
Server.PlayerManager = loadModule("_modules/players/server.lua")
---@type SPedModule
Server.PedManager = loadModule("_modules/peds/server.lua")
---@type SActionShapeModule
Server.ActionShapeManager = loadModule("_modules/actionshape/server.lua")
---@type SBlipModule
Server.BlipManager = loadModule("_modules/blips/server.lua")
---@type SParticleModule
Server.ParticleManager = loadModule("_modules/particle/server.lua")
---@type SRadarBlipModule
Server.RadarBlipManager = loadModule("_modules/radarblip/server.lua")
---@type SHelpModule
Server.HelpManager = loadModule("_modules/helpManager/server.lua")

loadModule("_modules/raycast/server.lua")
