--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
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

local function __TS__New(target, ...)
    local instance = setmetatable({}, target.prototype)
    instance:____constructor(...)
    return instance
end

local function __TS__StringSubstring(self, start, ____end)
    if ____end ~= ____end then
        ____end = 0
    end
    if ____end ~= nil and start > ____end then
        start, ____end = ____end, start
    end
    if start >= 0 then
        start = start + 1
    else
        start = 1
    end
    if ____end ~= nil and ____end < 0 then
        ____end = 0
    end
    return string.sub(self, start, ____end)
end
-- End of Lua Library inline imports
local ____exports = {}
local ____peripheral = require("core.peripheral")
local Peripheral = ____peripheral.Peripheral
local ____index = require("modules.net.index")
local Channel = ____index.Channel
local ____index = require("modules.ui.index")
local BasicUIEventBus = ____index.BasicUIEventBus
local ComputerCraftSurfaceAdapter = ____index.ComputerCraftSurfaceAdapter
local defaultTheme = ____index.defaultTheme
local UIRuntime = ____index.UIRuntime
local ____surfaceAdapter = require("modules.ui.render.surfaceAdapter")
local TerminalLike = ____surfaceAdapter.TerminalLike
local UIDrawSurface = ____surfaceAdapter.UIDrawSurface
local ____types = require("modules.ui.types.index")
local Theme = ____types.Theme
local ____protocol = require("projects.smeltery.shared.protocol")
local CONTROLLER_HOSTNAME = ____protocol.CONTROLLER_HOSTNAME
local Messages = ____protocol.Messages
local PROTOCOL = ____protocol.PROTOCOL
local ____protocol = require("projects.smeltery.shared.protocol")
local SmelteryState = ____protocol.SmelteryState
local ____screen = require("projects.smeltery.display.screen")
local SmelteryScreen = ____screen.SmelteryScreen
local THEME = __TS__ObjectAssign(
    {},
    defaultTheme,
    {components = __TS__ObjectAssign({}, defaultTheme.components, {button = {border = {enabled = false}}, pagination = {showFirstLast = false}})}
)
function ____exports.runDisplay()
    local screen
    local monitorName = Peripheral:findNameByType("monitor")
    if monitorName == nil then
        print("No monitor found next to this computer.")
        return
    end
    local monitor = peripheral.wrap(monitorName)
    monitor.setTextScale(0.5)
    local channel = __TS__New(Channel, {protocol = PROTOCOL, timeoutSeconds = 8})
    channel:open()
    local controller
    local ui = {}
    local function redraw()
        local ____opt_0 = ui.runtime
        return ____opt_0 and ____opt_0:invalidate({reason = "state", kind = "full"})
    end
    local function request(____, messageType, payload, done)
        if controller == nil then
            screen:notify("controller not found yet", colors.red)
            redraw(nil)
            return
        end
        channel:request(
            controller,
            messageType,
            payload,
            function(____, result)
                if result.ok then
                    screen:setState(result.value)
                    screen:notify(done, colors.lime)
                else
                    screen:notify(result.error, colors.red)
                end
                redraw(nil)
            end
        )
    end
    screen = __TS__New(
        SmelteryScreen,
        {
            setMode = function(____, mode) return request(nil, Messages.setMode, {mode = mode}, "mode " .. mode) end,
            insert = function(____, insert) return request(nil, Messages.insert, insert, insert.force == true and "forced insert sent" or "inserted") end,
            cast = function(____, cast) return request(nil, Messages.cast, cast, "cast") end,
            setFormat = function(____, format) return request(nil, Messages.setFormat, format, (format.format .. ": ") .. (format.auto and "auto" or "off")) end,
            setAlloy = function(____, alloy) return request(
                nil,
                Messages.setAlloy,
                alloy,
                "alloy " .. __TS__StringSubstring(
                    alloy.result,
                    (string.find(alloy.result, ":", nil, true) or 0) - 1 + 1
                )
            ) end
        }
    )
    channel:on(
        Messages.state,
        function(____, payload, from)
            controller = from
            screen:setState(payload)
        end
    )
    print("Looking for the Smeltery controller...")
    controller = channel:lookup(CONTROLLER_HOSTNAME)
    print(controller ~= nil and "Controller: computer #" .. tostring(controller) or "Not found yet: waiting for its broadcast")
    local runtime = __TS__New(
        UIRuntime,
        {
            root = screen.root,
            eventBus = __TS__New(BasicUIEventBus),
            theme = THEME,
            surface = ComputerCraftSurfaceAdapter:fromMonitor(monitor),
            surfaceKind = "monitor"
        }
    )
    ui.runtime = runtime
    if controller ~= nil then
        channel:request(
            controller,
            Messages.getState,
            nil,
            function(____, result)
                if result.ok then
                    screen:setState(result.value)
                end
                redraw(nil)
            end
        )
    end
    local everySecond
    everySecond = function()
        screen:tick()
        redraw(nil)
        runtime:schedule(1, everySecond)
    end
    runtime:schedule(1, everySecond)
    runtime:run({
        monitor = monitorName,
        onEvent = function(____, raw)
            if channel:handleEvent(raw) then
                redraw(nil)
            end
        end
    })
end
return ____exports
