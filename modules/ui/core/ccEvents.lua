--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local ____types = require("modules.ui.types.index")
local UIEvent = ____types.UIEvent
function ____exports.toUIEvent(self, raw, options)
    if options == nil then
        options = {}
    end
    local name = raw[1]
    local onMonitor = options.monitor ~= nil
    repeat
        local ____switch3 = name
        local ____cond3 = ____switch3 == "mouse_click" or ____switch3 == "mouse_drag" or ____switch3 == "mouse_up"
        if ____cond3 then
            if onMonitor then
                return nil
            end
            return {type = name, button = raw[2], x = raw[3], y = raw[4]}
        end
        ____cond3 = ____cond3 or ____switch3 == "monitor_touch"
        if ____cond3 then
            if not onMonitor or raw[2] ~= options.monitor then
                return nil
            end
            return {type = "monitor_touch", x = raw[3], y = raw[4]}
        end
        ____cond3 = ____cond3 or ____switch3 == "mouse_scroll"
        if ____cond3 then
            if onMonitor then
                return nil
            end
            return {type = "mouse_scroll", direction = raw[2] < 0 and -1 or 1, x = raw[3], y = raw[4]}
        end
        ____cond3 = ____cond3 or ____switch3 == "key"
        if ____cond3 then
            return {type = "key", key = raw[2], held = raw[3] == true}
        end
        ____cond3 = ____cond3 or ____switch3 == "key_up"
        if ____cond3 then
            return {type = "key_up", key = raw[2]}
        end
        ____cond3 = ____cond3 or ____switch3 == "char"
        if ____cond3 then
            return {type = "char", char = raw[2]}
        end
        ____cond3 = ____cond3 or ____switch3 == "paste"
        if ____cond3 then
            return {type = "paste", text = raw[2]}
        end
        ____cond3 = ____cond3 or ____switch3 == "timer"
        if ____cond3 then
            return {type = "timer", timerId = raw[2]}
        end
        do
            return nil
        end
    until true
end
return ____exports
