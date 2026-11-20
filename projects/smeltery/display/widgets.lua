--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__Class(self)
    local c = {prototype = {}}
    c.prototype.__index = c.prototype
    c.prototype.constructor = c
    return c
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

local function __TS__ArrayFind(self, predicate, thisArg)
    for i = 1, #self do
        local elem = self[i]
        if predicate(thisArg, elem, i - 1, self) then
            return elem
        end
    end
    return nil
end

local function __TS__ArrayForEach(self, callbackFn, thisArg)
    for i = 1, #self do
        callbackFn(thisArg, self[i], i - 1, self)
    end
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
function Painter.prototype.____constructor(self, draw, clip)
    self.draw = draw
    self.clip = clip
end
function Painter.prototype.text(self, x, y, text, foreground, background)
    if background == nil then
        background = colors.black
    end
    local start = x
    local shown = text
    local clip = self.clip
    if clip ~= nil then
        if y < clip.y or y >= clip.y + clip.height then
            return
        end
        local from = math.max(x, clip.x)
        local to = math.min(x + #text, clip.x + clip.width)
        if to <= from then
            return
        end
        shown = __TS__StringSubstring(text, from - x, to - x)
        start = from
    end
    if #shown == 0 then
        return
    end
    self.draw:withColors(
        {foregroundColor = foreground, backgroundColor = background},
        function() return self.draw:writeAt({x = start, y = y}, shown) end
    )
end
function Painter.prototype.fill(self, x, y, width, height, background)
    local rect = {x = x, y = y, width = width, height = height}
    local clip = self.clip
    if clip ~= nil then
        local left = math.max(x, clip.x)
        local top = math.max(y, clip.y)
        local right = math.min(x + width, clip.x + clip.width)
        local bottom = math.min(y + height, clip.y + clip.height)
        rect = {x = left, y = top, width = right - left, height = bottom - top}
    end
    if rect.width <= 0 or rect.height <= 0 then
        return
    end
    self.draw:fillRect(rect, " ", background)
end
function Painter.prototype.pixel(self, x, y, mask, color, background)
    if background == nil then
        background = colors.black
    end
    local low = mask % 32
    if mask >= 32 then
        self:text(
            x,
            y,
            string.char(128 + 31 - low),
            background,
            color
        )
    else
        self:text(
            x,
            y,
            string.char(128 + low),
            color,
            background
        )
    end
end
local PIXEL_WEIGHTS = {
    1,
    2,
    4,
    8,
    16,
    32
}
____exports.Pixels = __TS__Class()
local Pixels = ____exports.Pixels
Pixels.name = "Pixels"
function Pixels.prototype.____constructor(self, x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.colorAt = __TS__New(Map)
end
function Pixels.prototype.set(self, px, py, color)
    if px < 0 or py < 0 or px >= self.width * 2 or py >= self.height * 3 then
        return
    end
    self.colorAt:set(py * 4096 + px, color)
end
function Pixels.prototype.line(self, x0, y0, x1, y1, color)
    local steps = math.max(
        math.abs(x1 - x0),
        math.abs(y1 - y0),
        1
    )
    do
        local step = 0
        while step <= steps do
            self:set(
                math.floor(x0 + (x1 - x0) * step / steps + 0.5),
                math.floor(y0 + (y1 - y0) * step / steps + 0.5),
                color
            )
            step = step + 1
        end
    end
end
function Pixels.prototype.rect(self, px, py, width, height, color)
    do
        local row = 0
        while row < height do
            do
                local column = 0
                while column < width do
                    self:set(px + column, py + row, color)
                    column = column + 1
                end
            end
            row = row + 1
        end
    end
end
function Pixels.prototype.paint(self, p, background)
    if background == nil then
        background = colors.black
    end
    do
        local cy = 0
        while cy < self.height do
            do
                local cx = 0
                while cx < self.width do
                    do
                        local __continue30
                        repeat
                            local cell = {}
                            local any = false
                            do
                                local index = 0
                                while index < 6 do
                                    local color = self.colorAt:get((cy * 3 + math.floor(index / 2)) * 4096 + cx * 2 + index % 2)
                                    cell[#cell + 1] = color or background
                                    if color ~= nil then
                                        any = true
                                    end
                                    index = index + 1
                                end
                            end
                            if not any then
                                __continue30 = true
                                break
                            end
                            local counts = __TS__New(Map)
                            for ____, color in ipairs(cell) do
                                counts:set(
                                    color,
                                    (counts:get(color) or 0) + 1
                                )
                            end
                            local ranked = {}
                            for ____, ____value in __TS__Iterator(counts) do
                                local color = ____value[1]
                                local count = ____value[2]
                                ranked[#ranked + 1] = {color, count}
                            end
                            __TS__ArraySort(
                                ranked,
                                function(____, a, b) return b[2] - a[2] end
                            )
                            local first = __TS__ArrayFind(
                                ranked,
                                function(____, ____bindingPattern0)
                                    local color
                                    color = ____bindingPattern0[1]
                                    return color ~= background
                                end
                            )
                            if first == nil then
                                __continue30 = true
                                break
                            end
                            local on = first[1]
                            local ____opt_0 = __TS__ArrayFind(
                                ranked,
                                function(____, ____bindingPattern0)
                                    local color
                                    color = ____bindingPattern0[1]
                                    return color ~= on
                                end
                            )
                            local off = ____opt_0 and ____opt_0[1] or background
                            local mask = 0
                            __TS__ArrayForEach(
                                cell,
                                function(____, color, index)
                                    if color == on then
                                        mask = mask + PIXEL_WEIGHTS[index + 1]
                                    end
                                end
                            )
                            p:pixel(
                                self.x + cx,
                                self.y + cy,
                                mask,
                                on,
                                off
                            )
                            __continue30 = true
                        until true
                        if not __continue30 then
                            break
                        end
                    end
                    cx = cx + 1
                end
            end
            cy = cy + 1
        end
    end
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
    self.props:paint(__TS__New(____exports.Painter, context.draw, context.clipRect))
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
