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
-- End of Lua Library inline imports
local ____exports = {}
local ____ui = require("modules.ui.index")
local BaseComponent = ____ui.BaseComponent
local drawHorizontalLine = ____ui.drawHorizontalLine
local drawText = ____ui.drawText
local DrawTextOptions = ____ui.DrawTextOptions
local UIDrawSurface = ____ui.UIDrawSurface
local ____types = require("modules.ui.types.index")
local ComponentDependencies = ____types.ComponentDependencies
local LayoutConstraints = ____types.LayoutConstraints
local MeasuredSize = ____types.MeasuredSize
local RenderContext = ____types.RenderContext
local SeparatorProps = ____types.SeparatorProps
local SeparatorStyle = ____types.SeparatorStyle
local TextStyle = ____types.TextStyle
local UIContext = ____types.UIContext
local ____helpers = require("utils.helpers")
local createOptions = ____helpers.createOptions
____exports.SeparatorComponent = __TS__Class()
local SeparatorComponent = ____exports.SeparatorComponent
SeparatorComponent.name = "SeparatorComponent"
__TS__ClassExtends(SeparatorComponent, BaseComponent)
function SeparatorComponent.prototype.____constructor(self, props, dependencies)
    if dependencies == nil then
        dependencies = {}
    end
    BaseComponent.prototype.____constructor(self, "separator", props, dependencies)
end
function SeparatorComponent.prototype.measure(self, constraints, _context)
    local label = self.props.label or ""
    local width = self.props.width or self.props.minWidth or math.max(1, #label)
    local height = self.props.height or self.props.minHeight or 1
    return self:createMeasuredSize(width, height, constraints)
end
function SeparatorComponent.prototype.render(self, context)
    if not self.visible then
        return
    end
    if self.width <= 0 or self.height <= 0 then
        return
    end
    local style = self:getResolvedStyle(context)
    local y = self.y + math.floor((self.height - 1) / 2)
    local character = style.character or "─"
    drawHorizontalLine(
        nil,
        context.draw,
        {x = self.x, y = y},
        self.width,
        character,
        style.foregroundColor,
        style.backgroundColor,
        context.clipRect
    )
    local label = self.props.label or ""
    if #label == 0 or self.width <= 0 then
        return
    end
    local textWidth = math.min(self.width, #label + 2)
    local textX = self.x + math.max(
        0,
        math.floor((self.width - textWidth) / 2)
    )
    local ____drawText_6 = drawText
    local ____context_5 = context
    local ____createOptions_4 = createOptions
    local ____temp_2 = {x = textX, y = y, width = textWidth, height = 1}
    local ____temp_3 = (" " .. label) .. " "
    local ____opt_0 = style.labelStyle
    ____drawText_6(
        nil,
        ____context_5,
        ____createOptions_4(nil, {rect = ____temp_2, text = ____temp_3, fillBackground = (____opt_0 and ____opt_0.backgroundColor) ~= nil or style.backgroundColor ~= nil}):with("style", style.labelStyle):with("clipRect", context.clipRect):done()
    )
end
function SeparatorComponent.prototype.getResolvedStyle(self, context)
    return self:getStyle(
        context,
        function(____, themeStyle)
            local ____self_28 = createOptions(nil, themeStyle):with("character", themeStyle.character or "─"):with("foregroundColor", self.props.foregroundColor or themeStyle.foregroundColor or context.theme.palette.border):with("backgroundColor", self.props.backgroundColor or themeStyle.backgroundColor)
            local ____self_28_with_29 = ____self_28.with
            local ____self_22 = createOptions(nil, themeStyle.labelStyle or ({}))
            local ____self_22_with_23 = ____self_22.with
            local ____opt_20 = themeStyle.labelStyle
            local ____self_19 = ____self_22_with_23(____self_22, "alignment", ____opt_20 and ____opt_20.alignment or "center")
            local ____self_19_with_24 = ____self_19.with
            local ____opt_17 = themeStyle.labelStyle
            local ____self_16 = ____self_19_with_24(____self_19, "wrap", ____opt_17 and ____opt_17.wrap or "none")
            local ____self_16_with_25 = ____self_16.with
            local ____opt_13 = themeStyle.labelStyle
            local ____temp_15 = ____opt_13 and ____opt_13.ellipsis
            if ____temp_15 == nil then
                ____temp_15 = true
            end
            local ____self_12 = ____self_16_with_25(____self_16, "ellipsis", ____temp_15)
            local ____self_12_with_26 = ____self_12.with
            local ____opt_10 = themeStyle.labelStyle
            local ____self_9 = ____self_12_with_26(____self_12, "foregroundColor", ____opt_10 and ____opt_10.foregroundColor or self.props.foregroundColor or themeStyle.foregroundColor or context.theme.palette.text)
            local ____self_9_with_27 = ____self_9.with
            local ____opt_7 = themeStyle.labelStyle
            return ____self_28_with_29(
                ____self_28,
                "labelStyle",
                ____self_9_with_27(____self_9, "backgroundColor", ____opt_7 and ____opt_7.backgroundColor or self.props.backgroundColor or themeStyle.backgroundColor):done()
            ):done()
        end
    )
end
return ____exports
