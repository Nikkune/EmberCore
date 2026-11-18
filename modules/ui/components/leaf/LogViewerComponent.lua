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

local function __TS__SparseArrayNew(...)
    local sparseArray = {...}
    sparseArray.sparseLength = __TS__CountVarargs(...)
    return sparseArray
end

local function __TS__SparseArrayPush(sparseArray, ...)
    local args = {...}
    local argsLen = __TS__CountVarargs(...)
    local listLen = sparseArray.sparseLength
    for i = 1, argsLen do
        sparseArray[listLen + i] = args[i]
    end
    sparseArray.sparseLength = listLen + argsLen
end

local function __TS__SparseArraySpread(sparseArray)
    local _unpack = unpack or table.unpack
    return _unpack(sparseArray, 1, sparseArray.sparseLength)
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
local ____coreComponent = require("modules.ui.core.components.coreComponent")
local BaseComponent = ____coreComponent.BaseComponent
local ____renderHelpers = require("modules.ui.render.renderHelpers")
local drawBox = ____renderHelpers.drawBox
local DrawBoxOptions = ____renderHelpers.DrawBoxOptions
local drawText = ____renderHelpers.drawText
local DrawTextOptions = ____renderHelpers.DrawTextOptions
local ____surfaceAdapter = require("modules.ui.render.surfaceAdapter")
local UIDrawSurface = ____surfaceAdapter.UIDrawSurface
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
function LogViewerComponent.prototype.addEntry(self, entry, maxEntries)
    local ____array_0 = __TS__SparseArrayNew(unpack(self.props.entries))
    __TS__SparseArrayPush(____array_0, entry)
    local entries = {__TS__SparseArraySpread(____array_0)}
    self:setProps({entries = maxEntries ~= nil and __TS__ArraySlice(entries, -maxEntries) or entries})
end
function LogViewerComponent.prototype.clearEntries(self)
    self:setProps({entries = {}})
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
    local ____opt_1 = style.border
    local borderCharacters = ____opt_1 and ____opt_1.enabled and context.theme.borders[style.border.preset or "single"] or nil
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
            local ____self_30 = createOptions(
                nil,
                __TS__ObjectAssign({}, themeStyle)
            ):with("padding", self.props.padding or themeStyle.padding or 0)
            local ____self_30_with_31 = ____self_30.with
            local ____self_24 = createOptions(
                nil,
                __TS__ObjectAssign({}, themeStyle.lineStyle or ({}))
            )
            local ____self_24_with_25 = ____self_24.with
            local ____opt_22 = themeStyle.lineStyle
            local ____self_21 = ____self_24_with_25(____self_24, "alignment", ____opt_22 and ____opt_22.alignment or "left")
            local ____self_21_with_26 = ____self_21.with
            local ____opt_19 = themeStyle.lineStyle
            local ____self_18 = ____self_21_with_26(____self_21, "wrap", ____opt_19 and ____opt_19.wrap or "none")
            local ____self_18_with_27 = ____self_18.with
            local ____opt_15 = themeStyle.lineStyle
            local ____temp_17 = ____opt_15 and ____opt_15.ellipsis
            if ____temp_17 == nil then
                ____temp_17 = true
            end
            local ____self_14 = ____self_18_with_27(____self_18, "ellipsis", ____temp_17)
            local ____self_14_with_28 = ____self_14.with
            local ____self_props_foregroundColor_13 = self.props.foregroundColor
            if ____self_props_foregroundColor_13 == nil then
                local ____opt_11 = themeStyle.lineStyle
                ____self_props_foregroundColor_13 = ____opt_11 and ____opt_11.foregroundColor
            end
            local ____self_10 = ____self_14_with_28(____self_14, "foregroundColor", ____self_props_foregroundColor_13 or context.theme.palette.text)
            local ____self_10_with_29 = ____self_10.with
            local ____self_props_backgroundColor_9 = self.props.backgroundColor
            if ____self_props_backgroundColor_9 == nil then
                local ____opt_7 = themeStyle.lineStyle
                ____self_props_backgroundColor_9 = ____opt_7 and ____opt_7.backgroundColor
            end
            local ____self_6 = ____self_30_with_31(
                ____self_30,
                "lineStyle",
                ____self_10_with_29(____self_10, "backgroundColor", ____self_props_backgroundColor_9 or themeStyle.backgroundColor):done()
            )
            local ____self_6_with_32 = ____self_6.with
            local ____themeStyle_showTimestamp_5 = themeStyle.showTimestamp
            if ____themeStyle_showTimestamp_5 == nil then
                ____themeStyle_showTimestamp_5 = true
            end
            local ____self_4 = ____self_6_with_32(____self_6, "showTimestamp", ____themeStyle_showTimestamp_5)
            local ____self_4_with_33 = ____self_4.with
            local ____themeStyle_autoScroll_3 = themeStyle.autoScroll
            if ____themeStyle_autoScroll_3 == nil then
                ____themeStyle_autoScroll_3 = true
            end
            return ____self_4_with_33(____self_4, "autoScroll", ____themeStyle_autoScroll_3):done()
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
    local ____opt_34 = style.levelColors
    local levelForeground = ____opt_34 and ____opt_34[entry.level]
    local ____temp_39 = style.lineStyle or ({})
    local ____levelForeground_38 = levelForeground
    if ____levelForeground_38 == nil then
        local ____opt_36 = style.lineStyle
        ____levelForeground_38 = ____opt_36 and ____opt_36.foregroundColor
    end
    return __TS__ObjectAssign({}, ____temp_39, {foregroundColor = ____levelForeground_38 or context.theme.palette.text})
end
return ____exports
