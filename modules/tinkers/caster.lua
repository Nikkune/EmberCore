--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
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

local function __TS__StringEndsWith(self, searchString, endPosition)
    if endPosition == nil or endPosition > #self then
        endPosition = #self
    end
    return string.sub(self, endPosition - #searchString + 1, endPosition) == searchString
end

local function __TS__StringStartsWith(self, searchString, position)
    if position == nil or position < 0 then
        position = 0
    end
    return string.sub(self, position + 1, #searchString + position) == searchString
end

local function __TS__Class(self)
    local c = {prototype = {}}
    c.prototype.__index = c.prototype
    c.prototype.constructor = c
    return c
end

local function __TS__New(target, ...)
    local instance = setmetatable({}, target.prototype)
    instance:____constructor(...)
    return instance
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
local Inventory = ____inventory.Inventory
local ____inventory = require("core.inventory")
local ItemDetail = ____inventory.ItemDetail
local ItemSummary = ____inventory.ItemSummary
local ____tank = require("core.tank")
local Tank = ____tank.Tank
local ____fluidValues = require("modules.tinkers.fluidValues")
local CastAmounts = ____fluidValues.CastAmounts
local ____fluidValues = require("modules.tinkers.fluidValues")
local CastFormat = ____fluidValues.CastFormat
local ____smeltery = require("modules.tinkers.smeltery")
local Smeltery = ____smeltery.Smeltery
local CAST_SLOT = 1
local OUTPUT_SLOT = 2
function ____exports.formatOfCastTags(tags)
    if tags == nil then
        return nil
    end
    for tag, present in pairs(tags) do
        do
            local __continue4
            repeat
                if not present then
                    __continue4 = true
                    break
                end
                for ____, marker in ipairs({":casts/multi_use/", ":casts/single_use/"}) do
                    local index = (string.find(tag, marker, nil, true) or 0) - 1
                    if index >= 0 then
                        return __TS__StringSubstring(tag, index + #marker)
                    end
                end
                __continue4 = true
            until true
            if not __continue4 then
                break
            end
        end
    end
    return nil
end
function ____exports.formatOfCast(castName)
    local colon = (string.find(castName, ":", nil, true) or 0) - 1
    local path = colon >= 0 and __TS__StringSubstring(castName, colon + 1) or castName
    for ____, suffix in ipairs({
        "_red_sand_cast",
        "_sand_cast",
        "_cast",
        "_cast_gold",
        "_cast_red_sand",
        "_cast_sand"
    }) do
        if __TS__StringEndsWith(path, suffix) then
            return __TS__StringSubstring(path, 0, #path - #suffix)
        end
    end
    if __TS__StringStartsWith(path, "cast_") then
        return __TS__StringSubstring(path, #"cast_")
    end
    return nil
end
____exports.Caster = __TS__Class()
local Caster = ____exports.Caster
Caster.name = "Caster"
function Caster.prototype.____constructor(self, name, kind, tank, inventory, amounts)
    if amounts == nil then
        amounts = __TS__New(CastAmounts)
    end
    self.name = name
    self.kind = kind
    self.tank = tank
    self.inventory = inventory
    self.amounts = amounts
    self.castFormats = __TS__New(Map)
end
function Caster.fromName(self, name, amounts)
    local kind = __TS__StringIncludes(name, "basin") and "basin" or "table"
    return __TS__New(
        ____exports.Caster,
        name,
        kind,
        Tank:fromName(name),
        Inventory:fromName(name),
        amounts
    )
end
function Caster.prototype.read(self)
    local items = self.inventory:list()
    local cast = items[CAST_SLOT]
    local output = items[OUTPUT_SLOT]
    local fluids = self.tank:getFluids()
    local fluid = fluids[1]
    local state = {status = output ~= nil and "blocked" or (fluid ~= nil and "busy" or "idle"), amount = fluid and fluid.amount or 0}
    if cast ~= nil then
        state.cast = cast.name
    end
    if output ~= nil then
        state.output = {name = output.name, count = output.count}
    end
    if fluid ~= nil then
        state.fluid = fluid.name
    end
    local ____temp_2
    if cast ~= nil then
        ____temp_2 = self:formatOf(cast.name)
    else
        ____temp_2 = self.kind == "basin" and "block" or nil
    end
    local format = ____temp_2
    if format ~= nil then
        state.format = format
    end
    return state
end
function Caster.prototype.formatOf(self, castName)
    local format = self.castFormats:get(castName)
    if format == nil then
        local detail = self.inventory:getItem(CAST_SLOT)
        local ____temp_5
        if (detail and detail.name) == castName then
            ____temp_5 = ____exports.formatOfCastTags(detail.tags)
        else
            ____temp_5 = nil
        end
        format = ____temp_5 or ____exports.formatOfCast(castName) or false
        self.castFormats:set(castName, format)
    end
    local ____temp_6
    if format == false then
        ____temp_6 = nil
    else
        ____temp_6 = format
    end
    return ____temp_6
end
function Caster.prototype.castDetail(self)
    return self.inventory:getItem(CAST_SLOT)
end
function Caster.prototype.amountFor(self, format, fluid)
    return self.amounts:get(format, fluid)
end
function Caster.prototype.pour(self, smeltery, fluidName)
    local state = self:read()
    local amount = self:amountFor(state.format, fluidName)
    if state.status ~= "idle" or amount == nil then
        return 0
    end
    if smeltery:amountOf(fluidName) < amount then
        return 0
    end
    return smeltery:pour(self.tank, fluidName, amount)
end
function Caster.prototype.collect(self, target)
    if self.inventory:list()[OUTPUT_SLOT] == nil then
        return 0
    end
    return self.inventory:pushTo(target, OUTPUT_SLOT)
end
function Caster.prototype.pourPlanned(self, smeltery, fluidName, amount)
    return smeltery:pour(self.tank, fluidName, amount)
end
function Caster.prototype.collectPlanned(self, target)
    return self.inventory:push(target, OUTPUT_SLOT)
end
return ____exports
