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

local function __TS__ArraySlice(self, first, last)
    local len = #self
    first = first or 0
    if first < 0 then
        first = len + first
        if first < 0 then
            first = 0
        end
    else
        if first > len then
            first = len
        end
    end
    last = last or len
    if last < 0 then
        last = len + last
        if last < 0 then
            last = 0
        end
    else
        if last > len then
            last = len
        end
    end
    local out = {}
    first = first + 1
    last = last + 1
    local n = 1
    while first < last do
        out[n] = self[first]
        first = first + 1
        n = n + 1
    end
    return out
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
local ____ui = require("modules.ui.index")
local BaseComponent = ____ui.BaseComponent
local drawBox = ____ui.drawBox
local DrawBoxOptions = ____ui.DrawBoxOptions
local drawText = ____ui.drawText
local DrawTextOptions = ____ui.DrawTextOptions
local UIDrawSurface = ____ui.UIDrawSurface
local ____types = require("modules.ui.types.index")
local ComponentDependencies = ____types.ComponentDependencies
local LayoutConstraints = ____types.LayoutConstraints
local LogEntry = ____types.LogEntry
local LogViewerProps = ____types.LogViewerProps
local LogViewerStyle = ____types.LogViewerStyle
local MeasuredSize = ____types.MeasuredSize
local RenderContext = ____types.RenderContext
local TextStyle = ____types.TextStyle
local UIContext = ____types.UIContext
local ____helpers = require("utils.helpers")
local createOptions = ____helpers.createOptions
____exports.LogViewerComponent = __TS__Class()
local LogViewerComponent = ____exports.LogViewerComponent
LogViewerComponent.name = "LogViewerComponent"
__TS__ClassExtends(LogViewerComponent, BaseComponent)
function LogViewerComponent.prototype.____constructor(self, props, dependencies)
    if dependencies == nil then
        dependencies = {}
    end
    BaseComponent.prototype.____constructor(self, "log_viewer", props, dependencies)
end
function LogViewerComponent.prototype.measure(self, constraints, _context)
    local width = self.props.width or self.props.minWidth or constraints.maxWidth
    local height = self.props.height or self.props.minHeight or math.min(
        math.max(1, #self.props.entries),
        constraints.maxHeight
    )
    return self:createMeasuredSize(width, height, constraints)
end
function LogViewerComponent.prototype.render(self, context)
    if not self.visible then
        return
    end
    if self.width <= 0 or self.height <= 0 then
        return
    end
    local style = self:getResolvedStyle(context)
    local ____opt_0 = style.border
    local borderCharacters = ____opt_0 and ____opt_0.enabled and context.theme.borders[style.border.preset or "single"] or nil
    local innerRect = drawBox(
        nil,
        context.draw,
        createOptions(nil, {rect = self.rect, style = style}):with("borderCharacters", borderCharacters):with("clipRect", context.clipRect):done()
    )
    if innerRect.width <= 0 or innerRect.height <= 0 then
        return
    end
    local visibleEntries = self:getVisibleEntries(innerRect.height, style)
    do
        local index = 0
        while index < #visibleEntries do
            local entry = visibleEntries[index + 1]
            local lineStyle = self:getEntryTextStyle(style, entry, context)
            drawText(
                nil,
                context,
                createOptions(
                    nil,
                    {
                        rect = {x = innerRect.x, y = innerRect.y + index, width = innerRect.width, height = 1},
                        text = self:formatEntry(entry, style),
                        fillBackground = lineStyle.backgroundColor ~= nil
                    }
                ):with("style", lineStyle):with("clipRect", context.clipRect):done()
            )
            index = index + 1
        end
    end
end
function LogViewerComponent.prototype.getResolvedStyle(self, context)
    return self:getStyle(
        context,
        function(____, themeStyle)
            local ____self_27 = createOptions(nil, themeStyle):with("padding", themeStyle.padding or 0)
            local ____self_27_with_28 = ____self_27.with
            local ____self_21 = createOptions(nil, themeStyle.lineStyle or ({}))
            local ____self_21_with_22 = ____self_21.with
            local ____opt_19 = themeStyle.lineStyle
            local ____self_18 = ____self_21_with_22(____self_21, "alignment", ____opt_19 and ____opt_19.alignment or "left")
            local ____self_18_with_23 = ____self_18.with
            local ____opt_16 = themeStyle.lineStyle
            local ____self_15 = ____self_18_with_23(____self_18, "wrap", ____opt_16 and ____opt_16.wrap or "none")
            local ____self_15_with_24 = ____self_15.with
            local ____opt_12 = themeStyle.lineStyle
            local ____temp_14 = ____opt_12 and ____opt_12.ellipsis
            if ____temp_14 == nil then
                ____temp_14 = true
            end
            local ____self_11 = ____self_15_with_24(____self_15, "ellipsis", ____temp_14)
            local ____self_11_with_25 = ____self_11.with
            local ____opt_9 = themeStyle.lineStyle
            local ____self_8 = ____self_11_with_25(____self_11, "foregroundColor", ____opt_9 and ____opt_9.foregroundColor or self.props.foregroundColor or context.theme.palette.text)
            local ____self_8_with_26 = ____self_8.with
            local ____opt_6 = themeStyle.lineStyle
            local ____self_5 = ____self_27_with_28(
                ____self_27,
                "lineStyle",
                ____self_8_with_26(____self_8, "backgroundColor", ____opt_6 and ____opt_6.backgroundColor or self.props.backgroundColor or themeStyle.backgroundColor):done()
            )
            local ____self_5_with_29 = ____self_5.with
            local ____themeStyle_showTimestamp_4 = themeStyle.showTimestamp
            if ____themeStyle_showTimestamp_4 == nil then
                ____themeStyle_showTimestamp_4 = true
            end
            local ____self_3 = ____self_5_with_29(____self_5, "showTimestamp", ____themeStyle_showTimestamp_4)
            local ____self_3_with_30 = ____self_3.with
            local ____themeStyle_autoScroll_2 = themeStyle.autoScroll
            if ____themeStyle_autoScroll_2 == nil then
                ____themeStyle_autoScroll_2 = true
            end
            return ____self_3_with_30(____self_3, "autoScroll", ____themeStyle_autoScroll_2):done()
        end
    )
end
function LogViewerComponent.prototype.getVisibleEntries(self, maxLines, style)
    if maxLines <= 0 then
        return {}
    end
    local entries = self.props.entries
    local scrollOffset = math.max(0, self.props.scrollOffset or 0)
    local startIndex = 0
    if style.autoScroll then
        startIndex = math.max(0, #entries - maxLines - scrollOffset)
    else
        startIndex = math.min(
            scrollOffset,
            math.max(0, #entries - 1)
        )
    end
    return __TS__ArraySlice(entries, startIndex, startIndex + maxLines)
end
function LogViewerComponent.prototype.formatEntry(self, entry, style)
    local parts = {}
    if style.showTimestamp and entry.timestamp then
        parts[#parts + 1] = ("[" .. entry.timestamp) .. "]"
    end
    parts[#parts + 1] = string.upper(entry.level)
    parts[#parts + 1] = entry.message
    return table.concat(parts, " ")
end
function LogViewerComponent.prototype.getEntryTextStyle(self, style, entry, context)
    local ____opt_31 = style.levelColors
    local levelForeground = ____opt_31 and ____opt_31[entry.level]
    local ____style_lineStyle_36 = style.lineStyle
    local ____levelForeground_35 = levelForeground
    if ____levelForeground_35 == nil then
        local ____opt_33 = style.lineStyle
        ____levelForeground_35 = ____opt_33 and ____opt_33.foregroundColor
    end
    return __TS__ObjectAssign({}, ____style_lineStyle_36, {foregroundColor = ____levelForeground_35 or context.theme.palette.text})
end
return ____exports
