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

local function __TS__ArrayIsArray(value)
    return type(value) == "table" and (value[1] ~= nil or next(value) == nil)
end

local function __TS__ArrayFlatMap(self, callback, thisArg)
    local result = {}
    local len = 0
    for i = 1, #self do
        local value = callback(thisArg, self[i], i - 1, self)
        if __TS__ArrayIsArray(value) then
            for j = 1, #value do
                len = len + 1
                result[len] = value[j]
            end
        else
            len = len + 1
            result[len] = value
        end
    end
    return result
end

local function __TS__ArrayForEach(self, callbackFn, thisArg)
    for i = 1, #self do
        callbackFn(thisArg, self[i], i - 1, self)
    end
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
local ____coreComponent = require("modules.ui.core.components.coreComponent")
local BaseComponent = ____coreComponent.BaseComponent
local ____renderHelpers = require("modules.ui.render.renderHelpers")
local drawText = ____renderHelpers.drawText
local DrawTextOptions = ____renderHelpers.DrawTextOptions
local ____surfaceAdapter = require("modules.ui.render.surfaceAdapter")
local UIDrawSurface = ____surfaceAdapter.UIDrawSurface
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
function StatusBarComponent.prototype.setSegments(self, segments)
    self:setProps({segments = segments})
end
function StatusBarComponent.prototype.measure(self, constraints, context)
    local style = self:getResolvedStyle(context)
    local contentWidth = self:getContentWidth(style)
    local width = self.props.width or self.props.minWidth or math.max(contentWidth, constraints.maxWidth)
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
            local ____self_23 = createOptions(
                nil,
                __TS__ObjectAssign({}, themeStyle)
            ):with("foregroundColor", self.props.foregroundColor or themeStyle.foregroundColor or context.theme.palette.text):with("backgroundColor", self.props.backgroundColor or themeStyle.backgroundColor or context.theme.palette.surface)
            local ____self_23_with_24 = ____self_23.with
            local ____self_17 = createOptions(
                nil,
                __TS__ObjectAssign({}, themeStyle.text or ({}))
            )
            local ____self_17_with_18 = ____self_17.with
            local ____opt_15 = themeStyle.text
            local ____self_14 = ____self_17_with_18(____self_17, "alignment", ____opt_15 and ____opt_15.alignment or "left")
            local ____self_14_with_19 = ____self_14.with
            local ____opt_12 = themeStyle.text
            local ____self_11 = ____self_14_with_19(____self_14, "wrap", ____opt_12 and ____opt_12.wrap or "none")
            local ____self_11_with_20 = ____self_11.with
            local ____opt_8 = themeStyle.text
            local ____temp_10 = ____opt_8 and ____opt_8.ellipsis
            if ____temp_10 == nil then
                ____temp_10 = true
            end
            local ____self_7 = ____self_11_with_20(____self_11, "ellipsis", ____temp_10)
            local ____self_7_with_21 = ____self_7.with
            local ____self_props_foregroundColor_6 = self.props.foregroundColor
            if ____self_props_foregroundColor_6 == nil then
                local ____opt_4 = themeStyle.text
                ____self_props_foregroundColor_6 = ____opt_4 and ____opt_4.foregroundColor
            end
            local ____self_3 = ____self_7_with_21(____self_7, "foregroundColor", ____self_props_foregroundColor_6 or themeStyle.foregroundColor or context.theme.palette.text)
            local ____self_3_with_22 = ____self_3.with
            local ____self_props_backgroundColor_2 = self.props.backgroundColor
            if ____self_props_backgroundColor_2 == nil then
                local ____opt_0 = themeStyle.text
                ____self_props_backgroundColor_2 = ____opt_0 and ____opt_0.backgroundColor
            end
            return ____self_23_with_24(
                ____self_23,
                "text",
                ____self_3_with_22(____self_3, "backgroundColor", ____self_props_backgroundColor_2 or themeStyle.backgroundColor or context.theme.palette.surface):done()
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
    local widths = __TS__ArrayMap(
        segments,
        function(____, segment) return segment.width or #segment.text end
    )
    local flexible = __TS__ArrayFlatMap(
        segments,
        function(____, segment, index) return segment.width == nil and ({index}) or ({}) end
    )
    local remaining = math.max(0, self.width - fixedWidth) - __TS__ArrayReduce(
        flexible,
        function(____, sum, index) return sum + (widths[index + 1] or 0) end,
        0
    )
    if remaining > 0 and #flexible > 0 then
        local last = flexible[#flexible]
        widths[last + 1] = (widths[last + 1] or 0) + remaining
    end
    do
        local i = #flexible - 1
        while i >= 0 and remaining < 0 do
            local index = flexible[i + 1]
            local shrink = math.min(widths[index + 1] or 0, -remaining)
            widths[index + 1] = (widths[index + 1] or 0) - shrink
            remaining = remaining + shrink
            i = i - 1
        end
    end
    local currentX = self.x
    local resolved = {}
    __TS__ArrayForEach(
        segments,
        function(____, segment, index)
            local width = math.max(0, widths[index + 1] or 0)
            local segmentStyle = self:getSegmentStyle(segment, style, context)
            resolved[#resolved + 1] = {text = segment.text, x = currentX, width = width, style = segmentStyle}
            currentX = currentX + width
        end
    )
    return __TS__ArrayFilter(
        resolved,
        function(____, segment) return segment.width > 0 end
    )
end
function StatusBarComponent.prototype.getSegmentStyle(self, segment, style, context)
    local alignment = segment.alignment == "center" and "center" or (segment.alignment == "right" and "right" or "left")
    local ____self_32 = createOptions(
        nil,
        __TS__ObjectAssign({}, style.text or ({}))
    ):with("alignment", alignment)
    local ____self_32_with_33 = ____self_32.with
    local ____segment_color_31 = segment.color
    if ____segment_color_31 == nil then
        local ____opt_29 = style.text
        ____segment_color_31 = ____opt_29 and ____opt_29.foregroundColor
    end
    local ____self_28 = ____self_32_with_33(____self_32, "foregroundColor", ____segment_color_31 or style.foregroundColor or context.theme.palette.text)
    local ____self_28_with_34 = ____self_28.with
    local ____segment_backgroundColor_27 = segment.backgroundColor
    if ____segment_backgroundColor_27 == nil then
        local ____opt_25 = style.text
        ____segment_backgroundColor_27 = ____opt_25 and ____opt_25.backgroundColor
    end
    return ____self_28_with_34(____self_28, "backgroundColor", ____segment_backgroundColor_27 or style.backgroundColor or context.theme.palette.surface):done()
end
return ____exports
