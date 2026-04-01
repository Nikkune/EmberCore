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
local BaseComponent = ____ui.BaseComponent
local drawBox = ____ui.drawBox
local DrawBoxOptions = ____ui.DrawBoxOptions
local drawText = ____ui.drawText
local DrawTextOptions = ____ui.DrawTextOptions
local fillRect = ____ui.fillRect
local FillRectOptions = ____ui.FillRectOptions
local normalizeInsets = ____ui.normalizeInsets
local UIDrawSurface = ____ui.UIDrawSurface
local ____types = require("modules.ui.types.index")
local ComponentDependencies = ____types.ComponentDependencies
local LayoutConstraints = ____types.LayoutConstraints
local MeasuredSize = ____types.MeasuredSize
local ProgressBarProps = ____types.ProgressBarProps
local ProgressBarStyle = ____types.ProgressBarStyle
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
        drawText(
            nil,
            context,
            createOptions(nil, {rect = innerRect, text = text, fillBackground = false}):with("style", style.labelStyle):with("clipRect", context.clipRect):done()
        )
    end
end
function ProgressBarComponent.prototype.getResolvedStyle(self, context)
    return self:getStyle(
        context,
        function(____, themeStyle)
            local ____self_27 = createOptions(nil, themeStyle):with("padding", themeStyle.padding or 0):with("fillColor", themeStyle.fillColor or context.theme.palette.primary):with("emptyColor", themeStyle.emptyColor or context.theme.palette.surface)
            local ____self_27_with_28 = ____self_27.with
            local ____themeStyle_showPercentage_26 = themeStyle.showPercentage
            if ____themeStyle_showPercentage_26 == nil then
                ____themeStyle_showPercentage_26 = true
            end
            local ____self_25 = ____self_27_with_28(____self_27, "showPercentage", ____themeStyle_showPercentage_26):with("characterFilled", themeStyle.characterFilled or " "):with("characterEmpty", themeStyle.characterEmpty or " ")
            local ____self_25_with_29 = ____self_25.with
            local ____self_19 = createOptions(nil, themeStyle.labelStyle or ({}))
            local ____self_19_with_20 = ____self_19.with
            local ____opt_17 = themeStyle.labelStyle
            local ____self_16 = ____self_19_with_20(____self_19, "alignment", ____opt_17 and ____opt_17.alignment or "center")
            local ____self_16_with_21 = ____self_16.with
            local ____opt_14 = themeStyle.labelStyle
            local ____self_13 = ____self_16_with_21(____self_16, "wrap", ____opt_14 and ____opt_14.wrap or "none")
            local ____self_13_with_22 = ____self_13.with
            local ____opt_10 = themeStyle.labelStyle
            local ____temp_12 = ____opt_10 and ____opt_10.ellipsis
            if ____temp_12 == nil then
                ____temp_12 = true
            end
            local ____self_9 = ____self_13_with_22(____self_13, "ellipsis", ____temp_12)
            local ____self_9_with_23 = ____self_9.with
            local ____opt_7 = themeStyle.labelStyle
            local ____self_6 = ____self_9_with_23(____self_9, "foregroundColor", ____opt_7 and ____opt_7.foregroundColor or self.props.foregroundColor or context.theme.palette.text)
            local ____self_6_with_24 = ____self_6.with
            local ____opt_4 = themeStyle.labelStyle
            return ____self_25_with_29(
                ____self_25,
                "labelStyle",
                ____self_6_with_24(____self_6, "backgroundColor", ____opt_4 and ____opt_4.backgroundColor):done()
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
