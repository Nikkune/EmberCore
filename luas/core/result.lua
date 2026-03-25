--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__Class(self)
    local c = {prototype = {}}
    c.prototype.__index = c.prototype
    c.prototype.constructor = c
    return c
end

local __TS__Symbol, Symbol
do
    local symbolMetatable = {__tostring = function(self)
        return ("Symbol(" .. (self.description or "")) .. ")"
    end}
    function __TS__Symbol(description)
        return setmetatable({description = description}, symbolMetatable)
    end
    Symbol = {
        asyncDispose = __TS__Symbol("Symbol.asyncDispose"),
        dispose = __TS__Symbol("Symbol.dispose"),
        iterator = __TS__Symbol("Symbol.iterator"),
        hasInstance = __TS__Symbol("Symbol.hasInstance"),
        species = __TS__Symbol("Symbol.species"),
        toStringTag = __TS__Symbol("Symbol.toStringTag")
    }
end

local function __TS__InstanceOf(obj, classTbl)
    if type(classTbl) ~= "table" then
        error("Right-hand side of 'instanceof' is not an object", 0)
    end
    if classTbl[Symbol.hasInstance] ~= nil then
        return not not classTbl[Symbol.hasInstance](classTbl, obj)
    end
    if type(obj) == "table" then
        local luaClass = obj.constructor
        while luaClass ~= nil do
            if luaClass == classTbl then
                return true
            end
            luaClass = luaClass.____super
        end
    end
    return false
end

local function __TS__New(target, ...)
    local instance = setmetatable({}, target.prototype)
    instance:____constructor(...)
    return instance
end
-- End of Lua Library inline imports
local ____exports = {}
local ____errors = require("core.errors")
local EmberError = ____errors.EmberError
function ____exports.ok(self, value)
    return {ok = true, value = value}
end
function ____exports.err(self, ____error)
    return {ok = false, error = ____error}
end
____exports.Results = __TS__Class()
local Results = ____exports.Results
Results.name = "Results"
function Results.prototype.____constructor(self)
end
function Results.ok(self, value)
    return ____exports.ok(nil, value)
end
function Results.err(self, ____error)
    return ____exports.err(nil, ____error)
end
function Results.isOk(self, result)
    return result.ok
end
function Results.isErr(self, result)
    return not result.ok
end
function Results.map(self, result, fn)
    if not result.ok then
        return result
    end
    return ____exports.ok(
        nil,
        fn(nil, result.value)
    )
end
function Results.mapError(self, result, fn)
    if result.ok then
        return result
    end
    return ____exports.err(
        nil,
        fn(nil, result.error)
    )
end
function Results.unwrap(self, result)
    if not result.ok then
        error(
            nil,
            "Tried to unwrap an error result: " .. tostring(nil, result.error),
            2
        )
    end
    return result.value
end
function Results.unwrapOr(self, result, fallback)
    if not result.ok then
        return fallback
    end
    return result.value
end
function Results.try(self, fn)
    do
        local function ____catch(caught)
            if __TS__InstanceOf(caught, EmberError) then
                return true, ____exports.err(nil, caught)
            end
            return true, ____exports.err(
                nil,
                __TS__New(
                    EmberError,
                    "Unknown error",
                    "UNKNOWN_ERROR",
                    {cause = tostring(nil, caught)}
                )
            )
        end
        local ____try, ____hasReturned, ____returnValue = pcall(function()
            return true, ____exports.ok(
                nil,
                fn(nil)
            )
        end)
        if not ____try then
            ____hasReturned, ____returnValue = ____catch(____hasReturned)
        end
        if ____hasReturned then
            return ____returnValue
        end
    end
end
return ____exports
