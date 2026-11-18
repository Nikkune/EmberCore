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
local ____coreComponent = require("modules.ui.core.components.coreComponent")
local BaseComponent = ____coreComponent.BaseComponent
local ____renderHelpers = require("modules.ui.render.renderHelpers")
local drawBox = ____renderHelpers.drawBox
local DrawBoxOptions = ____renderHelpers.DrawBoxOptions
local drawText = ____renderHelpers.drawText
local DrawTextOptions = ____renderHelpers.DrawTextOptions
local fillRect = ____renderHelpers.fillRect
local FillRectOptions = ____renderHelpers.FillRectOptions
local intersectRects = ____renderHelpers.intersectRects
local normalizeInsets = ____renderHelpers.normalizeInsets
local ____surfaceAdapter = require("modules.ui.render.surfaceAdapter")
local UIDrawSurface = ____surfaceAdapter.UIDrawSurface
local ____types = require("modules.ui.types.index")
local ComponentDependencies = ____types.ComponentDependencies
local LayoutConstraints = ____types.LayoutConstraints
local MeasuredSize = ____types.MeasuredSize
local ProgressBarProps = ____types.ProgressBarProps
local ProgressBarStyle = ____types.ProgressBarStyle
local Rect = ____types.Rect
local RenderContext = ____types.RenderContext
local TextStyle = ____types.TextStyle
local UIContext = ____types.UIContext
local ____helpers = require("utils.helpers")
local createOptions = ____helpers.createOptions
____exports.ProgressBarComponent = __TS__Class()
local ProgressBarComponent = ____exports.ProgressBarComponent
ProgressBarComponent.name = "ProgressBarComponent"
__TS__ClassExtends(ProgressBarComponent, BaseComponent)
function ProgressBarComponent.prototype.____constructor(self, props, dependencies)
    if dependencies == nil then
        dependencies = {}
    end
    BaseComponent.prototype.____constructor(self, "progress_bar", props, dependencies)
end
function ProgressBarComponent.prototype.setValue(self, value)
    self:setProps({value = value})
end
function ProgressBarComponent.prototype.measure(self, constraints, context)
    local style = self:getResolvedStyle(context)
    local padding = normalizeInsets(nil, style.padding)
    local ____opt_0 = style.border
    local border = ____opt_0 and ____opt_0.enabled and 2 or 0
    local contentText = self:getDisplayText(style)
    local contentWidth = math.max(1, #contentText)
    local width = self.props.width or self.props.minWidth or contentWidth + padding.left + padding.right + border
    local height = self.props.height or self.props.minHeight or 1 + padding.top + padding.bottom + border
    return self:createMeasuredSize(width, height, constraints)
end
function ProgressBarComponent.prototype.render(self, context)
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
    local filledWidth = self.progress > 0 and math.max(
        1,
        math.floor(innerRect.width * self.progress)
    ) or 0
    local emptyWidth = math.max(0, innerRect.width - filledWidth)
    if filledWidth > 0 then
        fillRect(
            nil,
            context.draw,
            createOptions(nil, {rect = {x = innerRect.x, y = innerRect.y, width = filledWidth, height = innerRect.height}, character = style.characterFilled or " "}):with("backgroundColor", style.fillColor):with("foregroundColor", style.fillColor):with("clipRect", context.clipRect):done()
        )
    end
    if emptyWidth > 0 and style.emptyColor ~= nil then
        fillRect(
            nil,
            context.draw,
            createOptions(nil, {rect = {x = innerRect.x + filledWidth, y = innerRect.y, width = emptyWidth, height = innerRect.height}, character = style.characterEmpty or " "}):with("backgroundColor", style.emptyColor):with("foregroundColor", style.emptyColor):with("clipRect", context.clipRect):done()
        )
    end
    local text = self:getDisplayText(style)
    if #text > 0 then
        local segments = {{x = innerRect.x, width = filledWidth, background = style.fillColor}, {x = innerRect.x + filledWidth, width = emptyWidth, background = style.emptyColor or style.backgroundColor}}
        for ____, segment in ipairs(segments) do
            do
                local __continue12
                repeat
                    if segment.width <= 0 then
                        __continue12 = true
                        break
                    end
                    local segmentRect = {x = segment.x, y = innerRect.y, width = segment.width, height = innerRect.height}
                    local ____context_clipRect_4
                    if context.clipRect then
                        ____context_clipRect_4 = intersectRects(nil, segmentRect, context.clipRect)
                    else
                        ____context_clipRect_4 = segmentRect
                    end
                    local clipRect = ____context_clipRect_4
                    if not clipRect then
                        __continue12 = true
                        break
                    end
                    local ____drawText_12 = drawText
                    local ____context_11 = context
                    local ____self_9 = createOptions(nil, {rect = innerRect, text = text, fillBackground = false, clipRect = clipRect})
                    local ____self_9_with_10 = ____self_9.with
                    local ____self_7 = createOptions(
                        nil,
                        __TS__ObjectAssign({}, style.labelStyle or ({}))
                    )
                    local ____self_7_with_8 = ____self_7.with
                    local ____opt_5 = style.labelStyle
                    ____drawText_12(
                        nil,
                        ____context_11,
                        ____self_9_with_10(
                            ____self_9,
                            "style",
                            ____self_7_with_8(____self_7, "backgroundColor", ____opt_5 and ____opt_5.backgroundColor or segment.background):done()
                        ):done()
                    )
                    __continue12 = true
                until true
                if not __continue12 then
                    break
                end
            end
        end
    end
end
function ProgressBarComponent.prototype.getResolvedStyle(self, context)
    return self:getStyle(
        context,
        function(____, themeStyle)
            local ____self_37 = createOptions(
                nil,
                __TS__ObjectAssign({}, themeStyle)
            ):with("padding", self.props.padding or themeStyle.padding or 0):with("fillColor", themeStyle.fillColor or context.theme.palette.primary):with("emptyColor", themeStyle.emptyColor or context.theme.palette.surface)
            local ____self_37_with_38 = ____self_37.with
            local ____themeStyle_showPercentage_36 = themeStyle.showPercentage
            if ____themeStyle_showPercentage_36 == nil then
                ____themeStyle_showPercentage_36 = true
            end
            local ____self_35 = ____self_37_with_38(____self_37, "showPercentage", ____themeStyle_showPercentage_36):with("characterFilled", themeStyle.characterFilled or " "):with("characterEmpty", themeStyle.characterEmpty or " ")
            local ____self_35_with_39 = ____self_35.with
            local ____self_29 = createOptions(
                nil,
                __TS__ObjectAssign({}, themeStyle.labelStyle or ({}))
            )
            local ____self_29_with_30 = ____self_29.with
            local ____opt_27 = themeStyle.labelStyle
            local ____self_26 = ____self_29_with_30(____self_29, "alignment", ____opt_27 and ____opt_27.alignment or "center")
            local ____self_26_with_31 = ____self_26.with
            local ____opt_24 = themeStyle.labelStyle
            local ____self_23 = ____self_26_with_31(____self_26, "wrap", ____opt_24 and ____opt_24.wrap or "none")
            local ____self_23_with_32 = ____self_23.with
            local ____opt_20 = themeStyle.labelStyle
            local ____temp_22 = ____opt_20 and ____opt_20.ellipsis
            if ____temp_22 == nil then
                ____temp_22 = true
            end
            local ____self_19 = ____self_23_with_32(____self_23, "ellipsis", ____temp_22)
            local ____self_19_with_33 = ____self_19.with
            local ____self_props_foregroundColor_18 = self.props.foregroundColor
            if ____self_props_foregroundColor_18 == nil then
                local ____opt_16 = themeStyle.labelStyle
                ____self_props_foregroundColor_18 = ____opt_16 and ____opt_16.foregroundColor
            end
            local ____self_15 = ____self_19_with_33(____self_19, "foregroundColor", ____self_props_foregroundColor_18 or context.theme.palette.text)
            local ____self_15_with_34 = ____self_15.with
            local ____opt_13 = themeStyle.labelStyle
            return ____self_35_with_39(
                ____self_35,
                "labelStyle",
                ____self_15_with_34(____self_15, "backgroundColor", ____opt_13 and ____opt_13.backgroundColor):done()
            ):done()
        end
    )
end
function ProgressBarComponent.prototype.getDisplayText(self, style)
    local parts = {}
    if self.props.label then
        parts[#parts + 1] = self.props.label
    end
    if style.showPercentage then
        parts[#parts + 1] = tostring(math.floor(self.progress * 100)) .. "%"
    end
    return table.concat(parts, " ")
end
__TS__SetDescriptor(
    ProgressBarComponent.prototype,
    "minValue",
    {get = function(self)
        return self.props.minValue or 0
    end},
    true
)
__TS__SetDescriptor(
    ProgressBarComponent.prototype,
    "maxValue",
    {get = function(self)
        return math.max(self.minValue, self.props.maxValue)
    end},
    true
)
__TS__SetDescriptor(
    ProgressBarComponent.prototype,
    "value",
    {get = function(self)
        return self:clamp(self.props.value, self.minValue, self.maxValue)
    end},
    true
)
__TS__SetDescriptor(
    ProgressBarComponent.prototype,
    "progress",
    {get = function(self)
        local range = self.maxValue - self.minValue
        if range <= 0 then
            return 0
        end
        return (self.value - self.minValue) / range
    end},
    true
)
return ____exports
