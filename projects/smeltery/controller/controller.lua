--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__Class(self)
    local c = {prototype = {}}
    c.prototype.__index = c.prototype
    c.prototype.constructor = c
    return c
end

local function __TS__ArrayMap(self, callbackfn, thisArg)
    local result = {}
    for i = 1, #self do
        result[i] = callbackfn(thisArg, self[i], i - 1, self)
    end
    return result
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

local function __TS__ArrayFilter(self, callbackfn, thisArg)
    local result = {}
    local len = 0
    for i = 1, #self do
        if callbackfn(thisArg, self[i], i - 1, self) then
            len = len + 1
            result[len] = self[i]
        end
    end
    return result
end

local function __TS__ArrayFindIndex(self, callbackFn, thisArg)
    for i = 1, #self do
        if callbackFn(thisArg, self[i], i - 1, self) then
            return i - 1
        end
    end
    return -1
end

local function __TS__CountVarargs(...)
    return select("#", ...)
end

local function __TS__ArraySplice(self, ...)
    local args = {...}
    local len = #self
    local actualArgumentCount = __TS__CountVarargs(...)
    local start = args[1]
    local deleteCount = args[2]
    if start < 0 then
        start = len + start
        if start < 0 then
            start = 0
        end
    elseif start > len then
        start = len
    end
    local itemCount = actualArgumentCount - 2
    if itemCount < 0 then
        itemCount = 0
    end
    local actualDeleteCount
    if actualArgumentCount == 0 then
        actualDeleteCount = 0
    elseif actualArgumentCount == 1 then
        actualDeleteCount = len - start
    else
        actualDeleteCount = deleteCount or 0
        if actualDeleteCount < 0 then
            actualDeleteCount = 0
        end
        if actualDeleteCount > len - start then
            actualDeleteCount = len - start
        end
    end
    local out = {}
    for k = 1, actualDeleteCount do
        local from = start + k
        if self[from] ~= nil then
            out[k] = self[from]
        end
    end
    if itemCount < actualDeleteCount then
        for k = start + 1, len - actualDeleteCount do
            local from = k + actualDeleteCount
            local to = k + itemCount
            if self[from] then
                self[to] = self[from]
            else
                self[to] = nil
            end
        end
        for k = len - actualDeleteCount + itemCount + 1, len do
            self[k] = nil
        end
    elseif itemCount > actualDeleteCount then
        for k = len - actualDeleteCount, start + 1, -1 do
            local from = k + actualDeleteCount
            local to = k + itemCount
            if self[from] then
                self[to] = self[from]
            else
                self[to] = nil
            end
        end
    end
    local j = start + 1
    for i = 3, actualArgumentCount do
        self[j] = args[i]
        j = j + 1
    end
    for k = #self, len - actualDeleteCount + itemCount + 1, -1 do
        self[k] = nil
    end
    return out
end

local function __TS__ArraySome(self, callbackfn, thisArg)
    for i = 1, #self do
        if callbackfn(thisArg, self[i], i - 1, self) then
            return true
        end
    end
    return false
end

local function __TS__ObjectAssign(target, ...)
    local sources = {...}
    for i = 1, #sources do
        local source = sources[i]
        for key in pairs(source) do
            target[key] = source[key]
        end
    end
    return target
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

local function __TS__ArrayFind(self, predicate, thisArg)
    for i = 1, #self do
        local elem = self[i]
        if predicate(thisArg, elem, i - 1, self) then
            return elem
        end
    end
    return nil
end

local function __TS__ArrayIndexOf(self, searchElement, fromIndex)
    if fromIndex == nil then
        fromIndex = 0
    end
    local len = #self
    if len == 0 then
        return -1
    end
    if fromIndex >= len then
        return -1
    end
    if fromIndex < 0 then
        fromIndex = len + fromIndex
        if fromIndex < 0 then
            fromIndex = 0
        end
    end
    for i = fromIndex + 1, len do
        if self[i] == searchElement then
            return i - 1
        end
    end
    return -1
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

local function __TS__StringIncludes(self, searchString, position)
    if not position then
        position = 1
    else
        position = position + 1
    end
    local index = string.find(self, searchString, position, true)
    return index ~= nil
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
-- End of Lua Library inline imports
local ____exports = {}
local ____errors = require("core.errors")
local EmberError = ____errors.EmberError
local ____inventory = require("core.inventory")
local Inventory = ____inventory.Inventory
local ____inventory = require("core.inventory")
local ItemSummary = ____inventory.ItemSummary
local ____parallel = require("core.parallel")
local Parallel = ____parallel.Parallel
local ____tank = require("core.tank")
local Tank = ____tank.Tank
local ____tank = require("core.tank")
local FluidStack = ____tank.FluidStack
local ____index = require("modules.fluids.index")
local ReservoirPool = ____index.ReservoirPool
local ____index = require("modules.net.index")
local Channel = ____index.Channel
local ____index = require("modules.tinkers.index")
local Caster = ____index.Caster
local Smeltery = ____index.Smeltery
local ____index = require("modules.tinkers.index")
local AlloyGuard = ____index.AlloyGuard
local AlloyRatio = ____index.AlloyRatio
local CastAmounts = ____index.CastAmounts
local CasterState = ____index.CasterState
local MaterialMap = ____index.MaterialMap
local ____catalogue = require("projects.smeltery.shared.catalogue")
local alloyGuardOf = ____catalogue.alloyGuardOf
local castAmountsOf = ____catalogue.castAmountsOf
local loadCatalogue = ____catalogue.loadCatalogue
local materialMapOf = ____catalogue.materialMapOf
local temperatureMap = ____catalogue.temperatureMap
local ____catalogue = require("projects.smeltery.shared.catalogue")
local Catalogue = ____catalogue.Catalogue
local ____protocol = require("projects.smeltery.shared.protocol")
local CONTROLLER_HOSTNAME = ____protocol.CONTROLLER_HOSTNAME
local Messages = ____protocol.Messages
local MODES = ____protocol.MODES
local PROTOCOL = ____protocol.PROTOCOL
local ____protocol = require("projects.smeltery.shared.protocol")
local AlloyOption = ____protocol.AlloyOption
local AlloyView = ____protocol.AlloyView
local CasterView = ____protocol.CasterView
local CastRequest = ____protocol.CastRequest
local FuelView = ____protocol.FuelView
local InputItemView = ____protocol.InputItemView
local InsertRequest = ____protocol.InsertRequest
local InventoryView = ____protocol.InventoryView
local Mode = ____protocol.Mode
local SetAlloyRequest = ____protocol.SetAlloyRequest
local SetFormatRequest = ____protocol.SetFormatRequest
local SetModeRequest = ____protocol.SetModeRequest
local SmelteryState = ____protocol.SmelteryState
local WaitingItem = ____protocol.WaitingItem
local ____config = require("projects.smeltery.controller.config")
local CONFIG_PATH = ____config.CONFIG_PATH
local loadAlloy = ____config.loadAlloy
local loadCapacities = ____config.loadCapacities
local loadControllerConfig = ____config.loadControllerConfig
local loadMode = ____config.loadMode
local saveAlloy = ____config.saveAlloy
local saveCapacities = ____config.saveCapacities
local saveControllerConfig = ____config.saveControllerConfig
local saveMode = ____config.saveMode
local ____config = require("projects.smeltery.controller.config")
local ControllerConfig = ____config.ControllerConfig
local ____discovery = require("projects.smeltery.controller.discovery")
local discoverNetwork = ____discovery.discoverNetwork
local ____discovery = require("projects.smeltery.controller.discovery")
local Network = ____discovery.Network
local ____planner = require("projects.smeltery.controller.planner")
local assessInput = ____planner.assessInput
local assessItem = ____planner.assessItem
local planTick = ____planner.planTick
local ____planner = require("projects.smeltery.controller.planner")
local Action = ____planner.Action
local InputSlot = ____planner.InputSlot
local Plan = ____planner.Plan
local PlanContext = ____planner.PlanContext
local Snapshot = ____planner.Snapshot
____exports.Controller = __TS__Class()
local Controller = ____exports.Controller
Controller.name = "Controller"
function Controller.prototype.____constructor(self, config, catalogue, modePath)
    self.config = config
    self.modePath = modePath
    self.network = {casters = {}, reservoirs = {}, problems = {}}
    self.casters = {}
    self.fluidCache = __TS__New(Map)
    self.logLines = {}
    self.inputItems = {}
    self.sizes = __TS__New(Map)
    self.tickWanted = false
    self.needsDiscovery = true
    self.lastAlerts = ""
    self.materials = materialMapOf(catalogue)
    self.guard = alloyGuardOf(catalogue)
    self.amounts = castAmountsOf(catalogue)
    self.meltingTemperatures = temperatureMap(catalogue.meltingTemperatures)
    self.fuelTemperatures = temperatureMap(catalogue.fuels)
    self.fallbackHeat = self.fuelTemperatures:get(config.fuel)
    local saved = loadMode(modePath)
    self.mode = saved.mode
    self.previousMode = saved.previous
    self.alloyResults = __TS__New(
        Set,
        __TS__ArrayMap(
            catalogue.alloys,
            function(____, alloy) return alloy.result end
        )
    )
    self.alloyRatios = catalogue.alloyRatios
    self.alloy = loadAlloy()
    self.state = self:emptyState()
end
function Controller.prototype.setLogFile(self, path)
    if fs.exists(path) then
        if fs.exists(path .. ".old") then
            fs.delete(path .. ".old")
        end
        fs.move(path, path .. ".old")
    end
    self.logFile = path
end
function Controller.prototype.setConfigPath(self, path)
    self.configPath = path
end
function Controller.prototype.setFormat(self, request)
    local format = request.format
    if type(format) ~= "string" or format == "" or format == "no cast" then
        error(
            __TS__New(
                EmberError,
                "unknown format " .. tostring(format),
                "SMELTERY_ERROR"
            ),
            0
        )
    end
    local formats = __TS__ArrayFilter(
        self.config.formatPriority,
        function(____, candidate) return candidate ~= format end
    )
    if request.auto then
        local function size(____, name)
            return self.amounts:get(name) or 0
        end
        local index = __TS__ArrayFindIndex(
            formats,
            function(____, candidate) return size(nil, candidate) < size(nil, format) end
        )
        if index < 0 then
            formats[#formats + 1] = format
        else
            __TS__ArraySplice(formats, index, 0, format)
        end
    end
    if table.concat(formats, ",") == table.concat(self.config.formatPriority, ",") then
        return
    end
    self.config.formatPriority = formats
    self.state.autoFormats = formats
    if self.configPath ~= nil then
        saveControllerConfig(self.config, self.configPath)
    end
    self:log("auto formats: " .. (#formats > 0 and table.concat(formats, ", ") or "none"))
end
function Controller.prototype.setAlloy(self, request)
    local result = request.result
    if not __TS__ArraySome(
        self.alloyRatios,
        function(____, ratio) return ratio.result == result end
    ) then
        error(
            __TS__New(
                EmberError,
                "unknown alloy " .. tostring(result),
                "SMELTERY_ERROR"
            ),
            0
        )
    end
    if request.target ~= nil and not (request.target > 0) then
        error(
            __TS__New(EmberError, "the amount must be positive", "SMELTERY_ERROR"),
            0
        )
    end
    local alloy = {result = result, made = 0}
    if request.target ~= nil then
        alloy.target = request.target
    end
    self.alloy = alloy
    saveAlloy(alloy)
    self:log((("alloy: " .. ____exports.Controller:shortName(result)) .. ", ") .. (alloy.target ~= nil and tostring(alloy.target) .. " mB" or "until stopped"))
    self.state.alloy = __TS__ObjectAssign({}, alloy)
    if request.activate == true then
        self:setMode("alloy")
    end
end
function Controller.prototype.getState(self)
    return self.state
end
function Controller.prototype.getMode(self)
    return self.mode
end
function Controller.prototype.setMode(self, mode)
    if mode == self.mode then
        return
    end
    if mode == "alloy" and self.alloy == nil then
        error(
            __TS__New(EmberError, "choose an alloy first (Change alloy)", "SMELTERY_ERROR"),
            0
        )
    end
    if (mode == "purge" or mode == "alloy") and not ____exports.Controller:ends(self.mode) then
        self.previousMode = self.mode
    end
    if mode == "alloy" and self.alloy ~= nil then
        self.alloy.made = 0
        saveAlloy(self.alloy)
    end
    self:log((("mode " .. self.mode) .. " -> ") .. mode)
    self.quietSince = nil
    self.mode = mode
    saveMode(mode, self.previousMode, self.modePath)
    self.state.mode = mode
end
function Controller.prototype.tick(self)
    if self.needsDiscovery then
        self:connect()
    end
    local alerts = {unpack(self.network.problems)}
    local plan = {actions = {}, waiting = {}, alerts = {}}
    do
        local function ____catch(____error)
            ____exports.Controller:passTerminate(____error)
            alerts[#alerts + 1] = "peripheral error: " .. ____exports.Controller:messageOf(____error)
            self.needsDiscovery = true
        end
        local ____try, ____hasReturned = pcall(function()
            local pauseInput = self:readFuel(alerts)
            local snapshot = self:read()
            if snapshot ~= nil then
                if pauseInput ~= nil then
                    snapshot.pauseInput = pauseInput
                end
                local context = self:planContext()
                self.inputItems = assessInput(snapshot, context)
                plan = planTick(self.mode, snapshot, context)
                self:execute(plan)
                if #plan.actions > 0 then
                    self:refreshReading()
                end
                if plan.finished == true then
                    self:finish()
                else
                    self:checkIdle(plan, snapshot)
                end
            end
        end)
        if not ____try then
            ____catch(____hasReturned)
        end
    end
    self.tickWanted = false
    local ____self_buildState_1 = self.buildState
    local ____array_0 = __TS__SparseArrayNew(unpack(alerts))
    __TS__SparseArrayPush(
        ____array_0,
        unpack(plan.alerts)
    )
    self.state = ____self_buildState_1(
        self,
        {__TS__SparseArraySpread(____array_0)},
        plan.waiting
    )
    local alertText = table.concat(self.state.alerts, "; ")
    if alertText ~= self.lastAlerts then
        self:log(alertText == "" and "alerts cleared" or "alerts: " .. alertText)
        self.lastAlerts = alertText
    end
end
function Controller.prototype.insert(self, request)
    self:requireManual()
    local smeltery = self.smeltery
    local input = self.input
    if smeltery == nil or input == nil then
        error(
            __TS__New(EmberError, "Smeltery or input missing", "SMELTERY_ERROR"),
            0
        )
    end
    local detail = input:getItem(request.slot)
    if detail == nil then
        error(
            __TS__New(
                EmberError,
                ("input slot " .. tostring(request.slot)) .. " is empty",
                "SMELTERY_ERROR"
            ),
            0
        )
    end
    local item = {slot = request.slot, name = detail.name, count = detail.count}
    local fluid = self:fluidOf(
        detail.name,
        function() return detail end
    )
    if fluid ~= nil then
        item.fluid = fluid
    end
    local assessment = assessItem(
        item,
        self:presentFluids(smeltery),
        self:planContext()
    )
    local forced = request.force == true
    if assessment.status == "unknown" then
        error(
            __TS__New(EmberError, detail.name .. " melts into no known fluid", "SMELTERY_ERROR"),
            0
        )
    end
    if assessment.status == "heat" and not forced then
        error(
            __TS__New(
                EmberError,
                ((((detail.name .. " needs ") .. tostring(assessment.temperature or "?")) .. " K, the fuel gives ") .. tostring(self.heat or "?")) .. " K",
                "SMELTERY_ERROR"
            ),
            0
        )
    end
    if assessment.status == "alloy" and not forced then
        error(
            __TS__New(EmberError, (detail.name .. " would form ") .. (assessment.alloy or "an alloy"), "SMELTERY_ERROR"),
            0
        )
    end
    local moved = smeltery:insert(input, request.slot, request.count)
    if forced and assessment.status ~= "ok" then
        local why = assessment.status == "alloy" and ____exports.Controller:shortName(assessment.alloy or "an alloy") or ("needs " .. tostring(assessment.temperature or "?")) .. " K"
        self:log(((((("FORCED insert " .. tostring(moved)) .. " ") .. detail.name) .. " (") .. why) .. ")")
    else
        self:log((("inserted " .. tostring(moved)) .. " ") .. detail.name)
    end
    return moved
end
function Controller.prototype.cast(self, request)
    self:requireManual()
    local smeltery = self.smeltery
    if smeltery == nil then
        error(
            __TS__New(EmberError, "Smeltery missing", "SMELTERY_ERROR"),
            0
        )
    end
    local candidates = __TS__ArrayFilter(
        self.casters,
        function(____, caster)
            local ____temp_2
            if request.caster ~= nil then
                ____temp_2 = caster.name == request.caster
            else
                ____temp_2 = request.format ~= nil and caster:read().format == request.format
            end
            return ____temp_2
        end
    )
    if #candidates == 0 then
        error(
            __TS__New(EmberError, "no caster " .. (request.caster or request.format or ""), "SMELTERY_ERROR"),
            0
        )
    end
    for ____, caster in ipairs(candidates) do
        local moved = caster:pour(smeltery, request.fluid)
        if moved > 0 then
            self:log((((("poured " .. tostring(moved)) .. " mB ") .. ____exports.Controller:shortName(request.fluid)) .. " into ") .. caster.name)
            return moved
        end
    end
    error(
        __TS__New(
            EmberError,
            ("cannot cast " .. ____exports.Controller:shortName(request.fluid)) .. " now (casters busy, or not enough fluid)",
            "SMELTERY_ERROR"
        ),
        0
    )
end
function Controller.prototype.serve(self, channel)
    channel:on(
        Messages.getState,
        function() return self.state end
    )
    channel:on(
        Messages.setMode,
        function(____, payload)
            local mode = payload and payload.mode
            if not __TS__ArrayIncludes(MODES, mode) then
                error(
                    __TS__New(
                        EmberError,
                        "unknown mode " .. tostring(mode),
                        "SMELTERY_ERROR"
                    ),
                    0
                )
            end
            self:setMode(mode)
            self.tickWanted = true
            return self.state
        end
    )
    channel:on(
        Messages.insert,
        function(____, payload)
            self:insert(payload)
            self.tickWanted = true
            return self.state
        end
    )
    channel:on(
        Messages.cast,
        function(____, payload)
            self:cast(payload)
            self.tickWanted = true
            return self.state
        end
    )
    channel:on(
        Messages.setAlloy,
        function(____, payload)
            self:setAlloy(payload)
            self.tickWanted = true
            return self.state
        end
    )
    channel:on(
        Messages.setFormat,
        function(____, payload)
            self:setFormat(payload)
            self.tickWanted = true
            return self.state
        end
    )
end
function Controller.prototype.wantsTick(self)
    return self.tickWanted
end
function Controller.prototype.connect(self)
    self.network = discoverNetwork(self.config)
    self.needsDiscovery = false
    local ____self_network_5 = self.network
    local drain = ____self_network_5.drain
    local chute = ____self_network_5.chute
    local input = ____self_network_5.input
    local output = ____self_network_5.output
    self.smeltery = drain ~= nil and chute ~= nil and Smeltery:fromNames(drain, chute) or nil
    self.input = input ~= nil and Inventory:fromName(input) or nil
    self.output = output ~= nil and Inventory:fromName(output) or nil
    local assignments = {}
    for ____, entry in ipairs(self.config.assignments) do
        assignments[entry.reservoir] = entry.fluid
    end
    self.pool = __TS__New(
        ReservoirPool,
        self.network.reservoirs,
        {
            capacities = loadCapacities(),
            assignments = assignments
        }
    )
    local ____self_network_6 = self.network
    local heatOutput = ____self_network_6.heatOutput
    local unknownOutput = ____self_network_6.unknownOutput
    local fuelTank = ____self_network_6.fuelTank
    self.fuelTank = fuelTank ~= nil and Tank:fromName(fuelTank) or nil
    self.heatOutput = heatOutput ~= nil and Inventory:fromName(heatOutput) or nil
    self.unknownOutput = unknownOutput ~= nil and Inventory:fromName(unknownOutput) or nil
    self.casters = __TS__ArrayMap(
        self.network.casters,
        function(____, name) return Caster:fromName(name, self.amounts) end
    )
    self:log((("network: " .. tostring(#self.casters)) .. " caster(s)") .. (#self.network.problems > 0 and (", " .. tostring(#self.network.problems)) .. " problem(s)" or ""))
    for ____, caster in ipairs(self.casters) do
        do
            local function ____catch(____error)
                ____exports.Controller:passTerminate(____error)
                self:log(((("  " .. caster.name) .. ": unreadable (") .. ____exports.Controller:messageOf(____error)) .. ")")
            end
            local ____try, ____hasReturned = pcall(function()
                local state = caster:read()
                self:log((("  " .. caster.name) .. ": ") .. (state.format or (state.cast ~= nil and "unknown cast " .. state.cast or "no cast")))
            end)
            if not ____try then
                ____catch(____hasReturned)
            end
        end
    end
end
function Controller.prototype.read(self)
    local smeltery = self.smeltery
    if smeltery == nil then
        return nil
    end
    local present = self:readPresent(smeltery)
    local states = {}
    if #self.casters > 0 then
        Parallel:all(unpack(__TS__ArrayMap(
            self.casters,
            function(____, caster, index) return function()
                states[index + 1] = caster:read()
            end end
        )))
    end
    local outputUsed = self.output ~= nil and ____exports.Controller:usedSlots(self.output) or 0
    local outputSize = self.output ~= nil and self:sizeOf(self.output) or 0
    local pool = self.pool
    if pool ~= nil then
        pool:refresh()
    end
    local snapshot = {
        stored = ____exports.Controller:storedFluids(pool),
        storable = __TS__ArrayMap(
            __TS__ArrayFilter(
                present.fluids,
                function(____, fluid) return (pool and pool:canStore(fluid.name)) == true end
            ),
            function(____, fluid) return fluid.name end
        ),
        fluids = present.fluids,
        meltingFluids = present.melting,
        casters = __TS__ArrayMap(
            self.casters,
            function(____, caster, index) return {name = caster.name, state = states[index + 1]} end
        ),
        input = {},
        outputFree = outputSize - outputUsed
    }
    if present.uncertain then
        snapshot.uncertain = true
    end
    local input = self.input
    if input ~= nil then
        for slot, item in pairs(input:list()) do
            local entry = {slot = slot, name = item.name, count = item.count}
            local fluid = self:fluidOf(
                item.name,
                function() return input:getItem(slot) end
            )
            if fluid ~= nil then
                entry.fluid = fluid
            end
            local ____snapshot_input_11 = snapshot.input
            ____snapshot_input_11[#____snapshot_input_11 + 1] = entry
        end
        __TS__ArraySort(
            snapshot.input,
            function(____, a, b) return a.slot - b.slot end
        )
    end
    local reading = {
        fluids = present.fluids,
        melting = present.items,
        casters = __TS__ArrayMap(
            self.casters,
            function(____, caster, index) return ____exports.Controller:viewOf(caster, states[index + 1]) end
        )
    }
    if input ~= nil then
        reading.input = {
            name = input.name,
            size = self:sizeOf(input),
            used = #snapshot.input
        }
    end
    if self.output ~= nil then
        reading.output = {name = self.output.name, size = outputSize, used = outputUsed}
    end
    self.lastRead = reading
    return snapshot
end
function Controller.prototype.checkIdle(self, plan, snapshot)
    if self.mode ~= "auto" and self.mode ~= "alloy" and self.mode ~= "melt" then
        self.quietSince = nil
        return
    end
    local busy = #plan.actions > 0 or #snapshot.meltingFluids > 0 or __TS__ArraySome(
        snapshot.casters,
        function(____, caster) return caster.state.status == "busy" end
    )
    if busy or self.quietSince == nil then
        self.quietSince = os.clock()
        return
    end
    local seconds = self.config.idleSeconds
    if seconds > 0 and os.clock() - self.quietSince >= seconds then
        self:log(("nothing to do for " .. tostring(seconds)) .. " s: drain, then idle")
        self:setMode("drain")
    end
end
function Controller.ends(self, mode)
    return mode == "drain" or mode == "purge" or mode == "alloy"
end
function Controller.prototype.finish(self)
    if self.mode == "drain" then
        self:log("drain finished")
        self:setMode("idle")
    elseif self.mode == "purge" or self.mode == "alloy" then
        local ____self_log_15 = self.log
        local ____temp_14
        if self.mode == "purge" then
            ____temp_14 = "purge finished"
        else
            local ____opt_12 = self.alloy
            ____temp_14 = ("alloy finished: " .. tostring(____opt_12 and ____opt_12.made or 0)) .. " mB cast"
        end
        ____self_log_15(self, ____temp_14)
        self:setMode(____exports.Controller:ends(self.previousMode) and "idle" or self.previousMode)
    end
end
function Controller.storedFluids(self, pool)
    local stored = {}
    for ____, view in ipairs(pool and pool:views() or ({})) do
        do
            local __continue102
            repeat
                if view.fluid == nil then
                    __continue102 = true
                    break
                end
                local entry = __TS__ArrayFind(
                    stored,
                    function(____, candidate) return candidate.fluid == view.fluid end
                )
                if entry ~= nil then
                    entry.amount = entry.amount + view.amount
                else
                    stored[#stored + 1] = {fluid = view.fluid, amount = view.amount}
                end
                __continue102 = true
            until true
            if not __continue102 then
                break
            end
        end
    end
    return stored
end
function Controller.prototype.refreshReading(self)
    local reading = self.lastRead
    local smeltery = self.smeltery
    if reading == nil or smeltery == nil then
        return
    end
    local states = {}
    local tasks = __TS__ArrayMap(
        self.casters,
        function(____, caster, index) return function()
            states[index + 1] = caster:read()
        end end
    )
    tasks[#tasks + 1] = function()
        reading.fluids = smeltery:fluids()
    end
    tasks[#tasks + 1] = function()
        reading.melting = smeltery:melting()
    end
    if self.input ~= nil and reading.input ~= nil then
        local input = self.input
        local view = reading.input
        tasks[#tasks + 1] = function()
            view.used = ____exports.Controller:usedSlots(input)
        end
    end
    if self.output ~= nil and reading.output ~= nil then
        local output = self.output
        local view = reading.output
        tasks[#tasks + 1] = function()
            view.used = ____exports.Controller:usedSlots(output)
        end
    end
    Parallel:all(unpack(tasks))
    reading.casters = __TS__ArrayMap(
        self.casters,
        function(____, caster, index) return ____exports.Controller:viewOf(caster, states[index + 1]) end
    )
end
function Controller.prototype.execute(self, plan)
    local smelteryFull = false
    for ____, action in ipairs(plan.actions) do
        do
            local __continue120
            repeat
                if action.kind == "insert" and smelteryFull then
                    ____exports.Controller:addWaiting(plan.waiting, action.name, action.count)
                    __continue120 = true
                    break
                end
                local left = self:apply(action)
                if action.kind == "insert" and left > 0 then
                    smelteryFull = true
                    ____exports.Controller:addWaiting(plan.waiting, action.name, left)
                end
                if action.kind == "reject" and left > 0 then
                    local ____plan_alerts_18 = plan.alerts
                    ____plan_alerts_18[#____plan_alerts_18 + 1] = ((((action.reason .. " output full: ") .. tostring(left)) .. " ") .. action.name) .. " left in the input"
                end
                __continue120 = true
            until true
            if not __continue120 then
                break
            end
        end
    end
end
function Controller.prototype.apply(self, action)
    local smeltery = self.smeltery
    repeat
        local ____switch126 = action.kind
        local ____cond126 = ____switch126 == "collect"
        if ____cond126 then
            do
                local caster = __TS__ArrayFind(
                    self.casters,
                    function(____, candidate) return candidate.name == action.caster end
                )
                local output = self.output
                if caster == nil or output == nil then
                    return 0
                end
                local moved = caster:collect(output)
                if moved > 0 then
                    self:log((("collected " .. tostring(moved)) .. " from ") .. caster.name)
                end
                return 0
            end
        end
        ____cond126 = ____cond126 or ____switch126 == "pour"
        if ____cond126 then
            do
                local caster = __TS__ArrayFind(
                    self.casters,
                    function(____, candidate) return candidate.name == action.caster end
                )
                if caster == nil then
                    return 0
                end
                local moved = caster:pour(smeltery, action.fluid)
                if moved > 0 then
                    self:log((((("poured " .. tostring(moved)) .. " mB ") .. ____exports.Controller:shortName(action.fluid)) .. " into ") .. caster.name)
                end
                local alloy = self.alloy
                if moved > 0 and self.mode == "alloy" and alloy ~= nil and alloy.result == action.fluid then
                    alloy.made = alloy.made + moved
                    saveAlloy(alloy)
                end
                return 0
            end
        end
        ____cond126 = ____cond126 or ____switch126 == "reject"
        if ____cond126 then
            do
                local ____temp_19
                if action.reason == "heat" then
                    ____temp_19 = self.heatOutput
                else
                    ____temp_19 = self.unknownOutput
                end
                local target = ____temp_19
                if target == nil then
                    return action.count
                end
                local moved = self.input:pushTo(target, action.slot, action.count)
                if moved > 0 then
                    local why = action.reason == "heat" and ("needs " .. tostring(action.temperature or "?")) .. " K" or "melts into nothing known"
                    self:log(((((((("moved " .. tostring(moved)) .. " ") .. action.name) .. " to ") .. target.name) .. " (") .. why) .. ")")
                end
                return action.count - moved
            end
        end
        ____cond126 = ____cond126 or ____switch126 == "store"
        if ____cond126 then
            do
                local pool = self.pool
                if pool == nil then
                    return 0
                end
                local amount = math.min(
                    action.amount,
                    smeltery:amountOf(action.fluid)
                )
                if amount <= 0 then
                    return 0
                end
                local before = textutils.serialise(pool:capacities())
                local stored = pool:store(smeltery.drain, action.fluid, amount)
                if stored > 0 then
                    self:log(((((("stored " .. tostring(stored)) .. " mB ") .. ____exports.Controller:shortName(action.fluid)) .. " (") .. action.why) .. ")")
                end
                if stored < amount then
                    self:log((("no room left for " .. tostring(amount - stored)) .. " mB ") .. ____exports.Controller:shortName(action.fluid))
                end
                if textutils.serialise(pool:capacities()) ~= before then
                    saveCapacities(pool:capacities())
                end
                return 0
            end
        end
        ____cond126 = ____cond126 or ____switch126 == "restore"
        if ____cond126 then
            do
                local ____opt_20 = self.pool
                local taken = ____opt_20 and ____opt_20:take(smeltery.drain, action.fluid, action.amount) or 0
                local ____temp_27
                if action.why == "stock" then
                    ____temp_27 = "from the stock"
                else
                    local ____temp_26
                    if action.why == "alloy" then
                        local ____exports_Controller_24 = ____exports.Controller
                        local ____exports_Controller_shortName_25 = ____exports.Controller.shortName
                        local ____opt_22 = self.alloy
                        ____temp_26 = "for " .. ____exports_Controller_shortName_25(____exports_Controller_24, ____opt_22 and ____opt_22.result or "the alloy")
                    else
                        ____temp_26 = "to complete a cast"
                    end
                    ____temp_27 = ____temp_26
                end
                local why = ____temp_27
                if taken > 0 then
                    self:log((((("restored " .. tostring(taken)) .. " mB ") .. ____exports.Controller:shortName(action.fluid)) .. " ") .. why)
                end
                return 0
            end
        end
        do
            do
                local moved = smeltery:insert(self.input, action.slot, action.count)
                if moved > 0 then
                    local seen = table.concat(
                        __TS__ArrayMap(
                            action.seen,
                            function(____, fluid) return ____exports.Controller:shortName(fluid) end
                        ),
                        ", "
                    )
                    self:log(((((("inserted " .. tostring(moved)) .. " ") .. action.name) .. " (seen: ") .. (seen == "" and "nothing" or seen)) .. ")")
                end
                return action.count - moved
            end
        end
    until true
end
function Controller.prototype.fluidOf(self, name, detail)
    local fluid = self.fluidCache:get(name)
    if fluid == nil then
        local item = detail(nil)
        if item == nil or item.name ~= name then
            return nil
        end
        fluid = self.materials:fluidOf(item) or false
        self.fluidCache:set(name, fluid)
    end
    local ____temp_28
    if fluid == false then
        ____temp_28 = nil
    else
        ____temp_28 = fluid
    end
    return ____temp_28
end
function Controller.prototype.planContext(self)
    local context = {
        guard = self.guard,
        amounts = self.amounts,
        formatPriority = self.config.formatPriority,
        meltingTemperature = function(____, fluid) return self.meltingTemperatures:get(fluid) end,
        reject = {heat = self.heatOutput ~= nil, unknown = self.unknownOutput ~= nil},
        isAlloy = function(____, fluid) return self.alloyResults:has(fluid) end
    }
    if self.heat ~= nil then
        context.fuelTemperature = self.heat
    end
    local alloy = self.alloy
    if alloy ~= nil then
        context.alloy = {
            result = alloy.result,
            ratios = __TS__ArrayFilter(
                self.alloyRatios,
                function(____, ratio) return ratio.result == alloy.result end
            )
        }
        if alloy.target ~= nil then
            context.alloy.remaining = alloy.target - alloy.made
        end
    end
    return context
end
function Controller.prototype.readFuel(self, alerts)
    self.fuel = nil
    self.heat = self.fallbackHeat
    if self.fuelTank == nil then
        if self.fallbackHeat == nil then
            alerts[#alerts + 1] = ("unknown fuel '" .. self.config.fuel) .. "': melting temperatures not checked"
        end
        return nil
    end
    local fluid = unpack(
        self.fuelTank:getFluids(),
        1,
        1
    )
    self.fuel = {amount = fluid and fluid.amount or 0}
    if fluid == nil then
        alerts[#alerts + 1] = "fuel tank empty: input paused"
        return "fuel tank empty: input paused"
    end
    self.fuel.fluid = fluid.name
    local temperature = self.fuelTemperatures:get(fluid.name)
    if temperature == nil then
        alerts[#alerts + 1] = (("unknown fuel '" .. fluid.name) .. "': assuming ") .. self.config.fuel
        return nil
    end
    self.fuel.temperature = temperature
    self.heat = temperature
    return nil
end
function Controller.prototype.readPresent(self, smeltery)
    local items = smeltery.chute:list()
    local fluids = smeltery:fluids()
    local melting = {}
    local summaries = {}
    local uncertain = false
    for slot, item in pairs(items) do
        summaries[#summaries + 1] = {name = item.name, count = item.count}
        local fluid = self:fluidOf(
            item.name,
            function() return smeltery.chute:getItem(slot) end
        )
        if fluid == nil and not self.fluidCache:has(item.name) then
            uncertain = true
        elseif fluid ~= nil and not __TS__ArrayIncludes(melting, fluid) then
            melting[#melting + 1] = fluid
        end
    end
    return {fluids = fluids, melting = melting, items = summaries, uncertain = uncertain}
end
function Controller.prototype.presentFluids(self, smeltery)
    local present = self:readPresent(smeltery)
    if present.uncertain then
        error(
            __TS__New(EmberError, "the Smeltery content cannot be told right now, try again", "SMELTERY_ERROR"),
            0
        )
    end
    local ____array_31 = __TS__SparseArrayNew(unpack(present.melting))
    __TS__SparseArrayPush(
        ____array_31,
        unpack(__TS__ArrayMap(
            present.fluids,
            function(____, fluid) return fluid.name end
        ))
    )
    return {__TS__SparseArraySpread(____array_31)}
end
function Controller.prototype.requireManual(self)
    if self.mode ~= "manual" then
        error(
            __TS__New(EmberError, ("manual commands need manual mode (now " .. self.mode) .. ")", "SMELTERY_ERROR"),
            0
        )
    end
end
function Controller.prototype.buildState(self, alerts, waiting)
    local ____self_mode_34 = self.mode
    local ____os_epoch_result_35 = os.epoch("utc")
    local ____temp_36 = {}
    local ____temp_37 = {}
    local ____temp_38 = {}
    local ____waiting_39 = waiting
    local ____alerts_40 = alerts
    local ____temp_41 = {unpack(self.logLines)}
    local ____self_inputItems_42 = self.inputItems
    local ____self_config_formatPriority_43 = self.config.formatPriority
    local ____opt_32 = self.pool
    local state = {
        mode = ____self_mode_34,
        time = ____os_epoch_result_35,
        fluids = ____temp_36,
        melting = ____temp_37,
        casters = ____temp_38,
        waiting = ____waiting_39,
        alerts = ____alerts_40,
        log = ____temp_41,
        inputItems = ____self_inputItems_42,
        autoFormats = ____self_config_formatPriority_43,
        reservoirs = ____opt_32 and ____opt_32:views() or ({}),
        alloyOptions = self:alloyOptions()
    }
    if self.alloy ~= nil then
        state.alloy = __TS__ObjectAssign({}, self.alloy)
    end
    if self.fuel ~= nil then
        state.fuel = self.fuel
    end
    if self.heat ~= nil then
        state.heat = self.heat
    end
    local reading = self.lastRead
    if reading ~= nil then
        state.fluids = reading.fluids
        state.melting = reading.melting
        state.casters = reading.casters
        if reading.input ~= nil then
            state.input = reading.input
        end
        if reading.output ~= nil then
            state.output = reading.output
        end
    end
    return state
end
function Controller.prototype.alloyOptions(self)
    local stored = ____exports.Controller:storedFluids(self.pool)
    local function stockOf(____, fluid)
        local ____opt_44 = __TS__ArrayFind(
            stored,
            function(____, entry) return entry.fluid == fluid end
        )
        return ____opt_44 and ____opt_44.amount or 0
    end
    local options = {}
    for ____, ratio in ipairs(self.alloyRatios) do
        do
            local __continue185
            repeat
                local batches = math.min(unpack(__TS__ArrayMap(
                    ratio.inputs,
                    function(____, input) return math.floor(stockOf(nil, input.fluid) / input.amount) end
                )))
                local fromStock = math.max(0, batches) * ratio.amount
                local existing = __TS__ArrayFind(
                    options,
                    function(____, option) return option.result == ratio.result end
                )
                if existing ~= nil and existing.fromStock >= fromStock then
                    __continue185 = true
                    break
                end
                local option = {result = ratio.result, amount = ratio.amount, inputs = ratio.inputs, fromStock = fromStock}
                local temperature = self.meltingTemperatures:get(ratio.result)
                local heat = self.heat or self.fallbackHeat
                if temperature ~= nil and heat ~= nil and temperature > heat then
                    option.temperature = temperature
                end
                if existing ~= nil then
                    options[__TS__ArrayIndexOf(options, existing) + 1] = option
                else
                    options[#options + 1] = option
                end
                __continue185 = true
            until true
            if not __continue185 then
                break
            end
        end
    end
    return __TS__ArraySort(
        options,
        function(____, a, b)
            if a.fromStock ~= b.fromStock then
                return b.fromStock - a.fromStock
            end
            return a.result < b.result and -1 or (a.result > b.result and 1 or 0)
        end
    )
end
function Controller.prototype.emptyState(self)
    return {
        mode = self.mode,
        time = 0,
        fluids = {},
        melting = {},
        casters = {},
        inputItems = {},
        autoFormats = self.config.formatPriority,
        reservoirs = {},
        alloyOptions = self:alloyOptions(),
        waiting = {},
        alerts = {},
        log = {}
    }
end
function Controller.prototype.log(self, line)
    local stamped = (tostring(os.date("%H:%M:%S")) .. " ") .. line
    print(stamped)
    local ____self_logLines_46 = self.logLines
    ____self_logLines_46[#____self_logLines_46 + 1] = stamped
    if self.logFile ~= nil then
        local file = fs.open(self.logFile, "a")
        if file ~= nil then
            file.writeLine(stamped)
            file.close()
        end
    end
    while #self.logLines > self.config.logSize do
        table.remove(self.logLines, 1)
    end
end
function Controller.viewOf(self, caster, state)
    local view = {name = caster.name, kind = caster.kind, status = state.status, amount = state.amount}
    if state.format ~= nil then
        view.format = state.format
    end
    if state.fluid ~= nil then
        view.fluid = state.fluid
    end
    if state.output ~= nil then
        view.output = state.output
    end
    return view
end
function Controller.prototype.sizeOf(self, inventory)
    local size = self.sizes:get(inventory.name)
    if size == nil then
        size = inventory:size()
        self.sizes:set(inventory.name, size)
    end
    return size
end
function Controller.usedSlots(self, inventory)
    local used = 0
    for _slot in pairs(inventory:list()) do
        used = used + 1
    end
    return used
end
function Controller.addWaiting(self, waiting, name, count)
    for ____, item in ipairs(waiting) do
        if item.name == name and item.reason == "full" then
            item.count = item.count + count
            return
        end
    end
    waiting[#waiting + 1] = {name = name, count = count, reason = "full"}
end
function Controller.shortName(self, fluid)
    local colon = (string.find(fluid, ":", nil, true) or 0) - 1
    return colon >= 0 and __TS__StringSubstring(fluid, colon + 1) or fluid
end
function Controller.passTerminate(self, ____error)
    if ____error == "Terminated" then
        error(____error, 0)
    end
end
function Controller.messageOf(self, ____error)
    return __TS__InstanceOf(____error, Error) and ____error.message or tostring(____error)
end
local WAKE_EVENT = "smeltery_message"
function ____exports.runController()
    local config = loadControllerConfig()
    local controller = __TS__New(
        ____exports.Controller,
        config,
        loadCatalogue()
    )
    controller:setLogFile("/smeltery/controller.log")
    controller:setConfigPath(CONFIG_PATH)
    local channel = __TS__New(Channel, {protocol = PROTOCOL})
    local online = false
    do
        local function ____catch(____error)
            print(("No rednet (" .. (__TS__InstanceOf(____error, Error) and ____error.message or tostring(____error))) .. "): running without the display")
        end
        local ____try, ____hasReturned = pcall(function()
            channel:open()
            channel:host(CONTROLLER_HOSTNAME)
            online = true
        end)
        if not ____try then
            ____catch(____hasReturned)
        end
    end
    controller:serve(channel)
    local inbox = {}
    local function listen()
        while true do
            do
                local __continue220
                repeat
                    local event = {os.pullEvent("rednet_message")}
                    if event[4] ~= PROTOCOL then
                        __continue220 = true
                        break
                    end
                    inbox[#inbox + 1] = event
                    os.queueEvent(WAKE_EVENT)
                    __continue220 = true
                until true
                if not __continue220 then
                    break
                end
            end
        end
    end
    local function loop()
        local lastSent = ""
        local lastSentClock = -math.huge
        local timer = os.startTimer(0)
        while true do
            do
                local __continue223
                repeat
                    local event = {os.pullEvent()}
                    while #inbox > 0 do
                        channel:handleEvent(table.remove(inbox, 1))
                    end
                    local timerDue = event[1] == "timer" and event[2] == timer
                    if not timerDue and not controller:wantsTick() then
                        __continue223 = true
                        break
                    end
                    if not timerDue then
                        os.cancelTimer(timer)
                    end
                    controller:tick()
                    timer = os.startTimer(config.tickSeconds)
                    if not online then
                        __continue223 = true
                        break
                    end
                    local state = controller:getState()
                    local text = textutils.serialise(__TS__ObjectAssign({}, state, {time = 0}))
                    if text ~= lastSent or os.clock() - lastSentClock >= config.heartbeatSeconds then
                        channel:broadcast(Messages.state, state)
                        lastSent = text
                        lastSentClock = os.clock()
                    end
                    __continue223 = true
                until true
                if not __continue223 then
                    break
                end
            end
        end
    end
    Parallel:any(loop, listen)
end
return ____exports
