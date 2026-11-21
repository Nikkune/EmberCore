--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__ArraySort(self, compareFn)
    if compareFn ~= nil then
        table.sort(
            self,
            function(a, b) return compareFn(nil, a, b) < 0 end
        )
    else
        table.sort(self)
    end
    return self
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

local function __TS__New(target, ...)
    local instance = setmetatable({}, target.prototype)
    instance:____constructor(...)
    return instance
end

local Set
do
    Set = __TS__Class()
    Set.name = "Set"
    function Set.prototype.____constructor(self, values)
        self[Symbol.toStringTag] = "Set"
        self.size = 0
        self.nextKey = {}
        self.previousKey = {}
        if values == nil then
            return
        end
        local iterable = values
        if iterable[Symbol.iterator] then
            local iterator = iterable[Symbol.iterator](iterable)
            while true do
                local result = iterator:next()
                if result.done then
                    break
                end
                self:add(result.value)
            end
        else
            local array = values
            for ____, value in ipairs(array) do
                self:add(value)
            end
        end
    end
    function Set.prototype.add(self, value)
        local isNewValue = not self:has(value)
        if isNewValue then
            self.size = self.size + 1
        end
        if self.firstKey == nil then
            self.firstKey = value
            self.lastKey = value
        elseif isNewValue then
            self.nextKey[self.lastKey] = value
            self.previousKey[value] = self.lastKey
            self.lastKey = value
        end
        return self
    end
    function Set.prototype.clear(self)
        self.nextKey = {}
        self.previousKey = {}
        self.firstKey = nil
        self.lastKey = nil
        self.size = 0
    end
    function Set.prototype.delete(self, value)
        local contains = self:has(value)
        if contains then
            self.size = self.size - 1
            local next = self.nextKey[value]
            local previous = self.previousKey[value]
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
            self.nextKey[value] = nil
            self.previousKey[value] = nil
        end
        return contains
    end
    function Set.prototype.forEach(self, callback)
        for ____, key in __TS__Iterator(self:keys()) do
            callback(nil, key, key, self)
        end
    end
    function Set.prototype.has(self, value)
        return self.nextKey[value] ~= nil or self.lastKey == value
    end
    Set.prototype[Symbol.iterator] = function(self)
        return self:values()
    end
    function Set.prototype.entries(self)
        local nextKey = self.nextKey
        local key = self.firstKey
        return {
            [Symbol.iterator] = function(self)
                return self
            end,
            next = function(self)
                local result = {done = not key, value = {key, key}}
                key = nextKey[key]
                return result
            end
        }
    end
    function Set.prototype.keys(self)
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
    function Set.prototype.values(self)
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
    function Set.prototype.union(self, other)
        local result = __TS__New(Set, self)
        for ____, item in __TS__Iterator(other) do
            result:add(item)
        end
        return result
    end
    function Set.prototype.intersection(self, other)
        local result = __TS__New(Set)
        for ____, item in __TS__Iterator(self) do
            if other:has(item) then
                result:add(item)
            end
        end
        return result
    end
    function Set.prototype.difference(self, other)
        local result = __TS__New(Set, self)
        for ____, item in __TS__Iterator(other) do
            result:delete(item)
        end
        return result
    end
    function Set.prototype.symmetricDifference(self, other)
        local result = __TS__New(Set, self)
        for ____, item in __TS__Iterator(other) do
            if self:has(item) then
                result:delete(item)
            else
                result:add(item)
            end
        end
        return result
    end
    function Set.prototype.isSubsetOf(self, other)
        for ____, item in __TS__Iterator(self) do
            if not other:has(item) then
                return false
            end
        end
        return true
    end
    function Set.prototype.isSupersetOf(self, other)
        for ____, item in __TS__Iterator(other) do
            if not self:has(item) then
                return false
            end
        end
        return true
    end
    function Set.prototype.isDisjointFrom(self, other)
        for ____, item in __TS__Iterator(self) do
            if other:has(item) then
                return false
            end
        end
        return true
    end
    Set[Symbol.species] = Set
end

local function __TS__CountVarargs(...)
    return select("#", ...)
end

local function __TS__SparseArrayNew(...)
    local sparseArray = {...}
    sparseArray.sparseLength = __TS__CountVarargs(...)
    return sparseArray
end

local function __TS__SparseArrayPush(sparseArray, ...)
    local args = {...}
    local argsLen = __TS__CountVarargs(...)
    local listLen = sparseArray.sparseLength
    for i = 1, argsLen do
        sparseArray[listLen + i] = args[i]
    end
    sparseArray.sparseLength = listLen + argsLen
end

local function __TS__SparseArraySpread(sparseArray)
    local _unpack = unpack or table.unpack
    return _unpack(sparseArray, 1, sparseArray.sparseLength)
end

local function __TS__ArrayFind(self, predicate, thisArg)
    for i = 1, #self do
        local elem = self[i]
        if predicate(thisArg, elem, i - 1, self) then
            return elem
        end
    end
    return nil
end
-- End of Lua Library inline imports
local ____exports = {}
local ____peripheral = require("core.peripheral")
local Peripheral = ____peripheral.Peripheral
local ____config = require("projects.smeltery.controller.config")
local ControllerConfig = ____config.ControllerConfig
local function namesOfType(____type)
    local names = {}
    for ____, name in ipairs(peripheral.getNames()) do
        if Peripheral:hasType(name, ____type) then
            names[#names + 1] = name
        end
    end
    __TS__ArraySort(names)
    return names
end
local function pick(configured, ____type, label, problems)
    if configured ~= "" then
        if peripheral.isPresent(configured) then
            return configured
        end
        problems[#problems + 1] = ((label .. " '") .. configured) .. "' not found on the network"
        return nil
    end
    local first = unpack(
        namesOfType(____type),
        1,
        1
    )
    if first == nil then
        problems[#problems + 1] = ("no " .. label) .. " found on the network"
    end
    return first
end
local function pickInventory(configured, label, problems)
    if configured == "" then
        problems[#problems + 1] = label .. " inventory not set in the controller config"
        return nil
    end
    if not peripheral.isPresent(configured) then
        problems[#problems + 1] = ((label .. " inventory '") .. configured) .. "' not found on the network"
        return nil
    end
    return configured
end
local function findFuelTank()
    for ____, name in ipairs(namesOfType("fluid_storage")) do
        do
            local __continue14
            repeat
                if not __TS__StringStartsWith(name, "tconstruct:") then
                    __continue14 = true
                    break
                end
                if __TS__StringIncludes(name, "drain") or __TS__StringIncludes(name, "table") or __TS__StringIncludes(name, "basin") then
                    __continue14 = true
                    break
                end
                if __TS__StringIncludes(name, "tank") or __TS__StringIncludes(name, "gauge") then
                    return name
                end
                __continue14 = true
            until true
            if not __continue14 then
                break
            end
        end
    end
    return nil
end
function ____exports.discoverNetwork(config)
    local problems = {}
    local network = {casters = {}, craftCasters = {}, reservoirs = {}, problems = problems}
    local drain = pick(config.drain, "tconstruct:drain", "Smeltery drain", problems)
    local chute = pick(config.chute, "tconstruct:chute", "Smeltery chute", problems)
    local input = pickInventory(config.input, "input", problems)
    local output = pickInventory(config.output, "output", problems)
    if drain ~= nil then
        network.drain = drain
    end
    if chute ~= nil then
        network.chute = chute
    end
    if input ~= nil then
        network.input = input
    end
    if output ~= nil then
        network.output = output
    end
    if config.heatOutput ~= "" then
        local heat = pickInventory(config.heatOutput, "heat output", problems)
        if heat ~= nil then
            network.heatOutput = heat
        end
    end
    if config.unknownOutput ~= "" then
        local unknown = pickInventory(config.unknownOutput, "unknown output", problems)
        if unknown ~= nil then
            network.unknownOutput = unknown
        end
    end
    for ____, name in ipairs(config.craftCasters) do
        if peripheral.isPresent(name) then
            local ____network_craftCasters_0 = network.craftCasters
            ____network_craftCasters_0[#____network_craftCasters_0 + 1] = name
        else
            problems[#problems + 1] = ("craft caster '" .. name) .. "' not found on the network"
        end
    end
    local craft = __TS__New(Set, config.craftCasters)
    if #config.casters > 0 then
        for ____, name in ipairs(config.casters) do
            do
                local __continue33
                repeat
                    if craft:has(name) then
                        __continue33 = true
                        break
                    end
                    if peripheral.isPresent(name) then
                        local ____network_casters_1 = network.casters
                        ____network_casters_1[#____network_casters_1 + 1] = name
                    else
                        problems[#problems + 1] = ("caster '" .. name) .. "' not found on the network"
                    end
                    __continue33 = true
                until true
                if not __continue33 then
                    break
                end
            end
        end
    else
        local ____array_3 = __TS__SparseArrayNew(unpack(namesOfType("tconstruct:table")))
        __TS__SparseArrayPush(
            ____array_3,
            unpack(namesOfType("tconstruct:basin"))
        )
        for ____, name in ipairs({__TS__SparseArraySpread(____array_3)}) do
            if not craft:has(name) then
                local ____network_casters_2 = network.casters
                ____network_casters_2[#____network_casters_2 + 1] = name
            end
        end
    end
    if #network.casters == 0 then
        problems[#problems + 1] = "no casting table nor basin found on the network"
    end
    local ____temp_4
    if config.fuelTank ~= "" then
        ____temp_4 = peripheral.isPresent(config.fuelTank) and config.fuelTank or nil
    else
        ____temp_4 = findFuelTank()
    end
    local fuelTank = ____temp_4
    if config.fuelTank ~= "" and fuelTank == nil then
        problems[#problems + 1] = ("fuel tank '" .. config.fuelTank) .. "' not found on the network"
    end
    if fuelTank ~= nil then
        network.fuelTank = fuelTank
    end
    local trash
    if config.fluidTrash ~= "" then
        if peripheral.isPresent(config.fluidTrash) then
            trash = config.fluidTrash
        else
            problems[#problems + 1] = ("fluid trash '" .. config.fluidTrash) .. "' not found on the network"
        end
    else
        trash = __TS__ArrayFind(
            namesOfType("fluid_storage"),
            function(____, name) return __TS__StringIncludes(name, "trash") end
        )
    end
    if trash ~= nil then
        network.trash = trash
    end
    if #config.reservoirs > 0 then
        for ____, name in ipairs(config.reservoirs) do
            do
                local __continue52
                repeat
                    if name == trash then
                        __continue52 = true
                        break
                    end
                    if peripheral.isPresent(name) then
                        local ____network_reservoirs_5 = network.reservoirs
                        ____network_reservoirs_5[#____network_reservoirs_5 + 1] = name
                    else
                        problems[#problems + 1] = ("reservoir '" .. name) .. "' not found on the network"
                    end
                    __continue52 = true
                until true
                if not __continue52 then
                    break
                end
            end
        end
    else
        for ____, name in ipairs(namesOfType("fluid_storage")) do
            do
                local __continue58
                repeat
                    if __TS__StringStartsWith(name, "tconstruct:") or name == fuelTank or name == trash then
                        __continue58 = true
                        break
                    end
                    local ____network_reservoirs_6 = network.reservoirs
                    ____network_reservoirs_6[#____network_reservoirs_6 + 1] = name
                    __continue58 = true
                until true
                if not __continue58 then
                    break
                end
            end
        end
    end
    return network
end
return ____exports
