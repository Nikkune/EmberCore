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
local FocusableComponent = ____ui.FocusableComponent
local ____types = require("modules.ui.types.index")
local BaseProps = ____types.BaseProps
local ComponentDependencies = ____types.ComponentDependencies
local ComponentKind = ____types.ComponentKind
local InvalidationRequest = ____types.InvalidationRequest
local LayoutConstraints = ____types.LayoutConstraints
local MeasuredSize = ____types.MeasuredSize
local RenderContext = ____types.RenderContext
local UIContext = ____types.UIContext
local UIEvent = ____types.UIEvent
local UIPressableComponent = ____types.UIPressableComponent
____exports.PressableComponent = __TS__Class()
local PressableComponent = ____exports.PressableComponent
PressableComponent.name = "PressableComponent"
__TS__ClassExtends(PressableComponent, FocusableComponent)
function PressableComponent.prototype.____constructor(self, kind, props, dependencies)
    if dependencies == nil then
        dependencies = {}
    end
    FocusableComponent.prototype.____constructor(self, kind, props, dependencies)
end
function PressableComponent.prototype.press(self, context)
    return self:onPress(context)
end
function PressableComponent.prototype.handleEvent(self, event, context)
    repeat
        local ____switch5 = event.type
        local ____cond5 = ____switch5 == "mouse_click" or ____switch5 == "monitor_touch"
        if ____cond5 then
            do
                self:focus()
                local changed = self:press(context)
                if not changed then
                    return nil
                end
                return self:createStateInvalidation()
            end
        end
        do
            return nil
        end
    until true
end
function PressableComponent.prototype.onPress(self, _context)
    return false
end
return ____exports
