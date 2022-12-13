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

---@type SUtilsModule
Utils = loadModule("_modules/utils/server.lua")

Utils:checkGlobalMessage()
Utils:checkResourceVersion()
