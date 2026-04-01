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
-- End of Lua Library inline imports
local ____exports = {}
local ____ui = require("modules.ui.index")
local BaseComponent = ____ui.BaseComponent
local drawText = ____ui.drawText
local DrawTextOptions = ____ui.DrawTextOptions
local resolveTextLines = ____ui.resolveTextLines
local UIDrawSurface = ____ui.UIDrawSurface
local ____types = require("modules.ui.types.index")
local ComponentDependencies = ____types.ComponentDependencies
local LabelProps = ____types.LabelProps
local LabelStyle = ____types.LabelStyle
local LayoutConstraints = ____types.LayoutConstraints
local MeasuredSize = ____types.MeasuredSize
local RenderContext = ____types.RenderContext
local UIContext = ____types.UIContext
local ____helpers = require("utils.helpers")
local createOptions = ____helpers.createOptions
____exports.LabelComponent = __TS__Class()
local LabelComponent = ____exports.LabelComponent
LabelComponent.name = "LabelComponent"
__TS__ClassExtends(LabelComponent, BaseComponent)
function LabelComponent.prototype.____constructor(self, props, dependencies)
    if dependencies == nil then
        dependencies = {}
    end
    BaseComponent.prototype.____constructor(self, "label", props, dependencies)
end
function LabelComponent.prototype.measure(self, constraints, context)
    local style = self:getResolvedStyle(context)
    local width = self.props.width or self.props.minWidth or constraints.maxWidth
    local lines = resolveTextLines(
        nil,
        {
            text = self.props.text,
            width = math.max(0, width),
            style = style
        }
    )
    local contentWidth = __TS__ArrayReduce(
        lines,
        function(____, max, line) return math.max(max, #line.text) end,
        0
    )
    local contentHeight = math.max(1, #lines)
    return self:createMeasuredSize(self.props.width or self.props.minWidth or contentWidth, self.props.height or self.props.minHeight or contentHeight, constraints)
end
function LabelComponent.prototype.render(self, context)
    if not self.visible then
        return
    end
    if self.width <= 0 or self.height <= 0 then
        return
    end
    local style = self:getResolvedStyle(context)
    drawText(
        nil,
        context,
        createOptions(nil, {rect = self.rect, text = self.props.text, style = style, fillBackground = style.backgroundColor ~= nil}):with("clipRect", context.clipRect):done()
    )
end
function LabelComponent.prototype.getResolvedStyle(self, context)
    return self:getStyle(
        context,
        createOptions(nil, {}):with("foregroundColor", self.props.foregroundColor):with("backgroundColor", self.props.backgroundColor):done()
    )
end
return ____exports
