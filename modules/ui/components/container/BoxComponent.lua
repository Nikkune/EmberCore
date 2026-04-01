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
local drawText = ____ui.drawText
local DrawTextOptions = ____ui.DrawTextOptions
local getInnerRect = ____ui.getInnerRect
local normalizeInsets = ____ui.normalizeInsets
local UIDrawSurface = ____ui.UIDrawSurface
local ____types = require("modules.ui.types.index")
local BoxProps = ____types.BoxProps
local BoxStyle = ____types.BoxStyle
local ComponentDependencies = ____types.ComponentDependencies
local LayoutConstraints = ____types.LayoutConstraints
local MeasuredSize = ____types.MeasuredSize
local RenderContext = ____types.RenderContext
local TextStyle = ____types.TextStyle
local UIComponent = ____types.UIComponent
local UIContext = ____types.UIContext
local ____helpers = require("utils.helpers")
local createOptions = ____helpers.createOptions
____exports.BoxComponent = __TS__Class()
local BoxComponent = ____exports.BoxComponent
BoxComponent.name = "BoxComponent"
__TS__ClassExtends(BoxComponent, BaseContainerComponent)
function BoxComponent.prototype.____constructor(self, props, dependencies, children)
    if dependencies == nil then
        dependencies = {}
    end
    if children == nil then
        children = {}
    end
    BaseContainerComponent.prototype.____constructor(
        self,
        "box",
        props,
        dependencies,
        children
    )
end
function BoxComponent.prototype.measure(self, constraints, context)
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
    local measuredWidth = math.max(
        childrenWidth + padding.left + padding.right + borderX,
        titleWidth,
        self:getRequestedWidth(0)
    )
    local measuredHeight = math.max(
        childrenHeight + padding.top + padding.bottom + borderY,
        self:getRequestedHeight(0)
    )
    return self:createMeasuredSize(measuredWidth, measuredHeight, constraints)
end
function BoxComponent.prototype.layout(self, rect, context)
    BaseContainerComponent.prototype.layout(self, rect, context)
    local style = self:getResolvedStyle(context)
    local innerRect = getInnerRect(nil, self.rect, style)
    local entries = __TS__ArrayMap(
        self.children,
        function(____, child) return {child = child, rect = innerRect} end
    )
    self:layoutChildren(entries, context)
end
function BoxComponent.prototype.render(self, context)
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
function BoxComponent.prototype.getResolvedStyle(self, context)
    return self:getStyle(
        context,
        function(____, themeStyle) return createOptions(nil, themeStyle):with("foregroundColor", self.props.foregroundColor or themeStyle.foregroundColor or context.theme.palette.text):with("backgroundColor", self.props.backgroundColor or themeStyle.backgroundColor or context.theme.palette.surface):with("padding", themeStyle.padding or 0):done() end
    )
end
function BoxComponent.prototype.getInnerConstraints(self, constraints, style)
    local padding = normalizeInsets(nil, style.padding)
    local ____opt_10 = style.border
    local borderX = ____opt_10 and ____opt_10.enabled and 2 or 0
    local ____opt_12 = style.border
    local borderY = ____opt_12 and ____opt_12.enabled and 2 or 0
    local horizontal = padding.left + padding.right + borderX
    local vertical = padding.top + padding.bottom + borderY
    return {
        minWidth = math.max(0, constraints.minWidth - horizontal),
        maxWidth = math.max(0, constraints.maxWidth - horizontal),
        minHeight = math.max(0, constraints.minHeight - vertical),
        maxHeight = math.max(0, constraints.maxHeight - vertical)
    }
end
function BoxComponent.prototype.renderTitle(self, context, style)
    local title = self.props.title
    local ____temp_16 = not title
    if not ____temp_16 then
        local ____opt_14 = style.border
        ____temp_16 = not (____opt_14 and ____opt_14.enabled)
    end
    if ____temp_16 or self.width <= 2 or self.height <= 0 then
        return
    end
    drawText(
        nil,
        context,
        createOptions(
            nil,
            {
                rect = {
                    x = self.x + 2,
                    y = self.y,
                    width = math.max(0, self.width - 4),
                    height = 1
                },
                text = title,
                fillBackground = style.backgroundColor ~= nil
            }
        ):with(
            "style",
            createOptions(nil, {alignment = "left", wrap = "none", ellipsis = true}):with("backgroundColor", style.backgroundColor):with("foregroundColor", style.foregroundColor):done()
        ):with("clipRect", context.clipRect):done()
    )
end
return ____exports
