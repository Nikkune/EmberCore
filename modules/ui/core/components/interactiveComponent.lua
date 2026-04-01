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
local ____coreComponent = require("modules.ui.core.components.coreComponent")
local BaseComponent = ____coreComponent.BaseComponent
local ____types = require("modules.ui.types.index")
local BaseProps = ____types.BaseProps
local ComponentDependencies = ____types.ComponentDependencies
local ComponentKind = ____types.ComponentKind
local InvalidationRequest = ____types.InvalidationRequest
local LayoutConstraints = ____types.LayoutConstraints
local MeasuredSize = ____types.MeasuredSize
local Point = ____types.Point
local Rect = ____types.Rect
local RenderContext = ____types.RenderContext
local UIContext = ____types.UIContext
local UIEvent = ____types.UIEvent
local UIInteractiveComponent = ____types.UIInteractiveComponent
____exports.InteractiveComponent = __TS__Class()
local InteractiveComponent = ____exports.InteractiveComponent
InteractiveComponent.name = "InteractiveComponent"
__TS__ClassExtends(InteractiveComponent, BaseComponent)
function InteractiveComponent.prototype.____constructor(self, kind, props, dependencies)
    if dependencies == nil then
        dependencies = {}
    end
    BaseComponent.prototype.____constructor(self, kind, props, dependencies)
    self.eventBus = self.dependencies.eventBus
end
function InteractiveComponent.prototype.hitTest(self, point)
    if not self:isVisibleAndEnabled() then
        return false
    end
    return self:isPointInsideRect(point, self.rect)
end
function InteractiveComponent.prototype.dispatch(self, event, context)
    if not self:isVisibleAndEnabled() then
        return nil
    end
    if event.targetId and event.targetId ~= self.id then
        return nil
    end
    if not self:isEventInside(event) then
        return nil
    end
    return self:handleEvent(event, context)
end
function InteractiveComponent.prototype.handleEvent(self, _event, _context)
    return nil
end
function InteractiveComponent.prototype.createEventInvalidation(self, rect)
    return {reason = "event", kind = "region", rect = rect or self.rect}
end
function InteractiveComponent.prototype.createStateInvalidation(self, rect)
    return {reason = "state", kind = "region", rect = rect or self.rect}
end
function InteractiveComponent.prototype.isEventInside(self, event)
    if not (event.x ~= nil and event.y ~= nil) then
        return true
    end
    return self:hitTest({x = event.x, y = event.y})
end
return ____exports
