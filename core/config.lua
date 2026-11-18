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

local function __TS__ArrayIsArray(value)
    return type(value) == "table" and (value[1] ~= nil or next(value) == nil)
end
-- End of Lua Library inline imports
local ____exports = {}
local ____errors = require("core.errors")
local ConfigError = ____errors.ConfigError
local ____logger = require("core.logger")
local Logger = ____logger.Logger
local log = __TS__New(Logger, "Config", "info")
____exports.Config = __TS__Class()
local Config = ____exports.Config
Config.name = "Config"
function Config.prototype.____constructor(self)
end
function Config.load(self, path, defaults)
    self:recoverInterruptedSave(path)
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
    if parsed == nil or parsed == nil then
        log:error("Failed to parse config, using defaults", {path = path, action = "parse_error"})
        return defaults
    end
    return self:merge(defaults, parsed, path, "")
end
function Config.save(self, path, data)
    local tempPath = self:tempPath(path)
    local file = fs.open(tempPath, "w")
    if not file then
        error(
            __TS__New(ConfigError, ("Failed to write config file '" .. path) .. "'", {path = path, action = "open_write"}),
            0
        )
    end
    file.write(textutils.serialise(data))
    file.close()
    if fs.exists(path) then
        fs.delete(path)
    end
    fs.move(tempPath, path)
    log:info("Config saved", {path = path, action = "save_config"})
end
function Config.tempPath(self, path)
    return path .. ".tmp"
end
function Config.recoverInterruptedSave(self, path)
    local tempPath = self:tempPath(path)
    if not fs.exists(tempPath) then
        return
    end
    if fs.exists(path) then
        fs.delete(tempPath)
        return
    end
    fs.move(tempPath, path)
    log:warn("Recovered config from an interrupted save", {path = path, action = "recover_config"})
end
function Config.merge(self, defaults, loaded, path, prefix)
    local result = {}
    local ____temp_0
    if type(loaded) == "table" then
        ____temp_0 = loaded
    else
        ____temp_0 = {}
    end
    local source = ____temp_0
    for key in pairs(defaults) do
        do
            local __continue16
            repeat
                local fallback = defaults[key]
                local value = source[key]
                if value == nil then
                    result[key] = fallback
                    __continue16 = true
                    break
                end
                if type(value) ~= type(fallback) then
                    log:warn(
                        "Config value has the wrong type, using default",
                        {
                            path = path,
                            key = prefix .. key,
                            expected = type(fallback),
                            actual = type(value)
                        }
                    )
                    result[key] = fallback
                    __continue16 = true
                    break
                end
                if type(fallback) == "table" and not __TS__ArrayIsArray(fallback) then
                    result[key] = self:merge(fallback, value, path, (prefix .. key) .. ".")
                    __continue16 = true
                    break
                end
                result[key] = value
                __continue16 = true
            until true
            if not __continue16 then
                break
            end
        end
    end
    return result
end
return ____exports
