local function loadModule(path)
    local code = LoadResourceFile("aquiver_lua", path)
    if code then
        local f, err = load(code)

        local rets = table.pack(xpcall(f, debug.traceback))
        if rets[1] then
            print(string.format("^1[%s]-> ^6Loaded module (shared): %s", GetCurrentResourceName(), path))
            return table.unpack(rets, 2, rets.n)
        else
            print("failed loading module")
        end
    end
end

Shared = {}

---@type SharedConfigModule
Shared.Config = loadModule("_modules/config.lua")
---@type SharedEventManager
Shared.EventManager = loadModule("_modules/eventManager/shared.lua")
---@type SharedUtilsModule
Shared.Utils = loadModule("_modules/utils/shared.lua")
---@type SharedAttachmentModule
Shared.AttachmentManager = loadModule("_modules/attachmentRegister/shared.lua")
