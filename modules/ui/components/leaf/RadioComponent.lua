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
local ____RadioGroup = require("modules.ui.components.leaf.RadioGroup")
local RadioGroup = ____RadioGroup.RadioGroup
local ____types = require("modules.ui.types.index")
local ComponentDependencies = ____types.ComponentDependencies
local InvalidationRequest = ____types.InvalidationRequest
local LayoutConstraints = ____types.LayoutConstraints
local MeasuredSize = ____types.MeasuredSize
local RadioProps = ____types.RadioProps
local RadioStyle = ____types.RadioStyle
local Rect = ____types.Rect
local RenderContext = ____types.RenderContext
local TextStyle = ____types.TextStyle
local UIContext = ____types.UIContext
local ____helpers = require("utils.helpers")
local createOptions = ____helpers.createOptions
____exports.RadioComponent = __TS__Class()
local RadioComponent = ____exports.RadioComponent
RadioComponent.name = "RadioComponent"
__TS__ClassExtends(RadioComponent, PressableComponent)
function RadioComponent.prototype.____constructor(self, props, dependencies, group)
    if dependencies == nil then
        dependencies = {}
    end
    PressableComponent.prototype.____constructor(self, "radio", props, dependencies)
    self.radioGroup = group
    local ____group_1
    if group then
        ____group_1 = group:isSelected(props.value)
    else
        local ____props_selected_0 = props.selected
        if ____props_selected_0 == nil then
            ____props_selected_0 = false
        end
        ____group_1 = ____props_selected_0
    end
    self._selected = ____group_1
    if self.radioGroup then
        self.unsubscribeGroup = self.radioGroup:subscribe(function(____, value)
            local selected = value == self.props.value
            if self._selected == selected then
                return
            end
            self._selected = selected
            self:invalidate(self:createStateInvalidation())
            local ____this_3
            ____this_3 = self.props
            local ____opt_2 = ____this_3.onSelect
            if ____opt_2 ~= nil then
                ____opt_2(____this_3, selected)
            end
        end)
    end
end
function RadioComponent.prototype.onPropsChanged(self, patch)
    if patch.selected ~= nil then
        self:setSelected(patch.selected)
    end
end
function RadioComponent.prototype.setLabel(self, label)
    self:setProps({label = label})
end
function RadioComponent.prototype.createStateInvalidation(self, rect)
    if self.radioGroup then
        return {reason = "state", kind = "full"}
    end
    return PressableComponent.prototype.createStateInvalidation(self, rect)
end
function RadioComponent.prototype.destroy(self)
    local ____opt_4 = self.unsubscribeGroup
    if ____opt_4 ~= nil then
        ____opt_4(self)
    end
    self.unsubscribeGroup = nil
    PressableComponent.prototype.destroy(self)
end
function RadioComponent.prototype.setSelected(self, value)
    if self.radioGroup then
        if value then
            self.radioGroup:select(self.props.value)
        elseif self.radioGroup:isSelected(self.props.value) then
            self.radioGroup:clear()
        end
        return
    end
    if self._selected == value then
        return
    end
    self._selected = value
    self:invalidate(self:createStateInvalidation())
end
function RadioComponent.prototype.measure(self, constraints, context)
    local style = self:getResolvedStyle(context)
    local padding = normalizeInsets(nil, style.padding)
    local ____opt_6 = style.border
    local border = ____opt_6 and ____opt_6.enabled and 2 or 0
    local marker = self:getMarker(style)
    local contentPrefix = marker .. " "
    local requestedWidth = self.props.width or self.props.minWidth or constraints.maxWidth
    local availableWidth = math.max(0, requestedWidth - border - padding.left - padding.right)
    local textWidth = math.max(0, availableWidth - #contentPrefix)
    local lines = resolveTextLines(
        nil,
        createOptions(nil, {text = self.props.label, width = textWidth}):with("style", style.text):done()
    )
    local contentWidth = __TS__ArrayReduce(
        lines,
        function(____, max, line)
            local lineWidth = #contentPrefix + #line.text
            return math.max(max, lineWidth)
        end,
        #contentPrefix
    )
    local contentHeight = math.max(1, #lines)
    return self:createMeasuredSize(contentWidth + padding.left + padding.right + border, contentHeight + padding.top + padding.bottom + border, constraints)
end
function RadioComponent.prototype.render(self, context)
    if not self.visible then
        return
    end
    if self.width <= 0 or self.height <= 0 then
        return
    end
    local style = self:getResolvedStyle(context)
    local ____opt_8 = style.border
    local borderCharacters = ____opt_8 and ____opt_8.enabled and context.theme.borders[style.border.preset or "single"] or nil
    local innerRect = drawBox(
        nil,
        context.draw,
        createOptions(nil, {rect = self.rect, style = style}):with("borderCharacters", borderCharacters):with("clipRect", context.clipRect):done()
    )
    if innerRect.width <= 0 or innerRect.height <= 0 then
        return
    end
    local marker = self:getMarker(style)
    local markerText = marker .. " "
    local markerWidth = math.min(#markerText, innerRect.width)
    local ____drawText_22 = drawText
    local ____context_21 = context
    local ____createOptions_19 = createOptions
    local ____temp_18 = {x = innerRect.x, y = innerRect.y, width = markerWidth, height = innerRect.height}
    local ____opt_16 = style.text
    local ____self_15 = ____createOptions_19(nil, {rect = ____temp_18, text = markerText, fillBackground = (____opt_16 and ____opt_16.backgroundColor) ~= nil})
    local ____self_15_with_20 = ____self_15.with
    local ____self_13 = createOptions(
        nil,
        __TS__ObjectAssign({}, style.text or ({}))
    ):with("wrap", "none"):with("ellipsis", false)
    local ____self_13_with_14 = ____self_13.with
    local ____style_dotColor_12 = style.dotColor
    if ____style_dotColor_12 == nil then
        local ____opt_10 = style.text
        ____style_dotColor_12 = ____opt_10 and ____opt_10.foregroundColor
    end
    ____drawText_22(
        nil,
        ____context_21,
        ____self_15_with_20(
            ____self_15,
            "style",
            ____self_13_with_14(____self_13, "foregroundColor", ____style_dotColor_12 or context.theme.palette.text):done()
        ):with("clipRect", context.clipRect):done()
    )
    local textRectWidth = math.max(0, innerRect.width - #markerText)
    if textRectWidth <= 0 then
        return
    end
    local ____drawText_29 = drawText
    local ____context_28 = context
    local ____createOptions_27 = createOptions
    local ____temp_25 = {x = innerRect.x + #markerText, y = innerRect.y, width = textRectWidth, height = innerRect.height}
    local ____self_props_label_26 = self.props.label
    local ____opt_23 = style.text
    ____drawText_29(
        nil,
        ____context_28,
        ____createOptions_27(nil, {rect = ____temp_25, text = ____self_props_label_26, fillBackground = (____opt_23 and ____opt_23.backgroundColor) ~= nil}):with("style", style.text):with("clipRect", context.clipRect):done()
    )
end
function RadioComponent.prototype.onPress(self, _context)
    if self.radioGroup then
        return self.radioGroup:select(self.props.value)
    end
    if self._selected then
        return false
    end
    self._selected = true
    local ____this_31
    ____this_31 = self.props
    local ____opt_30 = ____this_31.onSelect
    if ____opt_30 ~= nil then
        ____opt_30(____this_31, true)
    end
    return true
end
function RadioComponent.prototype.getResolvedStyle(self, context)
    return self:getStyle(
        context,
        function(____, themeStyle)
            local foreground = self.props.foregroundColor or themeStyle.foregroundColor
            local background = self.props.backgroundColor or themeStyle.backgroundColor
            local tone = makeToneColorOverride(
                nil,
                nil,
                context.theme,
                foreground,
                background
            )
            local ____themeStyle_42 = themeStyle
            local ____temp_43 = self.props.padding or themeStyle.padding or ({left = 1, right = 1})
            local ____inheritTextColors_result_39 = inheritTextColors(nil, themeStyle.text, tone, self.props)
            local ____opt_32 = themeStyle.text
            local ____temp_40 = ____opt_32 and ____opt_32.alignment or "left"
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
                    text = __TS__ObjectAssign({}, ____inheritTextColors_result_39, {alignment = ____temp_40, wrap = ____temp_41, ellipsis = ____temp_38})
                }
            )
        end
    )
end
function RadioComponent.prototype.getMarker(self, style)
    if self._selected then
        return ("(" .. (style.selectedCharacter or "o")) .. ")"
    end
    return ("(" .. (style.unselectedCharacter or " ")) .. ")"
end
__TS__SetDescriptor(
    RadioComponent.prototype,
    "selected",
    {get = function(self)
        return self._selected
    end},
    true
)
return ____exports
