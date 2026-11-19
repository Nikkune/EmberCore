--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__New(target, ...)
    local instance = setmetatable({}, target.prototype)
    instance:____constructor(...)
    return instance
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
local ____logger = require("core.logger")
local Logger = ____logger.Logger
local ____peripheral = require("core.peripheral")
local Peripheral = ____peripheral.Peripheral
local ____result = require("core.result")
local Result = ____result.Result
local ____result = require("core.result")
local err = ____result.err
local ok = ____result.ok
local ____message = require("modules.net.message")
local isEnvelope = ____message.isEnvelope
local REPLY_TYPE = ____message.REPLY_TYPE
local ____message = require("modules.net.message")
local Envelope = ____message.Envelope
local log = __TS__New(Logger, "Net", "info")
____exports.Channel = __TS__Class()
local Channel = ____exports.Channel
Channel.name = "Channel"
function Channel.prototype.____constructor(self, options)
    self.handlers = __TS__New(Map)
    self.pending = __TS__New(Map)
    self.timers = __TS__New(Map)
    self.nextId = 1
    self.protocol = options.protocol
    self.timeoutSeconds = options.timeoutSeconds or 3
    if options.modem ~= nil then
        self.modemName = options.modem
    end
    if options.peers ~= nil then
        self.peers = __TS__New(Set, options.peers)
    end
end
function Channel.prototype.open(self)
    local name = self.modemName or ____exports.Channel:findModem()
    if name == nil then
        error(
            __TS__New(EmberError, "No modem found to open rednet", "NET_ERROR", {protocol = self.protocol, action = "open"}),
            0
        )
    end
    rednet.open(name)
    self.openedModem = name
    log:info("Rednet opened", {modem = name, protocol = self.protocol})
    return name
end
function Channel.prototype.close(self)
    if self.openedModem ~= nil then
        rednet.close(self.openedModem)
        self.openedModem = nil
    end
end
function Channel.prototype.host(self, hostname)
    rednet.host(self.protocol, hostname)
end
function Channel.prototype.lookup(self, hostname)
    local found = rednet.lookup(self.protocol, hostname)
    return type(found) == "number" and found or nil
end
function Channel.prototype.on(self, messageType, handler)
    self.handlers:set(messageType, handler)
end
function Channel.prototype.send(self, to, messageType, payload)
    rednet.send(
        to,
        self:envelope(messageType, payload),
        self.protocol
    )
end
function Channel.prototype.broadcast(self, messageType, payload)
    rednet.broadcast(
        self:envelope(messageType, payload),
        self.protocol
    )
end
function Channel.prototype.request(self, to, messageType, payload, callback, timeoutSeconds)
    local ____self_0, ____nextId_1 = self, "nextId"
    local ____self_nextId_2 = ____self_0[____nextId_1]
    ____self_0[____nextId_1] = ____self_nextId_2 + 1
    local id = ____self_nextId_2
    local message = self:envelope(messageType, payload)
    message.id = id
    local timer = os.startTimer(timeoutSeconds or self.timeoutSeconds)
    self.pending:set(id, {to = to, timer = timer, callback = callback})
    self.timers:set(timer, id)
    rednet.send(to, message, self.protocol)
    return id
end
function Channel.prototype.pendingCount(self)
    return self.pending.size
end
function Channel.prototype.handleEvent(self, raw)
    local name = unpack(raw, 1, 1)
    if name == "timer" then
        return self:handleTimer(raw[2])
    end
    if name ~= "rednet_message" then
        return false
    end
    local ____, from, message, protocol = unpack(raw, 1, 4)
    if protocol ~= self.protocol then
        return false
    end
    if self.peers ~= nil and not self.peers:has(from) then
        return true
    end
    if not isEnvelope(message) then
        return true
    end
    if message.type == REPLY_TYPE then
        self:handleReply(from, message)
    else
        self:handleMessage(from, message)
    end
    return true
end
function Channel.prototype.listen(self)
    while true do
        self:handleEvent({os.pullEvent()})
    end
end
function Channel.findModem(self)
    local anyModem
    for ____, name in ipairs(peripheral.getNames()) do
        do
            local __continue27
            repeat
                if not Peripheral:hasType(name, "modem") then
                    __continue27 = true
                    break
                end
                local modem = peripheral.wrap(name)
                if modem.isWireless() then
                    return name
                end
                if anyModem == nil then
                    anyModem = name
                end
                __continue27 = true
            until true
            if not __continue27 then
                break
            end
        end
    end
    return anyModem
end
function Channel.prototype.envelope(self, messageType, payload)
    local message = {net = 1, type = messageType}
    if payload ~= nil then
        message.payload = payload
    end
    return message
end
function Channel.prototype.handleTimer(self, timer)
    local id = self.timers:get(timer)
    if id == nil then
        return false
    end
    self.timers:delete(timer)
    local request = self.pending:get(id)
    if request ~= nil then
        self.pending:delete(id)
        request:callback(err(nil, "timeout"))
    end
    return true
end
function Channel.prototype.handleReply(self, from, message)
    if message.replyTo == nil then
        return
    end
    local request = self.pending:get(message.replyTo)
    if request == nil or request.to ~= from then
        return
    end
    self.pending:delete(message.replyTo)
    self.timers:delete(request.timer)
    os.cancelTimer(request.timer)
    request:callback(message.ok == true and ok(nil, message.payload) or err(nil, message.error or "request failed"))
end
function Channel.prototype.handleMessage(self, from, message)
    local handler = self.handlers:get(message.type)
    if handler == nil then
        log:warn("No handler for message", {type = message.type, from = from, protocol = self.protocol})
        if message.id ~= nil then
            self:reply(
                from,
                message.id,
                false,
                nil,
                ("unknown message type '" .. message.type) .. "'"
            )
        end
        return
    end
    do
        local function ____catch(____error)
            if ____error == "Terminated" then
                error(____error, 0)
            end
            local text = __TS__InstanceOf(____error, Error) and ____error.message or tostring(____error)
            log:error("Message handler failed", {type = message.type, from = from, error = text})
            if message.id ~= nil then
                self:reply(
                    from,
                    message.id,
                    false,
                    nil,
                    text
                )
            end
        end
        local ____try, ____hasReturned = pcall(function()
            local result = handler(nil, message.payload, from)
            if message.id ~= nil then
                self:reply(from, message.id, true, result)
            end
        end)
        if not ____try then
            ____catch(____hasReturned)
        end
    end
end
function Channel.prototype.reply(self, to, replyTo, success, payload, ____error)
    local message = self:envelope(REPLY_TYPE, payload)
    message.replyTo = replyTo
    message.ok = success
    if ____error ~= nil then
        message.error = ____error
    end
    rednet.send(to, message, self.protocol)
end
return ____exports
