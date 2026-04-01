--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__Class(self)
    local c = {prototype = {}}
    c.prototype.__index = c.prototype
    c.prototype.constructor = c
    return c
end

local function __TS__StringIncludes(self, searchString, position)
    if not position then
        position = 1
    else
        position = position + 1
    end
    local index = string.find(self, searchString, position, true)
    return index ~= nil
end

local function __TS__New(target, ...)
    local instance = setmetatable({}, target.prototype)
    instance:____constructor(...)
    return instance
end

local function __TS__ClassExtends(target, base)
    target.____super = base
    local staticMetatable = setmetatable({__index = base}, base)
    setmetatable(target, staticMetatable)
    local baseMetatable = getmetatable(base)
    if baseMetatable then
        if type(baseMetatable.__index) == "function" then
            staticMetatable.__index = baseMetatable.__index
        end
        if type(baseMetatable.__newindex) == "function" then
            staticMetatable.__newindex = baseMetatable.__newindex
        end
    end
    setmetatable(target.prototype, base.prototype)
    if type(base.prototype.__index) == "function" then
        target.prototype.__index = base.prototype.__index
    end
    if type(base.prototype.__newindex) == "function" then
        target.prototype.__newindex = base.prototype.__newindex
    end
    if type(base.prototype.__tostring) == "function" then
        target.prototype.__tostring = base.prototype.__tostring
    end
end

local Error, RangeError, ReferenceError, SyntaxError, TypeError, URIError
do
    local function getErrorStack(self, constructor)
        if debug == nil then
            return nil
        end
        local level = 1
        while true do
            local info = debug.getinfo(level, "f")
            level = level + 1
            if not info then
                level = 1
                break
            elseif info.func == constructor then
                break
            end
        end
        if __TS__StringIncludes(_VERSION, "Lua 5.0") then
            return debug.traceback(("[Level " .. tostring(level)) .. "]")
        elseif _VERSION == "Lua 5.1" then
            return string.sub(
                debug.traceback("", level),
                2
            )
        else
            return debug.traceback(nil, level)
        end
    end
    local function wrapErrorToString(self, getDescription)
        return function(self)
            local description = getDescription(self)
            local caller = debug.getinfo(3, "f")
            local isClassicLua = __TS__StringIncludes(_VERSION, "Lua 5.0")
            if isClassicLua or caller and caller.func ~= error then
                return description
            else
                return (description .. "\n") .. tostring(self.stack)
            end
        end
    end
    local function initErrorClass(self, Type, name)
        Type.name = name
        return setmetatable(
            Type,
            {__call = function(____, _self, message) return __TS__New(Type, message) end}
        )
    end
    local ____initErrorClass_1 = initErrorClass
    local ____class_0 = __TS__Class()
    ____class_0.name = ""
    function ____class_0.prototype.____constructor(self, message)
        if message == nil then
            message = ""
        end
        self.message = message
        self.name = "Error"
        self.stack = getErrorStack(nil, __TS__New)
        local metatable = getmetatable(self)
        if metatable and not metatable.__errorToStringPatched then
            metatable.__errorToStringPatched = true
            metatable.__tostring = wrapErrorToString(nil, metatable.__tostring)
        end
    end
    function ____class_0.prototype.__tostring(self)
        return self.message ~= "" and (self.name .. ": ") .. self.message or self.name
    end
    Error = ____initErrorClass_1(nil, ____class_0, "Error")
    local function createErrorClass(self, name)
        local ____initErrorClass_3 = initErrorClass
        local ____class_2 = __TS__Class()
        ____class_2.name = ____class_2.name
        __TS__ClassExtends(____class_2, Error)
        function ____class_2.prototype.____constructor(self, ...)
            ____class_2.____super.prototype.____constructor(self, ...)
            self.name = name
        end
        return ____initErrorClass_3(nil, ____class_2, name)
    end
    RangeError = createErrorClass(nil, "RangeError")
    ReferenceError = createErrorClass(nil, "ReferenceError")
    SyntaxError = createErrorClass(nil, "SyntaxError")
    TypeError = createErrorClass(nil, "TypeError")
    URIError = createErrorClass(nil, "URIError")
end
-- End of Lua Library inline imports
local ____exports = {}
local ____helpers = require("utils.helpers")
local assignIfDefined = ____helpers.assignIfDefined
____exports.EmberError = __TS__Class()
local EmberError = ____exports.EmberError
EmberError.name = "EmberError"
__TS__ClassExtends(EmberError, Error)
function EmberError.prototype.____constructor(self, message, code, context)
    if code == nil then
        code = "EMBER_ERROR"
    end
    Error.prototype.____constructor(self, message)
    self.name = "EmberError"
    self.code = code
    assignIfDefined(nil, self, "context", context)
end
function EmberError.prototype.__tostring(self)
    return (("[" .. self.code) .. "] ") .. self.message
end
____exports.ConfigError = __TS__Class()
local ConfigError = ____exports.ConfigError
ConfigError.name = "ConfigError"
__TS__ClassExtends(ConfigError, ____exports.EmberError)
function ConfigError.prototype.____constructor(self, message, context)
    ConfigError.____super.prototype.____constructor(self, message, "CONFIG_ERROR", context)
    self.name = "ConfigError"
end
____exports.PeripheralError = __TS__Class()
local PeripheralError = ____exports.PeripheralError
PeripheralError.name = "PeripheralError"
__TS__ClassExtends(PeripheralError, ____exports.EmberError)
function PeripheralError.prototype.____constructor(self, message, context)
    PeripheralError.____super.prototype.____constructor(self, message, "PERIPHERAL_ERROR", context)
    self.name = "PeripheralError"
end
____exports.InventoryError = __TS__Class()
local InventoryError = ____exports.InventoryError
InventoryError.name = "InventoryError"
__TS__ClassExtends(InventoryError, ____exports.EmberError)
function InventoryError.prototype.____constructor(self, message, context)
    InventoryError.____super.prototype.____constructor(self, message, "INVENTORY_ERROR", context)
    self.name = "InventoryError"
end
____exports.TankError = __TS__Class()
local TankError = ____exports.TankError
TankError.name = "TankError"
__TS__ClassExtends(TankError, ____exports.EmberError)
function TankError.prototype.____constructor(self, message, context)
    TankError.____super.prototype.____constructor(self, message, "TANK_ERROR", context)
    self.name = "TankError"
end
____exports.RuntimeError = __TS__Class()
local RuntimeError = ____exports.RuntimeError
RuntimeError.name = "RuntimeError"
__TS__ClassExtends(RuntimeError, ____exports.EmberError)
function RuntimeError.prototype.____constructor(self, message, context)
    RuntimeError.____super.prototype.____constructor(self, message, "RUNTIME_ERROR", context)
    self.name = "RuntimeError"
end
return ____exports
