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
local BaseContainerComponent = ____ui.BaseContainerComponent
local ____types = require("modules.ui.types.index")
local BaseProps = ____types.BaseProps
local ComponentDependencies = ____types.ComponentDependencies
local ComponentKind = ____types.ComponentKind
local InvalidationRequest = ____types.InvalidationRequest
local LayoutConstraints = ____types.LayoutConstraints
local MeasuredSize = ____types.MeasuredSize
local Point = ____types.Point
local RenderContext = ____types.RenderContext
local UIContext = ____types.UIContext
local UIEvent = ____types.UIEvent
local UIInteractiveComponent = ____types.UIInteractiveComponent
____exports.InteractiveContainerComponent = __TS__Class()
local InteractiveContainerComponent = ____exports.InteractiveContainerComponent
InteractiveContainerComponent.name = "InteractiveContainerComponent"
__TS__ClassExtends(InteractiveContainerComponent, BaseContainerComponent)
function InteractiveContainerComponent.prototype.____constructor(self, kind, props, dependencies, children)
    if dependencies == nil then
        dependencies = {}
    end
    if children == nil then
        children = {}
    end
    BaseContainerComponent.prototype.____constructor(
        self,
        kind,
        props,
        dependencies,
        children
    )
    self.eventBus = self.dependencies.eventBus
end
function InteractiveContainerComponent.prototype.hitTest(self, point)
    if not self:isVisibleAndEnabled() then
        return false
    end
    if self:isPointInsideRect(point, self.rect) then
        return true
    end
    do
        local index = #self.internalChildren - 1
        while index >= 0 do
            local child = self.internalChildren[index + 1]
            if child and child:hitTest(point) then
                return true
            end
            index = index - 1
        end
    end
    return false
end
function InteractiveContainerComponent.prototype.dispatch(self, event, context)
    if not self:isVisibleAndEnabled() then
        return nil
    end
    if event.targetId and event.targetId ~= self.id then
        do
            local index = #self.internalChildren - 1
            while index >= 0 do
                do
                    local child = self.internalChildren[index + 1]
                    if not child then
                        goto __continue13
                    end
                    local childResult = child:dispatch(event, context)
                    if childResult then
                        return childResult
                    end
                end
                ::__continue13::
                index = index - 1
            end
        end
        return nil
    end
    local childResult = self:dispatchToChildren(event, context)
    if childResult then
        return childResult
    end
    return self:handleEvent(event, context)
end
function InteractiveContainerComponent.prototype.dispatchToChildren(self, event, context)
    do
        local index = #self.internalChildren - 1
        while index >= 0 do
            do
                local child = self.internalChildren[index + 1]
                if not child or not child.visible or child.disabled then
                    goto __continue19
                end
                if event.x ~= nil and event.y ~= nil and not child:hitTest({x = event.x, y = event.y}) then
                    goto __continue19
                end
                local result = child:dispatch(event, context)
                if result then
                    return result
                end
            end
            ::__continue19::
            index = index - 1
        end
    end
    return nil
end
function InteractiveContainerComponent.prototype.handleEvent(self, _event, _context)
    return nil
end
function InteractiveContainerComponent.prototype.createEventInvalidation(self, reason)
    if reason == nil then
        reason = "event"
    end
    return {reason = reason, kind = "region", rect = self.rect}
end
function InteractiveContainerComponent.prototype.createStateInvalidation(self)
    return {reason = "state", kind = "region", rect = self.rect}
end
return ____exports
