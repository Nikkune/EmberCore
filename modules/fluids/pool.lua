--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__Class(self)
    local c = {prototype = {}}
    c.prototype.__index = c.prototype
    c.prototype.constructor = c
    return c
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

local function __TS__ArrayMap(self, callbackfn, thisArg)
    local result = {}
    for i = 1, #self do
        result[i] = callbackfn(thisArg, self[i], i - 1, self)
    end
    return result
end

local function __TS__ArraySome(self, callbackfn, thisArg)
    for i = 1, #self do
        if callbackfn(thisArg, self[i], i - 1, self) then
            return true
        end
    end
    return false
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

local function __TS__StringIncludes(self, searchString, position)
    if not position then
        position = 1
    else
        position = position + 1
    end
    local index = string.find(self, searchString, position, true)
    return index ~= nil
end

local function __TS__New(target, ...)
    local instance = setmetatable({}, target.prototype)
    instance:____constructor(...)
    return instance
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

local function __TS__ObjectGetOwnPropertyDescriptors(object)
    local metatable = getmetatable(object)
    if not metatable then
        return {}
    end
    return rawget(metatable, "_descriptors") or ({})
end

local function __TS__Delete(target, key)
    local descriptors = __TS__ObjectGetOwnPropertyDescriptors(target)
    local descriptor = descriptors[key]
    if descriptor then
        if not descriptor.configurable then
            error(
                __TS__New(
                    TypeError,
                    ((("Cannot delete property " .. tostring(key)) .. " of ") .. tostring(target)) .. "."
                ),
                0
            )
        end
        descriptors[key] = nil
        return true
    end
    target[key] = nil
    return true
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
-- End of Lua Library inline imports
local ____exports = {}
local ____parallel = require("core.parallel")
local Parallel = ____parallel.Parallel
local ____tank = require("core.tank")
local Tank = ____tank.Tank
____exports.ReservoirPool = __TS__Class()
local ReservoirPool = ____exports.ReservoirPool
ReservoirPool.name = "ReservoirPool"
function ReservoirPool.prototype.____constructor(self, names, options)
    if options == nil then
        options = {}
    end
    self.assignments = options.assignments or ({})
    self.learnt = __TS__ObjectAssign({}, options.capacities)
    self.setCapacities = __TS__ObjectAssign({}, options.setCapacities)
    self.typeCapacities = __TS__ObjectAssign({}, options.typeCapacities)
    self.reservoirs = __TS__ArrayMap(
        names,
        function(____, name)
            local view = {name = name, amount = 0}
            local assigned = self.assignments[name]
            if assigned ~= nil then
                view.assigned = assigned
            end
            local reservoir = {
                tank = Tank:fromName(name),
                view = view
            }
            self:resolveCapacity(reservoir)
            return reservoir
        end
    )
end
function ReservoirPool.prototype.refresh(self)
    if #self.reservoirs == 0 then
        return
    end
    Parallel:all(unpack(__TS__ArrayMap(
        self.reservoirs,
        function(____, reservoir) return function() return self:read(reservoir) end end
    )))
end
function ReservoirPool.prototype.views(self)
    return __TS__ArrayMap(
        self.reservoirs,
        function(____, reservoir) return __TS__ObjectAssign({}, reservoir.view) end
    )
end
function ReservoirPool.prototype.has(self, name)
    return __TS__ArraySome(
        self.reservoirs,
        function(____, reservoir) return reservoir.view.name == name end
    )
end
function ReservoirPool.prototype.assign(self, name, fluid)
    local reservoir = __TS__ArrayFind(
        self.reservoirs,
        function(____, candidate) return candidate.view.name == name end
    )
    if reservoir == nil then
        return
    end
    if fluid == nil then
        __TS__Delete(self.assignments, name)
        __TS__Delete(reservoir.view, "assigned")
    else
        self.assignments[name] = fluid
        reservoir.view.assigned = fluid
    end
end
function ReservoirPool.prototype.setCapacity(self, name, capacity)
    local reservoir = __TS__ArrayFind(
        self.reservoirs,
        function(____, candidate) return candidate.view.name == name end
    )
    if reservoir == nil then
        return
    end
    __TS__Delete(self.learnt, name)
    if capacity == nil then
        __TS__Delete(self.setCapacities, name)
    else
        self.setCapacities[name] = capacity
    end
    self:resolveCapacity(reservoir)
end
function ReservoirPool.prototype.capacities(self)
    local result = {}
    for ____, ____value in ipairs(self.reservoirs) do
        local view = ____value.view
        local learnt = self.learnt[view.name]
        if learnt ~= nil then
            result[view.name] = learnt
        end
    end
    return result
end
function ReservoirPool.prototype.stored(self, fluid)
    local total = 0
    for ____, ____value in ipairs(self.reservoirs) do
        local view = ____value.view
        if view.fluid == fluid then
            total = total + view.amount
        end
    end
    return total
end
function ReservoirPool.prototype.canStore(self, fluid)
    return #self:candidates(fluid) > 0
end
function ReservoirPool.prototype.store(self, source, fluid, amount)
    local stored = 0
    for ____, reservoir in ipairs(self:candidates(fluid)) do
        do
            local __continue33
            repeat
                if stored >= amount then
                    break
                end
                self:read(reservoir)
                if not self:accepts(reservoir, fluid) then
                    __continue33 = true
                    break
                end
                local wanted = amount - stored
                local moved = source:pushTo(reservoir.tank, wanted, fluid)
                self:read(reservoir)
                stored = stored + moved
                if moved < wanted and reservoir.view.fluid == fluid then
                    self.learnt[reservoir.view.name] = reservoir.view.amount
                    self:resolveCapacity(reservoir)
                end
                __continue33 = true
            until true
            if not __continue33 then
                break
            end
        end
    end
    return stored
end
function ReservoirPool.prototype.take(self, target, fluid, amount)
    local taken = 0
    local holders = __TS__ArraySort(
        __TS__ArrayFilter(
            self.reservoirs,
            function(____, reservoir) return reservoir.view.fluid == fluid end
        ),
        function(____, a, b) return a.view.amount - b.view.amount end
    )
    for ____, reservoir in ipairs(holders) do
        if taken >= amount then
            break
        end
        taken = taken + target:pullFrom(reservoir.tank, amount - taken, fluid)
        self:read(reservoir)
    end
    return taken
end
function ReservoirPool.prototype.resolveCapacity(self, reservoir)
    local name = reservoir.view.name
    local view = reservoir.view
    local found = {{self.learnt[name], "learnt"}, {self.setCapacities[name], "set"}, {self.typeCapacities[name], "type"}}
    __TS__Delete(view, "capacity")
    __TS__Delete(view, "capacitySource")
    for ____, ____value in ipairs(found) do
        local capacity = ____value[1]
        local source = ____value[2]
        do
            local __continue45
            repeat
                if capacity == nil then
                    __continue45 = true
                    break
                end
                view.capacity = capacity
                view.capacitySource = source
                return
            until true
            if not __continue45 then
                break
            end
        end
    end
end
function ReservoirPool.prototype.read(self, reservoir)
    local fluid = unpack(
        reservoir.tank:getFluids(),
        1,
        1
    )
    local view = reservoir.view
    view.amount = fluid and fluid.amount or 0
    if fluid ~= nil then
        view.fluid = fluid.name
    else
        __TS__Delete(view, "fluid")
    end
end
function ReservoirPool.prototype.accepts(self, reservoir, fluid)
    local view = reservoir.view
    if view.assigned ~= nil and view.assigned ~= fluid then
        return false
    end
    if view.fluid ~= nil and view.fluid ~= fluid then
        return false
    end
    return view.capacity == nil or view.amount < view.capacity
end
function ReservoirPool.prototype.candidates(self, fluid)
    local holding = __TS__ArrayFilter(
        self.reservoirs,
        function(____, reservoir) return reservoir.view.fluid == fluid and self:accepts(reservoir, fluid) end
    )
    local empty = __TS__ArrayFilter(
        self.reservoirs,
        function(____, reservoir) return reservoir.view.fluid == nil and self:accepts(reservoir, fluid) end
    )
    __TS__ArraySort(
        empty,
        function(____, a, b) return (a.view.assigned == fluid and 0 or 1) - (b.view.assigned == fluid and 0 or 1) end
    )
    local ____array_2 = __TS__SparseArrayNew(unpack(holding))
    __TS__SparseArrayPush(
        ____array_2,
        unpack(empty)
    )
    return {__TS__SparseArraySpread(____array_2)}
end
return ____exports
