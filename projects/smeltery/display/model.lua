--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__StringIncludes(self, searchString, position)
    if not position then
        position = 1
    else
        position = position + 1
    end
    local index = string.find(self, searchString, position, true)
    return index ~= nil
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

local function __TS__StringStartsWith(self, searchString, position)
    if position == nil or position < 0 then
        position = 0
    end
    return string.sub(self, position + 1, #searchString + position) == searchString
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

local function __TS__StringTrim(self)
    local result = string.gsub(self, "^[%s ﻿]*(.-)[%s ﻿]*$", "%1")
    return result
end

local function __TS__StringEndsWith(self, searchString, endPosition)
    if endPosition == nil or endPosition > #self then
        endPosition = #self
    end
    return string.sub(self, endPosition - #searchString + 1, endPosition) == searchString
end
-- End of Lua Library inline imports
local ____exports = {}
local ____protocol = require("projects.smeltery.shared.protocol")
local CasterView = ____protocol.CasterView
local SmelteryState = ____protocol.SmelteryState
____exports.Glyph = {
    up = string.char(30),
    down = string.char(31),
    right = string.char(16),
    left = string.char(17),
    dot = string.char(7),
    rule = string.char(128 + 4 + 8),
    underline = string.char(128 + 1 + 2)
}
local FLUID_COLORS = {
    {"rose_gold", colors.pink},
    {"pig_iron", colors.pink},
    {"iron", colors.lightGray},
    {"gold", colors.yellow},
    {"copper", colors.orange},
    {"tin", colors.white},
    {"silver", colors.white},
    {"lead", colors.blue},
    {"nickel", colors.lightGray},
    {"zinc", colors.lightGray},
    {"bronze", colors.brown},
    {"brass", colors.yellow},
    {"electrum", colors.yellow},
    {"cobalt", colors.blue},
    {"aluminum", colors.white},
    {"steel", colors.gray},
    {"netherite", colors.gray},
    {"debris", colors.brown},
    {"blazing", colors.red},
    {"lava", colors.orange},
    {"obsidian", colors.purple},
    {"emerald", colors.lime},
    {"diamond", colors.cyan},
    {"quartz", colors.white},
    {"glass", colors.white},
    {"slime", colors.lime},
    {"ender", colors.cyan},
    {"manyullyn", colors.purple},
    {"hepatizon", colors.purple},
    {"amethyst", colors.purple},
    {"invar", colors.lightGray},
    {"constantan", colors.orange},
    {"pewter", colors.lightGray},
    {"osmium", colors.lightBlue},
    {"platinum", colors.lightBlue},
    {"uranium", colors.lime},
    {"signalum", colors.red},
    {"lumium", colors.yellow},
    {"blood", colors.red}
}
local DARK_COLORS = {
    colors.gray,
    colors.blue,
    colors.purple,
    colors.brown,
    colors.green,
    colors.red,
    colors.black
}
function ____exports.fluidColor(fluid)
    for ____, ____value in ipairs(FLUID_COLORS) do
        local keyword = ____value[1]
        local color = ____value[2]
        if __TS__StringIncludes(fluid, keyword) then
            return color
        end
    end
    return colors.magenta
end
function ____exports.textOn(background)
    return __TS__ArrayIncludes(DARK_COLORS, background) and colors.white or colors.black
end
function ____exports.fluidLabel(fluid)
    local colon = (string.find(fluid, ":", nil, true) or 0) - 1
    local name = colon >= 0 and __TS__StringSubstring(fluid, colon + 1) or fluid
    if __TS__StringStartsWith(name, "molten_") then
        name = __TS__StringSubstring(name, #"molten_")
    end
    return table.concat(
        __TS__StringSplit(name, "_"),
        " "
    )
end
function ____exports.itemLabel(item)
    local colon = (string.find(item, ":", nil, true) or 0) - 1
    return colon >= 0 and __TS__StringSubstring(item, colon + 1) or item
end
function ____exports.formatLabel(format)
    return table.concat(
        __TS__StringSplit(format, "_"),
        " "
    )
end
function ____exports.groupCasters(casters, autoFormats)
    local groups = __TS__New(Map)
    for ____, caster in ipairs(casters) do
        local format = caster.format or "no cast"
        local group = groups:get(format)
        if group == nil then
            group = {
                format = format,
                free = 0,
                casting = 0,
                ready = 0,
                auto = __TS__ArrayIncludes(autoFormats, format)
            }
            groups:set(format, group)
        end
        if caster.status == "idle" then
            group.free = group.free + 1
        elseif caster.status == "busy" then
            group.casting = group.casting + 1
        else
            group.ready = group.ready + 1
        end
    end
    local list = {}
    for ____, format in ipairs(autoFormats) do
        local group = groups:get(format)
        if group ~= nil then
            list[#list + 1] = group
        end
    end
    local others = {}
    for ____, ____value in __TS__Iterator(groups) do
        local group = ____value[2]
        if not group.auto then
            others[#others + 1] = group
        end
    end
    __TS__ArraySort(
        others,
        function(____, a, b) return a.format < b.format and -1 or (a.format > b.format and 1 or 0) end
    )
    local ____array_0 = __TS__SparseArrayNew(unpack(list))
    __TS__SparseArrayPush(
        ____array_0,
        unpack(others)
    )
    return {__TS__SparseArraySpread(____array_0)}
end
function ____exports.attentionLines(state)
    local lines = {}
    for ____, alert in ipairs(state.alerts) do
        local colon = (string.find(alert, ": ", nil, true) or 0) - 1
        lines[#lines + 1] = colon >= 0 and ({
            color = colors.red,
            title = __TS__StringSubstring(alert, 0, colon),
            detail = __TS__StringTrim(__TS__StringSubstring(alert, colon + 2))
        }) or ({color = colors.red, title = alert, detail = ""})
    end
    for ____, item in ipairs(state.waiting) do
        local name = (tostring(item.count) .. " ") .. ____exports.itemLabel(item.name)
        if item.reason == "alloy" then
            lines[#lines + 1] = {
                color = colors.orange,
                title = name .. " waits",
                detail = "would form " .. ____exports.fluidLabel(item.alloy or "?")
            }
        elseif item.reason == "heat" then
            lines[#lines + 1] = {
                color = colors.orange,
                title = name .. " waits",
                detail = ("needs " .. tostring(item.temperature or "?")) .. " K"
            }
        elseif item.reason == "full" then
            lines[#lines + 1] = {color = colors.orange, title = name .. " waits", detail = "the Smeltery is full"}
        else
            lines[#lines + 1] = {color = colors.orange, title = name .. " waits", detail = "melts into nothing known"}
        end
    end
    return lines
end
function ____exports.parseLogLine(line)
    local time = __TS__StringSubstring(line, 0, 8)
    local body = __TS__StringSubstring(line, 9)
    local words = __TS__StringSplit(body, " ")
    local function word(____, index)
        return words[index + 1] or ""
    end
    repeat
        local ____switch36 = word(nil, 0)
        local ____cond36 = ____switch36 == "inserted"
        if ____cond36 then
            return {
                time = time,
                kind = "in",
                text = (____exports.itemLabel(word(nil, 2)) .. " ") .. word(nil, 1)
            }
        end
        ____cond36 = ____cond36 or ____switch36 == "poured"
        if ____cond36 then
            return {
                time = time,
                kind = "cast",
                text = (((____exports.fluidLabel(word(nil, 3)) .. " ") .. word(nil, 1)) .. " > ") .. ____exports.itemLabel(word(nil, 5))
            }
        end
        ____cond36 = ____cond36 or ____switch36 == "collected"
        if ____cond36 then
            return {
                time = time,
                kind = "out",
                text = (word(nil, 1) .. " from ") .. ____exports.itemLabel(word(nil, 3))
            }
        end
        ____cond36 = ____cond36 or ____switch36 == "moved"
        if ____cond36 then
            do
                local open = (string.find(body, "(", nil, true) or 0) - 1
                local why = open >= 0 and __TS__StringEndsWith(body, ")") and __TS__StringSubstring(body, open + 1, #body - 1) or ""
                return {
                    time = time,
                    kind = "reject",
                    text = (((____exports.itemLabel(word(nil, 2)) .. " ") .. word(nil, 1)) .. " > ") .. why
                }
            end
        end
        ____cond36 = ____cond36 or ____switch36 == "FORCED"
        if ____cond36 then
            return {
                time = time,
                kind = "forced",
                text = __TS__StringSubstring(body, #"FORCED ")
            }
        end
        ____cond36 = ____cond36 or ____switch36 == "mode"
        if ____cond36 then
            return {time = time, kind = "mode", text = body}
        end
        do
            return {time = time, kind = "other", text = body}
        end
    until true
end
return ____exports
