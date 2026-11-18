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
local ____coreComponent = require("modules.ui.core.components.coreComponent")
local BaseComponent = ____coreComponent.BaseComponent
local ____renderHelpers = require("modules.ui.render.renderHelpers")
local drawBox = ____renderHelpers.drawBox
local DrawBoxOptions = ____renderHelpers.DrawBoxOptions
local drawHorizontalLine = ____renderHelpers.drawHorizontalLine
local drawText = ____renderHelpers.drawText
local DrawTextOptions = ____renderHelpers.DrawTextOptions
local ____surfaceAdapter = require("modules.ui.render.surfaceAdapter")
local UIDrawSurface = ____surfaceAdapter.UIDrawSurface
local ____theme = require("modules.ui.theme.theme")
local getColumnRuleCharacter = ____theme.getColumnRuleCharacter
local getRuleCharacter = ____theme.getRuleCharacter
local ____tone = require("modules.ui.theme.tone")
local makeColors = ____tone.makeColors
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
function TableComponent.prototype.setRows(self, rows)
    self:setProps({rows = rows})
end
function TableComponent.prototype.measure(self, constraints, context)
    local style = self:getResolvedStyle(context)
    local ____style_showHeader_0 = style.showHeader
    if ____style_showHeader_0 == nil then
        ____style_showHeader_0 = true
    end
    local showHeader = ____style_showHeader_0
    local columnWidths = self:resolveColumnWidths(constraints.maxWidth, style)
    local separators = style.showBorders and math.max(0, #columnWidths - 1) or 0
    local contentWidth = __TS__ArrayReduce(
        columnWidths,
        function(____, sum, col) return sum + col.width end,
        0
    ) + separators
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
                getRuleCharacter(nil, context.theme),
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
                    getRuleCharacter(nil, context.theme),
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
            local ____self_56 = createOptions(
                nil,
                __TS__ObjectAssign({}, themeStyle)
            ):with("foregroundColor", self.props.foregroundColor or themeStyle.foregroundColor or context.theme.palette.text):with("backgroundColor", self.props.backgroundColor or themeStyle.backgroundColor or context.theme.palette.surface)
            local ____self_56_with_57 = ____self_56.with
            local ____themeStyle_showHeader_55 = themeStyle.showHeader
            if ____themeStyle_showHeader_55 == nil then
                ____themeStyle_showHeader_55 = true
            end
            local ____self_54 = ____self_56_with_57(____self_56, "showHeader", ____themeStyle_showHeader_55)
            local ____self_54_with_58 = ____self_54.with
            local ____themeStyle_showBorders_53 = themeStyle.showBorders
            if ____themeStyle_showBorders_53 == nil then
                ____themeStyle_showBorders_53 = true
            end
            local ____self_52 = ____self_54_with_58(____self_54, "showBorders", ____themeStyle_showBorders_53):with("separatorColor", themeStyle.separatorColor or context.theme.palette.border)
            local ____self_52_with_59 = ____self_52.with
            local ____self_46 = createOptions(
                nil,
                __TS__ObjectAssign({}, themeStyle.headerStyle or ({}))
            )
            local ____self_46_with_47 = ____self_46.with
            local ____opt_44 = themeStyle.headerStyle
            local ____self_43 = ____self_46_with_47(____self_46, "alignment", ____opt_44 and ____opt_44.alignment or "left")
            local ____self_43_with_48 = ____self_43.with
            local ____opt_41 = themeStyle.headerStyle
            local ____self_40 = ____self_43_with_48(____self_43, "wrap", ____opt_41 and ____opt_41.wrap or "none")
            local ____self_40_with_49 = ____self_40.with
            local ____opt_37 = themeStyle.headerStyle
            local ____temp_39 = ____opt_37 and ____opt_37.ellipsis
            if ____temp_39 == nil then
                ____temp_39 = true
            end
            local ____self_36 = ____self_40_with_49(____self_40, "ellipsis", ____temp_39)
            local ____self_36_with_50 = ____self_36.with
            local ____self_props_foregroundColor_35 = self.props.foregroundColor
            if ____self_props_foregroundColor_35 == nil then
                local ____opt_33 = themeStyle.headerStyle
                ____self_props_foregroundColor_35 = ____opt_33 and ____opt_33.foregroundColor
            end
            local ____self_32 = ____self_36_with_50(____self_36, "foregroundColor", ____self_props_foregroundColor_35 or context.theme.palette.text)
            local ____self_32_with_51 = ____self_32.with
            local ____self_props_backgroundColor_31 = self.props.backgroundColor
            if ____self_props_backgroundColor_31 == nil then
                local ____opt_29 = themeStyle.headerStyle
                ____self_props_backgroundColor_31 = ____opt_29 and ____opt_29.backgroundColor
            end
            local ____self_28 = ____self_52_with_59(
                ____self_52,
                "headerStyle",
                ____self_32_with_51(____self_32, "backgroundColor", ____self_props_backgroundColor_31 or themeStyle.backgroundColor):done()
            )
            local ____self_28_with_60 = ____self_28.with
            local ____self_22 = createOptions(
                nil,
                __TS__ObjectAssign({}, themeStyle.rowStyle or ({}))
            )
            local ____self_22_with_23 = ____self_22.with
            local ____opt_20 = themeStyle.rowStyle
            local ____self_19 = ____self_22_with_23(____self_22, "alignment", ____opt_20 and ____opt_20.alignment or "left")
            local ____self_19_with_24 = ____self_19.with
            local ____opt_17 = themeStyle.rowStyle
            local ____self_16 = ____self_19_with_24(____self_19, "wrap", ____opt_17 and ____opt_17.wrap or "none")
            local ____self_16_with_25 = ____self_16.with
            local ____opt_13 = themeStyle.rowStyle
            local ____temp_15 = ____opt_13 and ____opt_13.ellipsis
            if ____temp_15 == nil then
                ____temp_15 = true
            end
            local ____self_12 = ____self_16_with_25(____self_16, "ellipsis", ____temp_15)
            local ____self_12_with_26 = ____self_12.with
            local ____self_props_foregroundColor_11 = self.props.foregroundColor
            if ____self_props_foregroundColor_11 == nil then
                local ____opt_9 = themeStyle.rowStyle
                ____self_props_foregroundColor_11 = ____opt_9 and ____opt_9.foregroundColor
            end
            local ____self_8 = ____self_12_with_26(____self_12, "foregroundColor", ____self_props_foregroundColor_11 or context.theme.palette.text)
            local ____self_8_with_27 = ____self_8.with
            local ____self_props_backgroundColor_7 = self.props.backgroundColor
            if ____self_props_backgroundColor_7 == nil then
                local ____opt_5 = themeStyle.rowStyle
                ____self_props_backgroundColor_7 = ____opt_5 and ____opt_5.backgroundColor
            end
            return ____self_28_with_60(
                ____self_28,
                "rowStyle",
                ____self_8_with_27(____self_8, "backgroundColor", ____self_props_backgroundColor_7 or themeStyle.backgroundColor):done()
            ):done()
        end
    )
end
function TableComponent.prototype.resolveColumnWidths(self, availableWidth, style)
    local columns = self.props.columns
    if #columns == 0 then
        return {}
    end
    local ____style_showBorders_61 = style.showBorders
    if ____style_showBorders_61 == nil then
        ____style_showBorders_61 = false
    end
    local showBorders = ____style_showBorders_61
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
    local ____style_showBorders_62 = style.showBorders
    if ____style_showBorders_62 == nil then
        ____style_showBorders_62 = false
    end
    local showBorders = ____style_showBorders_62
    do
        local index = 0
        while index < #columns do
            local ____columns_index_63 = columns[index + 1]
            local column = ____columns_index_63.column
            local width = ____columns_index_63.width
            local ____drawText_70 = drawText
            local ____context_69 = context
            local ____createOptions_68 = createOptions
            local ____temp_66 = {x = currentX, y = y, width = width, height = 1}
            local ____column_title_67 = column.title
            local ____opt_64 = style.headerStyle
            ____drawText_70(
                nil,
                ____context_69,
                ____createOptions_68(nil, {rect = ____temp_66, text = ____column_title_67, fillBackground = (____opt_64 and ____opt_64.backgroundColor) ~= nil}):with(
                    "style",
                    self:resolveHeaderCellStyle(column, style)
                ):with("clipRect", context.clipRect):done()
            )
            currentX = currentX + width
            if showBorders and index < #columns - 1 then
                drawText(
                    nil,
                    context,
                    createOptions(
                        nil,
                        {
                            rect = {x = currentX, y = y, width = 1, height = 1},
                            text = getColumnRuleCharacter(nil, context.theme),
                            fillBackground = style.backgroundColor ~= nil
                        }
                    ):with(
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
    local ____style_showBorders_71 = style.showBorders
    if ____style_showBorders_71 == nil then
        ____style_showBorders_71 = false
    end
    local showBorders = ____style_showBorders_71
    local alternateBackground = style.alternateRowBackgroundColor
    local isAlternateRow = alternateBackground ~= nil and rowIndex % 2 == 1
    local ____isAlternateRow_74
    if isAlternateRow then
        ____isAlternateRow_74 = alternateBackground
    else
        local ____opt_72 = style.rowStyle
        ____isAlternateRow_74 = ____opt_72 and ____opt_72.backgroundColor
    end
    local rowBackground = ____isAlternateRow_74
    do
        local index = 0
        while index < #columns do
            local ____columns_index_75 = columns[index + 1]
            local column = ____columns_index_75.column
            local width = ____columns_index_75.width
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
                    createOptions(
                        nil,
                        {
                            rect = {x = currentX, y = y, width = 1, height = 1},
                            text = getColumnRuleCharacter(nil, context.theme),
                            fillBackground = rowBackground ~= nil or style.backgroundColor ~= nil
                        }
                    ):with(
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
    local ____self_79 = createOptions(
        nil,
        __TS__ObjectAssign({}, style.headerStyle or ({}))
    )
    local ____self_79_with_80 = ____self_79.with
    local ____column_alignment_78 = column.alignment
    if ____column_alignment_78 == nil then
        local ____opt_76 = style.headerStyle
        ____column_alignment_78 = ____opt_76 and ____opt_76.alignment
    end
    return ____self_79_with_80(____self_79, "alignment", ____column_alignment_78 or "left"):done()
end
function TableComponent.prototype.resolveRowCellStyle(self, column, style)
    local ____self_84 = createOptions(
        nil,
        __TS__ObjectAssign({}, style.rowStyle or ({}))
    )
    local ____self_84_with_85 = ____self_84.with
    local ____column_alignment_83 = column.alignment
    if ____column_alignment_83 == nil then
        local ____opt_81 = style.rowStyle
        ____column_alignment_83 = ____opt_81 and ____opt_81.alignment
    end
    return ____self_84_with_85(____self_84, "alignment", ____column_alignment_83 or "left"):done()
end
function TableComponent.prototype.renderCellValue(self, column, row, rowIndex)
    if column.render then
        return column:render(row, rowIndex)
    end
    local value = row[tostring(column.key)]
    return (value == nil or value == nil) and "" or tostring(value)
end
return ____exports
