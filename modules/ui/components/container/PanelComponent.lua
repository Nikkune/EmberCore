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
local drawHorizontalLine = ____ui.drawHorizontalLine
local drawText = ____ui.drawText
local DrawTextOptions = ____ui.DrawTextOptions
local getInnerRect = ____ui.getInnerRect
local normalizeInsets = ____ui.normalizeInsets
local UIDrawSurface = ____ui.UIDrawSurface
local ____types = require("modules.ui.types.index")
local ComponentDependencies = ____types.ComponentDependencies
local LayoutConstraints = ____types.LayoutConstraints
local MeasuredSize = ____types.MeasuredSize
local PanelProps = ____types.PanelProps
local PanelStyle = ____types.PanelStyle
local RenderContext = ____types.RenderContext
local TextStyle = ____types.TextStyle
local UIComponent = ____types.UIComponent
local UIContext = ____types.UIContext
local ____helpers = require("utils.helpers")
local createOptions = ____helpers.createOptions
____exports.PanelComponent = __TS__Class()
local PanelComponent = ____exports.PanelComponent
PanelComponent.name = "PanelComponent"
__TS__ClassExtends(PanelComponent, BaseContainerComponent)
function PanelComponent.prototype.____constructor(self, props, dependencies, children)
    if dependencies == nil then
        dependencies = {}
    end
    if children == nil then
        children = {}
    end
    BaseContainerComponent.prototype.____constructor(
        self,
        "panel",
        props,
        dependencies,
        children
    )
end
function PanelComponent.prototype.measure(self, constraints, context)
    local style = self:getResolvedStyle(context)
    local innerConstraints = self:getInnerConstraints(constraints, style)
    local childrenSizes = self:measureChildren(innerConstraints, context)
    local childrenWidth = __TS__ArrayReduce(
        childrenSizes,
        function(____, max, size) return math.max(max, size.width) end,
        0
    )
    local childrenHeight = __TS__ArrayReduce(
        childrenSizes,
        function(____, max, size) return math.max(max, size.height) end,
        0
    )
    local ____opt_0 = style.border
    local borderX = ____opt_0 and ____opt_0.enabled and 2 or 0
    local ____opt_2 = style.border
    local borderY = ____opt_2 and ____opt_2.enabled and 2 or 0
    local padding = normalizeInsets(nil, style.padding)
    local ____table_props_title_7
    if self.props.title then
        local ____temp_6 = #self.props.title
        local ____opt_4 = style.border
        ____table_props_title_7 = ____temp_6 + (____opt_4 and ____opt_4.enabled and 4 or 0)
    else
        ____table_props_title_7 = 0
    end
    local titleWidth = ____table_props_title_7
    local titleExtraHeight = self.props.title and 2 or 0
    local measuredWidth = math.max(
        childrenWidth + padding.left + padding.right + borderX,
        titleWidth,
        self:getRequestedWidth(0)
    )
    local measuredHeight = math.max(
        childrenHeight + padding.top + padding.bottom + borderY + titleExtraHeight,
        self:getRequestedHeight(0)
    )
    return self:createMeasuredSize(measuredWidth, measuredHeight, constraints)
end
function PanelComponent.prototype.layout(self, rect, context)
    BaseContainerComponent.prototype.layout(self, rect, context)
    local style = self:getResolvedStyle(context)
    local innerRect = getInnerRect(nil, self.rect, style)
    if self.props.title then
        innerRect = {
            x = innerRect.x,
            y = innerRect.y + 2,
            width = innerRect.width,
            height = math.max(0, innerRect.height - 2)
        }
    end
    local entries = __TS__ArrayMap(
        self.children,
        function(____, child) return {child = child, rect = innerRect} end
    )
    self:layoutChildren(entries, context)
end
function PanelComponent.prototype.render(self, context)
    if not self.visible then
        return
    end
    if self.width <= 0 or self.height <= 0 then
        return
    end
    local style = self:getResolvedStyle(context)
    local ____opt_8 = style.border
    local borderCharacters = ____opt_8 and ____opt_8.enabled and context.theme.borders[style.border.preset or "single"] or nil
    drawBox(
        nil,
        context.draw,
        createOptions(nil, {rect = self.rect, style = style}):with("borderCharacters", borderCharacters):with("clipRect", context.clipRect):done()
    )
    self:renderTitle(context, style)
    self:renderChildren(context)
end
function PanelComponent.prototype.getResolvedStyle(self, context)
    return self:getStyle(
        context,
        function(____, themeStyle)
            local ____self_31 = createOptions(nil, themeStyle):with("foregroundColor", self.props.foregroundColor or themeStyle.foregroundColor or context.theme.palette.text):with("backgroundColor", self.props.backgroundColor or themeStyle.backgroundColor or context.theme.palette.panel):with("padding", themeStyle.padding or 0):with("gapColor", themeStyle.gapColor or context.theme.palette.border)
            local ____self_31_with_32 = ____self_31.with
            local ____self_25 = createOptions(nil, themeStyle.titleStyle or ({}))
            local ____self_25_with_26 = ____self_25.with
            local ____opt_23 = themeStyle.titleStyle
            local ____self_22 = ____self_25_with_26(____self_25, "alignment", ____opt_23 and ____opt_23.alignment or "left")
            local ____self_22_with_27 = ____self_22.with
            local ____opt_20 = themeStyle.titleStyle
            local ____self_19 = ____self_22_with_27(____self_22, "wrap", ____opt_20 and ____opt_20.wrap or "none")
            local ____self_19_with_28 = ____self_19.with
            local ____opt_16 = themeStyle.titleStyle
            local ____temp_18 = ____opt_16 and ____opt_16.ellipsis
            if ____temp_18 == nil then
                ____temp_18 = true
            end
            local ____self_15 = ____self_19_with_28(____self_19, "ellipsis", ____temp_18)
            local ____self_15_with_29 = ____self_15.with
            local ____opt_13 = themeStyle.titleStyle
            local ____self_12 = ____self_15_with_29(____self_15, "foregroundColor", ____opt_13 and ____opt_13.foregroundColor or self.props.foregroundColor or themeStyle.foregroundColor or context.theme.palette.text)
            local ____self_12_with_30 = ____self_12.with
            local ____opt_10 = themeStyle.titleStyle
            return ____self_31_with_32(
                ____self_31,
                "titleStyle",
                ____self_12_with_30(____self_12, "backgroundColor", ____opt_10 and ____opt_10.backgroundColor or self.props.backgroundColor or themeStyle.backgroundColor or context.theme.palette.panel):done()
            ):done()
        end
    )
end
function PanelComponent.prototype.getInnerConstraints(self, constraints, style)
    local padding = normalizeInsets(nil, style.padding)
    local ____opt_33 = style.border
    local borderX = ____opt_33 and ____opt_33.enabled and 2 or 0
    local ____opt_35 = style.border
    local borderY = ____opt_35 and ____opt_35.enabled and 2 or 0
    local titleExtraHeight = self.props.title and 1 or 0
    local horizontal = padding.left + padding.right + borderX
    local vertical = padding.top + padding.bottom + borderY + titleExtraHeight
    return {
        minWidth = math.max(0, constraints.minWidth - horizontal),
        maxWidth = math.max(0, constraints.maxWidth - horizontal),
        minHeight = math.max(0, constraints.minHeight - vertical),
        maxHeight = math.max(0, constraints.maxHeight - vertical)
    }
end
function PanelComponent.prototype.renderTitle(self, context, style)
    local title = self.props.title
    if not title or self.width <= 0 or self.height <= 0 then
        return
    end
    local ____opt_37 = style.border
    local titleY = ____opt_37 and ____opt_37.enabled and self.y + 1 or self.y
    local ____opt_39 = style.border
    local titleX = ____opt_39 and ____opt_39.enabled and self.x + 1 or self.x
    local ____opt_41 = style.border
    local titleWidth = ____opt_41 and ____opt_41.enabled and math.max(0, self.width - 2) or self.width
    local ____drawText_48 = drawText
    local ____context_47 = context
    local ____createOptions_46 = createOptions
    local ____temp_45 = {x = titleX, y = titleY, width = titleWidth, height = 1}
    local ____opt_43 = style.titleStyle
    ____drawText_48(
        nil,
        ____context_47,
        ____createOptions_46(nil, {rect = ____temp_45, text = title, fillBackground = (____opt_43 and ____opt_43.backgroundColor) ~= nil}):with("style", style.titleStyle):with("clipRect", context.clipRect):done()
    )
    if style.gapColor ~= nil then
        local gapY = titleY + 1
        if gapY < self.y + self.height then
            drawHorizontalLine(
                nil,
                context.draw,
                {x = titleX, y = gapY},
                titleWidth,
                "─",
                style.gapColor,
                style.backgroundColor,
                context.clipRect
            )
        end
    end
end
return ____exports
