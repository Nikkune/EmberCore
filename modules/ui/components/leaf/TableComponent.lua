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
-- End of Lua Library inline imports
local ____exports = {}
local ____ui = require("modules.ui.index")
local BaseComponent = ____ui.BaseComponent
local drawBox = ____ui.drawBox
local DrawBoxOptions = ____ui.DrawBoxOptions
local drawHorizontalLine = ____ui.drawHorizontalLine
local drawText = ____ui.drawText
local DrawTextOptions = ____ui.DrawTextOptions
local makeColors = ____ui.makeColors
local UIDrawSurface = ____ui.UIDrawSurface
local ____types = require("modules.ui.types.index")
local ColumnDefinition = ____types.ColumnDefinition
local ComponentDependencies = ____types.ComponentDependencies
local LayoutConstraints = ____types.LayoutConstraints
local MeasuredSize = ____types.MeasuredSize
local RenderContext = ____types.RenderContext
local TableProps = ____types.TableProps
local TableStyle = ____types.TableStyle
local TextStyle = ____types.TextStyle
local UIContext = ____types.UIContext
local ____helpers = require("utils.helpers")
local createOptions = ____helpers.createOptions
____exports.TableComponent = __TS__Class()
local TableComponent = ____exports.TableComponent
TableComponent.name = "TableComponent"
__TS__ClassExtends(TableComponent, BaseComponent)
function TableComponent.prototype.____constructor(self, props, dependencies)
    if dependencies == nil then
        dependencies = {}
    end
    BaseComponent.prototype.____constructor(self, "table", props, dependencies)
end
function TableComponent.prototype.measure(self, constraints, context)
    local style = self:getResolvedStyle(context)
    local ____style_showHeader_0 = style.showHeader
    if ____style_showHeader_0 == nil then
        ____style_showHeader_0 = true
    end
    local showHeader = ____style_showHeader_0
    local columnWidths = self:resolveColumnWidths(constraints.maxWidth, style)
    local contentWidth = __TS__ArrayReduce(
        columnWidths,
        function(____, sum, col) return sum + col.width end,
        0
    ) + (style.showBorders and math.max(0, #columnWidths - 1) or 0)
    local rowCount = #self.props.rows + (showHeader and 1 or 0)
    local separatorCount = style.showBorders and math.max(0, rowCount - 1) or 0
    local contentHeight = rowCount + separatorCount
    return self:createMeasuredSize(
        self:getRequestedWidth(contentWidth),
        self:getRequestedHeight(math.max(1, contentHeight)),
        constraints
    )
end
function TableComponent.prototype.render(self, context)
    if not self.visible then
        return
    end
    if self.width <= 0 or self.height <= 0 then
        return
    end
    local style = self:getResolvedStyle(context)
    local ____opt_1 = style.border
    local borderCharacters = ____opt_1 and ____opt_1.enabled and context.theme.borders[style.border.preset or "single"] or nil
    local innerRect = drawBox(
        nil,
        context.draw,
        createOptions(nil, {rect = self.rect, style = style}):with("borderCharacters", borderCharacters):with("clipRect", context.clipRect):done()
    )
    if innerRect.width <= 0 or innerRect.height <= 0 then
        return
    end
    local columns = self:resolveColumnWidths(innerRect.width, style)
    local ____style_showHeader_3 = style.showHeader
    if ____style_showHeader_3 == nil then
        ____style_showHeader_3 = true
    end
    local showHeader = ____style_showHeader_3
    local ____style_showBorders_4 = style.showBorders
    if ____style_showBorders_4 == nil then
        ____style_showBorders_4 = false
    end
    local showBorders = ____style_showBorders_4
    local currentY = innerRect.y
    if showHeader and currentY < innerRect.y + innerRect.height then
        self:renderHeaderRow(
            context,
            columns,
            currentY,
            style,
            innerRect
        )
        currentY = currentY + 1
        if showBorders and currentY < innerRect.y + innerRect.height then
            drawHorizontalLine(
                nil,
                context.draw,
                {x = innerRect.x, y = currentY},
                innerRect.width,
                "─",
                style.separatorColor,
                style.backgroundColor,
                context.clipRect
            )
            currentY = currentY + 1
        end
    end
    do
        local rowIndex = 0
        while rowIndex < #self.props.rows do
            if currentY >= innerRect.y + innerRect.height then
                break
            end
            local row = self.props.rows[rowIndex + 1]
            self:renderDataRow(
                context,
                columns,
                row,
                rowIndex,
                currentY,
                style,
                innerRect
            )
            currentY = currentY + 1
            if showBorders and rowIndex < #self.props.rows - 1 and currentY < innerRect.y + innerRect.height then
                drawHorizontalLine(
                    nil,
                    context.draw,
                    {x = innerRect.x, y = currentY},
                    innerRect.width,
                    "─",
                    style.separatorColor,
                    style.backgroundColor,
                    context.clipRect
                )
                currentY = currentY + 1
            end
            rowIndex = rowIndex + 1
        end
    end
end
function TableComponent.prototype.getResolvedStyle(self, context)
    return self:getStyle(
        context,
        function(____, themeStyle)
            local ____self_52 = createOptions(nil, themeStyle):with("foregroundColor", self.props.foregroundColor or themeStyle.foregroundColor or context.theme.palette.text):with("backgroundColor", self.props.backgroundColor or themeStyle.backgroundColor or context.theme.palette.surface)
            local ____self_52_with_53 = ____self_52.with
            local ____themeStyle_showHeader_51 = themeStyle.showHeader
            if ____themeStyle_showHeader_51 == nil then
                ____themeStyle_showHeader_51 = true
            end
            local ____self_50 = ____self_52_with_53(____self_52, "showHeader", ____themeStyle_showHeader_51)
            local ____self_50_with_54 = ____self_50.with
            local ____themeStyle_showBorders_49 = themeStyle.showBorders
            if ____themeStyle_showBorders_49 == nil then
                ____themeStyle_showBorders_49 = true
            end
            local ____self_48 = ____self_50_with_54(____self_50, "showBorders", ____themeStyle_showBorders_49):with("separatorColor", themeStyle.separatorColor or context.theme.palette.border)
            local ____self_48_with_55 = ____self_48.with
            local ____self_42 = createOptions(nil, themeStyle.headerStyle or ({}))
            local ____self_42_with_43 = ____self_42.with
            local ____opt_40 = themeStyle.headerStyle
            local ____self_39 = ____self_42_with_43(____self_42, "alignment", ____opt_40 and ____opt_40.alignment or "left")
            local ____self_39_with_44 = ____self_39.with
            local ____opt_37 = themeStyle.headerStyle
            local ____self_36 = ____self_39_with_44(____self_39, "wrap", ____opt_37 and ____opt_37.wrap or "none")
            local ____self_36_with_45 = ____self_36.with
            local ____opt_33 = themeStyle.headerStyle
            local ____temp_35 = ____opt_33 and ____opt_33.ellipsis
            if ____temp_35 == nil then
                ____temp_35 = true
            end
            local ____self_32 = ____self_36_with_45(____self_36, "ellipsis", ____temp_35)
            local ____self_32_with_46 = ____self_32.with
            local ____opt_30 = themeStyle.headerStyle
            local ____self_29 = ____self_32_with_46(____self_32, "foregroundColor", ____opt_30 and ____opt_30.foregroundColor or context.theme.palette.text)
            local ____self_29_with_47 = ____self_29.with
            local ____opt_27 = themeStyle.headerStyle
            local ____self_26 = ____self_48_with_55(
                ____self_48,
                "headerStyle",
                ____self_29_with_47(____self_29, "backgroundColor", ____opt_27 and ____opt_27.backgroundColor or themeStyle.backgroundColor):done()
            )
            local ____self_26_with_56 = ____self_26.with
            local ____self_20 = createOptions(nil, themeStyle.rowStyle or ({}))
            local ____self_20_with_21 = ____self_20.with
            local ____opt_18 = themeStyle.rowStyle
            local ____self_17 = ____self_20_with_21(____self_20, "alignment", ____opt_18 and ____opt_18.alignment or "left")
            local ____self_17_with_22 = ____self_17.with
            local ____opt_15 = themeStyle.rowStyle
            local ____self_14 = ____self_17_with_22(____self_17, "wrap", ____opt_15 and ____opt_15.wrap or "none")
            local ____self_14_with_23 = ____self_14.with
            local ____opt_11 = themeStyle.rowStyle
            local ____temp_13 = ____opt_11 and ____opt_11.ellipsis
            if ____temp_13 == nil then
                ____temp_13 = true
            end
            local ____self_10 = ____self_14_with_23(____self_14, "ellipsis", ____temp_13)
            local ____self_10_with_24 = ____self_10.with
            local ____opt_8 = themeStyle.rowStyle
            local ____self_7 = ____self_10_with_24(____self_10, "foregroundColor", ____opt_8 and ____opt_8.foregroundColor or context.theme.palette.text)
            local ____self_7_with_25 = ____self_7.with
            local ____opt_5 = themeStyle.rowStyle
            return ____self_26_with_56(
                ____self_26,
                "rowStyle",
                ____self_7_with_25(____self_7, "backgroundColor", ____opt_5 and ____opt_5.backgroundColor or themeStyle.backgroundColor):done()
            ):done()
        end
    )
end
function TableComponent.prototype.resolveColumnWidths(self, availableWidth, style)
    local columns = self.props.columns
    if #columns == 0 then
        return {}
    end
    local ____style_showBorders_57 = style.showBorders
    if ____style_showBorders_57 == nil then
        ____style_showBorders_57 = false
    end
    local showBorders = ____style_showBorders_57
    local separatorWidth = showBorders and math.max(0, #columns - 1) or 0
    local usableWidth = math.max(0, availableWidth - separatorWidth)
    local fixedWidth = __TS__ArrayReduce(
        columns,
        function(____, sum, column) return sum + (column.width or 0) end,
        0
    )
    local flexibleColumns = __TS__ArrayFilter(
        columns,
        function(____, column) return column.width == nil end
    )
    local remainingWidth = math.max(0, usableWidth - fixedWidth)
    local baseFlexibleWidth = #flexibleColumns > 0 and math.floor(remainingWidth / #flexibleColumns) or 0
    local extraWidth = #flexibleColumns > 0 and remainingWidth % #flexibleColumns or 0
    return __TS__ArrayMap(
        columns,
        function(____, column)
            local width = column.width or math.max(column.minWidth or 1, baseFlexibleWidth)
            if column.width == nil and extraWidth > 0 then
                width = width + 1
                extraWidth = extraWidth - 1
            end
            if column.minWidth ~= nil then
                width = math.max(width, column.minWidth)
            end
            if column.maxWidth ~= nil then
                width = math.min(width, column.maxWidth)
            end
            width = math.max(1, width)
            return {column = column, width = width}
        end
    )
end
function TableComponent.prototype.renderHeaderRow(self, context, columns, y, style, innerRect)
    local currentX = innerRect.x
    local ____style_showBorders_58 = style.showBorders
    if ____style_showBorders_58 == nil then
        ____style_showBorders_58 = false
    end
    local showBorders = ____style_showBorders_58
    do
        local index = 0
        while index < #columns do
            local ____columns_index_59 = columns[index + 1]
            local column = ____columns_index_59.column
            local width = ____columns_index_59.width
            local ____drawText_66 = drawText
            local ____context_65 = context
            local ____createOptions_64 = createOptions
            local ____temp_62 = {x = currentX, y = y, width = width, height = 1}
            local ____column_title_63 = column.title
            local ____opt_60 = style.headerStyle
            ____drawText_66(
                nil,
                ____context_65,
                ____createOptions_64(nil, {rect = ____temp_62, text = ____column_title_63, fillBackground = (____opt_60 and ____opt_60.backgroundColor) ~= nil}):with(
                    "style",
                    self:resolveHeaderCellStyle(column, style)
                ):with("clipRect", context.clipRect):done()
            )
            currentX = currentX + width
            if showBorders and index < #columns - 1 then
                drawText(
                    nil,
                    context,
                    createOptions(nil, {rect = {x = currentX, y = y, width = 1, height = 1}, text = "│", fillBackground = style.backgroundColor ~= nil}):with(
                        "style",
                        makeColors(nil, {foregroundColor = style.separatorColor, backgroundColor = style.backgroundColor})
                    ):with("clipRect", context.clipRect):done()
                )
                currentX = currentX + 1
            end
            index = index + 1
        end
    end
end
function TableComponent.prototype.renderDataRow(self, context, columns, row, rowIndex, y, style, innerRect)
    local currentX = innerRect.x
    local ____style_showBorders_67 = style.showBorders
    if ____style_showBorders_67 == nil then
        ____style_showBorders_67 = false
    end
    local showBorders = ____style_showBorders_67
    local alternateBackground = style.alternateRowBackgroundColor
    local ____temp_70
    if alternateBackground ~= nil and rowIndex % 2 == 1 then
        ____temp_70 = alternateBackground
    else
        local ____opt_68 = style.rowStyle
        ____temp_70 = ____opt_68 and ____opt_68.backgroundColor
    end
    local rowBackground = ____temp_70
    do
        local index = 0
        while index < #columns do
            local ____columns_index_71 = columns[index + 1]
            local column = ____columns_index_71.column
            local width = ____columns_index_71.width
            local text = self:renderCellValue(column, row, rowIndex)
            drawText(
                nil,
                context,
                createOptions(nil, {rect = {x = currentX, y = y, width = width, height = 1}, text = text, fillBackground = rowBackground ~= nil}):with(
                    "style",
                    createOptions(
                        nil,
                        self:resolveRowCellStyle(column, style)
                    ):with("backgroundColor", rowBackground):done()
                ):with("clipRect", context.clipRect):done()
            )
            currentX = currentX + width
            if showBorders and index < #columns - 1 then
                drawText(
                    nil,
                    context,
                    createOptions(nil, {rect = {x = currentX, y = y, width = 1, height = 1}, text = "│", fillBackground = rowBackground ~= nil or style.backgroundColor ~= nil}):with(
                        "style",
                        makeColors(nil, {foregroundColor = style.separatorColor, backgroundColor = rowBackground or style.backgroundColor})
                    ):with("clipRect", context.clipRect):done()
                )
                currentX = currentX + 1
            end
            index = index + 1
        end
    end
end
function TableComponent.prototype.resolveHeaderCellStyle(self, column, style)
    local ____self_75 = createOptions(nil, style.headerStyle or ({}))
    local ____self_75_with_76 = ____self_75.with
    local ____column_alignment_74 = column.alignment
    if ____column_alignment_74 == nil then
        local ____opt_72 = style.headerStyle
        ____column_alignment_74 = ____opt_72 and ____opt_72.alignment
    end
    return ____self_75_with_76(____self_75, "alignment", ____column_alignment_74 or "left"):done()
end
function TableComponent.prototype.resolveRowCellStyle(self, column, style)
    local ____self_80 = createOptions(nil, style.rowStyle or ({}))
    local ____self_80_with_81 = ____self_80.with
    local ____column_alignment_79 = column.alignment
    if ____column_alignment_79 == nil then
        local ____opt_77 = style.rowStyle
        ____column_alignment_79 = ____opt_77 and ____opt_77.alignment
    end
    return ____self_80_with_81(____self_80, "alignment", ____column_alignment_79 or "left"):done()
end
function TableComponent.prototype.renderCellValue(self, column, row, rowIndex)
    if column.render then
        return column:render(row, rowIndex)
    end
    local value = row[tostring(column.key)]
    return (value == nil or value == nil) and "" or tostring(value)
end
return ____exports
