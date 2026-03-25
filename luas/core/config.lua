--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__New(target, ...)
    local instance = setmetatable({}, target.prototype)
    instance:____constructor(...)
    return instance
end

local function __TS__Class(self)
    local c = {prototype = {}}
    c.prototype.__index = c.prototype
    c.prototype.constructor = c
    return c
end
-- End of Lua Library inline imports
local ____exports = {}
local ____logger = require("core.logger")
local Logger = ____logger.Logger
local ____errors = require("core.errors")
local ConfigError = ____errors.ConfigError
local log = __TS__New(Logger, "Config", "info")
____exports.Config = __TS__Class()
local Config = ____exports.Config
Config.name = "Config"
function Config.prototype.____constructor(self)
end
function Config.load(self, path, defaults)
    if not fs.exists(path) then
        log:warn("Config file not found, creating default", {path = path, action = "create_config"})
        self:save(path, defaults)
        return defaults
    end
    local file = fs.open(path, "r")
    if not file then
        error(
            __TS__New(ConfigError, ("Failed to open config file '" .. path) .. "'", {path = path, action = "open_read"}),
            0
        )
    end
    local content = file.readAll()
    file.close()
    if not content or #content == 0 then
        log:warn("Config file empty, using defaults", {path = path, action = "empty_config"})
        return defaults
    end
    local parsed = textutils.unserialise(content)
    if not parsed then
        log:error("Failed to parse config, using defaults", {path = path, action = "parse_error"})
        return defaults
    end
    return self:merge(defaults, parsed)
end
function Config.save(self, path, data)
    local file = fs.open(path, "w")
    if not file then
        error(
            __TS__New(ConfigError, ("Failed to write config file '" .. path) .. "'", {path = path, action = "open_write"}),
            0
        )
    end
    file.write(textutils.serialise(data))
    file.close()
    log:info("Config saved", {path = path, action = "save_config"})
end
function Config.merge(self, defaults, loaded)
    local result = {}
    for key in pairs(defaults) do
        if loaded[key] ~= nil then
            result[key] = loaded[key]
        else
            result[key] = defaults[key]
        end
    end
    return result
end
return ____exports
