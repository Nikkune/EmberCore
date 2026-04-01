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
local normalizeInsets = ____ui.normalizeInsets
local PressableComponent = ____ui.PressableComponent
local resolveTextLines = ____ui.resolveTextLines
local ResolveTextLinesOptions = ____ui.ResolveTextLinesOptions
local UIDrawSurface = ____ui.UIDrawSurface
local ____types = require("modules.ui.types.index")
local ComponentDependencies = ____types.ComponentDependencies
local LayoutConstraints = ____types.LayoutConstraints
local MeasuredSize = ____types.MeasuredSize
local PaginationProps = ____types.PaginationProps
local PaginationStyle = ____types.PaginationStyle
local RenderContext = ____types.RenderContext
local TextStyle = ____types.TextStyle
local UIContext = ____types.UIContext
local UIEvent = ____types.UIEvent
local ____helpers = require("utils.helpers")
local createOptions = ____helpers.createOptions
____exports.PaginationComponent = __TS__Class()
local PaginationComponent = ____exports.PaginationComponent
PaginationComponent.name = "PaginationComponent"
__TS__ClassExtends(PaginationComponent, PressableComponent)
function PaginationComponent.prototype.____constructor(self, props, dependencies)
    if dependencies == nil then
        dependencies = {}
    end
    PressableComponent.prototype.____constructor(self, "pagination", props, dependencies)
end
function PaginationComponent.prototype.measure(self, constraints, context)
    local style = self:getResolvedStyle(context)
    local padding = normalizeInsets(nil, style.padding)
    local ____opt_0 = style.border
    local border = ____opt_0 and ____opt_0.enabled and 2 or 0
    local content = self:getDisplayText(style)
    local width = self.props.width or self.props.minWidth or #content + padding.left + padding.right + border
    local lines = resolveTextLines(
        nil,
        createOptions(
            nil,
            {
                text = content,
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
    return self:createMeasuredSize(self.props.width or self.props.minWidth or contentWidth + padding.left + padding.right + border, self.props.height or self.props.minHeight or contentHeight + padding.top + padding.bottom + border, constraints)
end
function PaginationComponent.prototype.render(self, context)
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
    local ____temp_6 = self:getDisplayText(style)
    local ____opt_4 = style.text
    ____drawText_9(
        nil,
        ____context_8,
        ____createOptions_7(nil, {rect = innerRect, text = ____temp_6, fillBackground = (____opt_4 and ____opt_4.backgroundColor) ~= nil}):with("style", style.text):with("clipRect", context.clipRect):done()
    )
end
function PaginationComponent.prototype.handleEvent(self, event, context)
    repeat
        local ____switch9 = event.type
        local ____cond9 = ____switch9 == "mouse_click" or ____switch9 == "monitor_touch"
        if ____cond9 then
            do
                if not (event.x ~= nil) then
                    return nil
                end
                self:focus()
                local targetPage = self:resolveTargetPageFromX(event.x)
                if targetPage == self.page then
                    return nil
                end
                return self:changePage(targetPage, context) and self:createStateInvalidation() or nil
            end
        end
        do
            return PressableComponent.prototype.handleEvent(self, event, context)
        end
    until true
end
function PaginationComponent.prototype.press(self, context)
    local nextPage = math.min(self.totalPages, self.page + 1)
    return self:changePage(nextPage, context)
end
function PaginationComponent.prototype.onPress(self, _context)
    return false
end
function PaginationComponent.prototype.getResolvedStyle(self, context)
    return self:getStyle(
        context,
        function(____, themeStyle)
            local ____self_35 = createOptions(nil, themeStyle):with("padding", themeStyle.padding or 0)
            local ____self_35_with_36 = ____self_35.with
            local ____self_29 = createOptions(nil, themeStyle.text or ({}))
            local ____self_29_with_30 = ____self_29.with
            local ____opt_27 = themeStyle.text
            local ____self_26 = ____self_29_with_30(____self_29, "alignment", ____opt_27 and ____opt_27.alignment or "center")
            local ____self_26_with_31 = ____self_26.with
            local ____opt_24 = themeStyle.text
            local ____self_23 = ____self_26_with_31(____self_26, "wrap", ____opt_24 and ____opt_24.wrap or "none")
            local ____self_23_with_32 = ____self_23.with
            local ____opt_20 = themeStyle.text
            local ____temp_22 = ____opt_20 and ____opt_20.ellipsis
            if ____temp_22 == nil then
                ____temp_22 = true
            end
            local ____self_19 = ____self_23_with_32(____self_23, "ellipsis", ____temp_22)
            local ____self_19_with_33 = ____self_19.with
            local ____opt_17 = themeStyle.text
            local ____self_16 = ____self_19_with_33(____self_19, "foregroundColor", ____opt_17 and ____opt_17.foregroundColor or self.props.foregroundColor or context.theme.palette.text)
            local ____self_16_with_34 = ____self_16.with
            local ____opt_14 = themeStyle.text
            local ____self_13 = ____self_35_with_36(
                ____self_35,
                "text",
                ____self_16_with_34(____self_16, "backgroundColor", ____opt_14 and ____opt_14.backgroundColor or self.props.backgroundColor or themeStyle.backgroundColor):done()
            )
            local ____self_13_with_37 = ____self_13.with
            local ____themeStyle_showFirstLast_12 = themeStyle.showFirstLast
            if ____themeStyle_showFirstLast_12 == nil then
                ____themeStyle_showFirstLast_12 = true
            end
            local ____self_11 = ____self_13_with_37(____self_13, "showFirstLast", ____themeStyle_showFirstLast_12)
            local ____self_11_with_38 = ____self_11.with
            local ____themeStyle_showPrevNext_10 = themeStyle.showPrevNext
            if ____themeStyle_showPrevNext_10 == nil then
                ____themeStyle_showPrevNext_10 = true
            end
            return ____self_11_with_38(____self_11, "showPrevNext", ____themeStyle_showPrevNext_10):done()
        end
    )
end
function PaginationComponent.prototype.changePage(self, page, _context)
    local nextPage = self:clamp(page, 1, self.totalPages)
    if nextPage == self.page then
        return false
    end
    local ____this_40
    ____this_40 = self.props
    local ____opt_39 = ____this_40.onPageChange
    if ____opt_39 ~= nil then
        ____opt_39(____this_40, nextPage)
    end
    return true
end
function PaginationComponent.prototype.getDisplayText(self, style)
    local parts = {}
    if style.showFirstLast then
        parts[#parts + 1] = "<<"
    end
    if style.showPrevNext then
        parts[#parts + 1] = "<"
    end
    parts[#parts + 1] = (tostring(self.page) .. "/") .. tostring(self.totalPages)
    if style.showPrevNext then
        parts[#parts + 1] = ">"
    end
    if style.showFirstLast then
        parts[#parts + 1] = ">>"
    end
    return table.concat(parts, " ")
end
function PaginationComponent.prototype.resolveTargetPageFromX(self, x)
    local relativeX = x - self.rect.x
    local width = math.max(1, self.rect.width)
    if relativeX < math.floor(width * 0.25) then
        return math.max(1, self.page - 1)
    end
    if relativeX >= math.ceil(width * 0.75) then
        return math.min(self.totalPages, self.page + 1)
    end
    return self.page
end
__TS__SetDescriptor(
    PaginationComponent.prototype,
    "totalPages",
    {get = function(self)
        if self.props.pageSize <= 0 then
            return 1
        end
        return math.max(
            1,
            math.ceil(self.props.totalItems / self.props.pageSize)
        )
    end},
    true
)
__TS__SetDescriptor(
    PaginationComponent.prototype,
    "page",
    {get = function(self)
        return self:clamp(self.props.page, 1, self.totalPages)
    end},
    true
)
return ____exports
