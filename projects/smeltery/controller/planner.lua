--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__StringStartsWith(self, searchString, position)
    if position == nil or position < 0 then
        position = 0
    end
    return string.sub(self, position + 1, #searchString + position) == searchString
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

local function __TS__ArraySome(self, callbackfn, thisArg)
    for i = 1, #self do
        if callbackfn(thisArg, self[i], i - 1, self) then
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

local function __TS__ArrayMap(self, callbackfn, thisArg)
    local result = {}
    for i = 1, #self do
        result[i] = callbackfn(thisArg, self[i], i - 1, self)
    end
    return result
end

local function __TS__ArrayEvery(self, callbackfn, thisArg)
    for i = 1, #self do
        if not callbackfn(thisArg, self[i], i - 1, self) then
            return false
        end
    end
    return true
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

local function __TS__ArrayForEach(self, callbackFn, thisArg)
    for i = 1, #self do
        callbackFn(thisArg, self[i], i - 1, self)
    end
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
-- End of Lua Library inline imports
local ____exports = {}
local shortFluid, smallestCast, isLeftover, store, unblock
local ____tank = require("core.tank")
local FluidStack = ____tank.FluidStack
local ____index = require("modules.tinkers.index")
local AlloyGuard = ____index.AlloyGuard
local AlloyRatio = ____index.AlloyRatio
local CastAmounts = ____index.CastAmounts
local CasterState = ____index.CasterState
local ____protocol = require("projects.smeltery.shared.protocol")
local InputItemView = ____protocol.InputItemView
local Mode = ____protocol.Mode
local WaitingItem = ____protocol.WaitingItem
function shortFluid(fluid)
    return table.concat(
        __TS__StringSplit(
            __TS__StringReplace(
                __TS__StringSubstring(
                    fluid,
                    (string.find(fluid, ":", nil, true) or 0) - 1 + 1
                ),
                "molten_",
                ""
            ),
            "_"
        ),
        " "
    )
end
function smallestCast(fluid, snapshot, context)
    local smallest
    for ____, format in ipairs(context.formatPriority) do
        do
            local __continue6
            repeat
                local amount = context.amounts:get(format, fluid)
                if amount == nil or not __TS__ArraySome(
                    snapshot.casters,
                    function(____, caster) return caster.state.format == format end
                ) then
                    __continue6 = true
                    break
                end
                if smallest == nil or amount < smallest then
                    smallest = amount
                end
                __continue6 = true
            until true
            if not __continue6 then
                break
            end
        end
    end
    return smallest
end
function isLeftover(fluid, snapshot, context)
    local smallest = smallestCast(fluid.name, snapshot, context)
    return smallest ~= nil and fluid.amount < smallest
end
function store(fluid, why, snapshot, plan)
    if not __TS__ArrayIncludes(snapshot.storable, fluid.name) then
        local ____plan_alerts_1 = plan.alerts
        ____plan_alerts_1[#____plan_alerts_1 + 1] = ("no reservoir for " .. shortFluid(fluid.name)) .. ": it stays in the Smeltery"
        return false
    end
    local ____plan_actions_2 = plan.actions
    ____plan_actions_2[#____plan_actions_2 + 1] = {kind = "store", fluid = fluid.name, amount = fluid.amount, why = why}
    return true
end
function ____exports.assessItem(item, present, context)
    if item.fluid == nil then
        return {status = "unknown"}
    end
    local temperature = context:meltingTemperature(item.fluid)
    if temperature ~= nil and context.fuelTemperature ~= nil and temperature > context.fuelTemperature then
        return {status = "heat", temperature = temperature}
    end
    local alloy = context.guard:wouldForm(present, item.fluid)
    if alloy ~= nil then
        return {status = "alloy", alloy = alloy.result, ingredients = alloy.ingredients}
    end
    return {status = "ok"}
end
function unblock(item, assessment, snapshot, context, plan, done)
    for ____, ingredient in ipairs(assessment.ingredients or ({})) do
        do
            local __continue132
            repeat
                if ingredient == item.fluid or done:has(ingredient) then
                    __continue132 = true
                    break
                end
                local fluid = __TS__ArrayFind(
                    snapshot.fluids,
                    function(____, candidate) return candidate.name == ingredient end
                )
                if fluid == nil or not isLeftover(fluid, snapshot, context) then
                    __continue132 = true
                    break
                end
                done:add(ingredient)
                store(fluid, "unblock", snapshot, plan)
                __continue132 = true
            until true
            if not __continue132 then
                break
            end
        end
    end
end
____exports.CRAFT_FORMAT = "craft"
function ____exports.craftInputMatches(input, item, tags)
    if item == nil then
        return false
    end
    local ____input_startsWith_result_0
    if __TS__StringStartsWith(input, "#") then
        ____input_startsWith_result_0 = __TS__ArrayIncludes(
            tags,
            __TS__StringSubstring(input, 1)
        )
    else
        ____input_startsWith_result_0 = input == item
    end
    return ____input_startsWith_result_0
end
local function storeUncastable(snapshot, context, plan)
    for ____, fluid in ipairs(snapshot.fluids) do
        if smallestCast(fluid.name, snapshot, context) == nil then
            store(fluid, "uncastable", snapshot, plan)
        end
    end
end
local function drainAll(snapshot, plan)
    local moving = false
    for ____, fluid in ipairs(snapshot.fluids) do
        moving = store(fluid, "drain", snapshot, plan) or moving
    end
    if not moving and #snapshot.meltingFluids == 0 then
        plan.finished = true
    end
end
local function purgeAll(snapshot, context, plan)
    local moving = false
    for ____, fluid in ipairs(snapshot.fluids) do
        local ____isLeftover_result_5 = isLeftover(fluid, snapshot, context)
        if not ____isLeftover_result_5 then
            local ____this_4
            ____this_4 = context
            local ____opt_3 = ____this_4.isAlloy
            ____isLeftover_result_5 = (____opt_3 and ____opt_3(____this_4, fluid.name)) == true
        end
        if ____isLeftover_result_5 then
            moving = store(fluid, "purge", snapshot, plan) or moving
        end
    end
    if not moving then
        plan.finished = true
    end
end
local function restoreAll(snapshot, context, plan)
    local completing = __TS__New(Set)
    for ____, fluid in ipairs(snapshot.fluids) do
        do
            local __continue28
            repeat
                local ____opt_6 = __TS__ArrayFind(
                    snapshot.stored,
                    function(____, entry) return entry.fluid == fluid.name end
                )
                local stock = ____opt_6 and ____opt_6.amount or 0
                if stock <= 0 then
                    __continue28 = true
                    break
                end
                for ____, format in ipairs(context.formatPriority) do
                    do
                        local __continue31
                        repeat
                            local amount = context.amounts:get(format, fluid.name)
                            if amount == nil or not __TS__ArraySome(
                                snapshot.casters,
                                function(____, caster) return caster.state.format == format end
                            ) then
                                __continue31 = true
                                break
                            end
                            if fluid.amount >= amount then
                                break
                            end
                            if fluid.amount + stock >= amount then
                                local ____plan_actions_8 = plan.actions
                                ____plan_actions_8[#____plan_actions_8 + 1] = {kind = "restore", fluid = fluid.name, amount = amount - fluid.amount, why = "complete"}
                                completing:add(fluid.name)
                                break
                            end
                            __continue31 = true
                        until true
                        if not __continue31 then
                            break
                        end
                    end
                end
                __continue28 = true
            until true
            if not __continue28 then
                break
            end
        end
    end
    return completing
end
local function collectAll(snapshot, plan)
    local ____array_10 = __TS__SparseArrayNew(unpack(snapshot.casters))
    __TS__SparseArrayPush(
        ____array_10,
        unpack(snapshot.craft or ({}))
    )
    for ____, caster in ipairs({__TS__SparseArraySpread(____array_10)}) do
        if caster.state.status == "blocked" then
            local ____plan_actions_9 = plan.actions
            ____plan_actions_9[#____plan_actions_9 + 1] = {kind = "collect", caster = caster.name}
        end
    end
end
local function pourAll(snapshot, context, plan, skip)
    if skip == nil then
        skip = __TS__New(Set)
    end
    if snapshot.outputFree <= 0 then
        local ____plan_alerts_11 = plan.alerts
        ____plan_alerts_11[#____plan_alerts_11 + 1] = "output full: casting paused"
        return
    end
    local used = __TS__New(Set)
    local collected = __TS__New(Set)
    for ____, action in ipairs(plan.actions) do
        if action.kind == "collect" then
            collected:add(action.caster)
        end
    end
    local function free(____, caster)
        return caster.state.status == "idle" or caster.state.status == "blocked" and collected:has(caster.name)
    end
    for ____, fluid in ipairs(snapshot.fluids) do
        do
            local __continue48
            repeat
                if skip:has(fluid.name) then
                    __continue48 = true
                    break
                end
                local left = fluid.amount
                for ____, format in ipairs(context.formatPriority) do
                    do
                        local __continue50
                        repeat
                            local amount = context.amounts:get(format, fluid.name)
                            local casters = __TS__ArrayFilter(
                                snapshot.casters,
                                function(____, caster) return caster.state.format == format end
                            )
                            if amount == nil or #casters == 0 or left < amount then
                                __continue50 = true
                                break
                            end
                            for ____, caster in ipairs(casters) do
                                do
                                    local __continue53
                                    repeat
                                        if left < amount then
                                            break
                                        end
                                        if used:has(caster.name) or not free(nil, caster) then
                                            __continue53 = true
                                            break
                                        end
                                        local ____plan_actions_12 = plan.actions
                                        ____plan_actions_12[#____plan_actions_12 + 1] = {kind = "pour", caster = caster.name, fluid = fluid.name, amount = amount}
                                        used:add(caster.name)
                                        left = left - amount
                                        __continue53 = true
                                    until true
                                    if not __continue53 then
                                        break
                                    end
                                end
                            end
                            break
                        until true
                        if not __continue50 then
                            break
                        end
                    end
                end
                __continue48 = true
            until true
            if not __continue48 then
                break
            end
        end
    end
end
local function pourOrders(snapshot, context, plan)
    local orders = context.orders or ({})
    if #orders == 0 then
        return
    end
    local castingPaused = snapshot.outputFree <= 0
    if castingPaused then
        local ____plan_alerts_13 = plan.alerts
        ____plan_alerts_13[#____plan_alerts_13 + 1] = "output full: casting paused"
    end
    local collected = __TS__New(Set)
    for ____, action in ipairs(plan.actions) do
        if action.kind == "collect" then
            collected:add(action.caster)
        end
    end
    local function free(____, caster)
        return not castingPaused and (caster.state.status == "idle" or caster.state.status == "blocked" and collected:has(caster.name))
    end
    local inside = __TS__New(Map)
    for ____, fluid in ipairs(snapshot.fluids) do
        inside:set(
            fluid.name,
            (inside:get(fluid.name) or 0) + fluid.amount
        )
    end
    local stock = __TS__New(Map)
    for ____, entry in ipairs(snapshot.stored) do
        stock:set(
            entry.fluid,
            (stock:get(entry.fluid) or 0) + entry.amount
        )
    end
    local ____array_14 = __TS__SparseArrayNew(unpack(snapshot.meltingFluids))
    __TS__SparseArrayPush(
        ____array_14,
        unpack(__TS__ArrayMap(
            snapshot.fluids,
            function(____, fluid) return fluid.name end
        ))
    )
    local present = {__TS__SparseArraySpread(____array_14)}
    local used = __TS__New(Set)
    local restores = __TS__New(Map)
    local pours = {}
    plan.orders = {}
    for ____, order in ipairs(orders) do
        local fluid = order.fluid
        local ____present_includes_result_15
        if __TS__ArrayIncludes(present, fluid) then
            ____present_includes_result_15 = nil
        else
            ____present_includes_result_15 = context.guard:wouldForm(present, fluid)
        end
        local alloy = ____present_includes_result_15
        local craft = order.craft
        local ____temp_18
        if craft ~= nil then
            local ____opt_16 = snapshot.craft
            ____temp_18 = ____opt_16 and __TS__ArrayFind(
                snapshot.craft,
                function(____, caster) return caster.name == craft.caster end
            )
        else
            ____temp_18 = nil
        end
        local craftCaster = ____temp_18
        local ____temp_21
        if craft ~= nil then
            ____temp_21 = (craftCaster and craftCaster.state.status) == "busy"
        else
            ____temp_21 = __TS__ArraySome(
                snapshot.casters,
                function(____, caster) return caster.state.status == "busy" and caster.state.fluid == fluid and __TS__ArraySome(
                    order.lines,
                    function(____, line) return line.format == caster.state.format end
                ) end
            )
        end
        local pouring = ____temp_21
        local remaining = 0
        local need
        for ____, line in ipairs(order.lines) do
            do
                local __continue75
                repeat
                    local amount = craft ~= nil and craft.amount or context.amounts:get(line.format, fluid)
                    if amount == nil then
                        __continue75 = true
                        break
                    end
                    local left = line.count - line.done
                    local candidates = __TS__ArrayFilter(
                        snapshot.casters,
                        function(____, caster) return caster.state.format == line.format end
                    )
                    if craft ~= nil then
                        candidates = craftCaster ~= nil and ({craftCaster}) or ({})
                        local holds = craftCaster ~= nil and ____exports.craftInputMatches(craft.input, craftCaster.state.cast, craftCaster.tags)
                        if left > 0 and craftCaster ~= nil and craftCaster.state.status ~= "busy" and not holds then
                            need = craft.input
                            candidates = {}
                        end
                    end
                    for ____, caster in ipairs(candidates) do
                        do
                            local __continue80
                            repeat
                                if left <= 0 then
                                    break
                                end
                                if used:has(caster.name) or not free(nil, caster) then
                                    __continue80 = true
                                    break
                                end
                                local have = inside:get(fluid) or 0
                                if have >= amount then
                                    inside:set(fluid, have - amount)
                                    pours[#pours + 1] = {
                                        kind = "pour",
                                        caster = caster.name,
                                        fluid = fluid,
                                        amount = amount,
                                        order = {id = order.id, format = line.format}
                                    }
                                else
                                    local stored = stock:get(fluid) or 0
                                    if alloy ~= nil or have + stored < amount then
                                        break
                                    end
                                    restores:set(
                                        fluid,
                                        (restores:get(fluid) or 0) + amount - have
                                    )
                                    stock:set(fluid, stored - (amount - have))
                                    inside:set(fluid, 0)
                                    if not __TS__ArrayIncludes(present, fluid) then
                                        present[#present + 1] = fluid
                                    end
                                end
                                used:add(caster.name)
                                left = left - 1
                                pouring = true
                                __continue80 = true
                            until true
                            if not __continue80 then
                                break
                            end
                        end
                    end
                    remaining = remaining + left * amount
                    __continue75 = true
                until true
                if not __continue75 then
                    break
                end
            end
        end
        local available = (inside:get(fluid) or 0) + (alloy ~= nil and 0 or (stock:get(fluid) or 0))
        local status = {id = order.id, status = pouring and "pouring" or "queued"}
        if remaining > available then
            status.status = "waiting"
            status.missing = remaining - available
            if alloy ~= nil then
                status.alloy = alloy.result
            end
        end
        if need ~= nil and not pouring then
            status.status = "waiting"
            status.need = need
        end
        local ____plan_orders_22 = plan.orders
        ____plan_orders_22[#____plan_orders_22 + 1] = status
    end
    restores:forEach(function(____, amount, fluid)
        local ____plan_actions_23 = plan.actions
        local ____temp_24 = #____plan_actions_23 + 1
        ____plan_actions_23[____temp_24] = {kind = "restore", fluid = fluid, amount = amount, why = "order"}
        return ____temp_24
    end)
    for ____, pour in ipairs(pours) do
        local ____plan_actions_25 = plan.actions
        ____plan_actions_25[#____plan_actions_25 + 1] = pour
    end
end
local function insertReady(snapshot, context, plan)
    if snapshot.pauseInput ~= nil then
        return
    end
    if snapshot.uncertain == true then
        local ____plan_alerts_26 = plan.alerts
        ____plan_alerts_26[#____plan_alerts_26 + 1] = "an item melting cannot be identified: input paused for this tick"
        return
    end
    local ____array_27 = __TS__SparseArrayNew(unpack(snapshot.meltingFluids))
    __TS__SparseArrayPush(
        ____array_27,
        unpack(__TS__ArrayMap(
            snapshot.fluids,
            function(____, fluid) return fluid.name end
        ))
    )
    local present = {__TS__SparseArraySpread(____array_27)}
    for ____, item in ipairs(snapshot.input) do
        do
            local __continue100
            repeat
                if ____exports.assessItem(item, present, context).status ~= "ok" then
                    __continue100 = true
                    break
                end
                local ____plan_actions_28 = plan.actions
                ____plan_actions_28[#____plan_actions_28 + 1] = {
                    kind = "insert",
                    slot = item.slot,
                    name = item.name,
                    count = item.count,
                    fluid = item.fluid,
                    seen = {unpack(present)}
                }
                present[#present + 1] = item.fluid
                __continue100 = true
            until true
            if not __continue100 then
                break
            end
        end
    end
end
local function wait(plan, item, reason, detail)
    if detail == nil then
        detail = {}
    end
    for ____, waiting in ipairs(plan.waiting) do
        if waiting.name == item.name and waiting.reason == reason then
            waiting.count = waiting.count + item.count
            return
        end
    end
    local waiting = {name = item.name, count = item.count, reason = reason}
    if detail.alloy ~= nil then
        waiting.alloy = detail.alloy
    end
    if detail.temperature ~= nil then
        waiting.temperature = detail.temperature
    end
    local ____plan_waiting_29 = plan.waiting
    ____plan_waiting_29[#____plan_waiting_29 + 1] = waiting
end
function ____exports.assessInput(snapshot, context)
    local present = {unpack(snapshot.meltingFluids)}
    for ____, fluid in ipairs(snapshot.fluids) do
        present[#present + 1] = fluid.name
    end
    return __TS__ArrayMap(
        snapshot.input,
        function(____, item)
            local assessment = ____exports.assessItem(item, present, context)
            local view = {slot = item.slot, name = item.name, count = item.count, status = assessment.status}
            if item.fluid ~= nil then
                view.fluid = item.fluid
            end
            if assessment.alloy ~= nil then
                view.alloy = assessment.alloy
            end
            if assessment.temperature ~= nil then
                view.temperature = assessment.temperature
            end
            return view
        end
    )
end
local function insertAll(snapshot, context, plan)
    local present = {unpack(snapshot.meltingFluids)}
    for ____, fluid in ipairs(snapshot.fluids) do
        present[#present + 1] = fluid.name
    end
    local unblocking = __TS__New(Set)
    for ____, item in ipairs(snapshot.input) do
        local assessment = ____exports.assessItem(item, present, context)
        repeat
            local ____switch124 = assessment.status
            local ____cond124 = ____switch124 == "unknown"
            if ____cond124 then
                local ____opt_30 = context.reject
                if (____opt_30 and ____opt_30.unknown) == true then
                    local ____plan_actions_32 = plan.actions
                    ____plan_actions_32[#____plan_actions_32 + 1] = {
                        kind = "reject",
                        slot = item.slot,
                        name = item.name,
                        count = item.count,
                        reason = "unknown"
                    }
                else
                    wait(plan, item, "unknown")
                end
                break
            end
            ____cond124 = ____cond124 or ____switch124 == "heat"
            if ____cond124 then
                local ____opt_33 = context.reject
                if (____opt_33 and ____opt_33.heat) == true then
                    local reject = {
                        kind = "reject",
                        slot = item.slot,
                        name = item.name,
                        count = item.count,
                        reason = "heat"
                    }
                    if assessment.temperature ~= nil then
                        reject.temperature = assessment.temperature
                    end
                    local ____plan_actions_35 = plan.actions
                    ____plan_actions_35[#____plan_actions_35 + 1] = reject
                else
                    wait(plan, item, "heat", assessment.temperature ~= nil and ({temperature = assessment.temperature}) or ({}))
                end
                break
            end
            ____cond124 = ____cond124 or ____switch124 == "alloy"
            if ____cond124 then
                wait(plan, item, "alloy", assessment.alloy ~= nil and ({alloy = assessment.alloy}) or ({}))
                unblock(
                    item,
                    assessment,
                    snapshot,
                    context,
                    plan,
                    unblocking
                )
                break
            end
            do
                local ____plan_actions_36 = plan.actions
                ____plan_actions_36[#____plan_actions_36 + 1] = {
                    kind = "insert",
                    slot = item.slot,
                    name = item.name,
                    count = item.count,
                    fluid = item.fluid,
                    seen = {unpack(present)}
                }
                present[#present + 1] = item.fluid
            end
        until true
    end
end
local function meltAll(snapshot, context, plan)
    local full = false
    for ____, fluid in ipairs(snapshot.fluids) do
        full = not store(fluid, "melt", snapshot, plan) or full
    end
    if full or snapshot.pauseInput ~= nil then
        return
    end
    if snapshot.uncertain == true then
        local ____plan_alerts_37 = plan.alerts
        ____plan_alerts_37[#____plan_alerts_37 + 1] = "an item melting cannot be identified: input paused for this tick"
        return
    end
    insertAll(snapshot, context, plan)
end
local ALLOY_BATCHES = 8
local ALLOY_BUFFER = 810
local function amountIn(snapshot, fluid)
    local ____opt_38 = __TS__ArrayFind(
        snapshot.fluids,
        function(____, candidate) return candidate.name == fluid end
    )
    return ____opt_38 and ____opt_38.amount or 0
end
local function pickRatio(job, snapshot)
    local function found(____, fluid)
        return amountIn(snapshot, fluid) > 0 or __TS__ArraySome(
            snapshot.stored,
            function(____, entry) return entry.fluid == fluid and entry.amount > 0 end
        ) or __TS__ArraySome(
            snapshot.input,
            function(____, item) return item.fluid == fluid end
        )
    end
    return __TS__ArrayFind(
        job.ratios,
        function(____, ratio) return __TS__ArrayEvery(
            ratio.inputs,
            function(____, input) return found(nil, input.fluid) end
        ) end
    ) or job.ratios[1]
end
local function alloyTick(snapshot, context, plan)
    local job = context.alloy
    local ____temp_40
    if job ~= nil then
        ____temp_40 = pickRatio(job, snapshot)
    else
        ____temp_40 = nil
    end
    local ratio = ____temp_40
    if job == nil or ratio == nil then
        local ____plan_alerts_41 = plan.alerts
        ____plan_alerts_41[#____plan_alerts_41 + 1] = "alloy mode: no alloy chosen"
        return
    end
    local ingredients = __TS__ArrayMap(
        ratio.inputs,
        function(____, input) return input.fluid end
    )
    if job.remaining ~= nil and job.remaining <= 0 then
        local moving = false
        for ____, fluid in ipairs(snapshot.fluids) do
            if fluid.name == job.result or __TS__ArrayIncludes(ingredients, fluid.name) then
                moving = store(fluid, "alloy", snapshot, plan) or moving
            end
        end
        if not moving then
            plan.finished = true
        end
        return
    end
    local others = __TS__New(
        Set,
        __TS__ArrayFilter(
            __TS__ArrayMap(
                snapshot.fluids,
                function(____, fluid) return fluid.name end
            ),
            function(____, name) return name ~= job.result end
        )
    )
    local wanted = job.remaining
    local function capOf(____, fluid)
        return fluid.name == job.result and wanted ~= nil and ({
            name = fluid.name,
            amount = math.min(fluid.amount, wanted)
        }) or fluid
    end
    local capped = __TS__ObjectAssign(
        {},
        snapshot,
        {fluids = __TS__ArrayMap(snapshot.fluids, capOf)}
    )
    pourAll(capped, context, plan, others)
    local made = amountIn(snapshot, job.result)
    if made >= ALLOY_BUFFER then
        return
    end
    local batches = ALLOY_BATCHES
    if job.remaining ~= nil then
        batches = math.min(
            batches,
            math.ceil((job.remaining - made) / ratio.amount)
        )
    end
    if batches <= 0 then
        return
    end
    local units = __TS__ArrayMap(
        ratio.inputs,
        function(____, input) return amountIn(snapshot, input.fluid) / input.amount end
    )
    local goal = math.min(unpack(units)) + batches
    local ____array_42 = __TS__SparseArrayNew(unpack(snapshot.meltingFluids))
    __TS__SparseArrayPush(
        ____array_42,
        unpack(__TS__ArrayMap(
            snapshot.fluids,
            function(____, fluid) return fluid.name end
        ))
    )
    local present = {__TS__SparseArraySpread(____array_42)}
    local missing = {}
    local inputOpen = snapshot.pauseInput == nil and snapshot.uncertain ~= true
    __TS__ArrayForEach(
        ratio.inputs,
        function(____, input, index)
            local need = math.ceil((goal - units[index + 1]) * input.amount)
            if need <= 0 then
                return
            end
            local blocking = context.guard:wouldForm(present, input.fluid, job.result)
            if blocking ~= nil then
                for ____, name in ipairs(blocking.ingredients) do
                    local fluid = __TS__ArrayFind(
                        snapshot.fluids,
                        function(____, candidate) return candidate.name == name end
                    )
                    if fluid ~= nil and name ~= job.result and not __TS__ArrayIncludes(ingredients, name) then
                        store(fluid, "unblock", snapshot, plan)
                    end
                end
                return
            end
            local ____opt_43 = __TS__ArrayFind(
                snapshot.stored,
                function(____, entry) return entry.fluid == input.fluid end
            )
            local stock = ____opt_43 and ____opt_43.amount or 0
            if stock > 0 then
                local ____plan_actions_45 = plan.actions
                ____plan_actions_45[#____plan_actions_45 + 1] = {
                    kind = "restore",
                    fluid = input.fluid,
                    amount = math.min(need, stock),
                    why = "alloy"
                }
            end
            if stock >= need then
                return
            end
            local item = __TS__ArrayFind(
                snapshot.input,
                function(____, candidate) return candidate.fluid == input.fluid end
            )
            if item == nil then
                if stock <= 0 then
                    missing[#missing + 1] = shortFluid(input.fluid)
                end
                return
            end
            if not inputOpen or __TS__ArrayIncludes(snapshot.meltingFluids, input.fluid) then
                return
            end
            local temperature = context:meltingTemperature(input.fluid)
            if temperature ~= nil and context.fuelTemperature ~= nil and temperature > context.fuelTemperature then
                wait(plan, item, "heat", {temperature = temperature})
                return
            end
            local ____plan_actions_46 = plan.actions
            ____plan_actions_46[#____plan_actions_46 + 1] = {
                kind = "insert",
                slot = item.slot,
                name = item.name,
                count = item.count,
                fluid = input.fluid,
                seen = {unpack(present)}
            }
            present[#present + 1] = input.fluid
        end
    )
    if #missing > 0 then
        local ____plan_alerts_47 = plan.alerts
        ____plan_alerts_47[#____plan_alerts_47 + 1] = (shortFluid(job.result) .. ": missing ") .. table.concat(missing, ", ")
    end
end
local function takeStock(snapshot, context, plan)
    if #snapshot.meltingFluids > 0 or #snapshot.stored == 0 then
        return
    end
    if __TS__ArraySome(
        plan.actions,
        function(____, action) return action.kind ~= "collect" and action.kind ~= "reject" end
    ) then
        return
    end
    if __TS__ArraySome(
        plan.waiting,
        function(____, item) return item.reason == "alloy" end
    ) then
        return
    end
    for ____, fluid in ipairs(snapshot.fluids) do
        local smallest = smallestCast(fluid.name, snapshot, context)
        if smallest ~= nil and fluid.amount >= smallest then
            return
        end
    end
    local present = __TS__ArrayMap(
        snapshot.fluids,
        function(____, fluid) return fluid.name end
    )
    local stocks = __TS__ArraySort(
        {unpack(snapshot.stored)},
        function(____, a, b) return b.amount - a.amount end
    )
    for ____, stock in ipairs(stocks) do
        do
            local __continue193
            repeat
                local smallest = smallestCast(stock.fluid, snapshot, context)
                if smallest == nil or stock.amount <= 0 then
                    __continue193 = true
                    break
                end
                local ____opt_48 = __TS__ArrayFind(
                    snapshot.fluids,
                    function(____, fluid) return fluid.name == stock.fluid end
                )
                local inside = ____opt_48 and ____opt_48.amount or 0
                if stock.amount + inside < smallest then
                    if plan.smallStocks == nil then
                        plan.smallStocks = {}
                    end
                    local ____plan_smallStocks_50 = plan.smallStocks
                    ____plan_smallStocks_50[#____plan_smallStocks_50 + 1] = {name = stock.fluid, amount = stock.amount}
                    __continue193 = true
                    break
                end
                local alloy = context.guard:wouldForm(present, stock.fluid)
                if alloy == nil then
                    local ____plan_actions_51 = plan.actions
                    ____plan_actions_51[#____plan_actions_51 + 1] = {kind = "restore", fluid = stock.fluid, amount = stock.amount, why = "stock"}
                    return
                end
                local unblocking = false
                for ____, ingredient in ipairs(alloy.ingredients) do
                    do
                        local __continue198
                        repeat
                            local fluid = __TS__ArrayFind(
                                snapshot.fluids,
                                function(____, candidate) return candidate.name == ingredient end
                            )
                            if ingredient == stock.fluid or fluid == nil or not isLeftover(fluid, snapshot, context) then
                                __continue198 = true
                                break
                            end
                            unblocking = store(fluid, "unblock", snapshot, plan) or unblocking
                            __continue198 = true
                        until true
                        if not __continue198 then
                            break
                        end
                    end
                end
                if unblocking then
                    return
                end
                __continue193 = true
            until true
            if not __continue193 then
                break
            end
        end
    end
end
function ____exports.planTick(mode, snapshot, context)
    local plan = {actions = {}, waiting = {}, alerts = {}}
    if mode == "idle" then
        return plan
    end
    collectAll(snapshot, plan)
    if mode == "manual" then
        pourOrders(snapshot, context, plan)
        if context.insertReady == true then
            insertReady(snapshot, context, plan)
        end
        return plan
    end
    if mode == "drain" then
        drainAll(snapshot, plan)
        return plan
    end
    if mode == "purge" then
        purgeAll(snapshot, context, plan)
        return plan
    end
    if mode == "melt" then
        meltAll(snapshot, context, plan)
        return plan
    end
    if mode == "alloy" then
        alloyTick(snapshot, context, plan)
        return plan
    end
    local completing = mode == "auto" and restoreAll(snapshot, context, plan) or __TS__New(Set)
    pourAll(snapshot, context, plan, completing)
    if mode == "lock" then
        return plan
    end
    storeUncastable(snapshot, context, plan)
    if snapshot.pauseInput ~= nil then
        return plan
    end
    if snapshot.uncertain == true then
        local ____plan_alerts_52 = plan.alerts
        ____plan_alerts_52[#____plan_alerts_52 + 1] = "an item melting cannot be identified: input paused for this tick"
        return plan
    end
    insertAll(snapshot, context, plan)
    if mode == "auto" then
        takeStock(snapshot, context, plan)
    end
    return plan
end
return ____exports
