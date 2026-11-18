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

local function __TS__CloneDescriptor(____bindingPattern0)
    local value
    local writable
    local set
    local get
    local configurable
    local enumerable
    enumerable = ____bindingPattern0.enumerable
    configurable = ____bindingPattern0.configurable
    get = ____bindingPattern0.get
    set = ____bindingPattern0.set
    writable = ____bindingPattern0.writable
    value = ____bindingPattern0.value
    local descriptor = {enumerable = enumerable == true, configurable = configurable == true}
    local hasGetterOrSetter = get ~= nil or set ~= nil
    local hasValueOrWritableAttribute = writable ~= nil or value ~= nil
    if hasGetterOrSetter and hasValueOrWritableAttribute then
        error("Invalid property descriptor. Cannot both specify accessors and a value or writable attribute.", 0)
    end
    if get or set then
        descriptor.get = get
        descriptor.set = set
    else
        descriptor.value = value
        descriptor.writable = writable == true
    end
    return descriptor
end

local __TS__DescriptorGet
do
    local getmetatable = _G.getmetatable
    local ____rawget = _G.rawget
    function __TS__DescriptorGet(self, metatable, key)
        while metatable do
            local rawResult = ____rawget(metatable, key)
            if rawResult ~= nil then
                return rawResult
            end
            local descriptors = ____rawget(metatable, "_descriptors")
            if descriptors then
                local descriptor = descriptors[key]
                if descriptor ~= nil then
                    if descriptor.get then
                        return descriptor.get(self)
                    end
                    return descriptor.value
                end
            end
            metatable = getmetatable(metatable)
        end
    end
end

local __TS__DescriptorSet
do
    local getmetatable = _G.getmetatable
    local ____rawget = _G.rawget
    local rawset = _G.rawset
    function __TS__DescriptorSet(self, metatable, key, value)
        while metatable do
            local descriptors = ____rawget(metatable, "_descriptors")
            if descriptors then
                local descriptor = descriptors[key]
                if descriptor ~= nil then
                    if descriptor.set then
                        descriptor.set(self, value)
                    else
                        if descriptor.writable == false then
                            error(
                                ((("Cannot assign to read only property '" .. key) .. "' of object '") .. tostring(self)) .. "'",
                                0
                            )
                        end
                        descriptor.value = value
                    end
                    return
                end
            end
            metatable = getmetatable(metatable)
        end
        rawset(self, key, value)
    end
end

local __TS__SetDescriptor
do
    local getmetatable = _G.getmetatable
    local function descriptorIndex(self, key)
        return __TS__DescriptorGet(
            self,
            getmetatable(self),
            key
        )
    end
    local function descriptorNewIndex(self, key, value)
        return __TS__DescriptorSet(
            self,
            getmetatable(self),
            key,
            value
        )
    end
    function __TS__SetDescriptor(target, key, desc, isPrototype)
        if isPrototype == nil then
            isPrototype = false
        end
        local ____isPrototype_0
        if isPrototype then
            ____isPrototype_0 = target
        else
            ____isPrototype_0 = getmetatable(target)
        end
        local metatable = ____isPrototype_0
        if not metatable then
            metatable = {}
            setmetatable(target, metatable)
        end
        local value = rawget(target, key)
        if value ~= nil then
            rawset(target, key, nil)
        end
        if not rawget(metatable, "_descriptors") then
            metatable._descriptors = {}
        end
        metatable._descriptors[key] = __TS__CloneDescriptor(desc)
        metatable.__index = descriptorIndex
        metatable.__newindex = descriptorNewIndex
    end
end
-- End of Lua Library inline imports
local ____exports = {}
local ____pressableComponent = require("modules.ui.core.components.pressableComponent")
local PressableComponent = ____pressableComponent.PressableComponent
local ____renderHelpers = require("modules.ui.render.renderHelpers")
local drawBox = ____renderHelpers.drawBox
local DrawBoxOptions = ____renderHelpers.DrawBoxOptions
local drawText = ____renderHelpers.drawText
local DrawTextOptions = ____renderHelpers.DrawTextOptions
local normalizeInsets = ____renderHelpers.normalizeInsets
local resolveTextLines = ____renderHelpers.resolveTextLines
local ResolveTextLinesOptions = ____renderHelpers.ResolveTextLinesOptions
local ____surfaceAdapter = require("modules.ui.render.surfaceAdapter")
local UIDrawSurface = ____surfaceAdapter.UIDrawSurface
local ____tone = require("modules.ui.theme.tone")
local inheritTextColors = ____tone.inheritTextColors
local makeToneColorOverride = ____tone.makeToneColorOverride
local ____types = require("modules.ui.types.index")
local ButtonStyle = ____types.ButtonStyle
local ComponentDependencies = ____types.ComponentDependencies
local LayoutConstraints = ____types.LayoutConstraints
local MeasuredSize = ____types.MeasuredSize
local RenderContext = ____types.RenderContext
local ToggleButtonProps = ____types.ToggleButtonProps
local UIContext = ____types.UIContext
local ____helpers = require("utils.helpers")
local createOptions = ____helpers.createOptions
____exports.ToggleButtonComponent = __TS__Class()
local ToggleButtonComponent = ____exports.ToggleButtonComponent
ToggleButtonComponent.name = "ToggleButtonComponent"
__TS__ClassExtends(ToggleButtonComponent, PressableComponent)
function ToggleButtonComponent.prototype.____constructor(self, props, dependencies)
    if dependencies == nil then
        dependencies = {}
    end
    PressableComponent.prototype.____constructor(self, "button", props, dependencies)
    local ____props_pressed_0 = props.pressed
    if ____props_pressed_0 == nil then
        ____props_pressed_0 = false
    end
    self._pressed = ____props_pressed_0
end
function ToggleButtonComponent.prototype.onPropsChanged(self, patch)
    if patch.pressed ~= nil then
        self._pressed = patch.pressed
    end
end
function ToggleButtonComponent.prototype.setLabel(self, label)
    self:setProps({label = label})
end
function ToggleButtonComponent.prototype.setPressed(self, value)
    if self._pressed == value then
        return
    end
    self._pressed = value
    self:invalidate(self:createStateInvalidation())
end
function ToggleButtonComponent.prototype.toggle(self)
    self:setPressed(not self._pressed)
end
function ToggleButtonComponent.prototype.measure(self, constraints, context)
    local style = self:getResolvedStyle(context)
    local padding = normalizeInsets(nil, style.padding)
    local ____opt_1 = style.border
    local border = ____opt_1 and ____opt_1.enabled and 2 or 0
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
        function(____, max, line) return math.max(max, #line.text) end,
        0
    )
    local contentHeight = math.max(1, #lines)
    return self:createMeasuredSize(contentWidth + padding.left + padding.right + border, contentHeight + padding.top + padding.bottom + border, constraints)
end
function ToggleButtonComponent.prototype.render(self, context)
    if not self.visible then
        return
    end
    if self.width <= 0 or self.height <= 0 then
        return
    end
    local style = self:getResolvedStyle(context)
    local ____opt_3 = style.border
    local borderCharacters = ____opt_3 and ____opt_3.enabled and context.theme.borders[style.border.preset or "single"] or nil
    local innerRect = drawBox(
        nil,
        context.draw,
        createOptions(nil, {rect = self.rect, style = style}):with("borderCharacters", borderCharacters):with("clipRect", context.clipRect):done()
    )
    local ____drawText_10 = drawText
    local ____context_9 = context
    local ____createOptions_8 = createOptions
    local ____self_props_label_7 = self.props.label
    local ____opt_5 = style.text
    ____drawText_10(
        nil,
        ____context_9,
        ____createOptions_8(nil, {rect = innerRect, text = ____self_props_label_7, fillBackground = (____opt_5 and ____opt_5.backgroundColor) ~= nil}):with("style", style.text):with("clipRect", context.clipRect):done()
    )
end
function ToggleButtonComponent.prototype.onPress(self, _context)
    self:toggle()
    local ____this_12
    ____this_12 = self.props
    local ____opt_11 = ____this_12.onToggle
    if ____opt_11 ~= nil then
        ____opt_11(____this_12, self._pressed)
    end
    local ____this_14
    ____this_14 = self.props
    local ____opt_13 = ____this_14.onPress
    if ____opt_13 ~= nil then
        ____opt_13(____this_14)
    end
    return true
end
function ToggleButtonComponent.prototype.getResolvedStyle(self, context)
    return self:getStyle(
        context,
        function(____, themeStyle)
            local colors = themeStyle.colors
            local ____table_disabled_33
            if self.disabled then
                ____table_disabled_33 = colors and colors.disabled
            else
                local ____table_flashing_32
                if self.flashing then
                    ____table_flashing_32 = colors and colors.active or colors and colors.selected or colors and colors.pressed
                else
                    local ____table__pressed_31
                    if self._pressed then
                        ____table__pressed_31 = colors and colors.pressed or colors and colors.active or colors and colors.selected
                    else
                        ____table__pressed_31 = colors and colors.default
                    end
                    ____table_flashing_32 = ____table__pressed_31
                end
                ____table_disabled_33 = ____table_flashing_32
            end
            local stateBackground = ____table_disabled_33
            local tone = makeToneColorOverride(
                nil,
                nil,
                context.theme,
                self.props.foregroundColor or themeStyle.foregroundColor,
                self.props.backgroundColor or stateBackground or themeStyle.backgroundColor
            )
            local ____themeStyle_44 = themeStyle
            local ____temp_45 = self.props.padding or themeStyle.padding or ({left = 1, right = 1})
            local ____inheritTextColors_result_41 = inheritTextColors(nil, themeStyle.text, tone, self.props)
            local ____opt_34 = themeStyle.text
            local ____temp_42 = ____opt_34 and ____opt_34.alignment or "center"
            local ____opt_36 = themeStyle.text
            local ____temp_43 = ____opt_36 and ____opt_36.wrap or "none"
            local ____opt_38 = themeStyle.text
            local ____temp_40 = ____opt_38 and ____opt_38.ellipsis
            if ____temp_40 == nil then
                ____temp_40 = true
            end
            return __TS__ObjectAssign(
                {},
                ____themeStyle_44,
                tone,
                {
                    padding = ____temp_45,
                    text = __TS__ObjectAssign({}, ____inheritTextColors_result_41, {alignment = ____temp_42, wrap = ____temp_43, ellipsis = ____temp_40})
                }
            )
        end
    )
end
__TS__SetDescriptor(
    ToggleButtonComponent.prototype,
    "pressed",
    {get = function(self)
        return self._pressed
    end},
    true
)
return ____exports
