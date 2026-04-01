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

local function __TS__ArrayMap(self, callbackfn, thisArg)
    local result = {}
    for i = 1, #self do
        result[i] = callbackfn(thisArg, self[i], i - 1, self)
    end
    return result
end

local function __TS__CountVarargs(...)
    return select("#", ...)
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
-- End of Lua Library inline imports
local ____exports = {}
local ____ui = require("modules.ui.index")
local BaseContainerComponent = ____ui.BaseContainerComponent
local drawBox = ____ui.drawBox
local DrawBoxOptions = ____ui.DrawBoxOptions
local getInnerRect = ____ui.getInnerRect
local normalizeInsets = ____ui.normalizeInsets
local UIDrawSurface = ____ui.UIDrawSurface
local ____types = require("modules.ui.types.index")
local ComponentDependencies = ____types.ComponentDependencies
local CrossAxisAlignment = ____types.CrossAxisAlignment
local LayoutConstraints = ____types.LayoutConstraints
local MainAxisAlignment = ____types.MainAxisAlignment
local MeasuredSize = ____types.MeasuredSize
local Rect = ____types.Rect
local RenderContext = ____types.RenderContext
local StackProps = ____types.StackProps
local StackStyle = ____types.StackStyle
local UIComponent = ____types.UIComponent
local UIContext = ____types.UIContext
local WrapMode = ____types.WrapMode
local ____helpers = require("utils.helpers")
local createOptions = ____helpers.createOptions
____exports.StackComponent = __TS__Class()
local StackComponent = ____exports.StackComponent
StackComponent.name = "StackComponent"
__TS__ClassExtends(StackComponent, BaseContainerComponent)
function StackComponent.prototype.____constructor(self, props, dependencies, children)
    if dependencies == nil then
        dependencies = {}
    end
    if children == nil then
        children = {}
    end
    BaseContainerComponent.prototype.____constructor(
        self,
        "stack",
        props,
        dependencies,
        children
    )
end
function StackComponent.prototype.measure(self, constraints, context)
    local style = self:getResolvedStyle(context)
    local innerConstraints = self:getInnerConstraints(constraints, style)
    local direction = self.props.direction or "column"
    local spacing = self.props.spacing or 0
    local wrap = self.props.wrap or "nowrap"
    local children = __TS__ArrayMap(
        self.children,
        function(____, child, index) return {
            child = child,
            index = index,
            size = child:measure(innerConstraints, context)
        } end
    )
    local lines = self:createLines(
        children,
        direction,
        wrap,
        spacing,
        direction == "row" and innerConstraints.maxWidth or innerConstraints.maxHeight
    )
    local contentMain = __TS__ArrayReduce(
        lines,
        function(____, max, line) return math.max(max, line.mainSize) end,
        0
    )
    local contentCross = __TS__ArrayReduce(
        lines,
        function(____, sum, line) return sum + line.crossSize end,
        0
    ) + math.max(0, #lines - 1) * spacing
    local contentWidth = direction == "row" and contentMain or contentCross
    local contentHeight = direction == "row" and contentCross or contentMain
    local padding = normalizeInsets(nil, style.padding)
    local ____opt_0 = style.border
    local borderX = ____opt_0 and ____opt_0.enabled and 2 or 0
    local ____opt_2 = style.border
    local borderY = ____opt_2 and ____opt_2.enabled and 2 or 0
    return self:createMeasuredSize(
        self:getRequestedWidth(contentWidth + padding.left + padding.right + borderX),
        self:getRequestedHeight(contentHeight + padding.top + padding.bottom + borderY),
        constraints
    )
end
function StackComponent.prototype.layout(self, rect, context)
    BaseContainerComponent.prototype.layout(self, rect, context)
    local style = self:getResolvedStyle(context)
    local innerRect = getInnerRect(nil, self.rect, style)
    local placements = self:createPlacements(innerRect, context)
    self:layoutChildren(placements, context)
end
function StackComponent.prototype.render(self, context)
    if not self.visible then
        return
    end
    if self.width <= 0 or self.height <= 0 then
        return
    end
    local style = self:getResolvedStyle(context)
    local ____opt_4 = style.border
    local borderCharacters = ____opt_4 and ____opt_4.enabled and context.theme.borders[style.border.preset or "single"] or nil
    drawBox(
        nil,
        context.draw,
        createOptions(nil, {rect = self.rect, style = style}):with("borderCharacters", borderCharacters):with("clipRect", context.clipRect):done()
    )
    self:renderChildren(context)
end
function StackComponent.prototype.getResolvedStyle(self, context)
    return self:getStyle(
        context,
        function(____, themeStyle) return createOptions(nil, themeStyle):with("foregroundColor", self.props.foregroundColor or themeStyle.foregroundColor or context.theme.palette.text):with("backgroundColor", self.props.backgroundColor or themeStyle.backgroundColor or context.theme.palette.surface):with("padding", themeStyle.padding or 0):done() end
    )
end
function StackComponent.prototype.getInnerConstraints(self, constraints, style)
    local padding = normalizeInsets(nil, style.padding)
    local ____opt_6 = style.border
    local borderX = ____opt_6 and ____opt_6.enabled and 2 or 0
    local ____opt_8 = style.border
    local borderY = ____opt_8 and ____opt_8.enabled and 2 or 0
    local horizontal = padding.left + padding.right + borderX
    local vertical = padding.top + padding.bottom + borderY
    return {
        minWidth = math.max(0, constraints.minWidth - horizontal),
        maxWidth = math.max(0, constraints.maxWidth - horizontal),
        minHeight = math.max(0, constraints.minHeight - vertical),
        maxHeight = math.max(0, constraints.maxHeight - vertical)
    }
end
function StackComponent.prototype.createPlacements(self, innerRect, context)
    local children = {table.unpack(self.children)}
    local direction = self.props.direction or "column"
    local spacing = self.props.spacing or 0
    local alignment = self.props.alignment or "start"
    local justify = self.props.justify or "start"
    local wrap = self.props.wrap or "nowrap"
    if #children == 0 or innerRect.width <= 0 or innerRect.height <= 0 then
        return {}
    end
    local measured = __TS__ArrayMap(
        children,
        function(____, child, index)
            local size = child:measure({minWidth = 0, maxWidth = innerRect.width, minHeight = 0, maxHeight = innerRect.height}, context)
            return {child = child, index = index, size = size}
        end
    )
    local availableMain = direction == "row" and innerRect.width or innerRect.height
    local availableCross = direction == "row" and innerRect.height or innerRect.width
    local lines = self:createLines(
        measured,
        direction,
        wrap,
        spacing,
        availableMain
    )
    local totalCross = __TS__ArrayReduce(
        lines,
        function(____, sum, line) return sum + line.crossSize end,
        0
    ) + math.max(0, #lines - 1) * spacing
    local remainingCross = math.max(0, availableCross - totalCross)
    local crossJustify = self:resolveCrossJustify(remainingCross, spacing, #lines, justify)
    local placements = {}
    local currentCross = crossJustify.startOffset
    for ____, line in ipairs(lines) do
        local remainingMain = math.max(0, availableMain - line.mainSize)
        local mainJustify = self:resolveMainJustify(remainingMain, spacing, #line.items, justify)
        local currentMain = mainJustify.startOffset
        for ____, item in ipairs(line.items) do
            local itemMain = direction == "row" and item.size.width or item.size.height
            local itemCross = direction == "row" and item.size.height or item.size.width
            local crossOffset = self:resolveCrossOffset(alignment, line.crossSize, itemCross)
            local stretchedCross = alignment == "stretch" and line.crossSize or itemCross
            local rect = direction == "row" and ({x = innerRect.x + currentMain, y = innerRect.y + currentCross + crossOffset, width = itemMain, height = stretchedCross}) or ({x = innerRect.x + currentCross + crossOffset, y = innerRect.y + currentMain, width = stretchedCross, height = itemMain})
            placements[#placements + 1] = {child = item.child, rect = rect}
            currentMain = currentMain + (itemMain + mainJustify.betweenSpacing)
        end
        currentCross = currentCross + (line.crossSize + crossJustify.betweenSpacing)
    end
    return placements
end
function StackComponent.prototype.createLines(self, children, direction, wrap, spacing, availableMain)
    if #children == 0 then
        return {}
    end
    if wrap == "nowrap" then
        return {self:createLine(children, direction, spacing)}
    end
    local lines = {}
    local current = {}
    local currentMain = 0
    for ____, item in ipairs(children) do
        do
            local itemMain = direction == "row" and item.size.width or item.size.height
            local nextMain = #current == 0 and itemMain or currentMain + spacing + itemMain
            if #current > 0 and nextMain > availableMain then
                lines[#lines + 1] = self:createLine(current, direction, spacing)
                current = {item}
                currentMain = itemMain
                goto __continue25
            end
            current[#current + 1] = item
            currentMain = nextMain
        end
        ::__continue25::
    end
    if #current > 0 then
        lines[#lines + 1] = self:createLine(current, direction, spacing)
    end
    return lines
end
function StackComponent.prototype.createLine(self, items, direction, spacing)
    local mainSize = __TS__ArrayReduce(
        items,
        function(____, sum, item)
            local size = direction == "row" and item.size.width or item.size.height
            return sum + size
        end,
        0
    ) + math.max(0, #items - 1) * spacing
    local crossSize = __TS__ArrayReduce(
        items,
        function(____, max, item)
            local size = direction == "row" and item.size.height or item.size.width
            return math.max(max, size)
        end,
        0
    )
    return {items = items, mainSize = mainSize, crossSize = crossSize}
end
function StackComponent.prototype.resolveMainJustify(self, remainingMain, spacing, childCount, justify)
    if childCount <= 0 then
        return {startOffset = 0, betweenSpacing = spacing}
    end
    repeat
        local ____switch34 = justify
        local ____cond34 = ____switch34 == "center"
        if ____cond34 then
            return {
                startOffset = math.floor(remainingMain / 2),
                betweenSpacing = spacing
            }
        end
        ____cond34 = ____cond34 or ____switch34 == "end"
        if ____cond34 then
            return {startOffset = remainingMain, betweenSpacing = spacing}
        end
        ____cond34 = ____cond34 or ____switch34 == "space-between"
        if ____cond34 then
            return {
                startOffset = 0,
                betweenSpacing = childCount > 1 and spacing + math.floor(remainingMain / (childCount - 1)) or spacing
            }
        end
        ____cond34 = ____cond34 or ____switch34 == "space-around"
        if ____cond34 then
            do
                local gap = childCount > 0 and math.floor(remainingMain / childCount) or 0
                return {
                    startOffset = math.floor(gap / 2),
                    betweenSpacing = spacing + gap
                }
            end
        end
        ____cond34 = ____cond34 or ____switch34 == "space-evenly"
        if ____cond34 then
            do
                local gap = math.floor(remainingMain / (childCount + 1))
                return {startOffset = gap, betweenSpacing = spacing + gap}
            end
        end
        ____cond34 = ____cond34 or ____switch34 == "start"
        do
            return {startOffset = 0, betweenSpacing = spacing}
        end
    until true
end
function StackComponent.prototype.resolveCrossJustify(self, remainingCross, spacing, lineCount, justify)
    if lineCount <= 0 then
        return {startOffset = 0, betweenSpacing = spacing}
    end
    if justify == "space-between" and lineCount > 1 then
        return {
            startOffset = 0,
            betweenSpacing = spacing + math.floor(remainingCross / (lineCount - 1))
        }
    end
    if justify == "space-around" then
        local gap = math.floor(remainingCross / lineCount)
        return {
            startOffset = math.floor(gap / 2),
            betweenSpacing = spacing + gap
        }
    end
    if justify == "space-evenly" then
        local gap = math.floor(remainingCross / (lineCount + 1))
        return {startOffset = gap, betweenSpacing = spacing + gap}
    end
    if justify == "center" then
        return {
            startOffset = math.floor(remainingCross / 2),
            betweenSpacing = spacing
        }
    end
    if justify == "end" then
        return {startOffset = remainingCross, betweenSpacing = spacing}
    end
    return {startOffset = 0, betweenSpacing = spacing}
end
function StackComponent.prototype.resolveCrossOffset(self, alignment, availableCross, childCross)
    local remaining = math.max(0, availableCross - childCross)
    repeat
        local ____switch45 = alignment
        local ____cond45 = ____switch45 == "center"
        if ____cond45 then
            return math.floor(remaining / 2)
        end
        ____cond45 = ____cond45 or ____switch45 == "end"
        if ____cond45 then
            return remaining
        end
        ____cond45 = ____cond45 or (____switch45 == "stretch" or ____switch45 == "start")
        do
            return 0
        end
    until true
end
return ____exports
