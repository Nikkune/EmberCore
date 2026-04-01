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
local CheckboxProps = ____types.CheckboxProps
local CheckboxStyle = ____types.CheckboxStyle
local ComponentDependencies = ____types.ComponentDependencies
local LayoutConstraints = ____types.LayoutConstraints
local MeasuredSize = ____types.MeasuredSize
local RenderContext = ____types.RenderContext
local TextStyle = ____types.TextStyle
local UIContext = ____types.UIContext
local ____helpers = require("utils.helpers")
local createOptions = ____helpers.createOptions
____exports.CheckboxComponent = __TS__Class()
local CheckboxComponent = ____exports.CheckboxComponent
CheckboxComponent.name = "CheckboxComponent"
__TS__ClassExtends(CheckboxComponent, PressableComponent)
function CheckboxComponent.prototype.____constructor(self, props, dependencies)
    if dependencies == nil then
        dependencies = {}
    end
    PressableComponent.prototype.____constructor(self, "checkbox", props, dependencies)
    self._checked = props.checked
end
function CheckboxComponent.prototype.setChecked(self, value)
    if self._checked == value then
        return
    end
    self._checked = value
    self:invalidate(self:createStateInvalidation())
end
function CheckboxComponent.prototype.toggle(self)
    self:setChecked(not self._checked)
end
function CheckboxComponent.prototype.measure(self, constraints, context)
    local style = self:getResolvedStyle(context)
    local padding = normalizeInsets(nil, style.padding)
    local ____opt_0 = style.border
    local border = ____opt_0 and ____opt_0.enabled and 2 or 0
    local marker = self:getMarker(style)
    local contentPrefix = marker .. " "
    local availableWidth = math.max(0, (self.props.width or self.props.minWidth or constraints.maxWidth) - border - padding.left - padding.right)
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
function CheckboxComponent.prototype.render(self, context)
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
    if innerRect.width <= 0 or innerRect.height <= 0 then
        return
    end
    local marker = self:getMarker(style)
    local markerText = marker .. " "
    local markerWidth = math.min(#markerText, innerRect.width)
    local ____drawText_16 = drawText
    local ____context_15 = context
    local ____createOptions_13 = createOptions
    local ____temp_12 = {x = innerRect.x, y = innerRect.y, width = markerWidth, height = innerRect.height}
    local ____opt_10 = style.text
    local ____self_9 = ____createOptions_13(nil, {rect = ____temp_12, text = markerText, fillBackground = (____opt_10 and ____opt_10.backgroundColor) ~= nil})
    local ____self_9_with_14 = ____self_9.with
    local ____self_7 = createOptions(
        nil,
        __TS__ObjectAssign({}, style.text)
    )
    local ____self_7_with_8 = ____self_7.with
    local ____style_checkColor_6 = style.checkColor
    if ____style_checkColor_6 == nil then
        local ____opt_4 = style.text
        ____style_checkColor_6 = ____opt_4 and ____opt_4.foregroundColor
    end
    ____drawText_16(
        nil,
        ____context_15,
        ____self_9_with_14(
            ____self_9,
            "style",
            ____self_7_with_8(____self_7, "foregroundColor", ____style_checkColor_6 or context.theme.palette.text):with("wrap", "none"):with("ellipsis", false):done()
        ):with("clipRect", context.clipRect):done()
    )
    local textRectWidth = math.max(0, innerRect.width - #markerText)
    if textRectWidth <= 0 then
        return
    end
    local ____drawText_23 = drawText
    local ____context_22 = context
    local ____createOptions_21 = createOptions
    local ____temp_19 = {x = innerRect.x + #markerText, y = innerRect.y, width = textRectWidth, height = innerRect.height}
    local ____self_props_label_20 = self.props.label
    local ____opt_17 = style.text
    ____drawText_23(
        nil,
        ____context_22,
        ____createOptions_21(nil, {rect = ____temp_19, text = ____self_props_label_20, fillBackground = (____opt_17 and ____opt_17.backgroundColor) ~= nil}):with("style", style.text):with("clipRect", context.clipRect):done()
    )
end
function CheckboxComponent.prototype.onPress(self, _context)
    self:toggle()
    local ____this_25
    ____this_25 = self.props
    local ____opt_24 = ____this_25.onChange
    if ____opt_24 ~= nil then
        ____opt_24(____this_25, self._checked)
    end
    return true
end
function CheckboxComponent.prototype.getResolvedStyle(self, context)
    return self:getStyle(
        context,
        function(____, themeStyle)
            local tone = makeToneColorOverride(
                nil,
                nil,
                context.theme,
                self.props.foregroundColor or themeStyle.foregroundColor,
                self.props.backgroundColor or themeStyle.backgroundColor
            )
            local ____themeStyle_36 = themeStyle
            local ____temp_37 = themeStyle.padding or ({left = 1, right = 1})
            local ____themeStyle_text_33 = themeStyle.text
            local ____opt_26 = themeStyle.text
            local ____temp_34 = ____opt_26 and ____opt_26.alignment or "left"
            local ____opt_28 = themeStyle.text
            local ____temp_35 = ____opt_28 and ____opt_28.wrap or "none"
            local ____opt_30 = themeStyle.text
            local ____temp_32 = ____opt_30 and ____opt_30.ellipsis
            if ____temp_32 == nil then
                ____temp_32 = true
            end
            return __TS__ObjectAssign(
                {},
                ____themeStyle_36,
                tone,
                {
                    padding = ____temp_37,
                    text = __TS__ObjectAssign({}, ____themeStyle_text_33, {alignment = ____temp_34, wrap = ____temp_35, ellipsis = ____temp_32})
                }
            )
        end
    )
end
function CheckboxComponent.prototype.getMarker(self, style)
    if self._checked then
        return ("[" .. (style.checkedCharacter or "x")) .. "]"
    end
    return ("[" .. (style.uncheckedCharacter or " ")) .. "]"
end
__TS__SetDescriptor(
    CheckboxComponent.prototype,
    "checked",
    {get = function(self)
        return self._checked
    end},
    true
)
return ____exports
