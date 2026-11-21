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

local __TS__StringSplit
do
    local sub = string.sub
    local find = string.find
    function __TS__StringSplit(source, separator, limit)
        if limit == nil then
            limit = 4294967295
        end
        if limit == 0 then
            return {}
        end
        local result = {}
        local resultIndex = 1
        if separator == nil or separator == "" then
            for i = 1, #source do
                result[resultIndex] = sub(source, i, i)
                resultIndex = resultIndex + 1
            end
        else
            local currentPos = 1
            while resultIndex <= limit do
                local startPos, endPos = find(source, separator, currentPos, true)
                if not startPos then
                    break
                end
                result[resultIndex] = sub(source, currentPos, startPos - 1)
                resultIndex = resultIndex + 1
                currentPos = endPos + 1
            end
            if resultIndex <= limit then
                result[resultIndex] = sub(source, currentPos)
            end
        end
        return result
    end
end

local function __TS__ArraySlice(self, first, last)
    local len = #self
    first = first or 0
    if first < 0 then
        first = len + first
        if first < 0 then
            first = 0
        end
    else
        if first > len then
            first = len
        end
    end
    last = last or len
    if last < 0 then
        last = len + last
        if last < 0 then
            last = 0
        end
    else
        if last > len then
            last = len
        end
    end
    local out = {}
    first = first + 1
    last = last + 1
    local n = 1
    while first < last do
        out[n] = self[first]
        first = first + 1
        n = n + 1
    end
    return out
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

local function __TS__ArrayForEach(self, callbackFn, thisArg)
    for i = 1, #self do
        callbackFn(thisArg, self[i], i - 1, self)
    end
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

local function __TS__StringCharAt(self, pos)
    if pos ~= pos then
        pos = 0
    end
    if pos < 0 then
        return ""
    end
    return string.sub(self, pos + 1, pos + 1)
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

local function __TS__ArrayMap(self, callbackfn, thisArg)
    local result = {}
    for i = 1, #self do
        result[i] = callbackfn(thisArg, self[i], i - 1, self)
    end
    return result
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

local function __TS__ArrayFind(self, predicate, thisArg)
    for i = 1, #self do
        local elem = self[i]
        if predicate(thisArg, elem, i - 1, self) then
            return elem
        end
    end
    return nil
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

local function __TS__ArrayReverse(self)
    local i = 1
    local j = #self
    while i < j do
        local temp = self[j]
        self[j] = self[i]
        self[i] = temp
        i = i + 1
        j = j - 1
    end
    return self
end

local function __TS__StringPadEnd(self, maxLength, fillString)
    if fillString == nil then
        fillString = " "
    end
    if maxLength ~= maxLength then
        maxLength = 0
    end
    if maxLength == -math.huge or maxLength == math.huge then
        error("Invalid string length", 0)
    end
    if #self >= maxLength or #fillString == 0 then
        return self
    end
    maxLength = maxLength - #self
    if maxLength > #fillString then
        fillString = fillString .. string.rep(
            fillString,
            math.floor(maxLength / #fillString)
        )
    end
    return self .. string.sub(
        fillString,
        1,
        math.floor(maxLength)
    )
end

local function __TS__ArraySome(self, callbackfn, thisArg)
    for i = 1, #self do
        if callbackfn(thisArg, self[i], i - 1, self) then
            return true
        end
    end
    return false
end

local function __TS__ArrayReduce(self, callbackFn, ...)
    local len = #self
    local k = 0
    local accumulator = nil
    if __TS__CountVarargs(...) ~= 0 then
        accumulator = ...
    elseif len > 0 then
        accumulator = self[1]
        k = 1
    else
        error("Reduce of empty array with no initial value", 0)
    end
    for i = k + 1, len do
        accumulator = callbackFn(
            nil,
            accumulator,
            self[i],
            i - 1,
            self
        )
    end
    return accumulator
end

local function __TS__StringPadStart(self, maxLength, fillString)
    if fillString == nil then
        fillString = " "
    end
    if maxLength ~= maxLength then
        maxLength = 0
    end
    if maxLength == -math.huge or maxLength == math.huge then
        error("Invalid string length", 0)
    end
    if #self >= maxLength or #fillString == 0 then
        return self
    end
    maxLength = maxLength - #self
    if maxLength > #fillString then
        fillString = fillString .. string.rep(
            fillString,
            math.floor(maxLength / #fillString)
        )
    end
    return string.sub(
        fillString,
        1,
        math.floor(maxLength)
    ) .. self
end

local function __TS__StringStartsWith(self, searchString, position)
    if position == nil or position < 0 then
        position = 0
    end
    return string.sub(self, position + 1, #searchString + position) == searchString
end
-- End of Lua Library inline imports
local ____exports = {}
local ____index = require("modules.fluids.index")
local ReservoirView = ____index.ReservoirView
local ____index = require("modules.tinkers.index")
local AlloyRatio = ____index.AlloyRatio
local ____components = require("modules.ui.components")
local ButtonComponent = ____components.ButtonComponent
local PaginationComponent = ____components.PaginationComponent
local ____types = require("modules.ui.types.index")
local Rect = ____types.Rect
local ____protocol = require("projects.smeltery.shared.protocol")
local AlloyOption = ____protocol.AlloyOption
local CraftCasterView = ____protocol.CraftCasterView
local CraftRecipeView = ____protocol.CraftRecipeView
local DeleteRecipeRequest = ____protocol.DeleteRecipeRequest
local InputItemView = ____protocol.InputItemView
local QueueCraftRequest = ____protocol.QueueCraftRequest
local TrashFluidRequest = ____protocol.TrashFluidRequest
local InsertRequest = ____protocol.InsertRequest
local Mode = ____protocol.Mode
local OrderView = ____protocol.OrderView
local QueueOrderRequest = ____protocol.QueueOrderRequest
local SaveRecipeRequest = ____protocol.SaveRecipeRequest
local SetAlloyRequest = ____protocol.SetAlloyRequest
local SetReservoirRequest = ____protocol.SetReservoirRequest
local SetFormatRequest = ____protocol.SetFormatRequest
local SetSmelteryCapacityRequest = ____protocol.SetSmelteryCapacityRequest
local SmelteryState = ____protocol.SmelteryState
local ____protocol = require("projects.smeltery.shared.protocol")
local MAX_INGREDIENTS = ____protocol.MAX_INGREDIENTS
local MODES = ____protocol.MODES
local ____recipes = require("projects.smeltery.shared.recipes")
local recipeProblem = ____recipes.recipeProblem
local ____model = require("projects.smeltery.display.model")
local attentionLines = ____model.attentionLines
local fit = ____model.fit
local fluidColor = ____model.fluidColor
local fluidLabel = ____model.fluidLabel
local formatLabel = ____model.formatLabel
local Glyph = ____model.Glyph
local groupCasters = ____model.groupCasters
local itemAmount = ____model.itemAmount
local knownFluids = ____model.knownFluids
local parseLogLine = ____model.parseLogLine
local placeLabel = ____model.placeLabel
local ____model = require("projects.smeltery.display.model")
local CastGroup = ____model.CastGroup
local LogKind = ____model.LogKind
local LogLine = ____model.LogLine
local ____widgets = require("projects.smeltery.display.widgets")
local AbsoluteLayout = ____widgets.AbsoluteLayout
local PaintComponent = ____widgets.PaintComponent
local Pixels = ____widgets.Pixels
local ____widgets = require("projects.smeltery.display.widgets")
local Painter = ____widgets.Painter
____exports.SCREEN_WIDTH = 100
____exports.SCREEN_HEIGHT = 52
____exports.PALETTE = {
    {colors.black, 723742},
    {colors.green, 1710660},
    {colors.gray, 5263498},
    {colors.lightGray, 13158624},
    {colors.white, 15263999},
    {colors.cyan, 4124927},
    {colors.magenta, 16727717},
    {colors.yellow, 16769354},
    {colors.purple, 8019199},
    {colors.lime, 5111690},
    {colors.red, 16730714},
    {colors.pink, 16752328},
    {colors.orange, 16747069},
    {colors.blue, 4025343},
    {colors.lightBlue, 9419007},
    {colors.brown, 10514506}
}
local N = {
    bg = colors.black,
    panel = colors.green,
    dim = colors.gray,
    soft = colors.lightGray,
    text = colors.white,
    cyan = colors.cyan,
    magenta = colors.magenta,
    yellow = colors.yellow,
    purple = colors.purple,
    lime = colors.lime,
    red = colors.red,
    orange = colors.orange
}
local TABS = {
    {"overview", "OVERVIEW"},
    {"modes", "MODES"},
    {"manual", "MANUAL"},
    {"stock", "STOCK"},
    {"log", "LOG"}
}
local TABS_X = 34
local MODE_COLORS = {
    idle = N.soft,
    auto = N.lime,
    manual = N.yellow,
    lock = N.red,
    drain = N.cyan,
    purge = N.purple,
    alloy = N.magenta,
    melt = colors.lightBlue
}
local MODE_LINES = {
    idle = {"Full stop.", "Nothing moves."},
    auto = {"Melts the input and", "casts pure metals", "into AUTO casts."},
    manual = {"You insert and cast", "from the Manual tab."},
    lock = {"Nothing new goes in;", "casts under way", "finish."},
    drain = {"Every fluid to the", "reservoirs, then", "idle."},
    purge = {"Leftovers and", "alloys to the", "reservoirs."},
    alloy = {},
    melt = {"Melts the input", "into the stock,", "casts nothing."}
}
local LOG_COLORS = {
    ["in"] = N.cyan,
    cast = N.text,
    out = N.lime,
    store = colors.lightBlue,
    stock = N.magenta,
    held = N.yellow,
    forced = N.red,
    mode = N.purple,
    alert = N.red,
    other = N.dim
}
local LOG_FILTERS = {
    {"all", "ALL", N.text},
    {"in", "IN", N.cyan},
    {"cast", "CAST", N.text},
    {"out", "OUT", N.lime},
    {"store", "STORE", colors.lightBlue},
    {"mode", "MODE", N.purple},
    {"alert", "ALERT", N.red}
}
local CASTS_PER_PAGE = 5
local FLUID_ROWS = 10
local FORMAT_ROWS = 5
local FORMAT_PAGE = FORMAT_ROWS * 2
local ORDER_ROWS = 5
local MAX_COUNT = 64
local STACK_ROWS = 4
local CRAFT_CASTERS = 3
local CRAFT_RECIPE_ROWS = 3
local ALLOYS_PER_PAGE = 10
local INGOT = 90
local ITEMS_PER_PAGE = 15
local RESERVOIRS_PER_PAGE = 15
local PICKER_COLUMNS = 4
local PICKER_ROWS = 18
local PICKER_PAGE = PICKER_COLUMNS * PICKER_ROWS
local PICKER_KNOWN = 4
local LETTERS = "abcdefghijklmnopqrstuvwxyz"
local STEPS = {10, 90, 1000}
local CAPACITY_STEPS = {
    10,
    90,
    1000,
    10000,
    100000
}
local MIN_AMOUNT = 10
local CAPACITIES = {
    16000,
    32000,
    64000,
    256000,
    1024000,
    4096000
}
local DEFAULT_CAPACITY = 16000
local FUEL_TANK = 4000
local LOG_LINES = 20
local CONFIRM_SECONDS = 10
local OFFLINE_SECONDS = 12
local function cardPlace(index)
    return {
        x = 3 + index % 4 * 24,
        y = 5 + math.floor(index / 4) * 21
    }
end
local function shortAmount(amount)
    if amount < 1000 then
        return tostring(math.floor(amount + 0.5))
    end
    local thousands = amount / 1000
    return tostring((thousands >= 10 or thousands % 1 == 0) and math.floor(thousands + 0.5) or math.floor(thousands * 10 + 0.5) / 10) .. "k"
end
local function keeps(filter, kind)
    if filter == "all" then
        return true
    end
    if filter == "store" then
        return kind == "store" or kind == "stock"
    end
    if filter == "alert" then
        return kind == "alert" or kind == "forced" or kind == "held"
    end
    return kind == filter
end
local function reservoirLines(name, width)
    local colon = (string.find(name, ":", nil, true) or 0) - 1
    local mod = colon >= 0 and table.concat(
        __TS__StringSplit(
            __TS__StringSubstring(name, 0, colon),
            "_"
        ),
        " "
    ) or ""
    local label = placeLabel(name)
    if #label <= width then
        return {
            label,
            fit(mod, width)
        }
    end
    local words = __TS__StringSplit(label, " ")
    local first = ""
    local index = 0
    while index < #words and (first == "" and #words[index + 1] or #first + 1 + #words[index + 1]) <= width do
        first = first == "" and words[index + 1] or (first .. " ") .. words[index + 1]
        index = index + 1
    end
    if first == "" then
        return {
            fit(label, width),
            fit(mod, width)
        }
    end
    return {
        first,
        fit(
            table.concat(
                __TS__ArraySlice(words, index),
                " "
            ),
            width
        )
    }
end
local FULL_SCREEN = {x = 1, y = 1, width = ____exports.SCREEN_WIDTH, height = ____exports.SCREEN_HEIGHT}
____exports.SmelteryScreen = __TS__Class()
local SmelteryScreen = ____exports.SmelteryScreen
SmelteryScreen.name = "SmelteryScreen"
function SmelteryScreen.prototype.____constructor(self, actions)
    self.actions = actions
    self.root = __TS__New(AbsoluteLayout, ____exports.SCREEN_WIDTH, ____exports.SCREEN_HEIGHT)
    self.lastState = -math.huge
    self.tab = "overview"
    self.castPage = 1
    self.itemPage = 1
    self.fluidPage = 1
    self.formatPage = 1
    self.orderPage = 1
    self.inputDetails = false
    self.counts = __TS__New(Map)
    self.orderView = "cast"
    self.craftCount = 1
    self.stockPage = 1
    self.logPage = 1
    self.logFilter = "all"
    self.capacityStep = 1000
    self.picking = false
    self.alloyPage = 1
    self.choicePage = 1
    self.choosing = false
    self.pickIngots = 16
    self.nonstop = false
    self.allButtons = {}
    self.tabButtons = __TS__New(Map)
    self.modeButtons = __TS__New(Map)
    self.itemButtons = {}
    self.fluidButtons = {}
    self.countLess = {}
    self.countMore = {}
    self.cancelButtons = {}
    self.craftButtons = {}
    self.stackButtons = {}
    self.autoButtons = {}
    self.filterButtons = __TS__New(Map)
    self.capacityStepButtons = {}
    self.alloyButtons = {}
    self.reservoirButtons = {}
    self.pickerButtons = {}
    self.knownButtons = {}
    self.letterButtons = {}
    self.inputButtons = {}
    self.inputLess = {}
    self.inputMore = {}
    self.inputRemove = {}
    self.stepButtons = {}
    self.root:place(
        __TS__New(
            PaintComponent,
            {paint = function(____, painter) return self:paint(painter) end}
        ),
        FULL_SCREEN
    )
    local tabX = TABS_X
    for ____, ____value in ipairs(TABS) do
        local tab = ____value[1]
        local label = ____value[2]
        self.tabButtons:set(
            tab,
            self:button(
                label,
                {x = tabX, y = 2, width = #label, height = 1},
                function() return self:showTab(tab) end
            )
        )
        tabX = tabX + (#label + 4)
    end
    __TS__ArrayForEach(
        MODES,
        function(____, mode, index)
            local card = cardPlace(index)
            self.modeButtons:set(
                mode,
                self:button(
                    " ACTIVATE ",
                    {x = card.x + 2, y = card.y + 16, width = 10, height = 1},
                    function() return self.actions:setMode(mode) end
                )
            )
        end
    )
    self.castPages = self:pagination(
        CASTS_PER_PAGE,
        {x = 86, y = 44, width = 11, height = 1},
        function(____, page)
            self.castPage = page
        end
    )
    do
        local row = 0
        while row < CASTS_PER_PAGE do
            local index = row
            local ____self_autoButtons_0 = self.autoButtons
            ____self_autoButtons_0[#____self_autoButtons_0 + 1] = self:button(
                "",
                {x = 91, y = 26 + index * 3, width = 6, height = 1},
                function() return self:toggleAuto(index) end
            )
            row = row + 1
        end
    end
    do
        local row = 0
        while row < STACK_ROWS do
            local index = row
            local ____self_stackButtons_1 = self.stackButtons
            ____self_stackButtons_1[#____self_stackButtons_1 + 1] = self:button(
                "",
                {x = 6, y = 26 + index * 3, width = 24, height = 1},
                function() return self:askTrashStack(index) end
            )
            row = row + 1
        end
    end
    self.setCapacity = self:button(
        " SET CAPACITY ",
        {x = 6, y = 44, width = 14, height = 1},
        function() return self:openCapacity() end
    )
    self.capacityLessButton = self:button(
        " - ",
        {x = 56, y = 17, width = 3, height = 1},
        function() return self:stepSmelteryCapacity(-1) end
    )
    self.capacityMoreButton = self:button(
        " + ",
        {x = 80, y = 17, width = 3, height = 1},
        function() return self:stepSmelteryCapacity(1) end
    )
    local capacityX = 59
    for ____, step in ipairs(CAPACITY_STEPS) do
        local label = (" " .. tostring(step)) .. " "
        local rect = {x = capacityX, y = 22, width = #label, height = 1}
        local ____self_capacityStepButtons_2 = self.capacityStepButtons
        ____self_capacityStepButtons_2[#____self_capacityStepButtons_2 + 1] = self:button(
            label,
            rect,
            function() return self:setCapacityStep(step) end
        )
        capacityX = capacityX + (#label + 1)
    end
    self.capacitySave = self:button(
        " SAVE ",
        {x = 54, y = 34, width = 6, height = 1},
        function() return self:saveCapacity(false) end
    )
    self.capacityAuto = self:button(
        " AUTO ",
        {x = 63, y = 34, width = 6, height = 1},
        function() return self:saveCapacity(true) end
    )
    self.capacityCancel = self:button(
        " CANCEL ",
        {x = 72, y = 34, width = 8, height = 1},
        function() return self:closeCapacity() end
    )
    self.switchManual = self:button(
        " SWITCH TO MANUAL ",
        {x = 78, y = 6, width = 18, height = 1},
        function() return self.actions:setMode("manual") end
    )
    do
        local row = 0
        while row < FLUID_ROWS do
            local index = row
            local ____self_fluidButtons_3 = self.fluidButtons
            ____self_fluidButtons_3[#____self_fluidButtons_3 + 1] = self:button(
                "",
                {x = 8, y = 7 + index * 2, width = 23, height = 1},
                function() return self:pickFluid(index) end
            )
            row = row + 1
        end
    end
    self.fluidPages = self:pagination(
        FLUID_ROWS,
        {x = 11, y = 27, width = 11, height = 1},
        function(____, page)
            self.fluidPage = page
            self:sync()
        end
    )
    do
        local cell = 0
        while cell < FORMAT_PAGE do
            local index = cell
            local place = ____exports.SmelteryScreen:formatPlace(index)
            local ____self_countLess_4 = self.countLess
            ____self_countLess_4[#____self_countLess_4 + 1] = self:button(
                " - ",
                {x = place.x + 20, y = place.y, width = 3, height = 1},
                function() return self:stepCount(index, -1) end
            )
            local ____self_countMore_5 = self.countMore
            ____self_countMore_5[#____self_countMore_5 + 1] = self:button(
                " + ",
                {x = place.x + 27, y = place.y, width = 3, height = 1},
                function() return self:stepCount(index, 1) end
            )
            cell = cell + 1
        end
    end
    self.formatPages = self:pagination(
        FORMAT_PAGE,
        {x = 86, y = 17, width = 11, height = 1},
        function(____, page)
            self.formatPage = page
            self:sync()
        end
    )
    self.castViewButton = self:button(
        " CAST ",
        {x = 82, y = 5, width = 6, height = 1},
        function() return self:setOrderView("cast") end
    )
    self.craftViewButton = self:button(
        " CRAFT ",
        {x = 89, y = 5, width = 7, height = 1},
        function() return self:setOrderView("craft") end
    )
    do
        local slot = 0
        while slot < CRAFT_CASTERS * CRAFT_RECIPE_ROWS do
            local index = slot
            local place = ____exports.SmelteryScreen:craftPlace(index)
            local ____self_craftButtons_6 = self.craftButtons
            ____self_craftButtons_6[#____self_craftButtons_6 + 1] = self:button(
                "",
                {x = place.x, y = place.y, width = 56, height = 1},
                function() return self:pickCraft(index) end
            )
            slot = slot + 1
        end
    end
    self.craftLess = self:button(
        " - ",
        {x = 45, y = 24, width = 3, height = 1},
        function() return self:stepCraft(-1) end
    )
    self.craftMore = self:button(
        " + ",
        {x = 52, y = 24, width = 3, height = 1},
        function() return self:stepCraft(1) end
    )
    self.clearButton = self:button(
        " CLEAR ",
        {x = 37, y = 26, width = 7, height = 1},
        function() return self:clearOrder() end
    )
    self.sendButton = self:button(
        "",
        {x = 77, y = 26, width = 20, height = 1},
        function() return self:sendOrder() end
    )
    do
        local row = 0
        while row < ORDER_ROWS do
            local index = row
            local ____self_cancelButtons_7 = self.cancelButtons
            ____self_cancelButtons_7[#____self_cancelButtons_7 + 1] = self:button(
                " x ",
                {x = 94, y = 33 + index * 2, width = 3, height = 1},
                function() return self:cancelOrder(index) end
            )
            row = row + 1
        end
    end
    self.orderPages = self:pagination(
        ORDER_ROWS,
        {x = 84, y = 31, width = 11, height = 1},
        function(____, page)
            self.orderPage = page
            self:sync()
        end
    )
    self.insertReadyButton = self:button(
        " INSERT READY ",
        {x = 66, y = 46, width = 14, height = 1},
        function() return self.actions:insertReady() end
    )
    self.detailsButton = self:button(
        (" DETAILS " .. Glyph.right) .. " ",
        {x = 83, y = 46, width = 11, height = 1},
        function() return self:openDetails(true) end
    )
    do
        local row = 0
        while row < ITEMS_PER_PAGE do
            local index = row
            local ____self_itemButtons_8 = self.itemButtons
            ____self_itemButtons_8[#____self_itemButtons_8 + 1] = self:button(
                "",
                {x = 86, y = 9 + index * 2, width = 9, height = 1},
                function() return self:pressItem(index) end
            )
            row = row + 1
        end
    end
    self.itemPages = self:pagination(
        ITEMS_PER_PAGE,
        {x = 6, y = 40, width = 11, height = 1},
        function(____, page)
            self.itemPage = page
            self:sync()
        end
    )
    self.backButton = self:button(
        (" " .. Glyph.left) .. " BACK ",
        {x = 6, y = 45, width = 8, height = 1},
        function() return self:openDetails(false) end
    )
    self.detailsReadyButton = self:button(
        " INSERT READY ",
        {x = 66, y = 45, width = 14, height = 1},
        function() return self.actions:insertReady() end
    )
    __TS__ArrayForEach(
        LOG_FILTERS,
        function(____, ____bindingPattern0, index)
            local label
            local filter
            filter = ____bindingPattern0[1]
            label = ____bindingPattern0[2]
            self.filterButtons:set(
                filter,
                self:button(
                    (" " .. label) .. " ",
                    {x = 3 + index * 10, y = 5, width = #label + 2, height = 1},
                    function() return self:setLogFilter(filter) end
                )
            )
        end
    )
    self.logPages = self:pagination(
        LOG_LINES,
        {x = 86, y = 5, width = 11, height = 1},
        function(____, page)
            self.logPage = page
        end
    )
    self.stockPages = self:pagination(
        RESERVOIRS_PER_PAGE,
        {x = 6, y = 45, width = 11, height = 1},
        function(____, page)
            self.stockPage = page
        end
    )
    do
        local slot = 0
        while slot < RESERVOIRS_PER_PAGE do
            local index = slot
            local place = ____exports.SmelteryScreen:reservoirPlace(index)
            local ____self_reservoirButtons_9 = self.reservoirButtons
            ____self_reservoirButtons_9[#____self_reservoirButtons_9 + 1] = self:button(
                "",
                {x = place.x, y = place.y + 6, width = 11, height = 1},
                function() return self:pressReservoir(index) end
            )
            slot = slot + 1
        end
    end
    local alloyCard = cardPlace(__TS__ArrayIndexOf(MODES, "alloy"))
    self.changeAlloy = self:button(
        " CHANGE ALLOY ",
        {x = alloyCard.x + 2, y = alloyCard.y + 14, width = 14, height = 1},
        function() return self:openPicker() end
    )
    do
        local row = 0
        while row < ALLOYS_PER_PAGE do
            local index = row
            local ____self_alloyButtons_10 = self.alloyButtons
            ____self_alloyButtons_10[#____self_alloyButtons_10 + 1] = self:button(
                "",
                {x = 10, y = 7 + index * 3, width = 36, height = 1},
                function() return self:pickAlloy(index) end
            )
            row = row + 1
        end
    end
    self.alloyPages = self:pagination(
        ALLOYS_PER_PAGE,
        {x = 10, y = 44, width = 11, height = 1},
        function(____, page)
            self.alloyPage = page
        end
    )
    self.lessButton = self:button(
        " - ",
        {x = 65, y = 21, width = 3, height = 1},
        function() return self:stepIngots(-1) end
    )
    self.moreButton = self:button(
        " + ",
        {x = 81, y = 21, width = 3, height = 1},
        function() return self:stepIngots(1) end
    )
    self.nonstopButton = self:button(
        " NONSTOP ",
        {x = 87, y = 21, width = 9, height = 1},
        function() return self:toggleNonstop() end
    )
    self.selectButton = self:button(
        " ACTIVATE ",
        {x = 65, y = 26, width = 10, height = 1},
        function() return self:selectAlloy() end
    )
    self.closePicker = self:button(
        " BACK ",
        {x = 78, y = 26, width = 6, height = 1},
        function() return self:cancelPicker() end
    )
    self.editButton = self:button(
        " EDIT ",
        {x = 65, y = 36, width = 6, height = 1},
        function() return self:openEditor(self:pickedOption()) end
    )
    self.newButton = self:button(
        " NEW ",
        {x = 73, y = 36, width = 5, height = 1},
        function() return self:openEditor(nil) end
    )
    self.deleteButton = self:button(
        " DELETE ",
        {x = 80, y = 36, width = 8, height = 1},
        function() return self:askDelete() end
    )
    self.chooseButton = self:button(
        " CHOOSE FLUID ",
        {x = 70, y = 13, width = 14, height = 1},
        function() return self:openFluidPicker() end
    )
    self.freeButton = self:button(
        " FREE ",
        {x = 86, y = 13, width = 6, height = 1},
        function() return self:choose(nil) end
    )
    self.capacityLess = self:button(
        (" " .. Glyph.left) .. " ",
        {x = 70, y = 39, width = 3, height = 1},
        function() return self:stepCapacity(-1) end
    )
    self.capacityMore = self:button(
        (" " .. Glyph.right) .. " ",
        {x = 94, y = 39, width = 3, height = 1},
        function() return self:stepCapacity(1) end
    )
    self.panelSave = self:button(
        " SAVE ",
        {x = 70, y = 43, width = 6, height = 1},
        function() return self:savePanel() end
    )
    self.panelCancel = self:button(
        " CANCEL ",
        {x = 79, y = 43, width = 8, height = 1},
        function() return self:cancelPanel() end
    )
    self.trashButton = self:button(
        " TRASH ",
        {x = 89, y = 43, width = 7, height = 1},
        function() return self:askTrashReservoir() end
    )
    self.resultButton = self:button(
        "",
        {x = 9, y = 9, width = 20, height = 1},
        function() return self:pickSlot("result") end
    )
    self.resultLess = self:button(
        " - ",
        {x = 31, y = 9, width = 3, height = 1},
        function() return self:stepAmount("result", -1) end
    )
    self.resultMore = self:button(
        " + ",
        {x = 44, y = 9, width = 3, height = 1},
        function() return self:stepAmount("result", 1) end
    )
    do
        local row = 0
        while row < MAX_INGREDIENTS do
            local index = row
            local y = 14 + index * 2
            local ____self_inputButtons_11 = self.inputButtons
            ____self_inputButtons_11[#____self_inputButtons_11 + 1] = self:button(
                "",
                {x = 9, y = y, width = 20, height = 1},
                function() return self:pickSlot(index) end
            )
            local ____self_inputLess_12 = self.inputLess
            ____self_inputLess_12[#____self_inputLess_12 + 1] = self:button(
                " - ",
                {x = 31, y = y, width = 3, height = 1},
                function() return self:stepAmount(index, -1) end
            )
            local ____self_inputMore_13 = self.inputMore
            ____self_inputMore_13[#____self_inputMore_13 + 1] = self:button(
                " + ",
                {x = 44, y = y, width = 3, height = 1},
                function() return self:stepAmount(index, 1) end
            )
            local ____self_inputRemove_14 = self.inputRemove
            ____self_inputRemove_14[#____self_inputRemove_14 + 1] = self:button(
                " x ",
                {x = 49, y = y, width = 3, height = 1},
                function() return self:removeInput(index) end
            )
            row = row + 1
        end
    end
    self.addInput = self:button(
        " + INGREDIENT ",
        {x = 6, y = 22, width = 14, height = 1},
        function() return self:addIngredient() end
    )
    local stepX = 12
    for ____, step in ipairs(STEPS) do
        local label = (" " .. tostring(step)) .. " "
        local ____self_stepButtons_15 = self.stepButtons
        ____self_stepButtons_15[#____self_stepButtons_15 + 1] = self:button(
            label,
            {x = stepX, y = 25, width = #label, height = 1},
            function() return self:setStep(step) end
        )
        stepX = stepX + (#label + 1)
    end
    do
        local cell = 0
        while cell < PICKER_PAGE do
            local index = cell
            local x = 9 + math.floor(index / PICKER_ROWS) * 23
            local ____self_pickerButtons_16 = self.pickerButtons
            ____self_pickerButtons_16[#____self_pickerButtons_16 + 1] = self:button(
                "",
                {x = x, y = 13 + index % PICKER_ROWS, width = 20, height = 1},
                function() return self:pressPicker(index) end
            )
            cell = cell + 1
        end
    end
    do
        local cell = 0
        while cell < PICKER_KNOWN do
            local index = cell
            local ____self_knownButtons_17 = self.knownButtons
            ____self_knownButtons_17[#____self_knownButtons_17 + 1] = self:button(
                "",
                {x = 9 + index * 23, y = 10, width = 20, height = 1},
                function() return self:pressKnown(index) end
            )
            cell = cell + 1
        end
    end
    do
        local letter = 0
        while letter < #LETTERS do
            local index = letter
            local label = (" " .. string.upper(__TS__StringCharAt(LETTERS, index))) .. " "
            local ____self_letterButtons_18 = self.letterButtons
            ____self_letterButtons_18[#____self_letterButtons_18 + 1] = self:button(
                label,
                {x = 6 + index * 3, y = 7, width = 3, height = 1},
                function() return self:jumpTo(index) end
            )
            letter = letter + 1
        end
    end
    self.pickerFree = self:button(
        " FREE ",
        {x = 86, y = 7, width = 6, height = 1},
        function() return self:choose(nil) end
    )
    self.pickerCancel = self:button(
        " CANCEL ",
        {x = 87, y = 45, width = 8, height = 1},
        function() return self:closeFluidPicker() end
    )
    self.choicePages = self:pagination(
        PICKER_PAGE,
        {x = 6, y = 45, width = 11, height = 1},
        function(____, page)
            self.choicePage = page
        end
    )
    self.root:place(
        __TS__New(
            PaintComponent,
            {paint = function(____, painter) return self:paintConfirm(painter) end}
        ),
        FULL_SCREEN
    )
    self.confirmYes = self:button(
        "",
        {x = 28, y = 28, width = 16, height = 1},
        function() return self:confirmStep() end
    )
    self.confirmNo = self:button(
        " CANCEL ",
        {x = 57, y = 28, width = 8, height = 1},
        function() return self:cancelConfirm() end
    )
    self:sync()
end
function SmelteryScreen.prototype.setState(self, state)
    self.state = state
    self.lastState = os.clock()
    self:sync()
end
function SmelteryScreen.prototype.notify(self, text, color)
    if color == nil then
        color = N.soft
    end
    self.message = {
        text = text,
        color = color,
        ["until"] = os.clock() + 6
    }
end
function SmelteryScreen.prototype.tick(self)
    if self.confirm ~= nil and self.confirm.step == 2 and os.clock() > self.confirm.deadline then
        self:notify(self.confirm.kind .. " cancelled: not confirmed in time")
        self.confirm = nil
    end
    self:sync()
end
function SmelteryScreen.prototype.setFluids(self, fluids)
    self.allFluids = fluids
    self:sync()
end
function SmelteryScreen.prototype.showTab(self, tab)
    self.tab = tab
    self.picking = false
    self.editor = nil
    self.assigning = nil
    self.capacityDraft = nil
    self.choosing = false
    self.inputDetails = false
    self:sync()
end
function SmelteryScreen.prototype.openCapacity(self)
    local ____opt_19 = self.state
    self.capacityDraft = ____opt_19 and ____opt_19.smelteryCapacity or 10000
    self:sync()
end
function SmelteryScreen.prototype.closeCapacity(self)
    self.capacityDraft = nil
    self:sync()
end
function SmelteryScreen.prototype.stepSmelteryCapacity(self, direction)
    if self.capacityDraft == nil then
        return
    end
    self.capacityDraft = math.max(self.capacityStep, self.capacityDraft + direction * self.capacityStep)
    self:sync()
end
function SmelteryScreen.prototype.setCapacityStep(self, step)
    self.capacityStep = step
    self:sync()
end
function SmelteryScreen.prototype.saveCapacity(self, auto)
    local draft = self.capacityDraft
    if draft == nil then
        return
    end
    self.actions:setSmelteryCapacity(auto and ({}) or ({capacity = draft}))
    self.capacityDraft = nil
    self:sync()
end
function SmelteryScreen.reservoirPlace(self, index)
    return {
        x = 6 + index % 5 * 12,
        y = 7 + math.floor(index / 5) * 13
    }
end
function SmelteryScreen.prototype.sortedReservoirs(self)
    local function rank(____, reservoir)
        return reservoir.fluid ~= nil and 0 or (reservoir.assigned ~= nil and 1 or 2)
    end
    local ____opt_21 = self.state
    return __TS__ArraySort(
        {unpack(____opt_21 and ____opt_21.reservoirs or ({}))},
        function(____, a, b)
            if rank(nil, a) ~= rank(nil, b) then
                return rank(nil, a) - rank(nil, b)
            end
            if a.amount ~= b.amount then
                return b.amount - a.amount
            end
            return a.name < b.name and -1 or (a.name > b.name and 1 or 0)
        end
    )
end
function SmelteryScreen.prototype.pageReservoirs(self)
    local start = (self.stockPage - 1) * RESERVOIRS_PER_PAGE
    return __TS__ArraySlice(
        self:sortedReservoirs(),
        start,
        start + RESERVOIRS_PER_PAGE
    )
end
function SmelteryScreen.prototype.pressReservoir(self, slot)
    local reservoir = self:pageReservoirs()[slot + 1]
    if reservoir == nil then
        return
    end
    local ____reservoir_name_24 = reservoir.name
    local ____reservoir_assigned_25 = reservoir.assigned
    local ____temp_23
    if reservoir.capacitySource == "set" then
        ____temp_23 = reservoir.capacity
    else
        ____temp_23 = nil
    end
    self.assigning = {reservoir = ____reservoir_name_24, fluid = ____reservoir_assigned_25, capacity = ____temp_23}
    self.choicePage = 1
    self:sync()
end
function SmelteryScreen.prototype.knownChoices(self)
    local state = self.state
    if state == nil then
        return {}
    end
    local extra = {}
    local editor = self.editor
    if editor ~= nil then
        for ____, fluid in ipairs({
            editor.result,
            unpack(__TS__ArrayMap(
                editor.inputs,
                function(____, input) return input.fluid end
            ))
        }) do
            if fluid ~= nil then
                extra[#extra + 1] = fluid
            end
        end
    end
    return knownFluids(state, extra)
end
function SmelteryScreen.prototype.pickerFluids(self)
    local fluids = {unpack(self.allFluids or ({}))}
    for ____, fluid in ipairs(self:knownChoices()) do
        if not __TS__ArrayIncludes(fluids, fluid) then
            fluids[#fluids + 1] = fluid
        end
    end
    return __TS__ArraySort(
        fluids,
        function(____, a, b)
            local left = fluidLabel(a)
            local right = fluidLabel(b)
            return left < right and -1 or (left > right and 1 or (a < b and -1 or (a > b and 1 or 0)))
        end
    )
end
function SmelteryScreen.prototype.pickerLabel(self, fluid, fluids)
    local label = fluidLabel(fluid)
    if #__TS__ArrayFilter(
        fluids,
        function(____, other) return fluidLabel(other) == label end
    ) < 2 then
        return label
    end
    local colon = (string.find(fluid, ":", nil, true) or 0) - 1
    return ((label .. " (") .. (colon > 0 and __TS__StringSplit(
        __TS__StringSubstring(fluid, 0, colon),
        "_"
    )[1] or "?")) .. ")"
end
function SmelteryScreen.prototype.pagePickerFluids(self, fluids)
    local start = (self.choicePage - 1) * PICKER_PAGE
    return __TS__ArraySlice(fluids, start, start + PICKER_PAGE)
end
function SmelteryScreen.prototype.openFluidPicker(self)
    self.choosing = true
    self.choicePage = 1
    self:sync()
end
function SmelteryScreen.prototype.closeFluidPicker(self)
    self.choosing = false
    self:sync()
end
function SmelteryScreen.prototype.jumpTo(self, letter)
    local fluids = self:pickerFluids()
    local wanted = __TS__StringCharAt(LETTERS, letter)
    local index = __TS__ArrayFindIndex(
        fluids,
        function(____, fluid) return __TS__StringSubstring(
            fluidLabel(fluid),
            0,
            1
        ) >= wanted end
    )
    if index < 0 then
        index = #fluids - 1
    end
    self.choicePage = math.max(
        1,
        math.floor(index / PICKER_PAGE) + 1
    )
    self:sync()
end
function SmelteryScreen.prototype.pressPicker(self, cell)
    local fluid = self:pagePickerFluids(self:pickerFluids())[cell + 1]
    if fluid ~= nil then
        self:choose(fluid)
    end
end
function SmelteryScreen.prototype.pressKnown(self, cell)
    local fluid = self:knownChoices()[cell + 1]
    if fluid ~= nil then
        self:choose(fluid)
    end
end
function SmelteryScreen.prototype.choose(self, fluid)
    local editor = self.editor
    if self.assigning ~= nil then
        self.assigning.fluid = fluid
    elseif editor ~= nil and fluid ~= nil then
        if editor.slot == "result" then
            editor.result = fluid
        elseif editor.slot ~= nil and editor.inputs[editor.slot + 1] ~= nil then
            editor.inputs[editor.slot + 1].fluid = fluid
        end
    end
    self.choosing = false
    self:sync()
end
function SmelteryScreen.prototype.chosenFluid(self)
    if self.assigning ~= nil then
        return self.assigning.fluid
    end
    local editor = self.editor
    if editor == nil or editor.slot == nil then
        return nil
    end
    local ____temp_28
    if editor.slot == "result" then
        ____temp_28 = editor.result
    else
        local ____opt_26 = editor.inputs[editor.slot + 1]
        ____temp_28 = ____opt_26 and ____opt_26.fluid
    end
    return ____temp_28
end
function SmelteryScreen.prototype.savePanel(self)
    local assigning = self.assigning
    if assigning ~= nil then
        local request = {reservoir = assigning.reservoir}
        if assigning.fluid ~= nil then
            request.fluid = assigning.fluid
        end
        if assigning.capacity ~= nil then
            request.capacity = assigning.capacity
        end
        self.actions:setReservoir(request)
        self.assigning = nil
    elseif self.editor ~= nil then
        self:saveEditor()
    end
    self:sync()
end
function SmelteryScreen.prototype.stepCapacity(self, direction)
    local assigning = self.assigning
    if assigning == nil then
        return
    end
    local current = assigning.capacity
    if direction > 0 then
        local ____temp_29
        if current == nil then
            ____temp_29 = CAPACITIES[1]
        else
            ____temp_29 = __TS__ArrayFind(
                CAPACITIES,
                function(____, capacity) return capacity > current end
            ) or current
        end
        assigning.capacity = ____temp_29
    elseif current ~= nil then
        local smaller = __TS__ArrayFilter(
            CAPACITIES,
            function(____, capacity) return capacity < current end
        )
        assigning.capacity = smaller[#smaller]
    end
    self:sync()
end
function SmelteryScreen.prototype.cancelPanel(self)
    self.assigning = nil
    self.editor = nil
    self.choosing = false
    self:sync()
end
function SmelteryScreen.prototype.pickedOption(self)
    return __TS__ArrayFind(
        self:alloyOptions(),
        function(____, option) return option.index == self.picked end
    )
end
function SmelteryScreen.prototype.openEditor(self, option)
    self.editor = option ~= nil and ({
        index = option.index,
        expected = option.result,
        result = option.result,
        amount = option.amount,
        inputs = __TS__ArrayMap(
            option.inputs,
            function(____, input) return {fluid = input.fluid, amount = input.amount} end
        ),
        step = INGOT
    }) or ({amount = INGOT, inputs = {{amount = INGOT}, {amount = INGOT}}, slot = "result", step = INGOT})
    self.choosing = option == nil
    self.choicePage = 1
    self:sync()
end
function SmelteryScreen.prototype.pickSlot(self, slot)
    if self.editor == nil then
        return
    end
    self.editor.slot = slot
    self.choosing = true
    self.choicePage = 1
    self:sync()
end
function SmelteryScreen.prototype.stepAmount(self, slot, direction)
    local editor = self.editor
    if editor == nil then
        return
    end
    local line = slot == "result" and editor or editor.inputs[slot + 1]
    if line == nil then
        return
    end
    line.amount = math.max(MIN_AMOUNT, line.amount + direction * editor.step)
    self:sync()
end
function SmelteryScreen.prototype.removeInput(self, index)
    local editor = self.editor
    if editor == nil then
        return
    end
    __TS__ArraySplice(editor.inputs, index, 1)
    if editor.slot == index then
        editor.slot = nil
    elseif type(editor.slot) == "number" and editor.slot > index then
        editor.slot = editor.slot - 1
    end
    self:sync()
end
function SmelteryScreen.prototype.addIngredient(self)
    local editor = self.editor
    if editor == nil or #editor.inputs >= MAX_INGREDIENTS then
        return
    end
    local ____editor_inputs_30 = editor.inputs
    ____editor_inputs_30[#____editor_inputs_30 + 1] = {amount = INGOT}
    editor.slot = #editor.inputs - 1
    self.choosing = true
    self.choicePage = 1
    self:sync()
end
function SmelteryScreen.prototype.setStep(self, step)
    if self.editor ~= nil then
        self.editor.step = step
    end
    self:sync()
end
function SmelteryScreen.prototype.editedRecipe(self)
    local editor = self.editor
    if editor == nil then
        return {problem = "no recipe"}
    end
    if editor.result == nil then
        return {problem = "choose the result"}
    end
    local inputs = {}
    for ____, input in ipairs(editor.inputs) do
        if input.fluid == nil then
            return {problem = "choose every ingredient"}
        end
        inputs[#inputs + 1] = {fluid = input.fluid, amount = input.amount}
    end
    local recipe = {result = editor.result, amount = editor.amount, inputs = inputs}
    local problem = recipeProblem(recipe)
    return problem ~= nil and ({problem = problem}) or ({recipe = recipe})
end
function SmelteryScreen.prototype.saveEditor(self)
    local editor = self.editor
    local ____temp_31 = self:editedRecipe()
    local recipe = ____temp_31.recipe
    local problem = ____temp_31.problem
    if editor == nil or recipe == nil then
        self:notify(problem or "cannot save", N.red)
        return
    end
    local request = {recipe = recipe}
    if editor.index ~= nil then
        request.index = editor.index
        if editor.expected ~= nil then
            request.expected = editor.expected
        end
    end
    local index = editor.index or #self:alloyOptions()
    self.actions:saveRecipe(
        request,
        function()
            self.editor = nil
            self.picked = index
            self:sync()
        end
    )
end
function SmelteryScreen.prototype.askDelete(self)
    local option = self:pickedOption()
    if option ~= nil then
        self.confirm = {kind = "delete", option = option, step = 1, deadline = 0}
    end
    self:sync()
end
function SmelteryScreen.prototype.alloyOptions(self)
    local ____opt_32 = self.state
    return ____opt_32 and ____opt_32.alloyOptions or ({})
end
function SmelteryScreen.prototype.openPicker(self)
    local ____opt_34 = self.state
    local alloy = ____opt_34 and ____opt_34.alloy
    local options = self:alloyOptions()
    self.picking = true
    local ____opt_36 = __TS__ArrayFind(
        options,
        function(____, option) return option.result == (alloy and alloy.result) end
    ) or options[1]
    self.picked = ____opt_36 and ____opt_36.index
    self.nonstop = alloy ~= nil and alloy.target == nil
    if (alloy and alloy.target) ~= nil then
        self.pickIngots = math.max(
            1,
            math.floor(alloy.target / INGOT + 0.5)
        )
    end
    self:sync()
end
function SmelteryScreen.prototype.cancelPicker(self)
    self.picking = false
    self:sync()
end
function SmelteryScreen.prototype.pickAlloy(self, row)
    local option = self:alloyOptions()[(self.alloyPage - 1) * ALLOYS_PER_PAGE + row + 1]
    if option ~= nil then
        self.picked = option.index
    end
    self:sync()
end
function SmelteryScreen.prototype.stepIngots(self, direction)
    local step = direction > 0 and (self.pickIngots >= 9 and 9 or 1) or (self.pickIngots > 9 and 9 or 1)
    self.pickIngots = math.max(1, self.pickIngots + direction * step)
    self.nonstop = false
    self:sync()
end
function SmelteryScreen.prototype.toggleNonstop(self)
    self.nonstop = not self.nonstop
    self:sync()
end
function SmelteryScreen.prototype.selectAlloy(self)
    local ____opt_42 = self:pickedOption()
    local result = ____opt_42 and ____opt_42.result
    if result == nil then
        return
    end
    local request = {result = result, activate = true}
    if not self.nonstop then
        request.target = self.pickIngots * INGOT
    end
    self.actions:setAlloy(request)
    self.picking = false
    self:sync()
end
function SmelteryScreen.prototype.pageItems(self)
    local ____opt_44 = self.state
    local items = ____opt_44 and ____opt_44.inputItems or ({})
    local start = (self.itemPage - 1) * ITEMS_PER_PAGE
    return __TS__ArraySlice(items, start, start + ITEMS_PER_PAGE)
end
function SmelteryScreen.prototype.pressItem(self, row)
    local item = self:pageItems()[row + 1]
    if item == nil then
        return
    end
    if item.status == "ok" then
        self.actions:insert({slot = item.slot})
    elseif item.status == "alloy" or item.status == "heat" then
        self.confirm = {kind = "force", item = item, step = 1, deadline = 0}
    end
    self:sync()
end
function SmelteryScreen.prototype.confirmStep(self)
    local confirm = self.confirm
    if confirm == nil then
        return
    end
    if confirm.step == 1 then
        self.confirm = __TS__ObjectAssign(
            {},
            confirm,
            {
                step = 2,
                deadline = os.clock() + CONFIRM_SECONDS
            }
        )
    elseif confirm.kind == "force" then
        self.confirm = nil
        self.actions:insert({slot = confirm.item.slot, force = true})
    elseif confirm.kind == "trash" then
        self.confirm = nil
        local request = {fluid = confirm.fluid}
        if confirm.reservoir ~= nil then
            request.reservoir = confirm.reservoir
        end
        self.actions:trashFluid(request)
        if confirm.reservoir ~= nil then
            self.assigning = nil
        end
    else
        self.confirm = nil
        self.picked = nil
        self.actions:deleteRecipe({index = confirm.option.index, expected = confirm.option.result})
    end
    self:sync()
end
function SmelteryScreen.prototype.cancelConfirm(self)
    self.confirm = nil
    self:sync()
end
function SmelteryScreen.prototype.manualFluids(self)
    local stored = __TS__New(Map)
    local ____opt_46 = self.state
    for ____, reservoir in ipairs(____opt_46 and ____opt_46.reservoirs or ({})) do
        local fluid = reservoir.fluid
        if fluid ~= nil and reservoir.amount > 0 then
            stored:set(
                fluid,
                (stored:get(fluid) or 0) + reservoir.amount
            )
        end
    end
    local ____opt_48 = self.state
    local list = __TS__ArrayMap(
        ____opt_48 and ____opt_48.fluids or ({}),
        function(____, fluid) return {
            name = fluid.name,
            amount = fluid.amount,
            stored = stored:get(fluid.name) or 0
        } end
    )
    local inside = __TS__New(
        Set,
        __TS__ArrayMap(
            list,
            function(____, fluid) return fluid.name end
        )
    )
    local only = {}
    stored:forEach(function(____, amount, name)
        if not inside:has(name) then
            only[#only + 1] = {name = name, amount = 0, stored = amount}
        end
    end)
    __TS__ArraySort(
        only,
        function(____, a, b) return b.stored - a.stored end
    )
    local ____array_50 = __TS__SparseArrayNew(unpack(list))
    __TS__SparseArrayPush(
        ____array_50,
        unpack(only)
    )
    return {__TS__SparseArraySpread(____array_50)}
end
function SmelteryScreen.prototype.fluids(self)
    local start = (self.fluidPage - 1) * FLUID_ROWS
    return __TS__ArraySlice(
        self:manualFluids(),
        start,
        start + FLUID_ROWS
    )
end
function SmelteryScreen.prototype.castGroups(self)
    local ____groupCasters_56 = groupCasters
    local ____opt_51 = self.state
    local ____temp_55 = ____opt_51 and ____opt_51.casters or ({})
    local ____opt_53 = self.state
    return ____groupCasters_56(____temp_55, ____opt_53 and ____opt_53.autoFormats or ({}))
end
function SmelteryScreen.prototype.orderFormats(self)
    local fluid = self.fluid
    return __TS__ArrayFilter(
        self:castGroups(),
        function(____, group) return group.format ~= "no cast" and (fluid == nil or self:castInfo(group.format, fluid).castable) end
    )
end
function SmelteryScreen.prototype.pageFormats(self)
    local start = (self.formatPage - 1) * FORMAT_PAGE
    return __TS__ArraySlice(
        self:orderFormats(),
        start,
        start + FORMAT_PAGE
    )
end
function SmelteryScreen.formatPlace(self, index)
    return {x = index < FORMAT_ROWS and 37 or 68, y = 7 + index % FORMAT_ROWS * 2}
end
function SmelteryScreen.prototype.pageOrders(self)
    local start = (self.orderPage - 1) * ORDER_ROWS
    local ____opt_57 = self.state
    return __TS__ArraySlice(____opt_57 and ____opt_57.orders or ({}), start, start + ORDER_ROWS)
end
function SmelteryScreen.prototype.castInfo(self, format, fluid)
    local ____opt_63 = self.state
    local ____opt_59 = ____opt_63 and ____opt_63.castOptions
    if ____opt_59 ~= nil then
        local ____opt_60 = self.state
        ____opt_59 = __TS__ArrayFind(
            ____opt_60 and ____opt_60.castOptions,
            function(____, candidate) return candidate.fluid == fluid end
        )
    end
    local option = ____opt_59
    if option == nil then
        return {castable = true}
    end
    local cast = __TS__ArrayFind(
        option.casts,
        function(____, candidate) return candidate.format == format end
    )
    return cast ~= nil and ({castable = true, amount = cast.amount}) or ({castable = false})
end
function SmelteryScreen.prototype.countOf(self, format)
    return self.counts:get(format) or 0
end
function SmelteryScreen.prototype.orderLines(self)
    local fluid = self.fluid
    if fluid == nil then
        return {}
    end
    return __TS__ArrayMap(
        __TS__ArrayFilter(
            self:orderFormats(),
            function(____, group) return self:countOf(group.format) > 0 and self:castInfo(group.format, fluid).castable end
        ),
        function(____, group) return {
            format = group.format,
            count = self:countOf(group.format)
        } end
    )
end
function SmelteryScreen.prototype.orderNeeds(self)
    local fluid = self.fluid
    local known = __TS__ArrayFind(
        self:manualFluids(),
        function(____, candidate) return candidate.name == fluid end
    )
    local result = {have = known and known.amount or 0, stored = known and known.stored or 0}
    if fluid == nil then
        return result
    end
    local needs = 0
    for ____, line in ipairs(self:orderLines()) do
        local amount = self:castInfo(line.format, fluid).amount
        needs = amount ~= nil and needs ~= nil and needs + amount * line.count or nil
    end
    if needs ~= nil then
        result.needs = needs
    end
    return result
end
function SmelteryScreen.prototype.pickFluid(self, row)
    local ____opt_69 = self:fluids()[row + 1]
    self.fluid = ____opt_69 and ____opt_69.name
    self:sync()
end
function SmelteryScreen.prototype.stepCount(self, cell, direction)
    local group = self:pageFormats()[cell + 1]
    if group == nil or self.fluid == nil then
        return
    end
    local count = math.max(
        0,
        math.min(
            MAX_COUNT,
            self:countOf(group.format) + direction
        )
    )
    if count == 0 then
        self.counts:delete(group.format)
    else
        self.counts:set(group.format, count)
    end
    self:sync()
end
function SmelteryScreen.prototype.clearOrder(self)
    self.counts:clear()
    self:sync()
end
function SmelteryScreen.prototype.sendOrder(self)
    if self.orderView == "craft" then
        self:sendCraft()
        return
    end
    local fluid = self.fluid
    local lines = self:orderLines()
    if fluid == nil then
        self:notify("pick a fluid first", N.red)
    elseif #lines == 0 then
        self:notify("touch + on a shape first", N.red)
    else
        self.actions:queueOrder(
            {fluid = fluid, lines = lines},
            function()
                self.counts:clear()
                self:sync()
            end
        )
    end
    self:sync()
end
function SmelteryScreen.prototype.setOrderView(self, view)
    self.orderView = view
    self:sync()
end
function SmelteryScreen.prototype.craftCasters(self)
    local ____opt_71 = self.state
    return __TS__ArraySlice(____opt_71 and ____opt_71.craftCasters or ({}), 0, CRAFT_CASTERS)
end
function SmelteryScreen.craftPlace(self, slot)
    local caster = math.floor(slot / CRAFT_RECIPE_ROWS)
    return {x = 39, y = 8 + caster * (CRAFT_RECIPE_ROWS + 1) + slot % CRAFT_RECIPE_ROWS}
end
function SmelteryScreen.prototype.craftAt(self, slot)
    local caster = self:craftCasters()[math.floor(slot / CRAFT_RECIPE_ROWS) + 1]
    local recipe = caster and caster.recipes[slot % CRAFT_RECIPE_ROWS + 1]
    return caster ~= nil and recipe ~= nil and ({caster = caster, recipe = recipe}) or nil
end
function SmelteryScreen.prototype.pickedCraft(self)
    local pick = self.craftPick
    local ____temp_81
    if pick ~= nil then
        local ____opt_79 = self.state
        local ____opt_75 = ____opt_79 and ____opt_79.craftCasters
        if ____opt_75 ~= nil then
            local ____opt_76 = self.state
            ____opt_75 = __TS__ArrayFind(
                ____opt_76 and ____opt_76.craftCasters,
                function(____, candidate) return candidate.name == pick.caster end
            )
        end
        ____temp_81 = ____opt_75
    else
        ____temp_81 = nil
    end
    local caster = ____temp_81
    local ____opt_82 = caster
    local recipe = ____opt_82 and __TS__ArrayFind(
        caster and caster.recipes,
        function(____, candidate) return candidate.index == (pick and pick.index) end
    )
    return caster ~= nil and recipe ~= nil and ({caster = caster, recipe = recipe}) or nil
end
function SmelteryScreen.prototype.pickCraft(self, slot)
    local craft = self:craftAt(slot)
    if craft ~= nil then
        self.craftPick = {caster = craft.caster.name, index = craft.recipe.index}
        self.craftCount = 1
    end
    self:sync()
end
function SmelteryScreen.prototype.stepCraft(self, direction)
    self.craftCount = math.max(
        1,
        math.min(MAX_COUNT, self.craftCount + direction)
    )
    self:sync()
end
function SmelteryScreen.prototype.sendCraft(self)
    local craft = self:pickedCraft()
    if craft == nil then
        self:notify("pick a recipe first", N.red)
        self:sync()
        return
    end
    self.actions:queueCraft(
        {caster = craft.caster.name, recipe = craft.recipe.index, count = self.craftCount},
        function()
            self.craftCount = 1
            self:sync()
        end
    )
end
function SmelteryScreen.prototype.askTrashStack(self, row)
    local ____opt_88 = self.state
    local fluid = __TS__ArrayReverse({unpack(____opt_88 and ____opt_88.fluids or ({}))})[row + 1]
    local ____temp_92 = fluid == nil
    if not ____temp_92 then
        local ____opt_90 = self.state
        ____temp_92 = (____opt_90 and ____opt_90.trash) == nil
    end
    if ____temp_92 then
        return
    end
    self.confirm = {
        kind = "trash",
        fluid = fluid.name,
        amount = fluid.amount,
        step = 1,
        deadline = 0
    }
    self:sync()
end
function SmelteryScreen.prototype.askTrashReservoir(self)
    local ____opt_93 = self.assigning
    local name = ____opt_93 and ____opt_93.reservoir
    local ____opt_95 = self.state
    if ____opt_95 ~= nil then
        local ____opt_96 = self.state
        ____opt_95 = __TS__ArrayFind(
            ____opt_96 and ____opt_96.reservoirs,
            function(____, candidate) return candidate.name == name end
        )
    end
    local reservoir = ____opt_95
    local ____temp_103 = (reservoir and reservoir.fluid) == nil or reservoir.amount <= 0
    if not ____temp_103 then
        local ____opt_101 = self.state
        ____temp_103 = (____opt_101 and ____opt_101.trash) == nil
    end
    if ____temp_103 then
        return
    end
    self.confirm = {
        kind = "trash",
        fluid = reservoir.fluid,
        amount = reservoir.amount,
        reservoir = reservoir.name,
        step = 1,
        deadline = 0
    }
    self:sync()
end
function SmelteryScreen.prototype.cancelOrder(self, row)
    local order = self:pageOrders()[row + 1]
    if order ~= nil then
        self.actions:cancelOrder(order.id)
    end
end
function SmelteryScreen.prototype.openDetails(self, open)
    self.inputDetails = open
    self:sync()
end
function SmelteryScreen.prototype.toggleAuto(self, row)
    local group = self:castGroups()[(self.castPage - 1) * CASTS_PER_PAGE + row + 1]
    if group ~= nil and group.format ~= "no cast" then
        self.actions:setFormat({format = group.format, auto = not group.auto})
    end
end
function SmelteryScreen.prototype.setLogFilter(self, filter)
    self.logFilter = filter
    self.logPage = 1
    self:sync()
end
function SmelteryScreen.prototype.logLines(self)
    local lines = {}
    local ____opt_104 = self.state
    for ____, raw in ipairs(____opt_104 and ____opt_104.log or ({})) do
        do
            local __continue313
            repeat
                if __TS__StringSubstring(raw, 8, 11) == "   " then
                    __continue313 = true
                    break
                end
                local line = parseLogLine(raw)
                if keeps(self.logFilter, line.kind) then
                    lines[#lines + 1] = line
                end
                __continue313 = true
            until true
            if not __continue313 then
                break
            end
        end
    end
    return lines
end
function SmelteryScreen.prototype.pageLogLines(self)
    local lines = self:logLines()
    local ____end = math.max(0, #lines - (self.logPage - 1) * LOG_LINES)
    return __TS__ArraySlice(
        lines,
        math.max(0, ____end - LOG_LINES),
        ____end
    )
end
function SmelteryScreen.prototype.button(self, label, rect, onPress)
    local button = self.root:place(
        __TS__New(ButtonComponent, {
            label = label,
            padding = 0,
            foregroundColor = N.text,
            backgroundColor = N.bg,
            onPress = onPress
        }),
        rect
    )
    local ____self_allButtons_106 = self.allButtons
    ____self_allButtons_106[#____self_allButtons_106 + 1] = button
    return button
end
function SmelteryScreen.prototype.pagination(self, pageSize, rect, onPageChange)
    return self.root:place(
        __TS__New(PaginationComponent, {
            page = 1,
            pageSize = pageSize,
            totalItems = 0,
            foregroundColor = N.soft,
            backgroundColor = N.bg,
            onPageChange = onPageChange
        }),
        rect
    )
end
function SmelteryScreen.prototype.show(self, button, visible, label, foreground, background)
    local patch = {visible = visible}
    if label ~= nil then
        patch.label = label
    end
    if foreground ~= nil then
        patch.foregroundColor = foreground
    end
    if background ~= nil then
        patch.backgroundColor = background
    end
    button:setProps(patch)
end
function SmelteryScreen.prototype.neon(self, button, visible, label, color, on)
    self:show(
        button,
        visible,
        label,
        on and N.bg or color,
        on and color or N.bg
    )
end
function SmelteryScreen.prototype.sync(self)
    local state = self.state
    local modal = self.confirm ~= nil
    local ready = state ~= nil
    for ____, ____value in __TS__Iterator(self.tabButtons) do
        local tab = ____value[1]
        local button = ____value[2]
        self:show(
            button,
            true,
            nil,
            tab == self.tab and N.magenta or N.dim,
            N.bg
        )
    end
    local editing = self.tab == "modes" and ready and self.editor ~= nil
    local cards = self.tab == "modes" and ready and not self.picking and not editing
    local picker = self.tab == "modes" and ready and self.picking and not editing
    for ____, ____value in __TS__Iterator(self.modeButtons) do
        local mode = ____value[1]
        local button = ____value[2]
        self:neon(
            button,
            cards and state.mode ~= mode,
            " ACTIVATE ",
            MODE_COLORS[mode],
            true
        )
    end
    self:neon(
        self.changeAlloy,
        cards,
        " CHANGE ALLOY ",
        N.magenta,
        false
    )
    self:syncPicker(picker)
    self:syncEditor(editing)
    self:syncChoices(editing)
    self:syncOverview()
    self:syncStock()
    self:syncManual()
    self:syncLog()
    local confirm = self.confirm
    local last = (confirm and confirm.kind) == "delete" and " DELETE " or ((confirm and confirm.kind) == "trash" and " TRASH " or " FORCE INSERT ")
    local yes = (confirm and confirm.step) == 2 and last or " CONTINUE "
    self:neon(
        self.confirmYes,
        modal,
        yes,
        (confirm and confirm.step) == 2 and N.red or N.yellow,
        true
    )
    self:neon(
        self.confirmNo,
        modal,
        " CANCEL ",
        N.soft,
        false
    )
    for ____, button in ipairs(self.allButtons) do
        if button ~= self.confirmYes and button ~= self.confirmNo then
            button:setProps({disabled = modal})
        end
    end
    local paginations = {
        self.castPages,
        self.itemPages,
        self.fluidPages,
        self.formatPages,
        self.orderPages,
        self.stockPages,
        self.alloyPages,
        self.choicePages,
        self.logPages
    }
    for ____, pages in ipairs(paginations) do
        pages:setProps({disabled = modal})
    end
    if self:pickerOpen() and self.state ~= nil then
        self:hideUnderPicker()
    end
end
function SmelteryScreen.prototype.syncPicker(self, picker)
    local options = self:alloyOptions()
    self.alloyPage = math.min(
        self.alloyPage,
        math.max(
            1,
            math.ceil(#options / ALLOYS_PER_PAGE)
        )
    )
    self.alloyPages:setProps({visible = picker and #options > ALLOYS_PER_PAGE, totalItems = #options, page = self.alloyPage})
    local pageOptions = __TS__ArraySlice(options, (self.alloyPage - 1) * ALLOYS_PER_PAGE, self.alloyPage * ALLOYS_PER_PAGE)
    __TS__ArrayForEach(
        self.alloyButtons,
        function(____, button, row)
            local option = pageOptions[row + 1]
            local picked = option ~= nil and option.index == self.picked
            local label = option ~= nil and __TS__StringPadEnd(
                fit(
                    string.upper(fluidLabel(option.result)),
                    36
                ),
                36
            ) or ""
            self:show(
                button,
                picker and option ~= nil,
                label,
                picked and N.magenta or N.text,
                picked and N.panel or N.bg
            )
        end
    )
    self:neon(
        self.lessButton,
        picker,
        " - ",
        N.cyan,
        true
    )
    self:neon(
        self.moreButton,
        picker,
        " + ",
        N.cyan,
        true
    )
    self:neon(
        self.nonstopButton,
        picker,
        " NONSTOP ",
        N.magenta,
        self.nonstop
    )
    local pickedOption = self:pickedOption()
    self:neon(
        self.selectButton,
        picker and pickedOption ~= nil,
        " ACTIVATE ",
        N.magenta,
        true
    )
    self:neon(
        self.closePicker,
        picker,
        " BACK ",
        N.soft,
        false
    )
    self:neon(
        self.editButton,
        picker and pickedOption ~= nil,
        " EDIT ",
        N.purple,
        false
    )
    self:neon(
        self.newButton,
        picker,
        " NEW ",
        N.purple,
        false
    )
    self:neon(
        self.deleteButton,
        picker and pickedOption ~= nil,
        " DELETE ",
        N.red,
        false
    )
end
function SmelteryScreen.prototype.syncOverview(self)
    local overview = self.tab == "overview" and self.state ~= nil
    local panel = overview and self.capacityDraft ~= nil
    local groups = self:castGroups()
    self.castPage = math.min(
        self.castPage,
        math.max(
            1,
            math.ceil(#groups / CASTS_PER_PAGE)
        )
    )
    local castsPaged = overview and not panel and #groups > CASTS_PER_PAGE
    self.castPages:setProps({visible = castsPaged, totalItems = #groups, page = self.castPage})
    local pageGroups = __TS__ArraySlice(groups, (self.castPage - 1) * CASTS_PER_PAGE, self.castPage * CASTS_PER_PAGE)
    __TS__ArrayForEach(
        self.autoButtons,
        function(____, button, row)
            local group = pageGroups[row + 1]
            local shown = overview and not panel and group ~= nil and group.format ~= "no cast"
            self:neon(
                button,
                shown,
                (group and group.auto) == true and " AUTO " or " off  ",
                (group and group.auto) == true and N.lime or N.dim,
                (group and group.auto) == true
            )
        end
    )
    local ____opt_121 = self.state
    local stack = __TS__ArrayReverse({unpack(____opt_121 and ____opt_121.fluids or ({}))})
    local ____temp_125 = overview and not panel
    if ____temp_125 then
        local ____opt_123 = self.state
        ____temp_125 = (____opt_123 and ____opt_123.trash) ~= nil
    end
    local trashing = ____temp_125
    __TS__ArrayForEach(
        self.stackButtons,
        function(____, button, row)
            local fluid = stack[row + 1]
            if not trashing or fluid == nil then
                self:show(button, false)
                return
            end
            local width = 38 - #(tostring(fluid.amount) .. " mB")
            local label = __TS__StringPadEnd(
                fit(
                    string.upper(fluidLabel(fluid.name)),
                    math.min(24, width)
                ),
                24
            )
            self:show(
                button,
                true,
                label,
                fluidColor(fluid.name),
                N.bg
            )
        end
    )
    self:neon(
        self.setCapacity,
        overview,
        " SET CAPACITY ",
        N.cyan,
        panel
    )
    self:neon(
        self.capacityLessButton,
        panel,
        " - ",
        N.cyan,
        true
    )
    self:neon(
        self.capacityMoreButton,
        panel,
        " + ",
        N.cyan,
        true
    )
    __TS__ArrayForEach(
        self.capacityStepButtons,
        function(____, button, index)
            self:neon(
                button,
                panel,
                nil,
                N.purple,
                CAPACITY_STEPS[index + 1] == self.capacityStep
            )
        end
    )
    self:neon(
        self.capacitySave,
        panel,
        " SAVE ",
        N.lime,
        true
    )
    self:neon(
        self.capacityAuto,
        panel,
        " AUTO ",
        N.purple,
        false
    )
    self:neon(
        self.capacityCancel,
        panel,
        " CANCEL ",
        N.soft,
        false
    )
end
function SmelteryScreen.prototype.syncStock(self)
    local stock = self.tab == "stock" and self.state ~= nil
    local ____opt_126 = self.state
    local count = ____opt_126 and #____opt_126.reservoirs or 0
    self.stockPage = math.min(
        self.stockPage,
        math.max(
            1,
            math.ceil(count / RESERVOIRS_PER_PAGE)
        )
    )
    self.stockPages:setProps({visible = stock and count > RESERVOIRS_PER_PAGE, totalItems = count, page = self.stockPage})
    local page = self:pageReservoirs()
    __TS__ArrayForEach(
        self.reservoirButtons,
        function(____, button, slot)
            local reservoir = page[slot + 1]
            if not stock or reservoir == nil then
                self:show(button, false)
                return
            end
            local first = unpack(
                reservoirLines(reservoir.name, 11),
                1,
                1
            )
            local ____reservoir_name_130 = reservoir.name
            local ____opt_128 = self.assigning
            local color = ____reservoir_name_130 == (____opt_128 and ____opt_128.reservoir) and N.yellow or (reservoir.fluid ~= nil and N.cyan or N.text)
            self:show(
                button,
                true,
                __TS__StringPadEnd(first, 11),
                color,
                N.bg
            )
        end
    )
end
function SmelteryScreen.prototype.syncManual(self)
    local state = self.state
    local tab = self.tab == "manual" and state ~= nil
    local manual = tab and state.mode == "manual"
    local details = manual and self.inputDetails
    local compose = manual and not self.inputDetails
    local function pages(____, count, size)
        return math.max(
            1,
            math.ceil(count / size)
        )
    end
    self:neon(
        self.switchManual,
        tab and not manual,
        " SWITCH TO MANUAL ",
        N.yellow,
        true
    )
    local fluidCount = #self:manualFluids()
    self.fluidPage = math.min(
        self.fluidPage,
        pages(nil, fluidCount, FLUID_ROWS)
    )
    self.fluidPages:setProps({visible = compose and fluidCount > FLUID_ROWS, totalItems = fluidCount, page = self.fluidPage})
    local fluids = self:fluids()
    __TS__ArrayForEach(
        self.fluidButtons,
        function(____, button, row)
            local fluid = fluids[row + 1]
            local label = fluid == nil and "" or ____exports.SmelteryScreen:fluidRow(fluid, 23)
            self:show(
                button,
                compose and fluid ~= nil,
                label,
                (fluid and fluid.name) == self.fluid and N.text or N.soft,
                N.bg
            )
        end
    )
    local ____opt_133 = state and state.craftCasters
    local crafting = (____opt_133 and #____opt_133 or 0) > 0
    if not crafting then
        self.orderView = "cast"
    end
    local casting = compose and self.orderView == "cast"
    local craftView = compose and self.orderView == "craft"
    self:neon(
        self.castViewButton,
        compose and crafting,
        " CAST ",
        N.yellow,
        self.orderView == "cast"
    )
    self:neon(
        self.craftViewButton,
        compose and crafting,
        " CRAFT ",
        N.yellow,
        self.orderView == "craft"
    )
    local picked = self:pickedCraft()
    __TS__ArrayForEach(
        self.craftButtons,
        function(____, button, slot)
            local craft = self:craftAt(slot)
            if not craftView or craft == nil then
                self:show(button, false)
                return
            end
            local chosen = (picked and picked.caster.name) == craft.caster.name and picked.recipe.index == craft.recipe.index
            self:show(
                button,
                true,
                ____exports.SmelteryScreen:craftRow(craft.recipe, 56),
                chosen and N.yellow or N.soft,
                chosen and N.panel or N.bg
            )
        end
    )
    self:neon(
        self.craftLess,
        craftView and picked ~= nil,
        " - ",
        N.cyan,
        self.craftCount > 1
    )
    self:neon(
        self.craftMore,
        craftView and picked ~= nil,
        " + ",
        N.cyan,
        true
    )
    local formatCount = #self:orderFormats()
    self.formatPage = math.min(
        self.formatPage,
        pages(nil, formatCount, FORMAT_PAGE)
    )
    self.formatPages:setProps({visible = casting and formatCount > FORMAT_PAGE, totalItems = formatCount, page = self.formatPage})
    local formats = self:pageFormats()
    local fluid = self.fluid
    do
        local cell = 0
        while cell < FORMAT_PAGE do
            local group = formats[cell + 1]
            local shown = casting and group ~= nil and fluid ~= nil and self:castInfo(group.format, fluid).castable
            local count = group ~= nil and self:countOf(group.format) or 0
            self:neon(
                self.countLess[cell + 1],
                shown,
                " - ",
                count > 0 and N.cyan or N.dim,
                count > 0
            )
            self:neon(
                self.countMore[cell + 1],
                shown,
                " + ",
                N.cyan,
                true
            )
            cell = cell + 1
        end
    end
    local ____temp_139
    if self.orderView == "craft" then
        ____temp_139 = picked ~= nil
    else
        ____temp_139 = fluid ~= nil and #self:orderLines() > 0
    end
    local ready = ____temp_139
    self:neon(
        self.clearButton,
        casting,
        " CLEAR ",
        N.soft,
        false
    )
    local send = "SEND " .. Glyph.right
    local left = math.floor((20 - #send) / 2)
    self:show(
        self.sendButton,
        compose,
        __TS__StringPadEnd(
            string.rep(
                " ",
                math.floor(left)
            ) .. send,
            20
        ),
        ready and N.bg or N.dim,
        ready and N.lime or N.panel
    )
    local ____opt_140 = state and state.orders
    local orderCount = ____opt_140 and #____opt_140 or 0
    self.orderPage = math.min(
        self.orderPage,
        pages(nil, orderCount, ORDER_ROWS)
    )
    self.orderPages:setProps({visible = tab and not details and orderCount > ORDER_ROWS, totalItems = orderCount, page = self.orderPage})
    local orders = self:pageOrders()
    __TS__ArrayForEach(
        self.cancelButtons,
        function(____, button, row) return self:neon(
            button,
            tab and not details and orders[row + 1] ~= nil,
            " x ",
            N.red,
            false
        ) end
    )
    local items = state and state.inputItems or ({})
    local anyReady = __TS__ArraySome(
        items,
        function(____, item) return item.status == "ok" end
    )
    self:neon(
        self.insertReadyButton,
        compose,
        " INSERT READY ",
        anyReady and N.lime or N.dim,
        anyReady
    )
    self:neon(
        self.detailsButton,
        compose,
        (" DETAILS " .. Glyph.right) .. " ",
        N.cyan,
        true
    )
    self.itemPage = math.min(
        self.itemPage,
        pages(nil, #items, ITEMS_PER_PAGE)
    )
    self.itemPages:setProps({visible = details and #items > ITEMS_PER_PAGE, totalItems = #items, page = self.itemPage})
    local pageItems = self:pageItems()
    __TS__ArrayForEach(
        self.itemButtons,
        function(____, button, row)
            local item = pageItems[row + 1]
            if not details or item == nil or item.status == "unknown" then
                self:show(button, false)
            elseif item.status == "ok" then
                self:neon(
                    button,
                    true,
                    " INSERT  ",
                    N.lime,
                    true
                )
            else
                self:neon(
                    button,
                    true,
                    " FORCE   ",
                    N.red,
                    true
                )
            end
        end
    )
    self:neon(
        self.backButton,
        details,
        (" " .. Glyph.left) .. " BACK ",
        N.cyan,
        true
    )
    self:neon(
        self.detailsReadyButton,
        details,
        " INSERT READY ",
        anyReady and N.lime or N.dim,
        anyReady
    )
end
function SmelteryScreen.craftRow(self, recipe, width)
    local keeps = recipe.consumed and "" or " (item stays)"
    return __TS__StringPadEnd(
        fit(
            ((((((tostring(recipe.amount) .. " mB ") .. fluidLabel(recipe.fluid)) .. " ") .. Glyph.right) .. " ") .. placeLabel(recipe.result)) .. keeps,
            width
        ),
        width
    )
end
function SmelteryScreen.fluidRow(self, fluid, width)
    local amount = fluid.amount > 0 and tostring(fluid.amount) .. " mB" or shortAmount(fluid.stored) .. " st."
    local name = fit(
        fluidLabel(fluid.name),
        width - #amount - 1
    )
    return (name .. string.rep(
        " ",
        math.floor(width - #name - #amount)
    )) .. amount
end
function SmelteryScreen.prototype.syncLog(self)
    local log = self.tab == "log" and self.state ~= nil
    for ____, ____value in ipairs(LOG_FILTERS) do
        local filter = ____value[1]
        local label = ____value[2]
        local color = ____value[3]
        self:neon(
            self.filterButtons:get(filter),
            log,
            (" " .. label) .. " ",
            color,
            filter == self.logFilter
        )
    end
    local lines = #self:logLines()
    self.logPage = math.min(
        self.logPage,
        math.max(
            1,
            math.ceil(lines / LOG_LINES)
        )
    )
    self.logPages:setProps({visible = log and lines > LOG_LINES, totalItems = lines, page = self.logPage})
end
function SmelteryScreen.prototype.syncEditor(self, editing)
    local editor = self.editor
    local shown = editing and editor ~= nil
    local function slotColor(____, slot)
        return (editor and editor.slot) == slot and N.yellow or N.text
    end
    local result = (editor and editor.result) ~= nil and fluidLabel(editor.result) or "choose..."
    self:show(
        self.resultButton,
        shown,
        __TS__StringPadEnd(
            fit(result, 20),
            20
        ),
        (editor and editor.result) ~= nil and slotColor(nil, "result") or N.dim,
        N.bg
    )
    self:neon(
        self.resultLess,
        shown,
        " - ",
        N.cyan,
        true
    )
    self:neon(
        self.resultMore,
        shown,
        " + ",
        N.cyan,
        true
    )
    do
        local row = 0
        while row < MAX_INGREDIENTS do
            local input = editor and editor.inputs[row + 1]
            local visible = shown and input ~= nil
            local label = (input and input.fluid) ~= nil and fluidLabel(input.fluid) or "choose..."
            local color = (input and input.fluid) ~= nil and slotColor(nil, row) or N.dim
            self:show(
                self.inputButtons[row + 1],
                visible,
                __TS__StringPadEnd(
                    fit(label, 20),
                    20
                ),
                color,
                N.bg
            )
            self:neon(
                self.inputLess[row + 1],
                visible,
                " - ",
                N.cyan,
                true
            )
            self:neon(
                self.inputMore[row + 1],
                visible,
                " + ",
                N.cyan,
                true
            )
            self:neon(
                self.inputRemove[row + 1],
                visible,
                " x ",
                N.red,
                true
            )
            row = row + 1
        end
    end
    self:neon(
        self.addInput,
        shown and (editor and #editor.inputs or 0) < MAX_INGREDIENTS,
        " + INGREDIENT ",
        N.purple,
        false
    )
    __TS__ArrayForEach(
        self.stepButtons,
        function(____, button, index) return self:neon(
            button,
            shown,
            nil,
            N.purple,
            (editor and editor.step) == STEPS[index + 1]
        ) end
    )
end
function SmelteryScreen.prototype.syncChoices(self, editing)
    local assigning = self.tab == "stock" and self.assigning ~= nil and self.state ~= nil
    local picking = self:pickerOpen() and self.state ~= nil
    self:neon(
        self.chooseButton,
        assigning,
        " CHOOSE FLUID ",
        N.cyan,
        true
    )
    local ____self_neon_166 = self.neon
    local ____self_freeButton_164 = self.freeButton
    local ____N_soft_165 = N.soft
    local ____opt_162 = self.assigning
    ____self_neon_166(
        self,
        ____self_freeButton_164,
        assigning,
        " FREE ",
        ____N_soft_165,
        (____opt_162 and ____opt_162.fluid) == nil
    )
    self:neon(
        self.capacityLess,
        assigning,
        nil,
        N.cyan,
        true
    )
    self:neon(
        self.capacityMore,
        assigning,
        nil,
        N.cyan,
        true
    )
    local panel = assigning or editing
    local savable = assigning or self:editedRecipe().recipe ~= nil
    self:neon(
        self.panelSave,
        panel,
        " SAVE ",
        savable and N.lime or N.dim,
        true
    )
    self:neon(
        self.panelCancel,
        panel,
        " CANCEL ",
        N.soft,
        false
    )
    local ____opt_167 = self.state
    if ____opt_167 ~= nil then
        local ____opt_171 = self.state
        ____opt_167 = __TS__ArrayFind(
            ____opt_171 and ____opt_171.reservoirs,
            function(____, candidate)
                local ____candidate_name_170 = candidate.name
                local ____opt_168 = self.assigning
                return ____candidate_name_170 == (____opt_168 and ____opt_168.reservoir)
            end
        )
    end
    local held = ____opt_167
    local ____assigning_176 = assigning
    if ____assigning_176 then
        local ____opt_174 = self.state
        ____assigning_176 = (____opt_174 and ____opt_174.trash) ~= nil
    end
    local trashable = ____assigning_176 and (held and held.fluid) ~= nil and held.amount > 0
    self:neon(
        self.trashButton,
        trashable,
        " TRASH ",
        N.red,
        false
    )
    local fluids = picking and self:pickerFluids() or ({})
    self.choicePage = math.min(
        self.choicePage,
        math.max(
            1,
            math.ceil(#fluids / PICKER_PAGE)
        )
    )
    self.choicePages:setProps({visible = picking and #fluids > PICKER_PAGE, totalItems = #fluids, page = self.choicePage})
    local chosen = self:chosenFluid()
    local page = self:pagePickerFluids(fluids)
    __TS__ArrayForEach(
        self.pickerButtons,
        function(____, button, cell)
            local fluid = page[cell + 1]
            local label = fluid == nil and "" or __TS__StringPadEnd(
                fit(
                    self:pickerLabel(fluid, fluids),
                    19
                ),
                20
            )
            self:show(
                button,
                picking and fluid ~= nil,
                label,
                fluid == chosen and N.yellow or N.soft,
                N.bg
            )
        end
    )
    local known = self:knownChoices()
    __TS__ArrayForEach(
        self.knownButtons,
        function(____, button, cell)
            local fluid = known[cell + 1]
            local label = fluid == nil and "" or __TS__StringPadEnd(
                fit(
                    self:pickerLabel(fluid, fluids),
                    19
                ),
                20
            )
            self:show(
                button,
                picking and fluid ~= nil,
                label,
                fluid == chosen and N.yellow or N.text,
                N.bg
            )
        end
    )
    local onPage = __TS__New(
        Set,
        __TS__ArrayMap(
            page,
            function(____, fluid) return __TS__StringSubstring(
                fluidLabel(fluid),
                0,
                1
            ) end
        )
    )
    local used = __TS__New(
        Set,
        __TS__ArrayMap(
            fluids,
            function(____, fluid) return __TS__StringSubstring(
                fluidLabel(fluid),
                0,
                1
            ) end
        )
    )
    __TS__ArrayForEach(
        self.letterButtons,
        function(____, button, index)
            local letter = __TS__StringCharAt(LETTERS, index)
            self:neon(
                button,
                picking,
                nil,
                used:has(letter) and N.purple or N.dim,
                onPage:has(letter)
            )
        end
    )
    self:neon(
        self.pickerFree,
        picking and assigning,
        " FREE ",
        N.soft,
        chosen == nil
    )
    self:neon(
        self.pickerCancel,
        picking,
        " CANCEL ",
        N.soft,
        false
    )
end
function SmelteryScreen.prototype.hideUnderPicker(self)
    local ____Set_180 = Set
    local ____array_179 = __TS__SparseArrayNew(unpack(self.pickerButtons))
    __TS__SparseArrayPush(
        ____array_179,
        unpack(self.knownButtons)
    )
    __TS__SparseArrayPush(
        ____array_179,
        unpack(self.letterButtons)
    )
    local picker = __TS__New(
        ____Set_180,
        {__TS__SparseArraySpread(____array_179)}
    )
    picker:add(self.pickerFree)
    picker:add(self.pickerCancel)
    for ____, button in __TS__Iterator(self.tabButtons:values()) do
        picker:add(button)
    end
    for ____, button in ipairs(self.allButtons) do
        if not picker:has(button) then
            button:setProps({visible = false})
        end
    end
    local under = {
        self.castPages,
        self.itemPages,
        self.fluidPages,
        self.formatPages,
        self.orderPages,
        self.stockPages,
        self.alloyPages,
        self.logPages
    }
    for ____, pages in ipairs(under) do
        pages:setProps({visible = false})
    end
end
function SmelteryScreen.prototype.bracket(self, p, x, y, width, height, color, title)
    local right = x + width - 1
    local bottom = y + height - 1
    p:pixel(x, y, 1 + 2 + 4 + 16, color)
    p:pixel(x + 1, y, 1 + 2, color)
    p:pixel(right - 1, y, 1 + 2, color)
    p:pixel(right, y, 1 + 2 + 8 + 32, color)
    p:pixel(x, bottom, 1 + 4 + 16 + 32, color)
    p:pixel(x + 1, bottom, 16 + 32, color)
    p:pixel(right - 1, bottom, 16 + 32, color)
    p:pixel(right, bottom, 2 + 8 + 16 + 32, color)
    if title ~= nil then
        p:text(
            x + 3,
            y,
            (" " .. fit(title, width - 6)) .. " ",
            color
        )
    end
end
function SmelteryScreen.prototype.bar(self, p, x, y, width, part, color)
    p:fill(
        x,
        y,
        width,
        1,
        N.panel
    )
    local filled = part > 0 and math.max(
        1,
        math.floor(width * math.min(1, part) + 0.5)
    ) or 0
    p:fill(
        x,
        y,
        filled,
        1,
        color
    )
end
function SmelteryScreen.prototype.paint(self, p)
    p:fill(
        1,
        1,
        ____exports.SCREEN_WIDTH,
        ____exports.SCREEN_HEIGHT,
        N.bg
    )
    self:paintHeader(p)
    local state = self.state
    if state == nil then
        p:text(36, 24, "Waiting for the controller...", N.cyan)
        p:text(31, 26, "Is the foundry computer running main?", N.dim)
        return
    end
    if self:pickerOpen() then
        self:paintFluidPicker(p)
        self:paintFooter(p, state)
        return
    end
    if self.tab == "overview" then
        self:paintOverview(p, state)
    elseif self.tab == "modes" then
        self:paintModes(p, state)
    elseif self.tab == "manual" then
        self:paintManual(p, state)
    elseif self.tab == "stock" then
        self:paintStock(p, state)
    else
        self:paintLog(p, state)
    end
    self:paintFooter(p, state)
end
function SmelteryScreen.prototype.paintHeader(self, p)
    p:text(3, 2, Glyph.up, N.cyan)
    p:text(5, 2, "SMELTERY//OS", N.cyan)
    local x = TABS_X
    for ____, ____value in ipairs(TABS) do
        local tab = ____value[1]
        local label = ____value[2]
        if tab == self.tab then
            p:text(
                x,
                3,
                string.rep(
                    Glyph.underline,
                    math.floor(#label)
                ),
                N.magenta
            )
        end
        x = x + (#label + 4)
    end
    local ____opt_181 = self.state
    local mode = ____opt_181 and ____opt_181.mode
    if mode ~= nil then
        p:text(
            84,
            2,
            (Glyph.dot .. " ") .. string.upper(mode),
            MODE_COLORS[mode]
        )
    end
    local online = os.clock() - self.lastState < OFFLINE_SECONDS
    p:text(93, 2, online and "LINK" or "LOST", online and N.cyan or N.red)
    p:fill(
        98,
        2,
        1,
        1,
        online and N.cyan or N.red
    )
end
function SmelteryScreen.prototype.paintFooter(self, p, state)
    p:fill(
        1,
        49,
        ____exports.SCREEN_WIDTH,
        4,
        N.panel
    )
    local message = self.message
    if message ~= nil and os.clock() < message["until"] then
        p:text(
            3,
            50,
            fit(message.text, 96),
            message.color,
            N.panel
        )
        return
    end
    if self.tab == "log" then
        local shown = #self:pageLogLines()
        p:text(
            3,
            50,
            ((((tostring(shown) .. " of ") .. tostring(#self:logLines())) .. " lines ") .. Glyph.mid) .. " touch a filter to narrow",
            N.dim,
            N.panel
        )
        return
    end
    local lines = attentionLines(state)
    local first = lines[1]
    if first ~= nil then
        local more = #lines > 1 and (" (+" .. tostring(#lines - 1)) .. " in LOG)" or ""
        local text = ("!! " .. first.title) .. (first.detail ~= "" and ": " .. first.detail or "")
        p:text(
            3,
            50,
            fit(text, 94 - #more) .. more,
            first.color == colors.red and N.magenta or N.yellow,
            N.panel
        )
        return
    end
    local last
    do
        local index = #state.log - 1
        while index >= 0 and last == nil do
            local line = state.log[index + 1]
            if line ~= nil and __TS__StringSubstring(line, 8, 11) ~= "   " then
                last = line
            end
            index = index - 1
        end
    end
    if last == nil then
        return
    end
    local line = parseLogLine(last)
    p:text(
        3,
        50,
        line.time,
        N.dim,
        N.panel
    )
    if line.kind ~= "other" then
        p:text(
            13,
            50,
            string.upper(line.kind),
            LOG_COLORS[line.kind],
            N.panel
        )
    end
    p:text(
        21,
        50,
        fit(line.text, 78),
        N.text,
        N.panel
    )
end
function SmelteryScreen.prototype.paintOverview(self, p, state)
    local draft = self.capacityDraft
    local capacity = draft or state.smelteryCapacity
    local total = __TS__ArrayReduce(
        state.fluids,
        function(____, sum, fluid) return sum + fluid.amount end,
        0
    )
    self:bracket(
        p,
        3,
        5,
        46,
        16,
        N.cyan,
        ("MOLTEN " .. Glyph.mid) .. " 10 MIN"
    )
    local ____array_183 = __TS__SparseArrayNew(unpack(state.history or ({})))
    __TS__SparseArrayPush(____array_183, total)
    local points = {__TS__SparseArraySpread(____array_183)}
    local scale = capacity or math.max(
        1,
        unpack(points)
    )
    local curve = __TS__New(
        Pixels,
        9,
        7,
        27,
        13
    )
    local width = 27 * 2 - 1
    local height = 13 * 3 - 1
    curve:line(
        0,
        height,
        width,
        height,
        N.dim
    )
    local function place(____, index)
        return {
            #points == 1 and width or math.floor(index * width / (#points - 1) + 0.5),
            height - math.floor(height * math.min(1, points[index + 1] / scale) + 0.5)
        }
    end
    do
        local index = 1
        while index < #points do
            local x0, y0 = unpack(
                place(nil, index - 1),
                1,
                2
            )
            local x1, y1 = unpack(
                place(nil, index),
                1,
                2
            )
            curve:line(
                x0,
                y0,
                x1,
                y1,
                N.cyan
            )
            index = index + 1
        end
    end
    if #points == 1 then
        local x0, y0 = unpack(
            place(nil, 0),
            1,
            2
        )
        curve:set(x0, y0, N.cyan)
    end
    curve:paint(p)
    p:text(
        5,
        7,
        shortAmount(scale),
        N.dim
    )
    p:text(5, 19, "0", N.dim)
    p:text(
        38,
        7,
        fit(
            tostring(total) .. " mB",
            10
        ),
        N.text
    )
    p:text(
        38,
        8,
        capacity ~= nil and fit(
            tostring(math.floor(100 * total / capacity + 0.5)) .. " % cap",
            10
        ) or "cap ?",
        capacity ~= nil and N.cyan or N.dim
    )
    local melting = __TS__ArrayReduce(
        state.melting,
        function(____, sum, item) return sum + item.count end,
        0
    )
    p:text(38, 10, "melting", N.dim)
    p:text(
        38,
        11,
        fit(
            (tostring(melting) .. " item") .. (melting == 1 and "" or "s"),
            10
        ),
        N.soft
    )
    self:bracket(
        p,
        3,
        23,
        46,
        24,
        N.purple,
        state.trash ~= nil and ("STACK " .. Glyph.mid) .. " touch a fluid to trash it" or "STACK"
    )
    local stack = __TS__ArrayReverse({unpack(state.fluids)})
    __TS__ArrayForEach(
        __TS__ArraySlice(stack, 0, STACK_ROWS),
        function(____, fluid, index)
            local y = 26 + index * 3
            local color = fluidColor(fluid.name)
            local amount = tostring(fluid.amount) .. " mB"
            p:text(
                6,
                y,
                fit(
                    string.upper(fluidLabel(fluid.name)),
                    math.min(24, 38 - #amount)
                ),
                color
            )
            p:text(46 - #amount, y, amount, N.text)
            self:bar(
                p,
                6,
                y + 1,
                40,
                fluid.amount / scale,
                color
            )
        end
    )
    if #stack > STACK_ROWS then
        p:text(
            6,
            37,
            ("+ " .. tostring(#stack - STACK_ROWS)) .. " more",
            N.dim
        )
    end
    if #stack == 0 then
        p:text(6, 26, "The Smeltery is empty.", N.dim)
    end
    p:text(6, 40, "FUEL", N.yellow)
    local fuel = state.fuel
    if fuel ~= nil then
        local name = fuel.fluid ~= nil and fluidLabel(fuel.fluid) or "empty"
        p:text(
            11,
            40,
            fit(
                ((((((name .. " ") .. tostring(fuel.amount)) .. " mB ") .. Glyph.mid) .. " ") .. tostring(state.heat or "?")) .. " K",
                35
            ),
            N.text
        )
        self:bar(
            p,
            6,
            41,
            40,
            fuel.amount / FUEL_TANK,
            N.yellow
        )
    else
        p:text(
            11,
            40,
            fit(
                ((("no fuel tank " .. Glyph.mid) .. " ") .. tostring(state.heat or "?")) .. " K assumed",
                35
            ),
            N.dim
        )
    end
    if draft ~= nil then
        self:paintCapacity(p, state, draft)
        return
    end
    self:paintFlow(p, state)
    self:paintCasters(p)
end
function SmelteryScreen.prototype.paintFlow(self, p, state)
    self:bracket(
        p,
        51,
        5,
        48,
        16,
        N.magenta,
        ("INPUT " .. Glyph.right) .. " OUTPUT"
    )
    local items = __TS__ArrayFilter(
        state.inputItems,
        function(____, item) return item.status ~= "unknown" end
    )
    local count = __TS__ArrayReduce(
        items,
        function(____, sum, item) return sum + item.count end,
        0
    )
    local amount = __TS__ArrayReduce(
        items,
        function(____, sum, item) return sum + item.count * itemAmount(item.name) end,
        0
    )
    p:text(54, 7, "TO MELT", N.magenta)
    p:text(
        63,
        7,
        count == 0 and "the input is empty" or fit(
            ((((tostring(count) .. " items ") .. Glyph.mid) .. " ~") .. tostring(amount)) .. " mB",
            34
        ),
        count == 0 and N.dim or N.text
    )
    local input = state.input
    if input ~= nil then
        self:bar(
            p,
            54,
            8,
            30,
            input.used / math.max(1, input.size),
            N.magenta
        )
    end
    local seconds = state.inputSeconds
    local eta = count == 0 and "" or (seconds == nil and "waiting" or (seconds <= 0 and "done" or ("~" .. tostring(math.max(
        1,
        math.ceil(seconds / 60)
    ))) .. " min"))
    p:text(
        86,
        8,
        fit(eta, 12),
        N.magenta
    )
    p:text(54, 10, "WILL BECOME", N.cyan)
    p:text(67, 10, "(AUTO casts)", N.dim)
    local forecast = __TS__ArraySort(
        {unpack(state.forecast or ({}))},
        function(____, a, b) return b.amount - a.amount end
    )
    __TS__ArrayForEach(
        __TS__ArraySlice(forecast, 0, 3),
        function(____, entry, index)
            local y = 12 + index * 2
            local color = fluidColor(entry.fluid)
            p:fill(
                54,
                y,
                1,
                1,
                color
            )
            p:text(
                56,
                y,
                fit(
                    fluidLabel(entry.fluid),
                    9
                ),
                color
            )
            p:text(
                66,
                y,
                __TS__StringPadStart(
                    tostring(entry.amount),
                    5
                ),
                N.dim
            )
            local casts = table.concat(
                __TS__ArrayMap(
                    entry.casts,
                    function(____, cast) return (tostring(cast.count) .. " ") .. formatLabel(cast.format) end
                ),
                " "
            )
            p:text(
                72,
                y,
                (Glyph.right .. " ") .. fit(casts ~= "" and casts or "stock", 24),
                N.text
            )
        end
    )
    local left = __TS__ArrayReduce(
        forecast,
        function(____, sum, entry) return sum + entry.left end,
        0
    )
    local more = #forecast > 3 and (" (+" .. tostring(#forecast - 3)) .. " more)" or ""
    if #forecast == 0 then
        p:text(54, 19, "nothing molten", N.dim)
    elseif left > 0 then
        p:text(
            54,
            19,
            fit(
                (tostring(left) .. " mB to the stock") .. more,
                43
            ),
            N.orange
        )
    else
        p:text(
            54,
            19,
            fit("nothing left over" .. more, 43),
            N.lime
        )
    end
end
function SmelteryScreen.prototype.paintCasters(self, p)
    self:bracket(
        p,
        51,
        23,
        48,
        24,
        N.lime,
        "CASTERS"
    )
    local groups = self:castGroups()
    __TS__ArrayForEach(
        __TS__ArraySlice(groups, (self.castPage - 1) * CASTS_PER_PAGE, self.castPage * CASTS_PER_PAGE),
        function(____, group, index)
            local y = 26 + index * 3
            p:text(
                54,
                y,
                fit(
                    string.upper(formatLabel(group.format)),
                    11
                ),
                group.auto and N.text or N.dim
            )
            local x = 66
            local blocks = {{group.casting, group.auto and N.orange or N.dim}, {group.ready, group.auto and N.yellow or N.dim}, {group.free, N.panel}}
            for ____, ____value in ipairs(blocks) do
                local count = ____value[1]
                local color = ____value[2]
                do
                    local n = 0
                    while n < count and x < 88 do
                        p:fill(
                            x,
                            y,
                            2,
                            1,
                            color
                        )
                        x = x + 3
                        n = n + 1
                    end
                end
            end
        end
    )
    if #groups == 0 then
        p:text(54, 26, "no caster found", N.dim)
    end
    p:fill(
        54,
        42,
        2,
        1,
        N.orange
    )
    p:text(57, 42, "casting", N.dim)
    p:fill(
        66,
        42,
        2,
        1,
        N.yellow
    )
    p:text(69, 42, "ready", N.dim)
    p:fill(
        76,
        42,
        2,
        1,
        N.panel
    )
    p:text(79, 42, "free", N.dim)
    p:text(
        54,
        44,
        fit("touch AUTO to switch a cast", #groups > CASTS_PER_PAGE and 30 or 43),
        N.dim
    )
end
function SmelteryScreen.prototype.paintCapacity(self, p, state, draft)
    self:bracket(
        p,
        51,
        5,
        48,
        42,
        N.cyan,
        "SMELTERY CAPACITY"
    )
    p:text(54, 8, "Total room for molten metal.", N.text)
    p:text(54, 9, "Read it in the Smeltery screen.", N.dim)
    p:text(54, 12, "NOW", N.dim)
    local capacity = state.smelteryCapacity
    local source = state.smelteryCapacitySource == "learnt" and "learnt (it was full)" or "set by hand"
    p:text(
        59,
        12,
        capacity ~= nil and fit(
            (((tostring(capacity) .. " mB ") .. Glyph.mid) .. " ") .. source,
            38
        ) or "unknown",
        capacity ~= nil and N.cyan or N.dim
    )
    p:text(
        66,
        17,
        tostring(draft) .. " mB",
        N.text
    )
    p:text(54, 22, "STEP", N.dim)
    p:text(54, 26, "The curve and the stack preview it.", N.dim)
    p:text(54, 28, "AUTO: forget it, learn it again the", N.dim)
    p:text(54, 29, "next time the Smeltery is full.", N.dim)
end
function SmelteryScreen.alloyLines(self, state)
    if state.alloy == nil then
        return {"No alloy chosen:", "touch CHANGE ALLOY."}
    end
    return {
        fit(
            ("Only " .. string.upper(fluidLabel(state.alloy.result))) .. ",",
            19
        ),
        "dosed from the input",
        "and the stock."
    }
end
function SmelteryScreen.prototype.paintModes(self, p, state)
    if self.editor ~= nil then
        self:paintEditor(p, self.editor)
        return
    end
    if self.picking then
        self:paintPicker(p, state)
        return
    end
    __TS__ArrayForEach(
        MODES,
        function(____, mode, index)
            local color = MODE_COLORS[mode]
            local ____cardPlace_result_184 = cardPlace(index)
            local x = ____cardPlace_result_184.x
            local y = ____cardPlace_result_184.y
            local active = state.mode == mode
            self:bracket(
                p,
                x,
                y,
                23,
                19,
                color
            )
            if active then
                p:fill(
                    x + 2,
                    y + 1,
                    19,
                    1,
                    color
                )
                p:text(
                    x + 3,
                    y + 1,
                    string.upper(mode),
                    N.bg,
                    color
                )
            else
                p:text(
                    x + 3,
                    y + 1,
                    string.upper(mode),
                    color
                )
            end
            local lines = mode == "alloy" and ____exports.SmelteryScreen:alloyLines(state) or MODE_LINES[mode]
            __TS__ArrayForEach(
                lines,
                function(____, line, row) return p:text(
                    x + 2,
                    y + 3 + row,
                    fit(line, 19),
                    active and N.text or N.dim
                ) end
            )
            local alloy = state.alloy
            if mode == "alloy" and alloy ~= nil and active then
                if alloy.target == nil then
                    p:text(
                        x + 2,
                        y + 8,
                        fit(
                            tostring(math.floor(alloy.made / INGOT)) .. " ingots made",
                            19
                        ),
                        N.magenta
                    )
                else
                    local target = math.max(
                        1,
                        math.floor(alloy.target / INGOT + 0.5)
                    )
                    p:text(
                        x + 2,
                        y + 8,
                        fit(
                            ((tostring(math.floor(alloy.made / INGOT)) .. "/") .. tostring(target)) .. " ingots",
                            19
                        ),
                        N.magenta
                    )
                    self:bar(
                        p,
                        x + 2,
                        y + 9,
                        19,
                        alloy.made / alloy.target,
                        N.magenta
                    )
                end
            end
            if active then
                local minutes = state.modeSince ~= nil and math.max(
                    0,
                    math.floor((state.time - state.modeSince) / 60000)
                ) or nil
                p:text(
                    x + 2,
                    y + 16,
                    fit(
                        (Glyph.dot .. " ACTIVE") .. (minutes ~= nil and (((" " .. Glyph.mid) .. " ") .. tostring(minutes)) .. " min" or ""),
                        19
                    ),
                    N.lime
                )
            end
        end
    )
    p:text(3, 47, "Touch ACTIVATE: the controller confirms live.", N.dim)
end
function SmelteryScreen.prototype.paintPicker(self, p, state)
    self:bracket(
        p,
        3,
        5,
        58,
        42,
        N.magenta,
        ("ALLOYS " .. Glyph.mid) .. " READY FIRST"
    )
    local options = self:alloyOptions()
    local start = (self.alloyPage - 1) * ALLOYS_PER_PAGE
    local function amount(____, mB)
        return mB % INGOT == 0 and tostring(mB / INGOT) or tostring(mB) .. " mB"
    end
    __TS__ArrayForEach(
        __TS__ArraySlice(options, start, start + ALLOYS_PER_PAGE),
        function(____, option, index)
            local y = 7 + index * 3
            local picked = option.index == self.picked
            local back = picked and N.panel or N.bg
            if picked then
                p:fill(
                    5,
                    y,
                    55,
                    2,
                    N.panel
                )
                p:text(
                    5,
                    y,
                    Glyph.right,
                    N.magenta,
                    N.panel
                )
            end
            p:fill(
                7,
                y,
                2,
                1,
                fluidColor(option.result)
            )
            local inputs = table.concat(
                __TS__ArrayMap(
                    option.inputs,
                    function(____, input) return (fluidLabel(input.fluid) .. " ") .. amount(nil, input.amount) end
                ),
                " + "
            )
            p:text(
                10,
                y + 1,
                fit(inputs, 36),
                N.dim,
                back
            )
            local status
            if option.temperature ~= nil then
                status = {
                    tostring(option.temperature) .. " K!",
                    N.red
                }
            elseif option.fromStock > 0 then
                status = {
                    ("stock: " .. tostring(math.floor(option.fromStock / INGOT))) .. " ing",
                    N.lime
                }
            else
                status = {"input", N.dim}
            end
            p:text(
                59 - #status[1],
                y,
                status[1],
                status[2],
                back
            )
        end
    )
    if #options == 0 then
        p:text(6, 7, "No alloy in the catalogue: touch NEW.", N.dim)
    end
    self:bracket(
        p,
        63,
        31,
        36,
        16,
        N.purple,
        "CATALOGUE"
    )
    local sameName = #options - __TS__New(
        Set,
        __TS__ArrayMap(
            options,
            function(____, option) return option.result end
        )
    ).size
    p:text(
        65,
        33,
        fit(
            (tostring(#options) .. " recipes") .. (sameName > 0 and (((" " .. Glyph.mid) .. " ") .. tostring(sameName)) .. " share a name" or ""),
            32
        ),
        N.text
    )
    local option = self:pickedOption()
    if option == nil then
        return
    end
    local label = fluidLabel(option.result)
    self:bracket(
        p,
        63,
        5,
        36,
        24,
        N.cyan,
        string.upper(label)
    )
    local function count(____, mB)
        return mB % INGOT == 0 and tostring(mB / INGOT) .. " " or ""
    end
    __TS__ArrayForEach(
        option.inputs,
        function(____, input, index)
            local y = 7 + index
            p:fill(
                65,
                y,
                2,
                1,
                fluidColor(input.fluid)
            )
            p:text(
                68,
                y,
                fit(
                    count(nil, input.amount) .. fluidLabel(input.fluid),
                    20
                ),
                N.text
            )
            p:text(
                90,
                y,
                __TS__StringPadStart(
                    tostring(input.amount) .. " mB",
                    7
                ),
                N.dim
            )
        end
    )
    local resultY = 7 + #option.inputs
    p:text(
        68,
        resultY,
        fit(
            ((Glyph.right .. " ") .. count(nil, option.amount)) .. label,
            20
        ),
        colors.pink
    )
    p:text(
        90,
        resultY,
        __TS__StringPadStart(
            tostring(option.amount) .. " mB",
            7
        ),
        N.dim
    )
    local stockY = resultY + 2
    p:text(65, stockY, "IN STOCK", N.dim)
    __TS__ArrayForEach(
        option.inputs,
        function(____, input, index)
            local stored = __TS__ArrayReduce(
                __TS__ArrayFilter(
                    state.reservoirs,
                    function(____, reservoir) return reservoir.fluid == input.fluid end
                ),
                function(____, sum, reservoir) return sum + reservoir.amount end,
                0
            )
            p:text(
                65,
                stockY + 1 + index,
                fit(
                    fluidLabel(input.fluid),
                    20
                ),
                N.text
            )
            p:text(
                86,
                stockY + 1 + index,
                __TS__StringPadStart(
                    tostring(stored) .. " mB",
                    11
                ),
                N.cyan
            )
        end
    )
    local ingots = math.floor(option.fromStock / INGOT)
    p:text(
        65,
        stockY + 1 + #option.inputs,
        ("= " .. tostring(ingots)) .. " ingots now",
        ingots > 0 and N.lime or N.dim
    )
    p:text(65, 20, "AMOUNT", N.dim)
    p:text(
        70,
        21,
        self.nonstop and "nonstop" or tostring(self.pickIngots) .. " ingots",
        self.nonstop and N.dim or N.text
    )
    local back = ____exports.SmelteryScreen:endsOnItsOwn(state.mode) and "the previous mode" or string.upper(state.mode)
    p:text(
        65,
        23,
        fit(self.nonstop and "runs until changed" or "then back to " .. back, 32),
        N.dim
    )
end
function SmelteryScreen.endsOnItsOwn(self, mode)
    return mode == "drain" or mode == "purge" or mode == "alloy"
end
function SmelteryScreen.prototype.paintEditor(self, p, editor)
    self:bracket(
        p,
        3,
        5,
        62,
        42,
        N.magenta,
        editor.index ~= nil and "EDIT RECIPE" or "NEW RECIPE"
    )
    p:text(6, 7, "RESULT", N.dim)
    if editor.slot == "result" then
        p:text(4, 9, Glyph.right, N.yellow)
    end
    if editor.result ~= nil then
        p:fill(
            6,
            9,
            2,
            1,
            fluidColor(editor.result)
        )
    end
    p:text(
        35,
        9,
        __TS__StringPadStart(
            tostring(editor.amount) .. " mB",
            8
        ),
        N.text
    )
    p:text(6, 12, "INGREDIENTS", N.dim)
    __TS__ArrayForEach(
        editor.inputs,
        function(____, input, row)
            local y = 14 + row * 2
            if editor.slot == row then
                p:text(4, y, Glyph.right, N.yellow)
            end
            if input.fluid ~= nil then
                p:fill(
                    6,
                    y,
                    2,
                    1,
                    fluidColor(input.fluid)
                )
            end
            p:text(
                35,
                y,
                __TS__StringPadStart(
                    tostring(input.amount) .. " mB",
                    8
                ),
                N.text
            )
        end
    )
    if #editor.inputs < MAX_INGREDIENTS then
        p:text(
            22,
            22,
            ("(up to " .. tostring(MAX_INGREDIENTS)) .. ")",
            N.dim
        )
    end
    p:text(6, 25, "STEP", N.dim)
    p:text(31, 25, "mB", N.dim)
    local ____temp_185 = self:editedRecipe()
    local recipe = ____temp_185.recipe
    local problem = ____temp_185.problem
    if recipe ~= nil then
        local function amount(____, mB, fluid)
            return ((mB % INGOT == 0 and tostring(mB / INGOT) .. " ing" or tostring(mB) .. " mB") .. " ") .. fluidLabel(fluid)
        end
        p:text(6, 28, "ready to save", N.lime)
        p:text(
            6,
            30,
            fit(
                table.concat(
                    __TS__ArrayMap(
                        recipe.inputs,
                        function(____, input) return amount(nil, input.amount, input.fluid) end
                    ),
                    " + "
                ),
                56
            ),
            N.soft
        )
        p:text(
            6,
            31,
            fit(
                "makes " .. amount(nil, recipe.amount, recipe.result),
                56
            ),
            colors.pink
        )
    else
        p:text(
            6,
            28,
            fit("cannot save: " .. (problem or "?"), 56),
            N.red
        )
    end
    self:bracket(
        p,
        67,
        5,
        32,
        42,
        N.cyan,
        "FLUIDS"
    )
    p:text(70, 7, "Touch the result or an", N.dim)
    p:text(70, 8, "ingredient: the fluid", N.dim)
    p:text(70, 9, "picker opens.", N.dim)
end
function SmelteryScreen.prototype.pickerOpen(self)
    if not self.choosing then
        return false
    end
    if self.tab == "stock" then
        return self.assigning ~= nil
    end
    return self.tab == "modes" and self.editor ~= nil and self.editor.slot ~= nil
end
function SmelteryScreen.prototype.paintFluidPicker(self, p)
    local editor = self.editor
    local target
    if self.assigning ~= nil then
        target = placeLabel(self.assigning.reservoir)
    elseif (editor and editor.slot) == "result" then
        target = "the result"
    else
        target = "ingredient " .. tostring((type(editor and editor.slot) == "number" and editor.slot or 0) + 1)
    end
    self:bracket(
        p,
        3,
        5,
        96,
        43,
        N.cyan,
        (("CHOOSE FLUID " .. Glyph.mid) .. " for ") .. target
    )
    local fluids = self:pickerFluids()
    local chosen = self:chosenFluid()
    local function mark(____, x, y, fluid)
        p:fill(
            x,
            y,
            2,
            1,
            fluidColor(fluid)
        )
        if fluid == chosen then
            p:text(x - 1, y, Glyph.right, N.yellow)
        end
    end
    p:text(6, 9, "KNOWN", N.yellow)
    local known = self:knownChoices()
    __TS__ArrayForEach(
        __TS__ArraySlice(known, 0, PICKER_KNOWN),
        function(____, fluid, index) return mark(nil, 6 + index * 23, 10, fluid) end
    )
    if #known == 0 then
        p:text(9, 10, "nothing seen yet", N.dim)
    end
    local page = self:pagePickerFluids(fluids)
    local from = page[1] ~= nil and string.upper(__TS__StringSubstring(
        fluidLabel(page[1]),
        0,
        1
    )) or ""
    p:text(6, 12, "ALL FLUIDS" .. (from ~= "" and ((" " .. Glyph.mid) .. " from ") .. from or ""), N.dim)
    __TS__ArrayForEach(
        page,
        function(____, fluid, index) return mark(
            nil,
            6 + math.floor(index / PICKER_ROWS) * 23,
            13 + index % PICKER_ROWS,
            fluid
        ) end
    )
    if self.allFluids == nil then
        p:text(9, 13, "loading...", N.dim)
    end
    local start = (self.choicePage - 1) * PICKER_PAGE
    local count = #fluids > PICKER_PAGE and (((tostring(start + 1) .. "-") .. tostring(start + #page)) .. " of ") .. tostring(#fluids) or tostring(#fluids) .. " fluids"
    p:text(
        #fluids > PICKER_PAGE and 20 or 6,
        45,
        fit(((count .. " ") .. Glyph.mid) .. " a letter jumps to its page", 60),
        N.dim
    )
end
function SmelteryScreen.prototype.paintManual(self, p, state)
    local manual = state.mode == "manual"
    if manual and self.inputDetails then
        self:paintInputDetails(p, state)
        return
    end
    if manual then
        self:paintFluidCard(p)
        self:paintOrderCard(p)
        self:paintInputBand(p, state)
    else
        p:fill(
            3,
            5,
            96,
            3,
            N.panel
        )
        p:fill(
            3,
            5,
            1,
            3,
            N.yellow
        )
        p:text(
            6,
            6,
            fit(("MANUAL MODE IS OFF " .. Glyph.mid) .. " orders and inserts need it", 70),
            N.yellow,
            N.panel
        )
    end
    self:paintQueue(p, state, manual)
end
function SmelteryScreen.prototype.paintFluidCard(self, p)
    self:bracket(
        p,
        3,
        5,
        30,
        25,
        N.cyan,
        ("1 " .. Glyph.mid) .. " FLUID"
    )
    local fluids = self:fluids()
    __TS__ArrayForEach(
        fluids,
        function(____, fluid, row)
            local y = 7 + row * 2
            if fluid.name == self.fluid then
                p:text(4, y, Glyph.right, N.yellow)
            end
            p:fill(
                5,
                y,
                2,
                1,
                fluidColor(fluid.name)
            )
            if fluid.amount > 0 and fluid.stored > 0 then
                local stored = ("+" .. shortAmount(fluid.stored)) .. " stored"
                p:text(31 - #stored, y + 1, stored, N.dim)
            end
        end
    )
    if #fluids == 0 then
        p:text(5, 7, "No fluid in the Smeltery", N.dim)
        p:text(5, 8, "nor in the reservoirs.", N.dim)
    end
end
function SmelteryScreen.prototype.paintOrderCard(self, p)
    local fluid = self.fluid
    local craft = self.orderView == "craft"
    local title = fluid ~= nil and (((("2 " .. Glyph.mid) .. " ORDER ") .. Glyph.mid) .. " ") .. string.upper(fluidLabel(fluid)) or ("2 " .. Glyph.mid) .. " ORDER"
    if craft then
        title = ((("2 " .. Glyph.mid) .. " CRAFT ") .. Glyph.mid) .. " onto an item"
    end
    local ____self_bracket_196 = self.bracket
    local ____p_194 = p
    local ____N_yellow_195 = N.yellow
    local ____opt_192 = self.state
    local ____opt_190 = ____opt_192 and ____opt_192.craftCasters
    ____self_bracket_196(
        self,
        ____p_194,
        35,
        5,
        64,
        25,
        ____N_yellow_195,
        (____opt_190 and #____opt_190 or 0) > 0 and fit(title, 40) or title
    )
    if craft then
        self:paintCraftView(p)
        return
    end
    local formats = self:pageFormats()
    __TS__ArrayForEach(
        formats,
        function(____, group, cell)
            local ____temp_197 = ____exports.SmelteryScreen:formatPlace(cell)
            local x = ____temp_197.x
            local y = ____temp_197.y
            local count = self:countOf(group.format)
            p:text(
                x,
                y,
                fit(
                    formatLabel(group.format),
                    13
                ),
                fluid == nil and N.dim or (count > 0 and N.yellow or N.soft)
            )
            p:text(
                x + 14,
                y,
                __TS__StringPadStart(
                    (tostring(group.free) .. "/") .. tostring(group.free + group.casting + group.ready),
                    5
                ),
                N.dim
            )
            if fluid ~= nil then
                p:text(
                    x + 24,
                    y,
                    __TS__StringPadStart(
                        tostring(count),
                        2
                    ),
                    count > 0 and N.yellow or N.dim
                )
            end
        end
    )
    if #formats == 0 then
        local none = fluid ~= nil and ("No cast on the network has a recipe for " .. fluidLabel(fluid)) .. "." or "No cast on the network."
        p:text(
            37,
            7,
            fit(none, 60),
            N.dim
        )
    end
    if fluid == nil then
        p:text(37, 19, "Pick a fluid on the left, then set how many", N.dim)
        p:text(37, 20, "castings of each shape (free / casters).", N.dim)
        return
    end
    local lines = self:orderLines()
    local ____temp_198 = self:orderNeeds()
    local needs = ____temp_198.needs
    local have = ____temp_198.have
    local stored = ____temp_198.stored
    local total = have + stored
    p:text(37, 19, "ORDER", N.dim)
    local what = table.concat(
        __TS__ArrayMap(
            lines,
            function(____, line) return (tostring(line.count) .. " ") .. formatLabel(line.format) end
        ),
        (" " .. Glyph.mid) .. " " or ","
    )
    p:text(
        45,
        19,
        fit(#lines > 0 and what or "nothing yet: touch + on a shape", 52),
        #lines > 0 and N.soft or N.dim
    )
    p:text(37, 20, "NEEDS", N.dim)
    p:text(
        45,
        20,
        needs ~= nil and (tostring(needs) .. " mB ") .. fluidLabel(fluid) or "? mB (cast amounts unknown)",
        N.text
    )
    p:text(37, 21, "HAVE", N.dim)
    p:text(
        45,
        21,
        fit(
            stored > 0 and ((((tostring(have) .. " + ") .. tostring(stored)) .. " stored = ") .. tostring(total)) .. " mB" or tostring(have) .. " mB",
            52
        ),
        N.text
    )
    if #lines > 0 and needs ~= nil then
        if needs > total then
            p:text(37, 22, "SHORT", N.dim)
            p:text(
                45,
                22,
                fit(
                    tostring(needs - total) .. " mB: casts what it can, then waits",
                    52
                ),
                N.orange
            )
        else
            p:text(45, 22, "enough: it all casts", N.lime)
        end
    end
    local ready = #lines > 0
    p:fill(
        77,
        25,
        20,
        3,
        ready and N.lime or N.panel
    )
end
function SmelteryScreen.prototype.paintCraftView(self, p)
    local casters = self:craftCasters()
    __TS__ArrayForEach(
        casters,
        function(____, caster, index)
            local y = 7 + index * (CRAFT_RECIPE_ROWS + 1)
            local kind = caster.kind == "basin" and "BASIN" or "TABLE"
            p:text(37, y, kind, N.cyan)
            p:text(
                43,
                y,
                fit(
                    placeLabel(caster.name),
                    16
                ),
                N.dim
            )
            local more = #caster.recipes > CRAFT_RECIPE_ROWS and (" (+" .. tostring(#caster.recipes - CRAFT_RECIPE_ROWS)) .. " recipes)" or ""
            local holds = caster.item ~= nil and ("holds " .. placeLabel(caster.item)) .. more or "put an item on the " .. string.lower(kind)
            p:text(
                60,
                y,
                fit(holds, 37),
                caster.item ~= nil and N.text or N.dim
            )
            if caster.item ~= nil and #caster.recipes == 0 then
                p:text(39, y + 1, "No recipe casts onto this item.", N.dim)
            end
        end
    )
    local ____opt_201 = self.state
    local ____opt_199 = ____opt_201 and ____opt_201.craftCasters
    local extra = (____opt_199 and #____opt_199 or 0) - #casters
    if extra > 0 then
        p:text(
            37,
            19,
            ("+ " .. tostring(extra)) .. " craft caster(s) not shown",
            N.dim
        )
    end
    local picked = self:pickedCraft()
    if picked == nil then
        p:text(37, 21, "Put an item on a craft caster, pick a recipe,", N.dim)
        p:text(37, 22, "then set how many castings.", N.dim)
        return
    end
    local caster = picked.caster
    local recipe = picked.recipe
    local known = __TS__ArrayFind(
        self:manualFluids(),
        function(____, candidate) return candidate.name == recipe.fluid end
    )
    local have = known and known.amount or 0
    local stored = known and known.stored or 0
    local needs = recipe.amount * self.craftCount
    p:text(37, 20, "CRAFT", N.dim)
    p:text(
        45,
        20,
        fit(
            (placeLabel(recipe.result) .. " on ") .. placeLabel(caster.name),
            52
        ),
        N.yellow
    )
    p:text(37, 21, "NEEDS", N.dim)
    p:text(
        45,
        21,
        fit(
            ((tostring(needs) .. " mB ") .. fluidLabel(recipe.fluid)) .. (recipe.consumed and self.craftCount > 1 and (", one " .. placeLabel(caster.item or "item")) .. " each" or ""),
            52
        ),
        N.text
    )
    p:text(37, 22, "HAVE", N.dim)
    p:text(
        45,
        22,
        fit(
            stored > 0 and ((((tostring(have) .. " + ") .. tostring(stored)) .. " stored = ") .. tostring(have + stored)) .. " mB" or tostring(have) .. " mB",
            30
        ),
        needs > have + stored and N.orange or N.text
    )
    p:text(37, 24, "COUNT", N.dim)
    p:text(
        49,
        24,
        __TS__StringPadStart(
            tostring(self.craftCount),
            2
        ),
        N.yellow
    )
    p:fill(
        77,
        25,
        20,
        3,
        N.lime
    )
end
function SmelteryScreen.prototype.paintQueue(self, p, state, manual)
    local orders = state.orders or ({})
    local how = manual and "side by side" or "PAUSED"
    self:bracket(
        p,
        3,
        31,
        96,
        13,
        N.magenta,
        (((((("QUEUE " .. Glyph.mid) .. " ") .. tostring(#orders)) .. " ") .. Glyph.mid) .. " ") .. how
    )
    if #orders == 0 then
        p:text(5, 33, manual and "No order. Pick a fluid, set the counts, then SEND." or "No order.", N.dim)
    end
    __TS__ArrayForEach(
        self:pageOrders(),
        function(____, order, row)
            local y = 33 + row * 2
            p:text(
                5,
                y,
                "#" .. tostring(order.id),
                N.dim
            )
            p:fill(
                10,
                y,
                2,
                1,
                fluidColor(order.fluid)
            )
            p:text(
                13,
                y,
                fit(
                    fluidLabel(order.fluid),
                    10
                ),
                N.text
            )
            local status = {"QUEUED", N.soft}
            if not manual then
                status = {"PAUSED", N.dim}
            elseif order.status == "pouring" then
                status = {"POURING", N.lime}
            elseif order.status == "waiting" then
                status = {"WAITING", N.orange}
            end
            p:text(24, y, status[1], status[2])
            local craft = order.craft
            local ____temp_213
            if craft ~= nil then
                local ____placeLabel_result_211 = placeLabel(craft.result)
                local ____opt_207 = order.lines[1]
                local ____temp_212 = ____opt_207 and ____opt_207.done or 0
                local ____opt_209 = order.lines[1]
                ____temp_213 = (((((____placeLabel_result_211 .. " ") .. tostring(____temp_212)) .. "/") .. tostring(____opt_209 and ____opt_209.count or 0)) .. " on ") .. placeLabel(craft.caster)
            else
                ____temp_213 = table.concat(
                    __TS__ArrayMap(
                        order.lines,
                        function(____, line) return (((formatLabel(line.format) .. " ") .. tostring(line.done)) .. "/") .. tostring(line.count) end
                    ),
                    "  "
                )
            end
            local lines = ____temp_213
            p:text(
                33,
                y,
                fit(lines, 37),
                N.soft
            )
            if order.status == "waiting" then
                local need = craft and craft.need
                local why = need ~= nil and "put " .. (__TS__StringStartsWith(need, "#") and "any " .. placeLabel(__TS__StringSubstring(need, 1)) or placeLabel(need)) or (order.alloy ~= nil and "would form " .. fluidLabel(order.alloy) or ("needs " .. tostring(order.missing or "?")) .. " mB")
                p:text(
                    72,
                    y,
                    fit(why, 21),
                    N.orange
                )
            end
        end
    )
end
function SmelteryScreen.prototype.paintInputBand(self, p, state)
    local items = state.inputItems
    p:fill(
        3,
        45,
        96,
        3,
        N.panel
    )
    p:text(
        5,
        46,
        "INPUT",
        N.cyan,
        N.panel
    )
    if #items == 0 then
        p:text(
            12,
            46,
            "empty",
            N.dim,
            N.panel
        )
        return
    end
    local function count(____, status)
        return #__TS__ArrayFilter(
            items,
            function(____, item) return item.status == status end
        )
    end
    local parts = {{
        (tostring(#items) .. " slot") .. (#items > 1 and "s" or ""),
        N.text
    }}
    if count(nil, "ok") > 0 then
        parts[#parts + 1] = {
            tostring(count(nil, "ok")) .. " ready",
            N.lime
        }
    end
    if count(nil, "alloy") > 0 then
        parts[#parts + 1] = {
            tostring(count(nil, "alloy")) .. " alloy",
            N.red
        }
    end
    if count(nil, "heat") > 0 then
        parts[#parts + 1] = {
            tostring(count(nil, "heat")) .. " too hot",
            N.orange
        }
    end
    if count(nil, "unknown") > 0 then
        parts[#parts + 1] = {
            tostring(count(nil, "unknown")) .. " no fluid",
            N.dim
        }
    end
    local x = 12
    for ____, ____value in ipairs(parts) do
        local text = ____value[1]
        local color = ____value[2]
        p:text(
            x,
            46,
            text,
            color,
            N.panel
        )
        x = x + (#text + 2)
    end
end
function SmelteryScreen.prototype.paintInputDetails(self, p, state)
    local items = state.inputItems
    self:bracket(
        p,
        3,
        5,
        96,
        38,
        N.cyan,
        (((("INPUT " .. Glyph.mid) .. " ") .. tostring(#items)) .. " slot") .. (#items == 1 and "" or "s")
    )
    p:text(6, 7, "SLOT", N.dim)
    p:text(12, 7, "ITEM", N.dim)
    p:text(46, 7, "COUNT", N.dim)
    p:text(53, 7, "STATUS", N.dim)
    __TS__ArrayForEach(
        self:pageItems(),
        function(____, item, row)
            local y = 9 + row * 2
            p:text(
                6,
                y,
                __TS__StringPadStart(
                    tostring(item.slot),
                    3
                ),
                N.dim
            )
            p:text(
                12,
                y,
                fit(
                    string.upper(placeLabel(item.name)),
                    32
                ),
                N.text
            )
            p:text(
                46,
                y,
                __TS__StringPadStart(
                    tostring(item.count),
                    5
                ),
                N.soft
            )
            local status = {
                (("ready " .. Glyph.right) .. " ") .. (item.fluid ~= nil and fluidLabel(item.fluid) or ""),
                N.lime
            }
            if item.status == "alloy" then
                status = {
                    "would form " .. fluidLabel(item.alloy or "an alloy"),
                    N.red
                }
            elseif item.status == "heat" then
                status = {
                    ("needs " .. tostring(item.temperature or "?")) .. " K",
                    N.orange
                }
            elseif item.status == "unknown" then
                status = {"melts into nothing known", N.dim}
            end
            p:text(
                53,
                y,
                fit(status[1], 31),
                status[2]
            )
        end
    )
    if #items == 0 then
        p:text(6, 9, "The input is empty.", N.dim)
    end
    p:text(
        #items > ITEMS_PER_PAGE and 20 or 6,
        40,
        fit(("FORCE asks twice " .. Glyph.mid) .. " INSERT READY skips what is refused", 70),
        N.dim
    )
end
function SmelteryScreen.prototype.paintStock(self, p, state)
    local reservoirs = state.reservoirs
    self:bracket(
        p,
        3,
        5,
        62,
        43,
        N.cyan,
        ("RESERVOIRS " .. Glyph.mid) .. " FULL FIRST"
    )
    local known = 0
    local scale = 0
    for ____, reservoir in ipairs(reservoirs) do
        do
            local __continue548
            repeat
                if reservoir.capacity == nil then
                    __continue548 = true
                    break
                end
                known = known + 1
                scale = math.max(scale, reservoir.capacity)
                __continue548 = true
            until true
            if not __continue548 then
                break
            end
        end
    end
    if scale == 0 then
        scale = DEFAULT_CAPACITY
    end
    __TS__ArrayForEach(
        self:pageReservoirs(),
        function(____, reservoir, index)
            local ____temp_216 = ____exports.SmelteryScreen:reservoirPlace(index)
            local x = ____temp_216.x
            local y = ____temp_216.y
            local fluid = reservoir.fluid
            local color = fluid ~= nil and fluidColor(fluid) or N.dim
            local tube = __TS__New(
                Pixels,
                x + 1,
                y,
                4,
                4
            )
            tube:rect(
                0,
                0,
                1,
                12,
                color
            )
            tube:rect(
                7,
                0,
                1,
                12,
                color
            )
            tube:rect(
                0,
                11,
                8,
                1,
                color
            )
            if fluid ~= nil and reservoir.amount > 0 then
                local rows = math.min(
                    11,
                    math.max(
                        1,
                        math.floor(11 * reservoir.amount / (reservoir.capacity or scale) + 0.5)
                    )
                )
                tube:rect(
                    1,
                    11 - rows,
                    6,
                    rows,
                    color
                )
            end
            tube:paint(p)
            if reservoir.capacity ~= nil and reservoir.amount >= reservoir.capacity then
                p:text(x + 6, y, "FULL", N.yellow)
            end
            local ____reservoir_name_219 = reservoir.name
            local ____opt_217 = self.assigning
            if ____reservoir_name_219 == (____opt_217 and ____opt_217.reservoir) then
                p:text(x - 1, y + 6, Glyph.right, N.yellow)
            end
            local label
            if fluid ~= nil and reservoir.assigned ~= nil and reservoir.assigned ~= fluid then
                label = {
                    "for " .. fluidLabel(reservoir.assigned),
                    N.orange
                }
            elseif fluid ~= nil then
                label = {
                    tostring(reservoir.amount) .. " mB",
                    N.text
                }
            elseif reservoir.assigned ~= nil then
                label = {
                    "for " .. fluidLabel(reservoir.assigned),
                    N.yellow
                }
            else
                label = {"free", N.dim}
            end
            p:text(
                x,
                y + 5,
                fit(label[1], 11),
                label[2]
            )
            p:text(
                x,
                y + 7,
                reservoirLines(reservoir.name, 11)[2],
                N.dim
            )
        end
    )
    if #reservoirs == 0 then
        p:text(6, 7, "No reservoir found.", N.dim)
    else
        p:text(#reservoirs > RESERVOIRS_PER_PAGE and 19 or 6, 45, "touch a name to reserve it", N.dim)
    end
    if self.assigning ~= nil then
        self:paintAssign(p, state, self.assigning)
        return
    end
    self:bracket(
        p,
        67,
        5,
        32,
        18,
        N.purple,
        "TOTALS"
    )
    local totals = {}
    for ____, reservoir in ipairs(reservoirs) do
        do
            local __continue563
            repeat
                if reservoir.fluid == nil then
                    __continue563 = true
                    break
                end
                local entry = __TS__ArrayFind(
                    totals,
                    function(____, candidate) return candidate.fluid == reservoir.fluid end
                )
                if entry ~= nil then
                    entry.amount = entry.amount + reservoir.amount
                else
                    totals[#totals + 1] = {fluid = reservoir.fluid, amount = reservoir.amount}
                end
                __continue563 = true
            until true
            if not __continue563 then
                break
            end
        end
    end
    __TS__ArraySort(
        totals,
        function(____, a, b) return b.amount - a.amount end
    )
    local ____opt_220 = totals[1]
    local biggest = ____opt_220 and ____opt_220.amount or 1
    __TS__ArrayForEach(
        __TS__ArraySlice(totals, 0, 4),
        function(____, total, index)
            local y = 7 + index * 4
            local color = fluidColor(total.fluid)
            local ingots = tostring(math.floor(total.amount / INGOT)) .. " ing"
            p:text(
                70,
                y,
                fit(
                    string.upper(fluidLabel(total.fluid)),
                    25 - #ingots
                ),
                color
            )
            p:text(96 - #ingots, y, ingots, N.text)
            self:bar(
                p,
                70,
                y + 1,
                26,
                total.amount / biggest,
                color
            )
        end
    )
    if #totals > 4 then
        p:text(
            70,
            21,
            ("+ " .. tostring(#totals - 4)) .. " more",
            N.dim
        )
    end
    if #totals == 0 then
        p:text(70, 7, "Nothing stored.", N.dim)
    end
    self:bracket(
        p,
        67,
        24,
        32,
        10,
        N.lime,
        "ROOM"
    )
    local empty = __TS__ArrayFilter(
        reservoirs,
        function(____, reservoir) return reservoir.fluid == nil end
    )
    local free = #__TS__ArrayFilter(
        empty,
        function(____, reservoir) return reservoir.assigned == nil end
    )
    local assigned = __TS__ArrayFilter(
        empty,
        function(____, reservoir) return reservoir.assigned ~= nil end
    )
    local room = tostring(free) .. " free"
    if #assigned == 1 then
        room = room .. ((" " .. Glyph.mid) .. " 1 for ") .. fluidLabel(assigned[1].assigned)
    elseif #assigned > 1 then
        room = room .. (((" " .. Glyph.mid) .. " ") .. tostring(#assigned)) .. " reserved"
    end
    p:text(
        70,
        26,
        fit(room, 27),
        N.text
    )
    p:text(
        70,
        28,
        (("capacity known " .. tostring(known)) .. "/") .. tostring(#reservoirs),
        N.dim
    )
    p:text(70, 30, "touch a name to set it", N.dim)
    local alerts = __TS__ArrayFilter(
        state.alerts,
        function(____, alert) return __TS__StringStartsWith(alert, "no reservoir") end
    )
    local small = state.smallStocks or ({})
    if #alerts > 0 then
        self:bracket(
            p,
            67,
            35,
            32,
            13,
            N.red,
            "NO ROOM"
        )
        local line = unpack(
            attentionLines(__TS__ObjectAssign({}, state, {alerts = alerts, waiting = {}})),
            1,
            1
        )
        if line ~= nil then
            p:text(
                70,
                37,
                fit(line.title, 27),
                N.red
            )
            p:text(
                70,
                38,
                fit(line.detail, 27),
                N.dim
            )
        end
        if #alerts > 1 then
            p:text(
                70,
                40,
                ("+ " .. tostring(#alerts - 1)) .. " more",
                N.dim
            )
        end
    elseif #small > 0 then
        self:bracket(
            p,
            67,
            35,
            32,
            13,
            N.yellow,
            "BELOW A CAST"
        )
        __TS__ArrayForEach(
            __TS__ArraySlice(small, 0, 3),
            function(____, stock, index)
                local y = 37 + index * 3
                local holder = __TS__ArrayFind(
                    reservoirs,
                    function(____, reservoir) return reservoir.fluid == stock.name end
                )
                p:fill(
                    70,
                    y,
                    1,
                    1,
                    fluidColor(stock.name)
                )
                p:text(
                    72,
                    y,
                    fit(
                        ((fluidLabel(stock.name) .. " ") .. tostring(stock.amount)) .. " mB",
                        25
                    ),
                    N.text
                )
                p:text(
                    72,
                    y + 1,
                    fit(
                        (holder ~= nil and ((placeLabel(holder.name) .. " ") .. Glyph.mid) .. " " or "") .. "waits for more",
                        25
                    ),
                    N.dim
                )
            end
        )
    end
end
function SmelteryScreen.prototype.paintAssign(self, p, state, assigning)
    local reservoir = __TS__ArrayFind(
        state.reservoirs,
        function(____, candidate) return candidate.name == assigning.reservoir end
    )
    self:bracket(
        p,
        67,
        5,
        32,
        42,
        N.yellow,
        "ASSIGN RESERVOIR"
    )
    p:text(
        70,
        6,
        fit(
            placeLabel(assigning.reservoir),
            27
        ),
        N.text
    )
    if (reservoir and reservoir.fluid) ~= nil then
        p:text(
            70,
            7,
            fit(
                ((("holds " .. fluidLabel(reservoir.fluid)) .. " ") .. tostring(reservoir.amount)) .. " mB",
                27
            ),
            N.soft
        )
    else
        p:text(70, 7, "empty", N.dim)
    end
    local now = (reservoir and reservoir.assigned) ~= nil and "for " .. fluidLabel(reservoir.assigned) or "free"
    p:text(
        70,
        8,
        fit("now: " .. now, 27),
        N.dim
    )
    p:text(70, 10, "RESERVE FOR", N.dim)
    if assigning.fluid ~= nil then
        p:fill(
            70,
            11,
            2,
            1,
            fluidColor(assigning.fluid)
        )
        p:text(
            73,
            11,
            fit(
                fluidLabel(assigning.fluid),
                24
            ),
            N.text
        )
    else
        p:text(70, 11, "free (any fluid)", N.soft)
    end
    local holds = reservoir and reservoir.fluid
    if holds ~= nil and assigning.fluid ~= nil and assigning.fluid ~= holds then
        p:text(
            70,
            35,
            fit(
                ("Keeps its " .. fluidLabel(holds)) .. ", no more;",
                27
            ),
            N.orange
        )
        p:text(
            70,
            36,
            fit(
                fluidLabel(assigning.fluid) .. " once empty.",
                27
            ),
            N.dim
        )
    else
        p:text(70, 35, "Reserved: only that fluid.", N.dim)
        p:text(70, 36, "Free: any, when empty.", N.dim)
    end
    p:text(70, 38, "CAPACITY", N.dim)
    local source = reservoir and reservoir.capacitySource
    local value
    if assigning.capacity ~= nil then
        p:text(79, 38, "set by hand", N.text)
        value = tostring(assigning.capacity) .. " mB"
    elseif (reservoir and reservoir.capacity) ~= nil and source ~= "set" then
        p:text(79, 38, source == "learnt" and "learnt" or "from its type", N.dim)
        value = "auto " .. tostring(reservoir.capacity)
    elseif source == "set" then
        p:text(79, 38, "type or learnt", N.dim)
        value = "auto"
    else
        p:text(79, 38, "unknown: set it", N.orange)
        value = "auto ?"
    end
    p:text(
        75,
        39,
        __TS__StringPadStart(value, 16),
        N.text
    )
end
function SmelteryScreen.prototype.paintLog(self, p, state)
    local lines = self:pageLogLines()
    __TS__ArrayForEach(
        lines,
        function(____, line, index)
            local y = 8 + index * 2
            local alert = line.kind == "alert" or line.kind == "forced"
            if alert then
                p:fill(
                    3,
                    y,
                    96,
                    1,
                    N.panel
                )
            end
            local back = alert and N.panel or N.bg
            p:text(
                3,
                y,
                line.time,
                N.dim,
                back
            )
            p:fill(
                13,
                y,
                1,
                1,
                LOG_COLORS[line.kind]
            )
            p:text(
                15,
                y,
                line.kind == "other" and "INFO" or string.upper(line.kind),
                LOG_COLORS[line.kind],
                back
            )
            p:text(
                23,
                y,
                fit(line.text, 76),
                alert and N.red or N.text,
                back
            )
        end
    )
    if #lines == 0 then
        p:text(3, 8, #state.log == 0 and "Nothing yet." or "Nothing for this filter.", N.dim)
    end
end
function SmelteryScreen.prototype.paintConfirm(self, p)
    local confirm = self.confirm
    if confirm == nil then
        return
    end
    local x = 25
    local y = 18
    local width = 51
    local height = 13
    local color = confirm.step == 2 and N.red or N.yellow
    p:fill(
        x,
        y,
        width,
        height,
        N.bg
    )
    self:bracket(
        p,
        x,
        y,
        width,
        height,
        color
    )
    if confirm.kind == "delete" then
        self:paintDelete(
            p,
            confirm.option,
            confirm.step,
            confirm.deadline,
            x,
            y,
            color
        )
        return
    end
    if confirm.kind == "trash" then
        p:text(x + 3, y + 2, "TRASH FLUID", color)
        p:text(
            x + 15,
            y + 2,
            ("step " .. tostring(confirm.step)) .. " of 2",
            N.dim
        )
        p:text(
            x + 3,
            y + 4,
            fit(
                (tostring(confirm.amount) .. " mB ") .. fluidLabel(confirm.fluid),
                45
            ),
            fluidColor(confirm.fluid)
        )
        p:text(
            x + 3,
            y + 5,
            fit(
                ("from " .. (confirm.reservoir ~= nil and placeLabel(confirm.reservoir) or "the Smeltery")) .. ", all of it",
                45
            ),
            N.soft
        )
        if confirm.step == 1 then
            p:text(x + 3, y + 7, "It goes to the fluid trash can.", N.dim)
        else
            p:text(x + 3, y + 7, "It cannot be undone.", N.dim)
            p:text(
                x + 21,
                y + 12,
                tostring(math.max(
                    0,
                    math.ceil(confirm.deadline - os.clock())
                )) .. " s",
                N.dim
            )
        end
        return
    end
    local item = confirm.item
    local what = item.status == "alloy" and ("will form " .. fluidLabel(item.alloy or "an alloy")) .. "." or ("needs " .. tostring(item.temperature or "?")) .. " K: it may not melt."
    p:text(x + 3, y + 2, "FORCE INSERT", color)
    p:text(
        x + 16,
        y + 2,
        ("step " .. tostring(confirm.step)) .. " of 2",
        N.dim
    )
    p:text(
        x + 3,
        y + 4,
        fit(
            (tostring(item.count) .. " ") .. placeLabel(item.name),
            45
        ),
        N.text
    )
    p:text(
        x + 3,
        y + 5,
        fit(what, 45),
        N.soft
    )
    if confirm.step == 1 then
        p:text(x + 3, y + 7, "Check what will happen before going on.", N.dim)
    else
        p:text(x + 3, y + 7, item.status == "alloy" and "An alloy cannot be undone." or "It stays in the Smeltery until hot enough.", N.dim)
        p:text(
            x + 21,
            y + 12,
            tostring(math.max(
                0,
                math.ceil(confirm.deadline - os.clock())
            )) .. " s",
            N.dim
        )
    end
end
function SmelteryScreen.prototype.paintDelete(self, p, option, step, deadline, x, y, color)
    p:text(x + 3, y + 2, "DELETE RECIPE", color)
    p:text(
        x + 17,
        y + 2,
        ("step " .. tostring(step)) .. " of 2",
        N.dim
    )
    local inputs = table.concat(
        __TS__ArrayMap(
            option.inputs,
            function(____, input) return (tostring(input.amount) .. " ") .. fluidLabel(input.fluid) end
        ),
        " + "
    )
    p:text(
        x + 3,
        y + 4,
        fit(inputs, 45),
        N.text
    )
    p:text(
        x + 3,
        y + 5,
        fit(
            (("makes " .. tostring(option.amount)) .. " mB ") .. fluidLabel(option.result),
            45
        ),
        colors.pink
    )
    local state = self.state
    local ____opt_232 = state and state.alloy
    local last = (____opt_232 and ____opt_232.result) == option.result and not __TS__ArraySome(
        self:alloyOptions(),
        function(____, other) return other.index ~= option.index and other.result == option.result end
    )
    if last and (state and state.mode) == "alloy" then
        p:text(x + 3, y + 7, "It is the alloy being made: alloy mode", N.orange)
        p:text(x + 3, y + 8, "stops and goes back to the previous mode.", N.orange)
    elseif last then
        p:text(x + 3, y + 7, "It is the alloy chosen for alloy mode:", N.orange)
        p:text(x + 3, y + 8, "none will be chosen any more.", N.orange)
    else
        p:text(x + 3, y + 7, step == 1 and "Check the recipe before going on." or "It cannot be undone.", N.dim)
    end
    if step == 2 then
        p:text(
            x + 21,
            y + 12,
            tostring(math.max(
                0,
                math.ceil(deadline - os.clock())
            )) .. " s",
            N.dim
        )
    end
end
return ____exports
