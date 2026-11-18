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
-- End of Lua Library inline imports
local ____exports = {}
local ____coreComponent = require("modules.ui.core.components.coreComponent")
local BaseComponent = ____coreComponent.BaseComponent
local ____renderHelpers = require("modules.ui.render.renderHelpers")
local drawHorizontalLine = ____renderHelpers.drawHorizontalLine
local drawText = ____renderHelpers.drawText
local DrawTextOptions = ____renderHelpers.DrawTextOptions
local ____surfaceAdapter = require("modules.ui.render.surfaceAdapter")
local UIDrawSurface = ____surfaceAdapter.UIDrawSurface
local ____theme = require("modules.ui.theme.theme")
local getRuleCharacter = ____theme.getRuleCharacter
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
    local width = self.props.width or self.props.minWidth or math.max(#label > 0 and #label + 2 or 1, constraints.maxWidth)
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
    local character = style.character or getRuleCharacter(nil, context.theme)
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
            local ____self_30 = createOptions(
                nil,
                __TS__ObjectAssign({}, themeStyle)
            ):with(
                "character",
                themeStyle.character or getRuleCharacter(nil, context.theme)
            ):with("foregroundColor", self.props.foregroundColor or themeStyle.foregroundColor or context.theme.palette.border):with("backgroundColor", self.props.backgroundColor or themeStyle.backgroundColor)
            local ____self_30_with_31 = ____self_30.with
            local ____self_24 = createOptions(
                nil,
                __TS__ObjectAssign({}, themeStyle.labelStyle or ({}))
            )
            local ____self_24_with_25 = ____self_24.with
            local ____opt_22 = themeStyle.labelStyle
            local ____self_21 = ____self_24_with_25(____self_24, "alignment", ____opt_22 and ____opt_22.alignment or "center")
            local ____self_21_with_26 = ____self_21.with
            local ____opt_19 = themeStyle.labelStyle
            local ____self_18 = ____self_21_with_26(____self_21, "wrap", ____opt_19 and ____opt_19.wrap or "none")
            local ____self_18_with_27 = ____self_18.with
            local ____opt_15 = themeStyle.labelStyle
            local ____temp_17 = ____opt_15 and ____opt_15.ellipsis
            if ____temp_17 == nil then
                ____temp_17 = true
            end
            local ____self_14 = ____self_18_with_27(____self_18, "ellipsis", ____temp_17)
            local ____self_14_with_28 = ____self_14.with
            local ____self_props_foregroundColor_13 = self.props.foregroundColor
            if ____self_props_foregroundColor_13 == nil then
                local ____opt_11 = themeStyle.labelStyle
                ____self_props_foregroundColor_13 = ____opt_11 and ____opt_11.foregroundColor
            end
            local ____self_10 = ____self_14_with_28(____self_14, "foregroundColor", ____self_props_foregroundColor_13 or themeStyle.foregroundColor or context.theme.palette.text)
            local ____self_10_with_29 = ____self_10.with
            local ____self_props_backgroundColor_9 = self.props.backgroundColor
            if ____self_props_backgroundColor_9 == nil then
                local ____opt_7 = themeStyle.labelStyle
                ____self_props_backgroundColor_9 = ____opt_7 and ____opt_7.backgroundColor
            end
            return ____self_30_with_31(
                ____self_30,
                "labelStyle",
                ____self_10_with_29(____self_10, "backgroundColor", ____self_props_backgroundColor_9 or themeStyle.backgroundColor):done()
            ):done()
        end
    )
end
return ____exports
