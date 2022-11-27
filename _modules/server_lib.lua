---@type AQUIVER_SERVER
APIServer = exports.aquiver_lua:getServer()
---@type AQUIVER_SHARED
APIShared = exports.aquiver_lua:getShared()

local function loadModule(path)
    local code = LoadResourceFile("aquiver_lua", path)
    if code then
        local f, err = load(code)

        local rets = table.pack(xpcall(f, debug.traceback))
        if rets[1] then
            print(string.format("^1[%s]-> ^6Loaded module (server): %s", GetCurrentResourceName(), path))
            return table.unpack(rets, 2, rets.n)
        else
            print("failed loading module")
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
---@type function
Server.checkResourceVersion = loadModule("_modules/versionChecker/server.lua")
