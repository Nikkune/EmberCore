-- Behaviour regression tests, run on the compiled Lua with a fake CC:Tweaked environment.
-- Usage: lua behavior.lua <luasDir> <testDir>
local luasDir, testDir = arg[1], arg[2]
package.path = luasDir .. '/?.lua'
dofile(testDir .. '/cc-env.lua')

local passed, failed = 0, 0

local function test(name, fn)
	local ok, err = pcall(fn)
	if ok then
		passed = passed + 1
		print('ok   ' .. name)
	else
		failed = failed + 1
		print('FAIL ' .. name .. '\n     ' .. tostring(err))
	end
end

local function expect(condition, message)
	if not condition then error(message, 2) end
end

local function new(class, ...)
	local instance = setmetatable({}, class.prototype)
	instance:____constructor(...)
	return instance
end

-- Silence logger output.
local realPrint = print
local function quiet(fn)
	print = function() end
	local results = { pcall(fn) }
	print = realPrint
	if not results[1] then error(results[2], 0) end
	return table.unpack(results, 2)
end

local ui = require('modules.ui.index')
local components = require('modules.ui.components')
local Surface = ui.ComputerCraftSurfaceAdapter

local function runtimeFor(root, width, height, theme)
	CURRENT_TERMINAL = makeTerminal(width, height)
	local runtime = new(ui.UIRuntime, {
		root        = root,
		eventBus    = new(ui.BasicUIEventBus),
		theme       = theme or ui.defaultTheme,
		surface     = Surface:fromTerminal(),
		surfaceKind = 'terminal',
	})
	return runtime, CURRENT_TERMINAL
end

-- 1. Surface size / cursor (CC returns two values, not a table).
test('surface: getSize() and getCursor() return the terminal values', function()
	CURRENT_TERMINAL = makeTerminal(20, 5)
	local surface = Surface:fromTerminal()
	local size = surface:getSize()
	expect(size.width == 20 and size.height == 5, ('got %s x %s'):format(tostring(size.width), tostring(size.height)))
	surface:setCursor({ x = 3, y = 4 })
	local cursor = surface:getCursor()
	expect(cursor.x == 3 and cursor.y == 4, 'cursor not read back')
end)

-- 2. Real CC objects are called with '.', not ':'.
test('surface: fromMonitor() works with a dot-call monitor', function()
	local monitor = makeTerminal(10, 3)
	local surface = Surface:fromMonitor(monitor)
	expect(surface:getSize().width == 10, 'wrong width')
	surface:writeAt({ x = 2, y = 2 }, 'hi')
	expect(monitor.line(2) == ' hi       ', ('line 2 is "%s"'):format(monitor.line(2)))
	surface:fillRect({ x = 1, y = 3, width = 2, height = 1 }, ' ', colors.blue)
	expect(monitor.cell(1, 3)[3] == colors.blue, 'fillRect background not applied')
end)

-- 3. Spreading an optional value must not crash (TSTL turns {...undefined} into pairs(nil)).
local leafCases = {
	{ 'ButtonComponent', { label = 'OK' } },
	{ 'ToggleButtonComponent', { label = 'OK' } },
	{ 'CheckboxComponent', { label = 'OK', checked = false } },
	{ 'RadioComponent', { label = 'OK', value = 'a' } },
	{ 'BadgeComponent', { label = 'OK' } },
}
for _, case in ipairs(leafCases) do
	test('render with default theme: ' .. case[1], function()
		local runtime, terminal = runtimeFor(new(components[case[1]], case[2]), 12, 3)
		runtime:render()
		expect(terminal.line(1):find('OK', 1, true) ~= nil, ('label not drawn: "%s"'):format(terminal.line(1)))
	end)
end

test('event bus: subscribeOnce() without options', function()
	local bus = new(ui.BasicUIEventBus)
	local calls = 0
	bus:subscribeOnce('mouse_click', function() calls = calls + 1 end)
	bus:dispatch({ type = 'mouse_click', x = 1, y = 1 })
	bus:dispatch({ type = 'mouse_click', x = 1, y = 1 })
	expect(calls == 1, 'handler called ' .. calls .. ' time(s)')
end)

-- 4. Layout containers forward clicks to their children.
for _, containerName in ipairs({ 'StackComponent', 'BoxComponent', 'ContainerComponent', 'GridComponent', 'PanelComponent' }) do
	test('click reaches a button inside ' .. containerName, function()
		local pressed = 0
		local button = new(components.ButtonComponent, { label = 'Go', onPress = function() pressed = pressed + 1 end })
		local container = new(components[containerName], {}, {}, { button })
		local runtime = runtimeFor(container, 20, 6)
		runtime:render()
		local r = button.rect
		expect(r.width > 0 and r.height > 0, 'button was not laid out')
		runtime:dispatch({ type = 'mouse_click', x = r.x, y = r.y, button = 1 })
		expect(pressed == 1, 'onPress called ' .. pressed .. ' time(s)')
	end)
end

test('click outside every child is ignored by a container', function()
	local pressed = 0
	local button = new(components.ButtonComponent, { label = 'Go', onPress = function() pressed = pressed + 1 end })
	local stack = new(components.StackComponent, {}, {}, { button })
	local runtime = runtimeFor(stack, 20, 6)
	runtime:render()
	runtime:dispatch({ type = 'mouse_click', x = 20, y = 6, button = 1 })
	expect(pressed == 0, 'onPress called for a click outside the button')
end)

-- 5 & 6. Peripheral lookup by type, including secondary types ("inventory").
local chest = { size = function() return 27 end }
local monitor = { getSize = function() return 7, 5 end }
installPeripherals({
	['minecraft:chest_0'] = { types = { 'minecraft:chest', 'inventory' }, object = chest },
	['left'] = { types = { 'monitor' }, object = monitor },
})
local Peripheral = require('core.peripheral').Peripheral

test('peripheral: findByType() returns the wrapped peripheral', function()
	expect(quiet(function() return Peripheral:findByType('monitor') end) == monitor, 'did not return the monitor itself')
end)

test('peripheral: findByType() returns nil when absent', function()
	expect(quiet(function() return Peripheral:findByType('speaker') end) == nil, 'did not return nil')
end)

test('peripheral: requireByType() throws when absent', function()
	local ok = pcall(quiet, function() return Peripheral:requireByType('speaker') end)
	expect(not ok, 'no error raised')
end)

test('peripheral: secondary types are matched', function()
	expect(quiet(function() return Peripheral:findNameByType('inventory') end) == 'minecraft:chest_0', 'findNameByType failed')
	expect(quiet(function() return Peripheral:requireType('minecraft:chest_0', 'inventory') end) == chest, 'requireType failed')
	expect(quiet(function() return Peripheral:wrapType('minecraft:chest_0', 'inventory') end) == chest, 'wrapType failed')
	expect(quiet(function() return Peripheral:getType('minecraft:chest_0') end) == 'minecraft:chest', 'getType should keep the primary type')
end)

realPrint(('\n%d passed, %d failed'):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
