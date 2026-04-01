--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__Class(self)
    local c = {prototype = {}}
    c.prototype.__index = c.prototype
    c.prototype.constructor = c
    return c
end

local function __TS__CloneDescriptor(____bindingPattern0)
    local value
    local writable
    local set
    local get
    local configurable
    local enumerable
    enumerable = ____bindingPattern0.enumerable
    configurable = ____bindingPattern0.configurable
    get = ____bindingPattern0.get
    set = ____bindingPattern0.set
    writable = ____bindingPattern0.writable
    value = ____bindingPattern0.value
    local descriptor = {enumerable = enumerable == true, configurable = configurable == true}
    local hasGetterOrSetter = get ~= nil or set ~= nil
    local hasValueOrWritableAttribute = writable ~= nil or value ~= nil
    if hasGetterOrSetter and hasValueOrWritableAttribute then
        error("Invalid property descriptor. Cannot both specify accessors and a value or writable attribute.", 0)
    end
    if get or set then
        descriptor.get = get
        descriptor.set = set
    else
        descriptor.value = value
        descriptor.writable = writable == true
    end
    return descriptor
end

local __TS__DescriptorGet
do
    local getmetatable = _G.getmetatable
    local ____rawget = _G.rawget
    function __TS__DescriptorGet(self, metatable, key)
        while metatable do
            local rawResult = ____rawget(metatable, key)
            if rawResult ~= nil then
                return rawResult
            end
            local descriptors = ____rawget(metatable, "_descriptors")
            if descriptors then
                local descriptor = descriptors[key]
                if descriptor ~= nil then
                    if descriptor.get then
                        return descriptor.get(self)
                    end
                    return descriptor.value
                end
            end
            metatable = getmetatable(metatable)
        end
    end
end

local __TS__DescriptorSet
do
    local getmetatable = _G.getmetatable
    local ____rawget = _G.rawget
    local rawset = _G.rawset
    function __TS__DescriptorSet(self, metatable, key, value)
        while metatable do
            local descriptors = ____rawget(metatable, "_descriptors")
            if descriptors then
                local descriptor = descriptors[key]
                if descriptor ~= nil then
                    if descriptor.set then
                        descriptor.set(self, value)
                    else
                        if descriptor.writable == false then
                            error(
                                ((("Cannot assign to read only property '" .. key) .. "' of object '") .. tostring(self)) .. "'",
                                0
                            )
                        end
                        descriptor.value = value
                    end
                    return
                end
            end
            metatable = getmetatable(metatable)
        end
        rawset(self, key, value)
    end
end

local __TS__SetDescriptor
do
    local getmetatable = _G.getmetatable
    local function descriptorIndex(self, key)
        return __TS__DescriptorGet(
            self,
            getmetatable(self),
            key
        )
    end
    local function descriptorNewIndex(self, key, value)
        return __TS__DescriptorSet(
            self,
            getmetatable(self),
            key,
            value
        )
    end
    function __TS__SetDescriptor(target, key, desc, isPrototype)
        if isPrototype == nil then
            isPrototype = false
        end
        local ____isPrototype_0
        if isPrototype then
            ____isPrototype_0 = target
        else
            ____isPrototype_0 = getmetatable(target)
        end
        local metatable = ____isPrototype_0
        if not metatable then
            metatable = {}
            setmetatable(target, metatable)
        end
        local value = rawget(target, key)
        if value ~= nil then
            rawset(target, key, nil)
        end
        if not rawget(metatable, "_descriptors") then
            metatable._descriptors = {}
        end
        metatable._descriptors[key] = __TS__CloneDescriptor(desc)
        metatable.__index = descriptorIndex
        metatable.__newindex = descriptorNewIndex
    end
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

local function __TS__New(target, ...)
    local instance = setmetatable({}, target.prototype)
    instance:____constructor(...)
    return instance
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

local function __TS__ArrayPushArray(self, items)
    local len = #self
    for i = 1, #items do
        len = len + 1
        self[len] = items[i]
    end
    return len
end
-- End of Lua Library inline imports
local ____exports = {}
local ____types = require("modules.ui.types.index")
local EventDispatchResult = ____types.EventDispatchResult
local EventSubscription = ____types.EventSubscription
local EventSubscriptionOptions = ____types.EventSubscriptionOptions
local UIEvent = ____types.UIEvent
local UIEventBus = ____types.UIEventBus
local UIEventHandler = ____types.UIEventHandler
local UIEventName = ____types.UIEventName
local subscriptionIdCounter = 0
local function createSubscriptionId(self)
    subscriptionIdCounter = subscriptionIdCounter + 1
    return "ui_subscription_" .. tostring(subscriptionIdCounter)
end
local BasicEventSubscription = __TS__Class()
BasicEventSubscription.name = "BasicEventSubscription"
function BasicEventSubscription.prototype.____constructor(self, id, ____type, handlerTyped, owner, once, order, targetId)
    self.id = id
    self.type = ____type
    self.handlerTyped = handlerTyped
    self.owner = owner
    self.once = once
    self.order = order
    self.active = true
    if targetId ~= nil then
        self.targetId = targetId
    end
end
function BasicEventSubscription.prototype.unsubscribe(self)
    if not self.active then
        return
    end
    self.owner:unsubscribe(self.id)
end
function BasicEventSubscription.prototype.setActive(self, active)
    self.active = active
end
__TS__SetDescriptor(
    BasicEventSubscription.prototype,
    "handler",
    {get = function(self)
        return self.handlerTyped
    end},
    true
)
____exports.BasicUIEventBus = __TS__Class()
local BasicUIEventBus = ____exports.BasicUIEventBus
BasicUIEventBus.name = "BasicUIEventBus"
function BasicUIEventBus.prototype.____constructor(self)
    self.subscriptions = {}
end
function BasicUIEventBus.prototype.subscribe(self, ____type, handler, options)
    if options == nil then
        options = {}
    end
    local ____BasicEventSubscription_2 = BasicEventSubscription
    local ____array_1 = __TS__SparseArrayNew(
        createSubscriptionId(nil),
        ____type,
        handler,
        self
    )
    local ____options_once_0 = options.once
    if ____options_once_0 == nil then
        ____options_once_0 = false
    end
    __TS__SparseArrayPush(____array_1, ____options_once_0, options.order or 0, options.targetId)
    local subscription = __TS__New(
        ____BasicEventSubscription_2,
        __TS__SparseArraySpread(____array_1)
    )
    local list = self:getOrCreateSubscriptions(____type)
    list[#list + 1] = subscription
    __TS__ArraySort(
        list,
        function(____, left, right) return left.order - right.order end
    )
    return subscription
end
function BasicUIEventBus.prototype.subscribeOnce(self, ____type, handler, options)
    return self:subscribe(
        ____type,
        handler,
        __TS__ObjectAssign({}, options, {once = true})
    )
end
function BasicUIEventBus.prototype.unsubscribe(self, subscriptionId)
    for eventType in pairs(self.subscriptions) do
        do
            local ____type = eventType
            local list = self.subscriptions[____type]
            if not list or #list == 0 then
                goto __continue14
            end
            do
                local i = 0
                while i < #list do
                    do
                        local subscription = list[i + 1]
                        if subscription == nil then
                            goto __continue17
                        end
                        if subscription.id ~= subscriptionId then
                            goto __continue17
                        end
                        subscription:setActive(false)
                        __TS__ArraySplice(list, i, 1)
                        return true
                    end
                    ::__continue17::
                    i = i + 1
                end
            end
        end
        ::__continue14::
    end
    return false
end
function BasicUIEventBus.prototype.dispatch(self, event)
    local list = self.subscriptions[event.type]
    if not list or #list == 0 then
        local ____event_cancelled_3 = event.cancelled
        if ____event_cancelled_3 == nil then
            ____event_cancelled_3 = false
        end
        local ____event_propagationStopped_4 = event.propagationStopped
        if ____event_propagationStopped_4 == nil then
            ____event_propagationStopped_4 = false
        end
        return {dispatched = false, listenerCount = 0, cancelled = ____event_cancelled_3, propagationStopped = ____event_propagationStopped_4}
    end
    local listenerCount = 0
    local snapshot = {table.unpack(list)}
    for ____, subscription in ipairs(snapshot) do
        do
            if not subscription.active then
                goto __continue23
            end
            if subscription.targetId ~= nil and subscription.targetId ~= event.targetId then
                goto __continue23
            end
            listenerCount = listenerCount + 1
            subscription:handler(event)
            if subscription.once then
                self:unsubscribe(subscription.id)
            end
            if event.propagationStopped then
                break
            end
        end
        ::__continue23::
    end
    local ____temp_7 = listenerCount > 0
    local ____listenerCount_8 = listenerCount
    local ____event_cancelled_5 = event.cancelled
    if ____event_cancelled_5 == nil then
        ____event_cancelled_5 = false
    end
    local ____event_propagationStopped_6 = event.propagationStopped
    if ____event_propagationStopped_6 == nil then
        ____event_propagationStopped_6 = false
    end
    return {dispatched = ____temp_7, listenerCount = ____listenerCount_8, cancelled = ____event_cancelled_5, propagationStopped = ____event_propagationStopped_6}
end
function BasicUIEventBus.prototype.emit(self, event)
    return self:dispatch(event)
end
function BasicUIEventBus.prototype.clear(self, ____type)
    if ____type ~= nil then
        local list = self.subscriptions[____type]
        if not list then
            return
        end
        for ____, subscription in ipairs(list) do
            subscription:setActive(false)
        end
        self.subscriptions[____type] = {}
        return
    end
    for eventType in pairs(self.subscriptions) do
        self:clear(eventType)
    end
end
function BasicUIEventBus.prototype.count(self, ____type)
    if ____type ~= nil then
        local ____opt_9 = self.subscriptions[____type]
        return ____opt_9 and #____opt_9 or 0
    end
    local total = 0
    for eventType in pairs(self.subscriptions) do
        local ____opt_11 = self.subscriptions[eventType]
        total = total + (____opt_11 and #____opt_11 or 0)
    end
    return total
end
function BasicUIEventBus.prototype.has(self, ____type)
    local ____opt_13 = self.subscriptions[____type]
    return (____opt_13 and #____opt_13 or 0) > 0
end
function BasicUIEventBus.prototype.getSubscriptions(self, ____type)
    if ____type ~= nil then
        return {table.unpack(self.subscriptions[____type] or ({}))}
    end
    local allSubscriptions = {}
    for eventType in pairs(self.subscriptions) do
        do
            local list = self.subscriptions[eventType]
            if not list or #list == 0 then
                goto __continue44
            end
            __TS__ArrayPushArray(allSubscriptions, list)
        end
        ::__continue44::
    end
    return allSubscriptions
end
function BasicUIEventBus.prototype.getOrCreateSubscriptions(self, ____type)
    if not self.subscriptions[____type] then
        self.subscriptions[____type] = {}
    end
    return self.subscriptions[____type]
end
function ____exports.stopPropagation(self, event)
    event.propagationStopped = true
end
function ____exports.cancelEvent(self, event)
    event.cancelled = true
end
function ____exports.cancelAndStop(self, event)
    event.cancelled = true
    event.propagationStopped = true
end
return ____exports
