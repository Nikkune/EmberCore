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
-- End of Lua Library inline imports
local ____exports = {}
local ____ui = require("modules.ui.index")
local BaseComponent = ____ui.BaseComponent
local drawText = ____ui.drawText
local DrawTextOptions = ____ui.DrawTextOptions
local UIDrawSurface = ____ui.UIDrawSurface
local ____types = require("modules.ui.types.index")
local ComponentDependencies = ____types.ComponentDependencies
local LayoutConstraints = ____types.LayoutConstraints
local MeasuredSize = ____types.MeasuredSize
local RenderContext = ____types.RenderContext
local StatusBarProps = ____types.StatusBarProps
local StatusBarSegment = ____types.StatusBarSegment
local StatusBarStyle = ____types.StatusBarStyle
local TextStyle = ____types.TextStyle
local UIContext = ____types.UIContext
local ____helpers = require("utils.helpers")
local createOptions = ____helpers.createOptions
____exports.StatusBarComponent = __TS__Class()
local StatusBarComponent = ____exports.StatusBarComponent
StatusBarComponent.name = "StatusBarComponent"
__TS__ClassExtends(StatusBarComponent, BaseComponent)
function StatusBarComponent.prototype.____constructor(self, props, dependencies)
    if dependencies == nil then
        dependencies = {}
    end
    BaseComponent.prototype.____constructor(self, "status_bar", props, dependencies)
end
function StatusBarComponent.prototype.measure(self, constraints, context)
    local style = self:getResolvedStyle(context)
    local contentWidth = self:getContentWidth(style)
    local width = self.props.width or self.props.minWidth or contentWidth
    local height = self.props.height or self.props.minHeight or 1
    return self:createMeasuredSize(width, height, constraints)
end
function StatusBarComponent.prototype.render(self, context)
    if not self.visible then
        return
    end
    if self.width <= 0 or self.height <= 0 then
        return
    end
    local style = self:getResolvedStyle(context)
    local segments = self:resolveSegments(style, context)
    if style.backgroundColor ~= nil then
        context.draw:fillRect(self.rect, " ", style.backgroundColor, style.foregroundColor)
    end
    do
        local index = 0
        while index < self.height do
            for ____, segment in ipairs(segments) do
                drawText(
                    nil,
                    context,
                    createOptions(nil, {rect = {x = segment.x, y = self.y + index, width = segment.width, height = 1}, text = segment.text, style = segment.style, fillBackground = segment.style.backgroundColor ~= nil}):with("clipRect", context.clipRect):done()
                )
            end
            index = index + 1
        end
    end
end
function StatusBarComponent.prototype.getResolvedStyle(self, context)
    return self:getStyle(
        context,
        function(____, themeStyle)
            local ____self_21 = createOptions(nil, themeStyle):with("foregroundColor", self.props.foregroundColor or themeStyle.foregroundColor or context.theme.palette.text):with("backgroundColor", self.props.backgroundColor or themeStyle.backgroundColor or context.theme.palette.surface)
            local ____self_21_with_22 = ____self_21.with
            local ____self_15 = createOptions(nil, themeStyle.text or ({}))
            local ____self_15_with_16 = ____self_15.with
            local ____opt_13 = themeStyle.text
            local ____self_12 = ____self_15_with_16(____self_15, "alignment", ____opt_13 and ____opt_13.alignment or "left")
            local ____self_12_with_17 = ____self_12.with
            local ____opt_10 = themeStyle.text
            local ____self_9 = ____self_12_with_17(____self_12, "wrap", ____opt_10 and ____opt_10.wrap or "none")
            local ____self_9_with_18 = ____self_9.with
            local ____opt_6 = themeStyle.text
            local ____temp_8 = ____opt_6 and ____opt_6.ellipsis
            if ____temp_8 == nil then
                ____temp_8 = true
            end
            local ____self_5 = ____self_9_with_18(____self_9, "ellipsis", ____temp_8)
            local ____self_5_with_19 = ____self_5.with
            local ____opt_3 = themeStyle.text
            local ____self_2 = ____self_5_with_19(____self_5, "foregroundColor", ____opt_3 and ____opt_3.foregroundColor or self.props.foregroundColor or themeStyle.foregroundColor or context.theme.palette.text)
            local ____self_2_with_20 = ____self_2.with
            local ____opt_0 = themeStyle.text
            return ____self_21_with_22(
                ____self_21,
                "text",
                ____self_2_with_20(____self_2, "backgroundColor", ____opt_0 and ____opt_0.backgroundColor or self.props.backgroundColor or themeStyle.backgroundColor or context.theme.palette.surface):done()
            ):done()
        end
    )
end
function StatusBarComponent.prototype.getContentWidth(self, _style)
    local segments = self.props.segments
    if #segments == 0 then
        return 1
    end
    local total = 0
    for ____, segment in ipairs(segments) do
        total = total + (segment.width or #segment.text)
    end
    return math.max(1, total)
end
function StatusBarComponent.prototype.resolveSegments(self, style, context)
    local segments = self.props.segments
    if #segments == 0 then
        return {}
    end
    local fixedWidth = __TS__ArrayReduce(
        segments,
        function(____, sum, segment) return sum + (segment.width or 0) end,
        0
    )
    local flexibleSegments = __TS__ArrayFilter(
        segments,
        function(____, segment) return segment.width == nil end
    )
    local remainingWidth = math.max(0, self.width - fixedWidth)
    local baseFlexibleWidth = #flexibleSegments > 0 and math.floor(remainingWidth / #flexibleSegments) or 0
    local extraWidth = #flexibleSegments > 0 and remainingWidth % #flexibleSegments or 0
    local currentX = self.x
    local resolved = {}
    for ____, segment in ipairs(segments) do
        local width = segment.width or baseFlexibleWidth
        if segment.width == nil and extraWidth > 0 then
            width = width + 1
            extraWidth = extraWidth - 1
        end
        width = math.max(0, width)
        local segmentStyle = self:getSegmentStyle(segment, style, context)
        resolved[#resolved + 1] = {text = segment.text, x = currentX, width = width, style = segmentStyle}
        currentX = currentX + width
    end
    return __TS__ArrayFilter(
        resolved,
        function(____, segment) return segment.width > 0 end
    )
end
function StatusBarComponent.prototype.getSegmentStyle(self, segment, style, context)
    local alignment = segment.alignment == "center" and "center" or (segment.alignment == "right" and "right" or "left")
    local ____self_30 = createOptions(nil, style.text or ({})):with("alignment", alignment)
    local ____self_30_with_31 = ____self_30.with
    local ____segment_color_29 = segment.color
    if ____segment_color_29 == nil then
        local ____opt_27 = style.text
        ____segment_color_29 = ____opt_27 and ____opt_27.foregroundColor
    end
    local ____self_26 = ____self_30_with_31(____self_30, "foregroundColor", ____segment_color_29 or style.foregroundColor or context.theme.palette.text)
    local ____self_26_with_32 = ____self_26.with
    local ____segment_backgroundColor_25 = segment.backgroundColor
    if ____segment_backgroundColor_25 == nil then
        local ____opt_23 = style.text
        ____segment_backgroundColor_25 = ____opt_23 and ____opt_23.backgroundColor
    end
    return ____self_26_with_32(____self_26, "backgroundColor", ____segment_backgroundColor_25 or style.backgroundColor or context.theme.palette.surface):done()
end
return ____exports
