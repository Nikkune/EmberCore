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
-- End of Lua Library inline imports
local ____exports = {}
local ____ui = require("modules.ui.index")
local drawBox = ____ui.drawBox
local DrawBoxOptions = ____ui.DrawBoxOptions
local drawText = ____ui.drawText
local DrawTextOptions = ____ui.DrawTextOptions
local makeToneColorOverride = ____ui.makeToneColorOverride
local normalizeInsets = ____ui.normalizeInsets
local PressableComponent = ____ui.PressableComponent
local resolveTextLines = ____ui.resolveTextLines
local ResolveTextLinesOptions = ____ui.ResolveTextLinesOptions
local UIDrawSurface = ____ui.UIDrawSurface
local ____types = require("modules.ui.types.index")
local ButtonProps = ____types.ButtonProps
local ButtonStyle = ____types.ButtonStyle
local ComponentDependencies = ____types.ComponentDependencies
local LayoutConstraints = ____types.LayoutConstraints
local MeasuredSize = ____types.MeasuredSize
local RenderContext = ____types.RenderContext
local UIContext = ____types.UIContext
local ____helpers = require("utils.helpers")
local createOptions = ____helpers.createOptions
____exports.ButtonComponent = __TS__Class()
local ButtonComponent = ____exports.ButtonComponent
ButtonComponent.name = "ButtonComponent"
__TS__ClassExtends(ButtonComponent, PressableComponent)
function ButtonComponent.prototype.____constructor(self, props, dependencies)
    if dependencies == nil then
        dependencies = {}
    end
    PressableComponent.prototype.____constructor(self, "button", props, dependencies)
end
function ButtonComponent.prototype.measure(self, constraints, context)
    local style = self:getResolvedStyle(context)
    local padding = normalizeInsets(nil, style.padding)
    local ____opt_0 = style.border
    local border = ____opt_0 and ____opt_0.enabled and 2 or 0
    local width = self.props.width or self.props.minWidth or constraints.maxWidth
    local lines = resolveTextLines(
        nil,
        createOptions(
            nil,
            {
                text = self.props.label,
                width = math.max(0, width - border - padding.left - padding.right)
            }
        ):with("style", style.text):done()
    )
    local contentWidth = __TS__ArrayReduce(
        lines,
        function(____, max, l) return math.max(max, #l.text) end,
        0
    )
    local contentHeight = math.max(1, #lines)
    return self:createMeasuredSize(contentWidth + padding.left + padding.right + border, contentHeight + padding.top + padding.bottom + border, constraints)
end
function ButtonComponent.prototype.render(self, context)
    if not self.visible then
        return
    end
    if self.width <= 0 or self.height <= 0 then
        return
    end
    local style = self:getResolvedStyle(context)
    local ____opt_2 = style.border
    local borderCharacters = ____opt_2 and ____opt_2.enabled and context.theme.borders[style.border.preset or "single"] or nil
    local innerRect = drawBox(
        nil,
        context.draw,
        createOptions(nil, {rect = self.rect, style = style}):with("borderCharacters", borderCharacters):with("clipRect", context.clipRect):done()
    )
    local ____drawText_9 = drawText
    local ____context_8 = context
    local ____createOptions_7 = createOptions
    local ____self_props_label_6 = self.props.label
    local ____opt_4 = style.text
    ____drawText_9(
        nil,
        ____context_8,
        ____createOptions_7(nil, {rect = innerRect, text = ____self_props_label_6, fillBackground = (____opt_4 and ____opt_4.backgroundColor) ~= nil}):with("style", style.text):with("clipRect", context.clipRect):done()
    )
end
function ButtonComponent.prototype.onPress(self, _context)
    local ____this_11
    ____this_11 = self.props
    local ____opt_10 = ____this_11.onPress
    if ____opt_10 ~= nil then
        ____opt_10(____this_11)
    end
    return true
end
function ButtonComponent.prototype.getResolvedStyle(self, context)
    return self:getStyle(
        context,
        function(____, themeStyle)
            local isDisabled = self.disabled
            local isFocused = self.focused
            local colors = themeStyle.colors
            local ____isDisabled_21
            if isDisabled then
                ____isDisabled_21 = colors and colors.disabled
            else
                local ____isFocused_20
                if isFocused then
                    ____isFocused_20 = colors and colors.active or colors and colors.selected
                else
                    ____isFocused_20 = colors and colors.default
                end
                ____isDisabled_21 = ____isFocused_20
            end
            local foreground = ____isDisabled_21
            local ____isDisabled_31
            if isDisabled then
                ____isDisabled_31 = colors and colors.disabled
            else
                local ____isFocused_30
                if isFocused then
                    ____isFocused_30 = colors and colors.active or colors and colors.selected
                else
                    ____isFocused_30 = colors and colors.default
                end
                ____isDisabled_31 = ____isFocused_30
            end
            local background = ____isDisabled_31
            local tone = makeToneColorOverride(
                nil,
                nil,
                context.theme,
                self.props.foregroundColor or foreground,
                self.props.backgroundColor or background
            )
            local ____themeStyle_42 = themeStyle
            local ____temp_43 = themeStyle.padding or ({left = 1, right = 1})
            local ____themeStyle_text_39 = themeStyle.text
            local ____opt_32 = themeStyle.text
            local ____temp_40 = ____opt_32 and ____opt_32.alignment or "center"
            local ____opt_34 = themeStyle.text
            local ____temp_41 = ____opt_34 and ____opt_34.wrap or "none"
            local ____opt_36 = themeStyle.text
            local ____temp_38 = ____opt_36 and ____opt_36.ellipsis
            if ____temp_38 == nil then
                ____temp_38 = true
            end
            return __TS__ObjectAssign(
                {},
                ____themeStyle_42,
                tone,
                {
                    padding = ____temp_43,
                    text = __TS__ObjectAssign({}, ____themeStyle_text_39, {alignment = ____temp_40, wrap = ____temp_41, ellipsis = ____temp_38})
                }
            )
        end
    )
end
return ____exports
