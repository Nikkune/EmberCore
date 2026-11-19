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
            local __continue4
            repeat
                local amount = context.amounts:get(format, fluid)
                if amount == nil or not __TS__ArraySome(
                    snapshot.casters,
                    function(____, caster) return caster.state.format == format end
                ) then
                    __continue4 = true
                    break
                end
                if smallest == nil or amount < smallest then
                    smallest = amount
                end
                __continue4 = true
            until true
            if not __continue4 then
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
        local ____plan_alerts_0 = plan.alerts
        ____plan_alerts_0[#____plan_alerts_0 + 1] = ("no reservoir for " .. shortFluid(fluid.name)) .. ": it stays in the Smeltery"
        return false
    end
    local ____plan_actions_1 = plan.actions
    ____plan_actions_1[#____plan_actions_1 + 1] = {kind = "store", fluid = fluid.name, amount = fluid.amount, why = why}
    return true
end
function unblock(item, assessment, snapshot, context, plan, done)
    for ____, ingredient in ipairs(assessment.ingredients or ({})) do
        do
            local __continue78
            repeat
                if ingredient == item.fluid or done:has(ingredient) then
                    __continue78 = true
                    break
                end
                local fluid = __TS__ArrayFind(
                    snapshot.fluids,
                    function(____, candidate) return candidate.name == ingredient end
                )
                if fluid == nil or not isLeftover(fluid, snapshot, context) then
                    __continue78 = true
                    break
                end
                done:add(ingredient)
                store(fluid, "unblock", snapshot, plan)
                __continue78 = true
            until true
            if not __continue78 then
                break
            end
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
        local ____isLeftover_result_4 = isLeftover(fluid, snapshot, context)
        if not ____isLeftover_result_4 then
            local ____this_3
            ____this_3 = context
            local ____opt_2 = ____this_3.isAlloy
            ____isLeftover_result_4 = (____opt_2 and ____opt_2(____this_3, fluid.name)) == true
        end
        if ____isLeftover_result_4 then
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
            local __continue22
            repeat
                local ____opt_5 = __TS__ArrayFind(
                    snapshot.stored,
                    function(____, entry) return entry.fluid == fluid.name end
                )
                local stock = ____opt_5 and ____opt_5.amount or 0
                if stock <= 0 then
                    __continue22 = true
                    break
                end
                for ____, format in ipairs(context.formatPriority) do
                    do
                        local __continue25
                        repeat
                            local amount = context.amounts:get(format, fluid.name)
                            if amount == nil or not __TS__ArraySome(
                                snapshot.casters,
                                function(____, caster) return caster.state.format == format end
                            ) then
                                __continue25 = true
                                break
                            end
                            if fluid.amount >= amount then
                                break
                            end
                            if fluid.amount + stock >= amount then
                                local ____plan_actions_7 = plan.actions
                                ____plan_actions_7[#____plan_actions_7 + 1] = {kind = "restore", fluid = fluid.name, amount = amount - fluid.amount, why = "complete"}
                                completing:add(fluid.name)
                                break
                            end
                            __continue25 = true
                        until true
                        if not __continue25 then
                            break
                        end
                    end
                end
                __continue22 = true
            until true
            if not __continue22 then
                break
            end
        end
    end
    return completing
end
local function collectAll(snapshot, plan)
    for ____, caster in ipairs(snapshot.casters) do
        if caster.state.status == "blocked" then
            local ____plan_actions_8 = plan.actions
            ____plan_actions_8[#____plan_actions_8 + 1] = {kind = "collect", caster = caster.name}
        end
    end
end
local function pourAll(snapshot, context, plan, skip)
    if skip == nil then
        skip = __TS__New(Set)
    end
    if snapshot.outputFree <= 0 then
        local ____plan_alerts_9 = plan.alerts
        ____plan_alerts_9[#____plan_alerts_9 + 1] = "output full: casting paused"
        return
    end
    local used = __TS__New(Set)
    for ____, fluid in ipairs(snapshot.fluids) do
        do
            local __continue38
            repeat
                if skip:has(fluid.name) then
                    __continue38 = true
                    break
                end
                local left = fluid.amount
                for ____, format in ipairs(context.formatPriority) do
                    do
                        local __continue40
                        repeat
                            local amount = context.amounts:get(format, fluid.name)
                            local casters = __TS__ArrayFilter(
                                snapshot.casters,
                                function(____, caster) return caster.state.format == format end
                            )
                            if amount == nil or #casters == 0 or left < amount then
                                __continue40 = true
                                break
                            end
                            for ____, caster in ipairs(casters) do
                                do
                                    local __continue43
                                    repeat
                                        if left < amount then
                                            break
                                        end
                                        if used:has(caster.name) or caster.state.status ~= "idle" then
                                            __continue43 = true
                                            break
                                        end
                                        local ____plan_actions_10 = plan.actions
                                        ____plan_actions_10[#____plan_actions_10 + 1] = {kind = "pour", caster = caster.name, fluid = fluid.name, amount = amount}
                                        used:add(caster.name)
                                        left = left - amount
                                        __continue43 = true
                                    until true
                                    if not __continue43 then
                                        break
                                    end
                                end
                            end
                            break
                        until true
                        if not __continue40 then
                            break
                        end
                    end
                end
                __continue38 = true
            until true
            if not __continue38 then
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
    local ____plan_waiting_11 = plan.waiting
    ____plan_waiting_11[#____plan_waiting_11 + 1] = waiting
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
            local ____switch70 = assessment.status
            local ____cond70 = ____switch70 == "unknown"
            if ____cond70 then
                local ____opt_12 = context.reject
                if (____opt_12 and ____opt_12.unknown) == true then
                    local ____plan_actions_14 = plan.actions
                    ____plan_actions_14[#____plan_actions_14 + 1] = {
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
            ____cond70 = ____cond70 or ____switch70 == "heat"
            if ____cond70 then
                local ____opt_15 = context.reject
                if (____opt_15 and ____opt_15.heat) == true then
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
                    local ____plan_actions_17 = plan.actions
                    ____plan_actions_17[#____plan_actions_17 + 1] = reject
                else
                    wait(plan, item, "heat", assessment.temperature ~= nil and ({temperature = assessment.temperature}) or ({}))
                end
                break
            end
            ____cond70 = ____cond70 or ____switch70 == "alloy"
            if ____cond70 then
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
                local ____plan_actions_18 = plan.actions
                ____plan_actions_18[#____plan_actions_18 + 1] = {
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
        local ____plan_alerts_19 = plan.alerts
        ____plan_alerts_19[#____plan_alerts_19 + 1] = "an item melting cannot be identified: input paused for this tick"
        return
    end
    insertAll(snapshot, context, plan)
end
local ALLOY_BATCHES = 8
local ALLOY_BUFFER = 810
local function amountIn(snapshot, fluid)
    local ____opt_20 = __TS__ArrayFind(
        snapshot.fluids,
        function(____, candidate) return candidate.name == fluid end
    )
    return ____opt_20 and ____opt_20.amount or 0
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
    local ____temp_22
    if job ~= nil then
        ____temp_22 = pickRatio(job, snapshot)
    else
        ____temp_22 = nil
    end
    local ratio = ____temp_22
    if job == nil or ratio == nil then
        local ____plan_alerts_23 = plan.alerts
        ____plan_alerts_23[#____plan_alerts_23 + 1] = "alloy mode: no alloy chosen"
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
    local ____array_24 = __TS__SparseArrayNew(unpack(snapshot.meltingFluids))
    __TS__SparseArrayPush(
        ____array_24,
        unpack(__TS__ArrayMap(
            snapshot.fluids,
            function(____, fluid) return fluid.name end
        ))
    )
    local present = {__TS__SparseArraySpread(____array_24)}
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
            local ____opt_25 = __TS__ArrayFind(
                snapshot.stored,
                function(____, entry) return entry.fluid == input.fluid end
            )
            local stock = ____opt_25 and ____opt_25.amount or 0
            if stock > 0 then
                local ____plan_actions_27 = plan.actions
                ____plan_actions_27[#____plan_actions_27 + 1] = {
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
            local ____plan_actions_28 = plan.actions
            ____plan_actions_28[#____plan_actions_28 + 1] = {
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
        local ____plan_alerts_29 = plan.alerts
        ____plan_alerts_29[#____plan_alerts_29 + 1] = (shortFluid(job.result) .. ": missing ") .. table.concat(missing, ", ")
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
            local __continue139
            repeat
                local smallest = smallestCast(stock.fluid, snapshot, context)
                if smallest == nil or stock.amount <= 0 then
                    __continue139 = true
                    break
                end
                local ____opt_30 = __TS__ArrayFind(
                    snapshot.fluids,
                    function(____, fluid) return fluid.name == stock.fluid end
                )
                local inside = ____opt_30 and ____opt_30.amount or 0
                if stock.amount + inside < smallest then
                    local ____plan_alerts_32 = plan.alerts
                    ____plan_alerts_32[#____plan_alerts_32 + 1] = ((("stock of " .. shortFluid(stock.fluid)) .. ": ") .. tostring(stock.amount)) .. " mB, below a cast"
                    __continue139 = true
                    break
                end
                local alloy = context.guard:wouldForm(present, stock.fluid)
                if alloy == nil then
                    local ____plan_actions_33 = plan.actions
                    ____plan_actions_33[#____plan_actions_33 + 1] = {kind = "restore", fluid = stock.fluid, amount = stock.amount, why = "stock"}
                    return
                end
                local unblocking = false
                for ____, ingredient in ipairs(alloy.ingredients) do
                    do
                        local __continue144
                        repeat
                            local fluid = __TS__ArrayFind(
                                snapshot.fluids,
                                function(____, candidate) return candidate.name == ingredient end
                            )
                            if ingredient == stock.fluid or fluid == nil or not isLeftover(fluid, snapshot, context) then
                                __continue144 = true
                                break
                            end
                            unblocking = store(fluid, "unblock", snapshot, plan) or unblocking
                            __continue144 = true
                        until true
                        if not __continue144 then
                            break
                        end
                    end
                end
                if unblocking then
                    return
                end
                __continue139 = true
            until true
            if not __continue139 then
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
    if snapshot.pauseInput ~= nil then
        return plan
    end
    if snapshot.uncertain == true then
        local ____plan_alerts_34 = plan.alerts
        ____plan_alerts_34[#____plan_alerts_34 + 1] = "an item melting cannot be identified: input paused for this tick"
        return plan
    end
    insertAll(snapshot, context, plan)
    if mode == "auto" then
        takeStock(snapshot, context, plan)
    end
    return plan
end
return ____exports
