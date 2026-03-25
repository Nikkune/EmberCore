--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__Class(self)
    local c = {prototype = {}}
    c.prototype.__index = c.prototype
    c.prototype.constructor = c
    return c
end
-- End of Lua Library inline imports
local ____exports = {}
local LOG_LEVEL_ORDER = {debug = 0, info = 1, warn = 2, error = 3}
local function getLevelColor(self, level)
    repeat
        local ____switch3 = level
        local ____cond3 = ____switch3 == "debug"
        if ____cond3 then
            return colors.lightBlue
        end
        ____cond3 = ____cond3 or ____switch3 == "info"
        if ____cond3 then
            return colors.white
        end
        ____cond3 = ____cond3 or ____switch3 == "warn"
        if ____cond3 then
            return colors.orange
        end
        ____cond3 = ____cond3 or ____switch3 == "error"
        if ____cond3 then
            return colors.red
        end
    until true
end
local function pad(self, value)
    return value < 10 and "0" .. tostring(value) or tostring(value)
end
local function getTimestamp(self)
    local now = os:date("*t")
    local year = now.year
    local month = pad(nil, now.month)
    local day = pad(nil, now.day)
    local hour = pad(nil, now.hour)
    local minute = pad(nil, now.min)
    local second = pad(nil, now.sec)
    return (((((((((tostring(year) .. "-") .. month) .. "-") .. day) .. " ") .. hour) .. ":") .. minute) .. ":") .. second
end
local function formatMeta(self, meta)
    if not meta then
        return ""
    end
    local parts = {}
    for key in pairs(meta) do
        do
            local value = meta[key]
            if value == nil then
                goto __continue8
            end
            parts[#parts + 1] = (key .. "=") .. tostring(value)
        end
        ::__continue8::
    end
    return table.concat(parts, " ")
end
____exports.Logger = __TS__Class()
local Logger = ____exports.Logger
Logger.name = "Logger"
function Logger.prototype.____constructor(self, scope, level, useColors)
    if scope == nil then
        scope = "EmberCore"
    end
    if level == nil then
        level = "info"
    end
    if useColors == nil then
        useColors = true
    end
    self.scope = scope
    self.level = level
    self.useColors = useColors
end
function Logger.prototype.setLevel(self, level)
    self.level = level
end
function Logger.prototype.debug(self, message, meta)
    self:log("debug", message, meta)
end
function Logger.prototype.info(self, message, meta)
    self:log("info", message, meta)
end
function Logger.prototype.warn(self, message, meta)
    self:log("warn", message, meta)
end
function Logger.prototype.error(self, message, meta)
    self:log("error", message, meta)
end
function Logger.prototype.log(self, level, message, meta)
    if LOG_LEVEL_ORDER[level] < LOG_LEVEL_ORDER[self.level] then
        return
    end
    local timestamp = getTimestamp(nil)
    local levelStr = string.upper(level)
    local metaStr = formatMeta(nil, meta)
    local line = ((((timestamp .. " | ") .. levelStr) .. " | ") .. self.scope) .. " |"
    if #metaStr > 0 then
        line = line .. " " .. metaStr
    end
    if #message > 0 then
        line = line .. (" msg=\"" .. message) .. "\""
    end
    self:writeLine(level, line)
end
function Logger.prototype.writeLine(self, level, line)
    if not self.useColors then
        print(line)
        return
    end
    local previousColor = term.getTextColor()
    term.setTextColor(getLevelColor(nil, level))
    print(line)
    term.setTextColor(previousColor)
end
return ____exports
