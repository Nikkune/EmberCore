--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__Class(self)
    local c = {prototype = {}}
    c.prototype.__index = c.prototype
    c.prototype.constructor = c
    return c
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

local function __TS__ArrayMap(self, callbackfn, thisArg)
    local result = {}
    for i = 1, #self do
        result[i] = callbackfn(thisArg, self[i], i - 1, self)
    end
    return result
end
-- End of Lua Library inline imports
local ____exports = {}
local ____components = require("modules.ui.components")
local ContainerComponent = ____components.ContainerComponent
local ____coreComponent = require("modules.ui.core.components.coreComponent")
local BaseComponent = ____coreComponent.BaseComponent
local ____surfaceAdapter = require("modules.ui.render.surfaceAdapter")
local UIDrawSurface = ____surfaceAdapter.UIDrawSurface
local ____types = require("modules.ui.types.index")
local BaseProps = ____types.BaseProps
local LabelStyle = ____types.LabelStyle
local LayoutConstraints = ____types.LayoutConstraints
local MeasuredSize = ____types.MeasuredSize
local Rect = ____types.Rect
local RenderContext = ____types.RenderContext
local UIComponent = ____types.UIComponent
local UIContext = ____types.UIContext
____exports.Painter = __TS__Class()
local Painter = ____exports.Painter
Painter.name = "Painter"
function Painter.prototype.____constructor(self, draw)
    self.draw = draw
end
function Painter.prototype.text(self, x, y, text, foreground, background)
    if background == nil then
        background = colors.black
    end
    if #text == 0 then
        return
    end
    self.draw:withColors(
        {foregroundColor = foreground, backgroundColor = background},
        function() return self.draw:writeAt({x = x, y = y}, text) end
    )
end
function Painter.prototype.fill(self, x, y, width, height, background)
    if width <= 0 or height <= 0 then
        return
    end
    self.draw:fillRect({x = x, y = y, width = width, height = height}, " ", background)
end
____exports.PaintComponent = __TS__Class()
local PaintComponent = ____exports.PaintComponent
PaintComponent.name = "PaintComponent"
__TS__ClassExtends(PaintComponent, BaseComponent)
function PaintComponent.prototype.____constructor(self, props)
    BaseComponent.prototype.____constructor(self, "label", props)
end
function PaintComponent.prototype.measure(self, constraints, _context)
    return self:createMeasuredSize(constraints.maxWidth, constraints.maxHeight, constraints)
end
function PaintComponent.prototype.render(self, context)
    if not self.visible then
        return
    end
    self.props:paint(__TS__New(____exports.Painter, context.draw))
end
function PaintComponent.prototype.getResolvedStyle(self, context)
    return self:getStyle(context, {})
end
____exports.AbsoluteLayout = __TS__Class()
local AbsoluteLayout = ____exports.AbsoluteLayout
AbsoluteLayout.name = "AbsoluteLayout"
__TS__ClassExtends(AbsoluteLayout, ContainerComponent)
function AbsoluteLayout.prototype.____constructor(self, width, height)
    ContainerComponent.prototype.____constructor(self, {width = width, height = height})
    self.places = __TS__New(Map)
end
function AbsoluteLayout.prototype.place(self, child, rect)
    self.places:set(child, rect)
    self:addChild(child)
    return child
end
function AbsoluteLayout.prototype.layout(self, rect, context)
    ContainerComponent.prototype.layout(self, rect, context)
    self:layoutChildren(
        __TS__ArrayMap(
            self.children,
            function(____, child) return {
                child = child,
                rect = self.places:get(child) or rect
            } end
        ),
        context
    )
end
return ____exports
