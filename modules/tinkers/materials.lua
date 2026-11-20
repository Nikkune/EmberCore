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

local __TS__Iterator
do
    local function iteratorGeneratorStep(self)
        local co = self.____coroutine
        local status, value = coroutine.resume(co)
        if not status then
            error(value, 0)
        end
        if coroutine.status(co) == "dead" then
            return
        end
        return true, value
    end
    local function iteratorIteratorStep(self)
        local result = self:next()
        if result.done then
            return
        end
        return true, result.value
    end
    local function iteratorStringStep(self, index)
        index = index + 1
        if index > #self then
            return
        end
        return index, string.sub(self, index, index)
    end
    function __TS__Iterator(iterable)
        if type(iterable) == "string" then
            return iteratorStringStep, iterable, 0
        elseif iterable.____coroutine ~= nil then
            return iteratorGeneratorStep, iterable
        elseif iterable[Symbol.iterator] then
            local iterator = iterable[Symbol.iterator](iterable)
            return iteratorIteratorStep, iterator
        else
            return ipairs(iterable)
        end
    end
end

local Map
do
    Map = __TS__Class()
    Map.name = "Map"
    function Map.prototype.____constructor(self, entries)
        self[Symbol.toStringTag] = "Map"
        self.items = {}
        self.size = 0
        self.nextKey = {}
        self.previousKey = {}
        if entries == nil then
            return
        end
        local iterable = entries
        if iterable[Symbol.iterator] then
            local iterator = iterable[Symbol.iterator](iterable)
            while true do
                local result = iterator:next()
                if result.done then
                    break
                end
                local value = result.value
                self:set(value[1], value[2])
            end
        else
            local array = entries
            for ____, kvp in ipairs(array) do
                self:set(kvp[1], kvp[2])
            end
        end
    end
    function Map.prototype.clear(self)
        self.items = {}
        self.nextKey = {}
        self.previousKey = {}
        self.firstKey = nil
        self.lastKey = nil
        self.size = 0
    end
    function Map.prototype.delete(self, key)
        local contains = self:has(key)
        if contains then
            self.size = self.size - 1
            local next = self.nextKey[key]
            local previous = self.previousKey[key]
            if next ~= nil and previous ~= nil then
                self.nextKey[previous] = next
                self.previousKey[next] = previous
            elseif next ~= nil then
                self.firstKey = next
                self.previousKey[next] = nil
            elseif previous ~= nil then
                self.lastKey = previous
                self.nextKey[previous] = nil
            else
                self.firstKey = nil
                self.lastKey = nil
            end
            self.nextKey[key] = nil
            self.previousKey[key] = nil
        end
        self.items[key] = nil
        return contains
    end
    function Map.prototype.forEach(self, callback)
        for ____, key in __TS__Iterator(self:keys()) do
            callback(nil, self.items[key], key, self)
        end
    end
    function Map.prototype.get(self, key)
        return self.items[key]
    end
    function Map.prototype.has(self, key)
        return self.nextKey[key] ~= nil or self.lastKey == key
    end
    function Map.prototype.set(self, key, value)
        local isNewValue = not self:has(key)
        if isNewValue then
            self.size = self.size + 1
        end
        self.items[key] = value
        if self.firstKey == nil then
            self.firstKey = key
            self.lastKey = key
        elseif isNewValue then
            self.nextKey[self.lastKey] = key
            self.previousKey[key] = self.lastKey
            self.lastKey = key
        end
        return self
    end
    Map.prototype[Symbol.iterator] = function(self)
        return self:entries()
    end
    function Map.prototype.entries(self)
        local items = self.items
        local nextKey = self.nextKey
        local key = self.firstKey
        return {
            [Symbol.iterator] = function(self)
                return self
            end,
            next = function(self)
                local result = {done = not key, value = {key, items[key]}}
                key = nextKey[key]
                return result
            end
        }
    end
    function Map.prototype.keys(self)
        local nextKey = self.nextKey
        local key = self.firstKey
        return {
            [Symbol.iterator] = function(self)
                return self
            end,
            next = function(self)
                local result = {done = not key, value = key}
                key = nextKey[key]
                return result
            end
        }
    end
    function Map.prototype.values(self)
        local items = self.items
        local nextKey = self.nextKey
        local key = self.firstKey
        return {
            [Symbol.iterator] = function(self)
                return self
            end,
            next = function(self)
                local result = {done = not key, value = items[key]}
                key = nextKey[key]
                return result
            end
        }
    end
    Map[Symbol.species] = Map
end

local function __TS__New(target, ...)
    local instance = setmetatable({}, target.prototype)
    instance:____constructor(...)
    return instance
end

local function __TS__StringSubstring(self, start, ____end)
    if ____end ~= ____end then
        ____end = 0
    end
    if ____end ~= nil and start > ____end then
        start, ____end = ____end, start
    end
    if start >= 0 then
        start = start + 1
    else
        start = 1
    end
    if ____end ~= nil and ____end < 0 then
        ____end = 0
    end
    return string.sub(self, start, ____end)
end

local __TS__StringReplace
do
    local sub = string.sub
    function __TS__StringReplace(source, searchValue, replaceValue)
        local startPos, endPos = string.find(source, searchValue, nil, true)
        if not startPos then
            return source
        end
        local before = sub(source, 1, startPos - 1)
        local replacement = type(replaceValue) == "string" and replaceValue or replaceValue(nil, searchValue, startPos - 1, source)
        local after = sub(source, endPos + 1)
        return (before .. replacement) .. after
    end
end

local function __TS__StringStartsWith(self, searchString, position)
    if position == nil or position < 0 then
        position = 0
    end
    return string.sub(self, position + 1, #searchString + position) == searchString
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
-- End of Lua Library inline imports
local ____exports = {}
local ____inventory = require("core.inventory")
local ItemDetail = ____inventory.ItemDetail
____exports.DEFAULT_TAG_PREFIXES = {
    "forge:ingots/",
    "forge:nuggets/",
    "forge:storage_blocks/",
    "forge:raw_materials/",
    "forge:ores/",
    "forge:dusts/",
    "forge:gems/",
    "forge:plates/",
    "forge:gears/",
    "forge:rods/"
}
____exports.DEFAULT_FLUID_PATTERN = "tconstruct:molten_%s"
____exports.MaterialMap = __TS__Class()
local MaterialMap = ____exports.MaterialMap
MaterialMap.name = "MaterialMap"
function MaterialMap.prototype.____constructor(self, options)
    if options == nil then
        options = {}
    end
    self.overrides = __TS__New(Map)
    self.tagPrefixes = options.tagPrefixes or ____exports.DEFAULT_TAG_PREFIXES
    self.fluidPattern = options.fluidPattern or ____exports.DEFAULT_FLUID_PATTERN
    if options.fluids ~= nil then
        local byMaterial = __TS__New(Map)
        for ____, fluid in ipairs(options.fluids) do
            local index = (string.find(fluid, ":molten_", nil, true) or 0) - 1
            if index >= 0 then
                byMaterial:set(
                    __TS__StringSubstring(fluid, index + #":molten_"),
                    fluid
                )
            end
        end
        self.fluidsByMaterial = byMaterial
    end
    for ____, override in ipairs(options.overrides or ({})) do
        self.overrides:set(override.item, override.fluid)
    end
end
function MaterialMap.prototype.fluidOf(self, item)
    local override = self.overrides:get(item.name)
    if override ~= nil then
        return override
    end
    local material = self:materialOf(item)
    if material == nil then
        return nil
    end
    if self.fluidsByMaterial ~= nil then
        return self.fluidsByMaterial:get(material)
    end
    return __TS__StringReplace(self.fluidPattern, "%s", material)
end
function MaterialMap.prototype.materialOf(self, item)
    if not item.tags then
        return nil
    end
    local found
    for tag, present in pairs(item.tags) do
        do
            local __continue15
            repeat
                if not present then
                    __continue15 = true
                    break
                end
                local material = self:materialOfTag(tag)
                if material == nil then
                    __continue15 = true
                    break
                end
                if found ~= nil and found ~= material then
                    return nil
                end
                found = material
                __continue15 = true
            until true
            if not __continue15 then
                break
            end
        end
    end
    return found
end
function MaterialMap.prototype.materialOfTag(self, tag)
    for ____, prefix in ipairs(self.tagPrefixes) do
        do
            local __continue20
            repeat
                if not __TS__StringStartsWith(tag, prefix) then
                    __continue20 = true
                    break
                end
                local material = __TS__StringSubstring(tag, #prefix)
                if __TS__StringStartsWith(material, "raw_") then
                    material = __TS__StringSubstring(material, 4)
                end
                if #material == 0 or __TS__StringIncludes(material, "/") then
                    return nil
                end
                if self.fluidsByMaterial ~= nil and not self.fluidsByMaterial:has(material) then
                    return nil
                end
                return material
            until true
            if not __continue20 then
                break
            end
        end
    end
    return nil
end
return ____exports
