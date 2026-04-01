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

local function __TS__ArrayMap(self, callbackfn, thisArg)
    local result = {}
    for i = 1, #self do
        result[i] = callbackfn(thisArg, self[i], i - 1, self)
    end
    return result
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
local GridProps = ____types.GridProps
local GridStyle = ____types.GridStyle
local LayoutConstraints = ____types.LayoutConstraints
local MeasuredSize = ____types.MeasuredSize
local Rect = ____types.Rect
local RenderContext = ____types.RenderContext
local UIComponent = ____types.UIComponent
local UIContext = ____types.UIContext
local ____arrays = require("modules.ui.utils.arrays")
local createFilledArray = ____arrays.createFilledArray
local ____helpers = require("utils.helpers")
local createOptions = ____helpers.createOptions
____exports.GridComponent = __TS__Class()
local GridComponent = ____exports.GridComponent
GridComponent.name = "GridComponent"
__TS__ClassExtends(GridComponent, BaseContainerComponent)
function GridComponent.prototype.____constructor(self, props, dependencies, children)
    if dependencies == nil then
        dependencies = {}
    end
    if children == nil then
        children = {}
    end
    BaseContainerComponent.prototype.____constructor(
        self,
        "grid",
        props,
        dependencies,
        children
    )
end
function GridComponent.prototype.measure(self, constraints, context)
    local style = self:getResolvedStyle(context)
    local innerConstraints = self:getInnerConstraints(constraints, style)
    local columns = self:getColumns()
    local columnSpacing = self.props.columnSpacing or 0
    local rowSpacing = self.props.rowSpacing or 0
    local childrenSizes = self:measureChildren(innerConstraints, context)
    if #childrenSizes == 0 then
        return self:createMeasuredSize(
            self:getRequestedWidth(0),
            self:getRequestedHeight(0),
            constraints
        )
    end
    local columnWidths = createFilledArray(nil, columns, 0)
    local rowHeights = {}
    do
        local index = 0
        while index < #childrenSizes do
            local size = childrenSizes[index + 1]
            local column = index % columns
            local row = math.floor(index / columns)
            columnWidths[column + 1] = math.max(columnWidths[column + 1] or 0, size.width)
            rowHeights[row + 1] = math.max(rowHeights[row + 1] or 0, size.height)
            index = index + 1
        end
    end
    local contentWidth = __TS__ArrayReduce(
        columnWidths,
        function(____, sum, width) return sum + width end,
        0
    ) + math.max(0, #columnWidths - 1) * columnSpacing
    local contentHeight = __TS__ArrayReduce(
        rowHeights,
        function(____, sum, height) return sum + height end,
        0
    ) + math.max(0, #rowHeights - 1) * rowSpacing
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
function GridComponent.prototype.layout(self, rect, context)
    BaseContainerComponent.prototype.layout(self, rect, context)
    local style = self:getResolvedStyle(context)
    local innerRect = getInnerRect(nil, self.rect, style)
    local placements = self:createPlacements(innerRect, context)
    self:layoutChildren(placements, context)
end
function GridComponent.prototype.render(self, context)
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
function GridComponent.prototype.getResolvedStyle(self, context)
    return self:getStyle(
        context,
        function(____, themeStyle) return createOptions(nil, themeStyle):with("foregroundColor", self.props.foregroundColor or themeStyle.foregroundColor or context.theme.palette.text):with("backgroundColor", self.props.backgroundColor or themeStyle.backgroundColor or context.theme.palette.surface):with("padding", themeStyle.padding or 0):done() end
    )
end
function GridComponent.prototype.getColumns(self)
    return math.max(1, self.props.columns or 1)
end
function GridComponent.prototype.getInnerConstraints(self, constraints, style)
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
function GridComponent.prototype.createPlacements(self, innerRect, context)
    local children = {table.unpack(self.children)}
    local columns = self:getColumns()
    local columnSpacing = self.props.columnSpacing or 0
    local rowSpacing = self.props.rowSpacing or 0
    if #children == 0 or innerRect.width <= 0 or innerRect.height <= 0 then
        return {}
    end
    local availableWidth = math.max(
        0,
        innerRect.width - math.max(0, columns - 1) * columnSpacing
    )
    local baseColumnWidth = columns > 0 and math.floor(availableWidth / columns) or 0
    local extraWidth = columns > 0 and availableWidth % columns or 0
    local columnWidths = __TS__ArrayMap(
        createFilledArray(nil, columns, baseColumnWidth),
        function(____, width)
            if extraWidth > 0 then
                extraWidth = extraWidth - 1
                return width + 1
            end
            return width
        end
    )
    local rowCount = math.ceil(#children / columns)
    local rowHeights = createFilledArray(nil, rowCount, 0)
    do
        local index = 0
        while index < #children do
            local child = children[index + 1]
            local column = index % columns
            local row = math.floor(index / columns)
            local columnWidth = columnWidths[column + 1] or 0
            local measured = child:measure({minWidth = 0, maxWidth = columnWidth, minHeight = 0, maxHeight = innerRect.height}, context)
            rowHeights[row + 1] = math.max(rowHeights[row + 1] or 0, measured.height)
            index = index + 1
        end
    end
    local placements = {}
    local currentY = innerRect.y
    do
        local row = 0
        while row < rowCount do
            local currentX = innerRect.x
            local rowHeight = rowHeights[row + 1] or 0
            do
                local column = 0
                while column < columns do
                    local index = row * columns + column
                    local child = children[index + 1]
                    if not child then
                        break
                    end
                    local columnWidth = columnWidths[column + 1] or 0
                    placements[#placements + 1] = {child = child, rect = {x = currentX, y = currentY, width = columnWidth, height = rowHeight}}
                    currentX = currentX + (columnWidth + columnSpacing)
                    column = column + 1
                end
            end
            currentY = currentY + (rowHeight + rowSpacing)
            row = row + 1
        end
    end
    return placements
end
return ____exports
