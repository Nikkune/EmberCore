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

local function __TS__ArrayMap(self, callbackfn, thisArg)
    local result = {}
    for i = 1, #self do
        result[i] = callbackfn(thisArg, self[i], i - 1, self)
    end
    return result
end

local function __TS__ArrayFilter(self, callbackfn, thisArg)
    local result = {}
    local len = 0
    for i = 1, #self do
        if callbackfn(thisArg, self[i], i - 1, self) then
            len = len + 1
            result[len] = self[i]
        end
    end
    return result
end

local function __TS__CountVarargs(...)
    return select("#", ...)
end

local function __TS__ArraySplice(self, ...)
    local args = {...}
    local len = #self
    local actualArgumentCount = __TS__CountVarargs(...)
    local start = args[1]
    local deleteCount = args[2]
    if start < 0 then
        start = len + start
        if start < 0 then
            start = 0
        end
    elseif start > len then
        start = len
    end
    local itemCount = actualArgumentCount - 2
    if itemCount < 0 then
        itemCount = 0
    end
    local actualDeleteCount
    if actualArgumentCount == 0 then
        actualDeleteCount = 0
    elseif actualArgumentCount == 1 then
        actualDeleteCount = len - start
    else
        actualDeleteCount = deleteCount or 0
        if actualDeleteCount < 0 then
            actualDeleteCount = 0
        end
        if actualDeleteCount > len - start then
            actualDeleteCount = len - start
        end
    end
    local out = {}
    for k = 1, actualDeleteCount do
        local from = start + k
        if self[from] ~= nil then
            out[k] = self[from]
        end
    end
    if itemCount < actualDeleteCount then
        for k = start + 1, len - actualDeleteCount do
            local from = k + actualDeleteCount
            local to = k + itemCount
            if self[from] then
                self[to] = self[from]
            else
                self[to] = nil
            end
        end
        for k = len - actualDeleteCount + itemCount + 1, len do
            self[k] = nil
        end
    elseif itemCount > actualDeleteCount then
        for k = len - actualDeleteCount, start + 1, -1 do
            local from = k + actualDeleteCount
            local to = k + itemCount
            if self[from] then
                self[to] = self[from]
            else
                self[to] = nil
            end
        end
    end
    local j = start + 1
    for i = 3, actualArgumentCount do
        self[j] = args[i]
        j = j + 1
    end
    for k = #self, len - actualDeleteCount + itemCount + 1, -1 do
        self[k] = nil
    end
    return out
end

local function __TS__ArraySetLength(self, length)
    if length < 0 or length ~= length or length == math.huge or math.floor(length) ~= length then
        error(
            "invalid array length: " .. tostring(length),
            0
        )
    end
    for i = length + 1, #self do
        self[i] = nil
    end
    return length
end

local function __TS__ArrayPushArray(self, items)
    local len = #self
    for i = 1, #items do
        len = len + 1
        self[len] = items[i]
    end
    return len
end
-- End of Lua Library inline imports
local ____exports = {}
local ____types = require("modules.ui.types.index")
local DirtyRegion = ____types.DirtyRegion
local InvalidationRequest = ____types.InvalidationRequest
local LayoutConstraints = ____types.LayoutConstraints
local Rect = ____types.Rect
local RenderContext = ____types.RenderContext
local RuntimeSurface = ____types.RuntimeSurface
local SurfaceKind = ____types.SurfaceKind
local Theme = ____types.Theme
local UIContext = ____types.UIContext
local UIEvent = ____types.UIEvent
local UIEventBus = ____types.UIEventBus
local UIInteractiveComponent = ____types.UIInteractiveComponent
local UIInvalidator = ____types.UIInvalidator
local UIRenderResult = ____types.UIRenderResult
local ____helpers = require("utils.helpers")
local createOptions = ____helpers.createOptions
____exports.UIRuntime = __TS__Class()
local UIRuntime = ____exports.UIRuntime
UIRuntime.name = "UIRuntime"
function UIRuntime.prototype.____constructor(self, options)
    self.tick = 0
    self.dirty = true
    self.fullRedraw = true
    self.dirtyRegions = {}
    self.root = options.root
    self.eventBus = options.eventBus
    self.theme = options.theme
    self.surface = options.surface
    self.surfaceKind = options.surfaceKind
    self.maxDirtyRegionsBeforeFullRedraw = options.maxDirtyRegionsBeforeFullRedraw or 8
    self.fullRedrawCoverageThreshold = options.fullRedrawCoverageThreshold or 0.6
end
function UIRuntime.prototype.invalidate(self, request)
    if request == nil then
        request = {reason = "manual", kind = "full"}
    end
    self.dirty = true
    local kind = request.kind or (request.rect and "region" or "full")
    if kind == "full" or not request.rect then
        self.fullRedraw = true
        self.dirtyRegions = {}
        return
    end
    local ____self_dirtyRegions_0 = self.dirtyRegions
    ____self_dirtyRegions_0[#____self_dirtyRegions_0 + 1] = self:clampRegionToSurface(request.rect)
end
function UIRuntime.prototype.dispatch(self, event)
    local request = self:dispatchToRoot(event)
    if not request then
        return false
    end
    self.eventBus:dispatch(event)
    self:invalidate(request)
    return true
end
function UIRuntime.prototype.render(self)
    if not self.dirty then
        return {rendered = false, tick = self.tick, fullRedraw = false, dirtyRegions = {}}
    end
    self.tick = self.tick + 1
    local uiContext = self:createUIContext()
    local constraints = self:createRootConstraints()
    local rootRect = self:createRootRect()
    self.root:measure(constraints, uiContext)
    self.root:layout(rootRect, uiContext)
    local dirtyRegions = self:normalizeDirtyRegions(self.dirtyRegions)
    local fullRedraw = self:shouldFullRedraw(dirtyRegions)
    local baseRenderContext = self:createRenderContext()
    if fullRedraw then
        self:clearSurface()
        self.root:render(baseRenderContext)
    else
        self:renderDirtyRegions(baseRenderContext, dirtyRegions)
    end
    local result = {rendered = true, tick = self.tick, fullRedraw = fullRedraw, dirtyRegions = dirtyRegions}
    self.dirty = false
    self.fullRedraw = false
    self.dirtyRegions = {}
    return result
end
function UIRuntime.prototype.forceRender(self)
    self.dirty = true
    self.fullRedraw = true
    return self:render()
end
function UIRuntime.prototype.setTheme(self, theme)
    self.theme = theme
    self:invalidate({reason = "theme", kind = "full"})
end
function UIRuntime.prototype.getTheme(self)
    return self.theme
end
function UIRuntime.prototype.getTick(self)
    return self.tick
end
function UIRuntime.prototype.isDirty(self)
    return self.dirty
end
function UIRuntime.prototype.isFullRedrawPending(self)
    return self.fullRedraw
end
function UIRuntime.prototype.getDirtyRegions(self)
    return {table.unpack(self.dirtyRegions)}
end
function UIRuntime.prototype.getActiveElement(self)
    return self.activeElement
end
function UIRuntime.prototype.setActiveElement(self, elementId)
    self.activeElement = elementId
end
function UIRuntime.prototype.createUIContext(self)
    return createOptions(nil, {theme = self.theme, surface = self.surfaceKind}):with("activeElement", self.activeElement):done()
end
function UIRuntime.prototype.createRenderContext(self)
    return {theme = self.theme, surface = self.surfaceKind, tick = self.tick, draw = self.surface}
end
function UIRuntime.prototype.createRootConstraints(self)
    local ____temp_1 = self.surface:getSize()
    local width = ____temp_1.width
    local height = ____temp_1.height
    return {minWidth = 0, minHeight = 0, maxWidth = width, maxHeight = height}
end
function UIRuntime.prototype.createRootRect(self)
    local ____temp_2 = self.surface:getSize()
    local width = ____temp_2.width
    local height = ____temp_2.height
    return {x = 1, y = 1, width = width, height = height}
end
function UIRuntime.prototype.clearSurface(self)
    if type(self.surface.clear) == "function" then
        self.surface:clear(self.theme.palette.backgroundColor)
    end
end
function UIRuntime.prototype.renderDirtyRegions(self, baseContext, regions)
    for ____, region in ipairs(regions) do
        self.root:render(__TS__ObjectAssign({}, baseContext, {clipRect = region}))
    end
end
function UIRuntime.prototype.shouldFullRedraw(self, regions)
    if self.fullRedraw then
        return true
    end
    if #regions == 0 then
        return true
    end
    if #regions >= self.maxDirtyRegionsBeforeFullRedraw then
        return true
    end
    local ____temp_3 = self.surface:getSize()
    local width = ____temp_3.width
    local height = ____temp_3.height
    local totalSurfaceArea = width * height
    local dirtyArea = self:computeRegionsArea(regions)
    if totalSurfaceArea <= 0 then
        return true
    end
    return dirtyArea / totalSurfaceArea >= self.fullRedrawCoverageThreshold
end
function UIRuntime.prototype.computeRegionsArea(self, regions)
    local total = 0
    for ____, region in ipairs(regions) do
        total = total + math.max(0, region.width) * math.max(0, region.height)
    end
    return total
end
function UIRuntime.prototype.normalizeDirtyRegions(self, regions)
    if #regions == 0 then
        return {}
    end
    local clamped = __TS__ArrayFilter(
        __TS__ArrayMap(
            regions,
            function(____, region) return self:clampRegionToSurface(region) end
        ),
        function(____, region) return region.width > 0 and region.height > 0 end
    )
    if #clamped <= 1 then
        return clamped
    end
    local merged = {}
    for ____, region in ipairs(clamped) do
        self:mergeRegionIntoList(merged, region)
    end
    return merged
end
function UIRuntime.prototype.mergeRegionIntoList(self, regions, nextRegion)
    local current = nextRegion
    local mergedAny = false
    do
        local index = 0
        while index < #regions do
            do
                local existing = regions[index + 1]
                if existing then
                    if not self:regionsOverlapOrTouch(existing, current) then
                        goto __continue46
                    end
                    current = self:mergeRegions(existing, current)
                    __TS__ArraySplice(regions, index, 1)
                    index = index - 1
                    mergedAny = true
                end
            end
            ::__continue46::
            index = index + 1
        end
    end
    regions[#regions + 1] = current
    if mergedAny then
        local normalized = self:normalizeDirtyRegions(regions)
        __TS__ArraySetLength(regions, 0)
        __TS__ArrayPushArray(regions, normalized)
    end
end
function UIRuntime.prototype.regionsOverlapOrTouch(self, a, b)
    local aRight = a.x + a.width - 1
    local aBottom = a.y + a.height - 1
    local bRight = b.x + b.width - 1
    local bBottom = b.y + b.height - 1
    return not (aRight + 1 < b.x or bRight + 1 < a.x or aBottom + 1 < b.y or bBottom + 1 < a.y)
end
function UIRuntime.prototype.mergeRegions(self, a, b)
    local left = math.min(a.x, b.x)
    local top = math.min(a.y, b.y)
    local right = math.max(a.x + a.width - 1, b.x + b.width - 1)
    local bottom = math.max(a.y + a.height - 1, b.y + b.height - 1)
    return {x = left, y = top, width = right - left + 1, height = bottom - top + 1}
end
function UIRuntime.prototype.clampRegionToSurface(self, region)
    local ____temp_4 = self.surface:getSize()
    local surfaceWidth = ____temp_4.width
    local surfaceHeight = ____temp_4.height
    local left = math.max(1, region.x)
    local top = math.max(1, region.y)
    local right = math.min(surfaceWidth, region.x + region.width - 1)
    local bottom = math.min(surfaceHeight, region.y + region.height - 1)
    return {
        x = left,
        y = top,
        width = math.max(0, right - left + 1),
        height = math.max(0, bottom - top + 1)
    }
end
function UIRuntime.prototype.dispatchToRoot(self, event)
    if event.x ~= nil and event.y ~= nil then
        if not self.root:hitTest({x = event.x, y = event.y}) then
            return nil
        end
    end
    local request = self.root:dispatch(
        event,
        self:createUIContext()
    )
    if request and event.targetId then
        self.activeElement = event.targetId
    end
    return request
end
return ____exports
