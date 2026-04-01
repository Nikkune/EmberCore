--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__New(target, ...)
    local instance = setmetatable({}, target.prototype)
    instance:____constructor(...)
    return instance
end

local function __TS__ArrayIncludes(self, searchElement, fromIndex)
    if fromIndex == nil then
        fromIndex = 0
    end
    local len = #self
    local k = fromIndex
    if fromIndex < 0 then
        k = len + fromIndex
    end
    if k < 0 then
        k = 0
    end
    for i = k + 1, len do
        if self[i] == searchElement then
            return true
        end
    end
    return false
end

local function __TS__Class(self)
    local c = {prototype = {}}
    c.prototype.__index = c.prototype
    c.prototype.constructor = c
    return c
end
-- End of Lua Library inline imports
local ____exports = {}
local ____assert = require("core.assert")
local assertNotNil = ____assert.assertNotNil
local ____errors = require("core.errors")
local PeripheralError = ____errors.PeripheralError
local ____logger = require("core.logger")
local Logger = ____logger.Logger
local log = __TS__New(Logger, "Peripheral", "info")
local SIDES = {
    "back",
    "bottom",
    "front",
    "left",
    "right",
    "top"
}
function ____exports.isSide(self, value)
    return __TS__ArrayIncludes(SIDES, value)
end
function ____exports.getSides(self)
    return {table.unpack(SIDES)}
end
____exports.Peripheral = __TS__Class()
local Peripheral = ____exports.Peripheral
Peripheral.name = "Peripheral"
function Peripheral.prototype.____constructor(self)
end
function Peripheral.list(self)
    return peripheral.getNames()
end
function Peripheral.listSides(self)
    return ____exports.getSides(nil)
end
function Peripheral.has(self, name)
    return peripheral.isPresent(name)
end
function Peripheral.getType(self, name)
    local value = peripheral.getType(name)
    if value == nil or value == nil then
        return nil
    end
    if type(nil, value) == "table" then
        return value[1]
    end
    return value
end
function Peripheral.wrap(self, name)
    local wrapped = peripheral.wrap(name)
    if wrapped == nil or wrapped == nil then
        log:debug("Peripheral wrap failed", {name = name, action = "wrap", status = "missing"})
        return nil
    end
    log:debug("Peripheral wrapped", {name = name, action = "wrap", status = "ok"})
    return wrapped
end
function Peripheral.require(self, name)
    local wrapped = ____exports.Peripheral:wrap(name)
    if wrapped == nil then
        local message = ("Peripheral not found on side '" .. name) .. "'"
        log:error(message, {name = name, action = "require", status = "failed"})
        error(
            __TS__New(PeripheralError, message, {name = name, action = "require"}),
            0
        )
    end
    return wrapped
end
function Peripheral.wrapType(self, name, expectedType)
    local actualType = self:getType(name)
    if actualType ~= expectedType then
        log:debug("Peripheral type mismatch", {
            name = name,
            action = "wrapType",
            status = "failed",
            expected = expectedType,
            actual = actualType or "nil"
        })
        return nil
    end
    return self:wrap(name)
end
function Peripheral.requireType(self, name, expectedType)
    local actualType = self:getType(name)
    if actualType ~= expectedType then
        local message = ((((("Peripheral on side '" .. name) .. "' has type '") .. (actualType or "nil")) .. "', expected '") .. expectedType) .. "'"
        log:error(message, {
            name = name,
            action = "require_type",
            status = "failed",
            expectedType = expectedType,
            actualType = actualType or "nil"
        })
        error(
            __TS__New(PeripheralError, message, {name = name, action = "require_type", expectedType = expectedType, actualType = actualType or "nil"}),
            0
        )
    end
    local wrapped = self:wrap(name)
    assertNotNil(nil, wrapped, ("Peripheral on side '" .. name) .. "' could not be wrapped")
    log:debug("Peripheral type validated", {name = name, action = "require_type", status = "ok", expected = expectedType})
    return wrapped
end
function Peripheral.findByType(self, expectedType)
    local wrapped = {peripheral.find(expectedType)}
    if wrapped == nil or wrapped == nil then
        log:debug("No peripheral found by type", {type = expectedType, action = "find_by_type", status = "missing"})
        return nil
    end
    log:debug("Peripheral found by type", {type = expectedType, action = "find_by_type", status = "ok"})
    return wrapped
end
function Peripheral.requireByType(self, expectedType)
    local wrapped = self:findByType(expectedType)
    if wrapped == nil then
        local message = ("No peripheral found with type '" .. expectedType) .. "'"
        log:error(message, {expectedType = expectedType, action = "require_by_type", status = "failed"})
        error(
            __TS__New(PeripheralError, message, {expectedType = expectedType, action = "require_by_type"}),
            0
        )
    end
    return wrapped
end
function Peripheral.findNameByType(self, expectedType)
    for ____, side in ipairs(peripheral.getNames()) do
        local ____type = self:getType(side)
        if ____type == expectedType then
            return side
        end
    end
    return nil
end
function Peripheral.requireNameByType(self, expectedType)
    local side = self:findNameByType(expectedType)
    if not side then
        local message = ("No peripheral name found with type '" .. expectedType) .. "'"
        log:error(message, {expectedType = expectedType, action = "require_name_by_type", status = "failed"})
        error(
            __TS__New(PeripheralError, message, {expectedType = expectedType, action = "require_name_by_type"}),
            0
        )
    end
    return side
end
return ____exports
