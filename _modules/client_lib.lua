local function loadModule(path)
    local code = LoadResourceFile("aquiver_lua", path)
    if code then
        local f, err = load(code)

        local rets = table.pack(xpcall(f, debug.traceback))
        if rets[1] then
            print(string.format("^1[%s]-> ^6Loaded module (client): %s", GetCurrentResourceName(), path))
            return table.unpack(rets, 2, rets.n)
        else
            print("failed loading module")
        end
    end
end

Client = {}

---@type CUtilsModule
Client.Utils = loadModule("_modules/utils/client.lua")
---@type CObjectsModule
Client.ObjectManager = loadModule("_modules/objects/client.lua")
---@type CPlayerModule
Client.LocalPlayer = loadModule("_modules/players/client.lua")
---@type CPedModule
Client.PedManager = loadModule("_modules/peds/client.lua")
---@type CRaycastManager
Client.RaycastManager = loadModule("_modules/raycast/client.lua")
---@type CActionShapeModule
Client.ActionShapeManager = loadModule("_modules/actionshape/client.lua")
---@type CBlipModule
Client.BlipManager = loadModule("_modules/blips/client.lua")
---@type CParticleModule
Client.ParticleManager = loadModule("_modules/particle/client.lua")
---@type CRadarBlipModule
Client.RadarBlipManager = loadModule("_modules/radarblip/client.lua")
---@type CHelpModule
Client.HelpManager = loadModule("_modules/HelpManager/client.lua")
