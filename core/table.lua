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
____exports.TableUtils = __TS__Class()
local TableUtils = ____exports.TableUtils
TableUtils.name = "TableUtils"
function TableUtils.prototype.____constructor(self)
end
function TableUtils.keys(self, ____table)
    local result = {}
    for key in pairs(____table) do
        result[#result + 1] = key
    end
    return result
end
function TableUtils.values(self, ____table)
    local result = {}
    for key in pairs(____table) do
        result[#result + 1] = ____table[key]
    end
    return result
end
function TableUtils.size(self, ____table)
    local count = 0
    for _key in pairs(____table) do
        count = count + 1
    end
    return count
end
function TableUtils.isEmpty(self, ____table)
    for _key in pairs(____table) do
        return false
    end
    return true
end
function TableUtils.contains(self, values, value)
    for ____, current in ipairs(values) do
        if current == value then
            return true
        end
    end
    return false
end
function TableUtils.copyShallow(self, ____table)
    local result = {}
    for key in pairs(____table) do
        local typedKey = key
        result[typedKey] = ____table[typedKey]
    end
    return result
end
function TableUtils.mergeShallow(self, base, override)
    local result = self:copyShallow(base)
    for key in pairs(override) do
        local typedKey = key
        local value = override[typedKey]
        if value ~= nil then
            result[typedKey] = value
        end
    end
    return result
end
function TableUtils.mapValues(self, ____table, mapper)
    local result = {}
    for key in pairs(____table) do
        local typedKey = key
        result[key] = mapper(nil, ____table[typedKey], typedKey)
    end
    return result
end
return ____exports
