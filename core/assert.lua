--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
function ____exports.assert(self, condition, message)
    if message == nil then
        message = "Assertion failed"
    end
    if not condition then
        error(message, 2)
    end
end
function ____exports.assertNotNil(self, value, message)
    if value == nil or value == nil then
        error(message, 2)
    end
    return value
end
function ____exports.assertString(self, value, name)
    if type(value) ~= "string" then
        error(name .. " must be a string", 2)
    end
end
function ____exports.assertNumber(self, value, name)
    if type(value) ~= "number" then
        error(name .. " must be a number", 2)
    end
end
function ____exports.assertBoolean(self, value, name)
    if type(value) ~= "boolean" then
        error(name .. " must be a boolean", 2)
    end
end
function ____exports.assertTable(self, value, name)
    if type(value) ~= "table" then
        error(name .. " must be a table", 2)
    end
end
function ____exports.assertPeripheral(self, value, side)
    if value == nil or value == nil then
        error(("No peripheral found on side '" .. side) .. "'", 2)
    end
end
return ____exports
