--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__Class(self)
    local c = {prototype = {}}
    c.prototype.__index = c.prototype
    c.prototype.constructor = c
    return c
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
local ____types = require("modules.ui.types.index")
local BaseProps = ____types.BaseProps
local Color = ____types.Color
local ComponentDependencies = ____types.ComponentDependencies
local ComponentKind = ____types.ComponentKind
local InvalidationRequest = ____types.InvalidationRequest
local LayoutConstraints = ____types.LayoutConstraints
local MeasuredSize = ____types.MeasuredSize
local Point = ____types.Point
local Rect = ____types.Rect
local RenderContext = ____types.RenderContext
local ThemeComponentKind = ____types.ThemeComponentKind
local UIComponent = ____types.UIComponent
local UIContext = ____types.UIContext
local UIInvalidator = ____types.UIInvalidator
local componentIdCounter = 0
local function createComponentId(self, kind)
    componentIdCounter = componentIdCounter + 1
    return (("ui_" .. kind) .. "_") .. tostring(componentIdCounter)
end
____exports.BaseComponent = __TS__Class()
local BaseComponent = ____exports.BaseComponent
BaseComponent.name = "BaseComponent"
function BaseComponent.prototype.____constructor(self, kind, props, dependencies)
    if dependencies == nil then
        dependencies = {}
    end
    self.rect = {x = 1, y = 1, width = 0, height = 0}
    self.kind = kind
    self.props = props
    self.id = props.id or createComponentId(nil, kind)
    self.dependencies = dependencies
    self.invalidator = dependencies.invalidator
end
function BaseComponent.prototype.layout(self, rect, _context)
    self.rect = rect
end
function BaseComponent.prototype.invalidate(self, request)
    if request == nil then
        request = {reason = "manual"}
    end
    local ____opt_0 = self.invalidator
    if ____opt_0 ~= nil then
        ____opt_0:invalidate(__TS__ObjectAssign({}, request, {rect = request.rect or self.rect}))
    end
end
function BaseComponent.prototype.destroy(self)
end
function BaseComponent.prototype.createMeasuredSize(self, width, height, constraints)
    if not constraints then
        return {
            width = math.max(0, width),
            height = math.max(0, height)
        }
    end
    return {
        width = self:clamp(width, constraints.minWidth, constraints.maxWidth),
        height = self:clamp(height, constraints.minHeight, constraints.maxHeight)
    }
end
function BaseComponent.prototype.isVisibleAndEnabled(self)
    return self.visible and not self.disabled
end
function BaseComponent.prototype.getRequestedWidth(self, fallback)
    return self.props.width or self.props.minWidth or fallback
end
function BaseComponent.prototype.getRequestedHeight(self, fallback)
    return self.props.height or self.props.minHeight or fallback
end
function BaseComponent.prototype.clamp(self, value, min, max)
    return math.max(
        min,
        math.min(max, value)
    )
end
function BaseComponent.prototype.isPointInsideRect(self, point, rect)
    return point.x >= rect.x and point.y >= rect.y and point.x < rect.x + rect.width and point.y < rect.y + rect.height
end
function BaseComponent.prototype.getThemeStyle(self, context)
    local components = context.theme.components
    if not components then
        return {}
    end
    local kind = self.kind
    return components[kind] or ({})
end
function BaseComponent.prototype.getStyle(self, context, override)
    local themeStyle = self:getThemeStyle(context)
    if not override then
        return themeStyle
    end
    if type(override) == "function" then
        return override(nil, themeStyle)
    end
    return __TS__ObjectAssign({}, themeStyle, override)
end
function BaseComponent.prototype.resolveColor(self, value, fallback, defaultColor)
    return value or fallback or defaultColor
end
__TS__SetDescriptor(
    BaseComponent.prototype,
    "visible",
    {get = function(self)
        local ____self_props_visible_2 = self.props.visible
        if ____self_props_visible_2 == nil then
            ____self_props_visible_2 = true
        end
        return ____self_props_visible_2
    end},
    true
)
__TS__SetDescriptor(
    BaseComponent.prototype,
    "disabled",
    {get = function(self)
        local ____self_props_disabled_3 = self.props.disabled
        if ____self_props_disabled_3 == nil then
            ____self_props_disabled_3 = false
        end
        return ____self_props_disabled_3
    end},
    true
)
__TS__SetDescriptor(
    BaseComponent.prototype,
    "width",
    {get = function(self)
        return self.rect.width
    end},
    true
)
__TS__SetDescriptor(
    BaseComponent.prototype,
    "height",
    {get = function(self)
        return self.rect.height
    end},
    true
)
__TS__SetDescriptor(
    BaseComponent.prototype,
    "x",
    {get = function(self)
        return self.rect.x
    end},
    true
)
__TS__SetDescriptor(
    BaseComponent.prototype,
    "y",
    {get = function(self)
        return self.rect.y
    end},
    true
)
return ____exports
