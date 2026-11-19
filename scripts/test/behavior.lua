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

-- ============================================================
-- Core: Lua globals declared in src/types/lua.d.ts must be called without self
-- ============================================================

test('assert: type checks accept the right type and report the wrong one', function()
	local A = require('core.assert')
	A.assertString(nil, 'x', 'name')
	A.assertNumber(nil, 1, 'count')
	local ok, err = pcall(A.assertString, nil, 42, 'name')
	expect(not ok and tostring(err):find('name must be a string', 1, true), 'got: ' .. tostring(err))
	local okAssert, errAssert = pcall(A.assert, nil, false, 'custom message')
	expect(not okAssert and tostring(errAssert):find('custom message', 1, true), 'assert message lost: ' .. tostring(errAssert))
end)

test('inventory: list-based helpers count and find items', function()
	local Inventory = require('core.inventory').Inventory
	local items = { [1] = { name = 'minecraft:iron_ingot', count = 10 }, [4] = { name = 'minecraft:coal', count = 3 }, [7] = { name = 'minecraft:iron_ingot', count = 5 } }
	local inv = new(Inventory, 'chest', { size = function() return 27 end, list = function() return items end })
	expect(inv:countItem('minecraft:iron_ingot') == 15, 'countItem = ' .. tostring(inv:countItem('minecraft:iron_ingot')))
	expect(inv:countAllItems() == 18, 'countAllItems wrong')
	expect(inv:findFirstSlotByName('minecraft:coal') == 4, 'findFirstSlotByName wrong')
	expect(not inv:isEmpty(), 'isEmpty should be false')
	expect(inv:getFreeSlotCount() == 24, 'getFreeSlotCount = ' .. tostring(inv:getFreeSlotCount()))
end)

test('results: try() keeps the cause of a Lua error', function()
	local Results = require('core.result').Results
	local r = Results:try(function() error('boom') end)
	expect(not r.ok, 'should be an error result')
	expect(tostring(r.error.context and r.error.context.cause):find('boom', 1, true), 'cause lost: ' .. tostring(r.error.context and r.error.context.cause))
end)

test('tank: list() keeps every tank when an empty one is nil', function()
	local Tank = require('core.tank').Tank
	local raw = { tanks = function() return { nil, { name = 'minecraft:water', amount = 1000 } } end }
	local tank = new(Tank, 'tank', raw)
	expect(#tank:list() == 2, 'list() has ' .. #tank:list() .. ' entries, expected 2')
	expect(tank:getTotalAmount() == 1000, 'total = ' .. tank:getTotalAmount())
	expect(tank:getTank(2).name == 'minecraft:water', 'slot 2 should be the water tank')
end)

-- ============================================================
-- Rendering and interaction behaviour
-- ============================================================

local palette = ui.defaultTheme.palette

local function themeWith(components)
	return { name = 'test', palette = palette, borders = ui.defaultTheme.borders, components = components }
end

local function cellAt(terminal, text, y)
	local x = terminal.line(y or 1):find(text, 1, true)
	expect(x ~= nil, ('"%s" not found on line %d: "%s"'):format(text, y or 1, terminal.line(y or 1)))
	return terminal.cell(x, y or 1), x
end

test('button label uses the button colors', function()
	local button = new(components.ButtonComponent, { label = 'OK', backgroundColor = colors.blue, foregroundColor = colors.yellow })
	local runtime, terminal = runtimeFor(button, 6, 1)
	runtime:render()
	local cell = cellAt(terminal, 'OK')
	expect(cell[3] == colors.blue, 'label background is not the button background')
	expect(cell[2] == colors.yellow, 'label foreground is not the button foreground')
end)

test('state color is the button background, text stays readable', function()
	local button = new(components.ButtonComponent, { label = 'OK' })
	local runtime, terminal = runtimeFor(button, 6, 1, themeWith({ button = { colors = { default = colors.red } } }))
	runtime:render()
	local cell = cellAt(terminal, 'OK')
	expect(cell[3] == colors.red, 'background is not the state color')
	expect(cell[2] == palette.text, 'text color should be the palette text color')
end)

test('default border preset is a thin frame of single-byte CC drawing characters', function()
	local button = new(components.ButtonComponent, { label = 'Go', width = 6, backgroundColor = colors.gray, foregroundColor = colors.white })
	local runtime, terminal = runtimeFor(button, 6, 3, themeWith({ button = { border = { enabled = true } } }))
	runtime:render()
	local c = string.char
	local expected = {
		c(0x97) .. c(0x83):rep(4) .. c(0x94),
		c(0x95) .. ' Go ' .. c(0x95),
		c(0x8A) .. c(0x8F):rep(4) .. c(0x85),
	}
	for y = 1, 3 do
		expect(terminal.line(y) == expected[y], ('line %d is %q'):format(y, terminal.line(y)))
	end
	-- Left/top parts: border color on the box background; right/bottom parts: inverted.
	expect(terminal.cell(1, 2)[2] == colors.white and terminal.cell(1, 2)[3] == colors.gray, 'left side colors')
	expect(terminal.cell(6, 2)[2] == colors.gray and terminal.cell(6, 2)[3] == colors.white, 'right side should be inverted')
	expect(terminal.cell(3, 3)[2] == colors.gray and terminal.cell(3, 3)[3] == colors.white, 'bottom should be inverted')
end)

test('double border preset is a thick frame of CC drawing characters', function()
	local button = new(components.ButtonComponent, { label = 'Go', width = 6, backgroundColor = colors.gray, foregroundColor = colors.white })
	local runtime, terminal = runtimeFor(button, 6, 3, themeWith({ button = { border = { enabled = true, preset = 'double' } } }))
	runtime:render()
	local c = string.char
	local expected = {
		c(0x80) .. c(0x8F):rep(4) .. c(0x80),
		c(0x80) .. ' Go ' .. c(0x80),
		c(0x80) .. c(0x83):rep(4) .. c(0x80),
	}
	for y = 1, 3 do
		expect(terminal.line(y) == expected[y], ('line %d is %q'):format(y, terminal.line(y)))
	end
	-- Sides and corners are full cells (inverted empty character), top is drawn, bottom inverted.
	expect(terminal.cell(1, 2)[3] == colors.white, 'left side should be a full cell of the border color')
	expect(terminal.cell(3, 1)[2] == colors.white and terminal.cell(3, 1)[3] == colors.gray, 'top colors')
	expect(terminal.cell(3, 3)[2] == colors.gray and terminal.cell(3, 3)[3] == colors.white, 'bottom should be inverted')
end)

test('withAsciiBorders() switches borders and rules to ASCII', function()
	local theme = ui.withAsciiBorders(nil, themeWith({ button = { border = { enabled = true } } }))
	local button = new(components.ButtonComponent, { label = 'Go', width = 6 })
	local runtime, terminal = runtimeFor(button, 6, 3, theme)
	runtime:render()
	expect(terminal.line(1) == '+----+', ('top border is "%s"'):format(terminal.line(1)))
	expect(terminal.line(2) == '| Go |', ('middle line is "%s"'):format(terminal.line(2)))
	expect(terminal.line(3) == '+----+', ('bottom border is "%s"'):format(terminal.line(3)))
	local separator = new(components.SeparatorComponent, {})
	local runtime2, terminal2 = runtimeFor(separator, 5, 1, theme)
	runtime2:render()
	expect(terminal2.line(1) == '-----', 'separator is "' .. terminal2.line(1) .. '"')
end)

test('ellipsis is a single ASCII character', function()
	expect(ui.applyEllipsis(nil, 'Bonjour', 5) == 'Bonj.', 'got "' .. ui.applyEllipsis(nil, 'Bonjour', 5) .. '"')
end)

test('progress bar label keeps the fill visible', function()
	local bar = new(components.ProgressBarComponent, { value = 5, maxValue = 10, width = 10 })
	local runtime, terminal = runtimeFor(bar, 10, 1)
	runtime:render()
	for x = 1, 5 do
		expect(terminal.cell(x, 1)[3] == palette.primary, ('cell %d is not filled'):format(x))
	end
	for x = 6, 10 do
		expect(terminal.cell(x, 1)[3] == palette.surface, ('cell %d should be empty'):format(x))
	end
end)

test('rendering does not modify the shared theme, props win over theme', function()
	local theme = themeWith({ progress_bar = {}, stack = {} })
	local red = new(components.ProgressBarComponent, { value = 1, maxValue = 2, width = 6, foregroundColor = colors.red })
	local runtimeRed = runtimeFor(red, 6, 1, theme)
	runtimeRed:render()
	expect(next(theme.components.progress_bar) == nil, 'theme.components.progress_bar was modified')

	local lime = new(components.ProgressBarComponent, { value = 1, maxValue = 2, width = 6, foregroundColor = colors.lime })
	local runtimeLime, terminal = runtimeFor(lime, 6, 1, theme)
	runtimeLime:render()
	expect(cellAt(terminal, '50%')[2] == colors.lime, 'second bar does not use its own foregroundColor')

	local stack = new(components.StackComponent, { backgroundColor = colors.green }, {}, {})
	runtimeFor(stack, 4, 1, theme):render()
	expect(next(theme.components.stack) == nil, 'theme.components.stack was modified')
end)

test('focus moves to the clicked button and is cleared by an outside click', function()
	local a = new(components.ButtonComponent, { label = 'A' })
	local b = new(components.ButtonComponent, { label = 'B' })
	local stack = new(components.StackComponent, { direction = 'row', spacing = 1 }, {}, { a, b })
	local runtime = runtimeFor(stack, 20, 3)
	runtime:render()
	runtime:dispatch({ type = 'mouse_click', x = a.rect.x, y = a.rect.y, button = 1 })
	expect(a.focused and not b.focused, 'A should be the only focused button')
	runtime:dispatch({ type = 'mouse_click', x = b.rect.x, y = b.rect.y, button = 1 })
	expect(b.focused and not a.focused, 'focus did not move from A to B')
	runtime:dispatch({ type = 'mouse_click', x = 20, y = 3, button = 1 })
	expect(not a.focused and not b.focused, 'outside click did not clear the focus')
end)

test('stack: justify acts on the main axis only', function()
	local label = new(components.LabelComponent, { text = 'AB' })
	local stack = new(components.StackComponent, { direction = 'column', justify = 'center', alignment = 'start' }, {}, { label })
	local runtime = runtimeFor(stack, 10, 5)
	runtime:render()
	expect(label.rect.x == 1, 'label x = ' .. label.rect.x .. ', expected 1 (alignment start)')
	expect(label.rect.y == 3, 'label y = ' .. label.rect.y .. ', expected 3 (justify center)')

	local centered = new(components.LabelComponent, { text = 'AB' })
	local stack2 = new(components.StackComponent, { direction = 'column', alignment = 'center' }, {}, { centered })
	runtimeFor(stack2, 10, 5):render()
	expect(centered.rect.x == 5, 'alignment center: label x = ' .. centered.rect.x .. ', expected 5')
end)

test('pagination: << and >> jump to the first and last page, display follows', function()
	local changes = {}
	local pagination = new(components.PaginationComponent, {
		page = 3, totalItems = 50, pageSize = 10, width = 20,
		onPageChange = function(_, page) changes[#changes + 1] = page end,
	})
	local runtime, terminal = runtimeFor(pagination, 20, 1)
	runtime:render()
	local _, firstX = cellAt(terminal, '<<')
	runtime:dispatch({ type = 'mouse_click', x = firstX, y = 1, button = 1 })
	runtime:render()
	expect(changes[1] == 1, 'onPageChange got ' .. tostring(changes[1]) .. ', expected 1')
	expect(terminal.line(1):find('1/5', 1, true), 'display did not update: "' .. terminal.line(1) .. '"')
	local _, lastX = cellAt(terminal, '>>')
	runtime:dispatch({ type = 'mouse_click', x = lastX, y = 1, button = 1 })
	runtime:render()
	expect(changes[2] == 5, 'onPageChange got ' .. tostring(changes[2]) .. ', expected 5')
	expect(terminal.line(1):find('5/5', 1, true), 'display did not update: "' .. terminal.line(1) .. '"')
	local _, prevX = cellAt(terminal, ' < ')
	runtime:dispatch({ type = 'mouse_click', x = prevX + 1, y = 1, button = 1 })
	expect(changes[3] == 4, '< should go to page 4, got ' .. tostring(changes[3]))
end)

test('padding prop is applied (containers and leaves)', function()
	local button = new(components.ButtonComponent, { label = 'X', padding = 0 })
	local stack = new(components.StackComponent, { direction = 'column', padding = 1 }, {}, { button })
	runtimeFor(stack, 10, 5):render()
	expect(button.rect.x == 2 and button.rect.y == 2, ('stack padding ignored: button at %d,%d'):format(button.rect.x, button.rect.y))
	expect(button.rect.width == 1, 'button padding ignored: width ' .. button.rect.width)
end)

test('margin prop spaces children in every container', function()
	local first = new(components.LabelComponent, { text = 'AB', margin = { bottom = 1, left = 2 } })
	local second = new(components.LabelComponent, { text = 'CD' })
	local stack = new(components.StackComponent, { direction = 'column' }, {}, { first, second })
	runtimeFor(stack, 10, 5):render()
	expect(first.rect.x == 3 and first.rect.y == 1, ('first label at %d,%d, expected 3,1'):format(first.rect.x, first.rect.y))
	expect(second.rect.y == 3, 'second label y = ' .. second.rect.y .. ', expected 3 (1 + height 1 + margin 1)')

	for _, containerName in ipairs({ 'BoxComponent', 'ContainerComponent', 'PanelComponent', 'GridComponent' }) do
		local button = new(components.ButtonComponent, { label = 'X', margin = 1 })
		local container = new(components[containerName], {}, {}, { button })
		runtimeFor(container, 12, 6):render()
		expect(button.rect.x >= 2 and button.rect.y >= 2,
			('%s: button at %d,%d ignores its margin'):format(containerName, button.rect.x, button.rect.y))
	end
end)

test('table header and rows use the table props colors', function()
	local tbl = new(components.TableComponent, {
		columns = { { key = 'name', title = 'Nom' } },
		rows = { { name = 'fer' } },
		width = 10,
		foregroundColor = colors.yellow,
		backgroundColor = colors.blue,
	})
	local runtime, terminal = runtimeFor(tbl, 10, 4)
	runtime:render()
	local header = cellAt(terminal, 'Nom', 1)
	expect(header[2] == colors.yellow and header[3] == colors.blue, 'header ignores the props colors')
	local _, rowY
	for y = 1, 4 do if terminal.line(y):find('fer', 1, true) then rowY = y end end
	expect(rowY ~= nil, 'row not drawn')
	local row = cellAt(terminal, 'fer', rowY)
	expect(row[2] == colors.yellow and row[3] == colors.blue, 'row ignores the props colors')
end)

test('separator spans the container width and keeps its label', function()
	local separator = new(components.SeparatorComponent, { label = 'etat' })
	local stack = new(components.StackComponent, { direction = 'column' }, {}, { separator })
	local runtime, terminal = runtimeFor(stack, 20, 3)
	runtime:render()
	expect(separator.rect.width == 20, 'separator width ' .. separator.rect.width .. ', expected 20')
	local line = terminal.line(separator.rect.y)
	expect(line:find(' etat ', 1, true), 'label truncated: "' .. line .. '"')
	local x = line:find(' etat ', 1, true)
	expect(x > 1 and line:sub(1, 1) ~= ' ', 'no line drawn left of the label: "' .. line .. '"')
end)

test('radio group: the deselected radio is notified', function()
	local group = new(components.RadioGroup, 'a')
	local events = {}
	local ra = new(components.RadioComponent, { label = 'A', value = 'a', onSelect = function(_, v) events[#events + 1] = 'a:' .. tostring(v) end }, {}, group)
	local rb = new(components.RadioComponent, { label = 'B', value = 'b', onSelect = function(_, v) events[#events + 1] = 'b:' .. tostring(v) end }, {}, group)
	local stack = new(components.StackComponent, {}, {}, { ra, rb })
	local runtime, terminal = runtimeFor(stack, 20, 4)
	runtime:render()
	expect(terminal.line(ra.rect.y):find('(o) A', 1, true), 'A should start selected: "' .. terminal.line(ra.rect.y) .. '"')
	runtime:dispatch({ type = 'mouse_click', x = rb.rect.x, y = rb.rect.y, button = 1 })
	runtime:render()
	local got = table.concat(events, ' ')
	expect(got == 'a:false b:true', 'events: "' .. got .. '"')
	expect(rb.selected and not ra.selected, 'selection did not move to B')
	expect(terminal.line(ra.rect.y):find('( ) A', 1, true), 'A was not redrawn as deselected: "' .. terminal.line(ra.rect.y) .. '"')
	expect(terminal.line(rb.rect.y):find('(o) B', 1, true), 'B was not redrawn as selected: "' .. terminal.line(rb.rect.y) .. '"')
end)

-- ============================================================
-- Runtime ergonomics: auto redraw, setters, event bus, event loop
-- ============================================================

test('runtime: state changes made by the app trigger a redraw (invalidator attached)', function()
	local checkbox = new(components.CheckboxComponent, { label = 'C', checked = false })
	local stack = new(components.StackComponent, { direction = 'column' }, {}, { checkbox })
	local runtime, terminal = runtimeFor(stack, 12, 4)
	runtime:render()
	expect(not runtime:isDirty(), 'runtime dirty after render')
	checkbox:setChecked(true)
	expect(runtime:isDirty(), 'setChecked() did not mark the runtime dirty')
	runtime:render()
	expect(terminal.line(checkbox.rect.y):find('[x]', 1, true), 'checkbox not redrawn: "' .. terminal.line(checkbox.rect.y) .. '"')

	local late = new(components.LabelComponent, { text = 'late' })
	stack:addChild(late)
	runtime:render()
	late:setText('later')
	expect(runtime:isDirty(), 'a child added after the runtime was created is not attached')
	runtime:render()
	expect(terminal.line(late.rect.y):find('later', 1, true), 'added child not redrawn')
end)

test('setters: setText, setLabel, setValue, setProps redraw with the new values', function()
	local label = new(components.LabelComponent, { text = 'a' })
	local button = new(components.ButtonComponent, { label = 'Go' })
	local bar = new(components.ProgressBarComponent, { value = 0, maxValue = 10, width = 10 })
	local log = new(components.LogViewerComponent, { entries = {}, height = 2 })
	local stack = new(components.StackComponent, { direction = 'column' }, {}, { label, button, bar, log })
	local runtime, terminal = runtimeFor(stack, 20, 6)
	runtime:render()
	label:setText('Hello world')
	button:setLabel('Stop')
	bar:setValue(10)
	log:addEntry({ level = 'info', message = 'started' })
	runtime:render()
	expect(terminal.line(label.rect.y):find('Hello world', 1, true), 'label: "' .. terminal.line(label.rect.y) .. '"')
	expect(terminal.line(button.rect.y):find('Stop', 1, true), 'button: "' .. terminal.line(button.rect.y) .. '"')
	expect(terminal.line(bar.rect.y):find('100%', 1, true), 'bar: "' .. terminal.line(bar.rect.y) .. '"')
	expect(terminal.line(log.rect.y):find('started', 1, true), 'log: "' .. terminal.line(log.rect.y) .. '"')
	label:setProps({ text = 'via setProps' })
	runtime:render()
	expect(terminal.line(label.rect.y):find('via setProps', 1, true), 'setProps: "' .. terminal.line(label.rect.y) .. '"')
end)

test('setProps keeps component state in sync (checked, page, pressed, selected)', function()
	local checkbox = new(components.CheckboxComponent, { label = 'C', checked = false })
	checkbox:setProps({ checked = true })
	expect(checkbox.checked, 'checkbox state not updated')
	local pagination = new(components.PaginationComponent, { page = 1, totalItems = 50, pageSize = 10 })
	pagination:setProps({ page = 4 })
	expect(pagination.page == 4, 'pagination page = ' .. pagination.page)
	local toggle = new(components.ToggleButtonComponent, { label = 'T' })
	toggle:setProps({ pressed = true })
	expect(toggle.pressed, 'toggle state not updated')
	local radio = new(components.RadioComponent, { label = 'R', value = 'r' })
	radio:setProps({ selected = true })
	expect(radio.selected, 'radio state not updated')
end)

test('event bus receives events no component handled', function()
	local stack = new(components.StackComponent, {}, {}, { new(components.LabelComponent, { text = 'x' }) })
	local runtime = runtimeFor(stack, 10, 3)
	runtime:render()
	local received = 0
	runtime.eventBus:subscribe('mouse_click', function() received = received + 1 end)
	runtime:dispatch({ type = 'mouse_click', x = 9, y = 3, button = 1 })
	runtime:dispatch({ type = 'char', char = 'a' })
	expect(received == 1, 'bus received ' .. received .. ' click(s)')
end)

test('toUIEvent translates CC events', function()
	local e = ui.toUIEvent(nil, { 'mouse_click', 2, 5, 7 })
	expect(e and e.type == 'mouse_click' and e.button == 2 and e.x == 5 and e.y == 7, 'mouse_click')
	e = ui.toUIEvent(nil, { 'monitor_touch', 'right', 3, 4 }, { monitor = 'right' })
	expect(e and e.type == 'monitor_touch' and e.x == 3 and e.y == 4, 'monitor_touch')
	expect(ui.toUIEvent(nil, { 'monitor_touch', 'left', 3, 4 }, { monitor = 'right' }) == nil, 'touch on another monitor should be ignored')
	expect(ui.toUIEvent(nil, { 'mouse_click', 1, 1, 1 }, { monitor = 'right' }) == nil, 'terminal clicks ignored on a monitor surface')
	e = ui.toUIEvent(nil, { 'mouse_scroll', 1, 2, 3 })
	expect(e and e.direction == 1 and e.x == 2, 'mouse_scroll')
	e = ui.toUIEvent(nil, { 'key', 28, false })
	expect(e and e.type == 'key' and e.key == 28 and e.held == false, 'key')
	e = ui.toUIEvent(nil, { 'char', 'q' })
	expect(e and e.char == 'q', 'char')
	expect(ui.toUIEvent(nil, { 'redstone' }) == nil, 'unknown events give nil')
end)

test('runtime.run() renders, dispatches clicks and returns after stop()', function()
	local pressed = 0
	local runtime
	local button = new(components.ButtonComponent, { label = 'Go', onPress = function() pressed = pressed + 1 end })
	local stack = new(components.StackComponent, {}, {}, { button })
	local terminal
	runtime, terminal = runtimeFor(stack, 10, 3)
	local queue = {
		function() return 'mouse_click', 1, button.rect.x, button.rect.y end,
		function() return 'term_resize' end,
		function() runtime:stop(); return 'timer', 1 end,
	}
	local realPull = os.pullEvent
	os.pullEvent = function()
		local nextEvent = table.remove(queue, 1)
		if not nextEvent then error('run() did not stop') end
		return nextEvent()
	end
	local ok, err = pcall(function() runtime:run() end)
	os.pullEvent = realPull
	expect(ok, tostring(err))
	expect(pressed == 1, 'button pressed ' .. pressed .. ' time(s)')
	expect(terminal.line(button.rect.y):find('Go', 1, true), 'screen not rendered')
end)

test('buttons flash on click, then show their state color only', function()
	local theme = themeWith({ button = { colors = { default = colors.gray, active = colors.blue } } })
	local button = new(components.ButtonComponent, { label = 'Go' })
	local toggle = new(components.ToggleButtonComponent, { label = 'Tg' })
	local stack = new(components.StackComponent, { direction = 'row', spacing = 1 }, {}, { button, toggle })
	local runtime, terminal = runtimeFor(stack, 20, 1, theme)
	runtime:render()
	local function bg(component) return terminal.cell(component.rect.x, component.rect.y)[3] end

	runtime:dispatch({ type = 'mouse_click', x = button.rect.x, y = button.rect.y, button = 1 })
	runtime:render()
	expect(bg(button) == colors.blue, 'button does not flash on click')
	runtime:dispatch({ type = 'timer', timerId = LAST_TIMER })
	runtime:render()
	expect(bg(button) == colors.gray, 'button stays highlighted after the flash (focus must not color it)')

	runtime:dispatch({ type = 'mouse_click', x = toggle.rect.x, y = toggle.rect.y, button = 1 })
	runtime:dispatch({ type = 'timer', timerId = LAST_TIMER })
	runtime:render()
	expect(toggle.pressed and bg(toggle) == colors.blue, 'toggle ON should use the pressed/active color')
	runtime:dispatch({ type = 'mouse_click', x = toggle.rect.x, y = toggle.rect.y, button = 1 })
	runtime:render()
	expect(bg(toggle) == colors.blue, 'toggle should flash on click')
	runtime:dispatch({ type = 'timer', timerId = LAST_TIMER })
	runtime:render()
	expect(not toggle.pressed and bg(toggle) == colors.gray, 'toggle OFF must be the default color, even when focused')
end)

test('box title does not erase the rest of the top border', function()
	local theme = ui.withAsciiBorders(nil, themeWith({ box = { border = { enabled = true } } }))
	local box = new(components.BoxComponent, { title = 'Title', width = 20, height = 3 }, {}, {})
	local runtime, terminal = runtimeFor(box, 20, 3, theme)
	runtime:render()
	expect(terminal.line(1) == '+- Title ----------+', 'top line is "' .. terminal.line(1) .. '"')
end)

test('status bar: full width, natural segment widths, per-segment colors', function()
	local status = new(components.StatusBarComponent, { segments = {
		{ text = ' 7:12 ', backgroundColor = colors.gray },
		{ text = ' clics: 10 ', backgroundColor = colors.blue },
		{ text = ' Q: quitter ' },
	} })
	local stack = new(components.StackComponent, { direction = 'column' }, {}, { status })
	local runtime, terminal = runtimeFor(stack, 40, 1)
	runtime:render()
	local line = terminal.line(1)
	expect(status.rect.width == 40, 'status bar width ' .. status.rect.width .. ', expected 40')
	expect(line:find(' 7:12  clics: 10  Q: quitter ', 1, true) == 1, 'segments truncated or misplaced: "' .. line .. '"')
	expect(terminal.cell(2, 1)[3] == colors.gray, 'first segment background is not gray')
	expect(terminal.cell(8, 1)[3] == colors.blue, 'second segment background is not blue')
	expect(terminal.cell(20, 1)[3] == palette.surface, 'third segment should use the bar background')
end)

test('children inherit the container background (no black holes in a panel)', function()
	local label = new(components.LabelComponent, { text = 'L' })
	local badge = new(components.BadgeComponent, { label = 'B', backgroundColor = colors.lime, margin = { right = 1 } })
	local row = new(components.StackComponent, { direction = 'row' }, {}, { badge, label })
	local panel = new(components.PanelComponent, { backgroundColor = colors.gray }, {}, { row })
	local runtime, terminal = runtimeFor(panel, 12, 3)
	runtime:render()
	local gapX = badge.rect.x + badge.rect.width
	expect(terminal.cell(gapX, badge.rect.y)[3] == colors.gray, 'badge margin is not the panel background')
	expect(terminal.cell(label.rect.x, label.rect.y)[3] == colors.gray, 'label without background is not on the panel background')
end)

test('table: a column alignment does not leak into the other columns', function()
	local tbl = new(components.TableComponent, {
		columns = { { key = 'item', title = 'Objet' }, { key = 'qte', title = 'Qte', alignment = 'right' } },
		rows = { { item = 'iron', qte = '94' }, { item = 'coal', qte = '12' } },
		width = 20,
	})
	local runtime, terminal = runtimeFor(tbl, 20, 6)
	runtime:render()
	for y = 1, 6 do
		local line = terminal.line(y)
		for _, word in ipairs({ 'Objet', 'iron', 'coal' }) do
			local x = line:find(word, 1, true)
			if x then expect(x == 1, ('"%s" should be left aligned, line %d: "%s"'):format(word, y, line)) end
		end
	end
end)

-- ============================================================
-- Core robustness
-- ============================================================

test('logger: logging works (os.date called without self)', function()
	local Logger = require('core.logger').Logger
	local log = new(Logger, 'Test', 'debug', false)
	local lines = {}
	local previous = print
	print = function(line) lines[#lines + 1] = line end
	local ok, err = pcall(function() log:info('hello', { a = 1 }) end)
	print = previous
	expect(ok, 'Logger.info crashed: ' .. tostring(err))
	expect(lines[1] and lines[1]:find('INFO | Test | a=1 msg="hello"', 1, true), 'line: ' .. tostring(lines[1]))
end)

local function loopYields(run)
	FAKE_CLOCK, QUEUED_EVENTS = 0, {}
	local calls = 0
	local ok, err = pcall(quiet, function()
		run(function()
			calls = calls + 1
			FAKE_CLOCK = FAKE_CLOCK + 0.4 -- a busy task that never yields
			if calls == 10 then error('stop', 0) end
		end)
	end)
	expect(not ok and tostring(err):find('stop', 1, true), 'unexpected error: ' .. tostring(err))
	return #QUEUED_EVENTS
end

test('loop: forever/until yield regularly when the task never does (no "Too long without yielding")', function()
	local Loop = require('core.loop').Loop
	local foreverYields = loopYields(function(task) Loop:forever(task) end)
	expect(foreverYields >= 2, 'forever() yielded ' .. foreverYields .. ' time(s) in 4 s of busy work')
	-- `until` is a Lua keyword: from Lua the method is called as Loop["until"](Loop, ...).
	local untilYields = loopYields(function(task) Loop['until'](Loop, function() return false end, task) end)
	expect(untilYields >= 2, 'until() yielded ' .. untilYields .. ' time(s) in 4 s of busy work')
end)

test('config: deep merge with defaults, wrong types ignored, unknown keys dropped', function()
	local Config = require('core.config').Config
	FILES = { ['app.cfg'] = textutils.serialise({ name = 42, nested = { x = 5 }, extra = true }) }
	local cfg = quiet(function()
		return Config:load('app.cfg', { name = 'smeltery', nested = { x = 1, y = 2 }, speed = 3 })
	end)
	expect(cfg.name == 'smeltery', 'wrong type should keep the default, got ' .. tostring(cfg.name))
	expect(cfg.nested.x == 5 and cfg.nested.y == 2, ('nested merge: x=%s y=%s'):format(tostring(cfg.nested.x), tostring(cfg.nested.y)))
	expect(cfg.speed == 3, 'missing key should keep the default')
	expect(cfg.extra == nil, 'unknown key should be dropped')
end)

test('config: save goes through a temp file, and load recovers an interrupted save', function()
	local Config = require('core.config').Config
	FILES = { ['app.cfg'] = textutils.serialise({ speed = 1 }) }
	quiet(function() Config:save('app.cfg', { speed = 9 }) end)
	expect(FILES['app.cfg.tmp'] == nil, 'temp file left behind')
	expect(textutils.unserialise(FILES['app.cfg']).speed == 9, 'config not saved')

	-- Crash after deleting the old file, before moving the new one in place.
	FILES = { ['app.cfg.tmp'] = textutils.serialise({ speed = 7 }) }
	local cfg = quiet(function() return Config:load('app.cfg', { speed = 1 }) end)
	expect(cfg.speed == 7, 'interrupted save not recovered (speed = ' .. tostring(cfg.speed) .. ')')
	expect(FILES['app.cfg'] ~= nil and FILES['app.cfg.tmp'] == nil, 'recovered file not put in place')
end)

test('inventory: moveAllOfItem lists the inventory once', function()
	local Inventory = require('core.inventory').Inventory
	local listCalls, sizeCalls, pushed = 0, 0, {}
	local items = { [1] = { name = 'iron', count = 10 }, [3] = { name = 'coal', count = 4 }, [5] = { name = 'iron', count = 7 } }
	local raw = {
		size = function() sizeCalls = sizeCalls + 1; return 27 end,
		list = function() listCalls = listCalls + 1; return items end,
		pushItems = function(_, slot) pushed[#pushed + 1] = slot; return items[slot].count end,
	}
	local source = new(Inventory, 'chest_a', raw)
	local target = new(Inventory, 'chest_b', {})
	local moved = source:moveAllOfItem(target, 'iron')
	table.sort(pushed)
	expect(moved == 17, 'moved ' .. moved .. ', expected 17')
	expect(table.concat(pushed, ',') == '1,5', 'pushed slots ' .. table.concat(pushed, ','))
	expect(listCalls == 1, 'list() called ' .. listCalls .. ' times, expected 1')
	expect(sizeCalls == 0, 'size() called ' .. sizeCalls .. ' times, expected 0')
end)

test('peripheral: errors name the peripheral, not a "side"', function()
	installPeripherals({})
	local P = require('core.peripheral').Peripheral
	local ok, err = pcall(quiet, function() return P:require('minecraft:chest_9') end)
	expect(not ok, 'no error raised')
	local message = type(err) == 'table' and err.message or tostring(err)
	expect(message:find("Peripheral 'minecraft:chest_9' not found", 1, true), 'message: ' .. message)
end)

-- ============================================================
-- Layout and rendering: hidden children, overflow, region redraw
-- ============================================================

test('hidden children take no space (Stack, Grid, Box)', function()
	local a = new(components.LabelComponent, { text = 'AAAA', visible = false })
	local b = new(components.LabelComponent, { text = 'B' })
	local stack = new(components.StackComponent, { direction = 'column' }, {}, { a, b })
	local runtime, terminal = runtimeFor(stack, 10, 3)
	runtime:render()
	expect(b.rect.y == 1, 'stack: visible label at y=' .. b.rect.y .. ', expected 1')

	b:setProps({ visible = false })
	a:setProps({ visible = true })
	runtime:render()
	expect(a.rect.y == 1 and terminal.line(1):find('AAAA', 1, true), 'stack after toggling visibility: "' .. terminal.line(1) .. '"')
	expect(not terminal.line(2):find('B', 1, true), 'hidden label still drawn')

	local g1 = new(components.LabelComponent, { text = 'x', visible = false })
	local g2 = new(components.LabelComponent, { text = 'y' })
	local grid = new(components.GridComponent, { columns = 2 }, {}, { g1, g2 })
	runtimeFor(grid, 10, 2):render()
	expect(g2.rect.x == 1, 'grid: visible child in column ' .. g2.rect.x .. ', expected the first')

	local big = new(components.LabelComponent, { text = 'very long text', visible = false })
	local small = new(components.LabelComponent, { text = 'ok' })
	local box = new(components.BoxComponent, {}, {}, { big, small })
	local wrapper = new(components.StackComponent, { direction = 'row' }, {}, { box })
	runtimeFor(wrapper, 20, 2):render()
	expect(box.rect.width == 2, 'box sized by a hidden child: width ' .. box.rect.width)
end)

test('children are clipped to their container', function()
	local buttons = {}
	for i = 1, 3 do buttons[i] = new(components.ButtonComponent, { label = 'Btn' .. i }) end
	local row = new(components.StackComponent, { direction = 'row', width = 10 }, {}, buttons)
	local outer = new(components.StackComponent, { direction = 'row' }, {}, { row })
	local runtime, terminal = runtimeFor(outer, 20, 1)
	runtime:render()
	local line = terminal.line(1)
	expect(line:sub(11) == string.rep(' ', 10), 'children drawn outside the 10-wide row: "' .. line .. '"')

	local pressed = 0
	buttons[3].props.onPress = nil
	buttons[3]:setProps({ onPress = function() pressed = pressed + 1 end })
	runtime:render()
	runtime:dispatch({ type = 'mouse_click', x = buttons[3].rect.x + 1, y = 1, button = 1 })
	expect(buttons[3].rect.x > 10, 'test setup: the third button should overflow the row')
	expect(pressed == 0, 'a button clipped out of its container can still be clicked')
end)

test('a redrawn region is cleared first (no leftovers)', function()
	local label = new(components.LabelComponent, { text = 'x' })
	local stack = new(components.StackComponent, { direction = 'column' }, {}, { label })
	local runtime, terminal = runtimeFor(stack, 10, 3)
	runtime:render()
	terminal.setCursorPos(5, 2); terminal.write('ZZ')
	runtime:invalidate({ reason = 'state', kind = 'region', rect = { x = 4, y = 2, width = 4, height = 1 } })
	runtime:render()
	expect(not terminal.line(2):find('ZZ', 1, true), 'stale characters left in the redrawn region: "' .. terminal.line(2) .. '"')
	expect(terminal.cell(5, 2)[3] == palette.backgroundColor, 'region not cleared with the theme background')
end)

-- ============================================================
-- Tinkers module: Smeltery, casters, materials, alloy guard
-- ============================================================

local tinkers = require('modules.tinkers.index')

-- Fake Tinkers network. Fluid storages hold { {name, amount}, ... } (bottom first) and move fluid
-- with pushFluid like CC does; a caster takes at most one casting (its capacity) and only when its
-- output slot is empty; cool(caster) turns its fluid into the finished item.
local function fakeTinkers()
	local devices = {}
	local net = { devices = devices }

	local function fluidStore(fluids, capacity)
		local store = { fluids = fluids or {}, capacity = capacity or math.huge }
		function store.total()
			local total = 0
			for _, f in ipairs(store.fluids) do total = total + f.amount end
			return total
		end
		function store.take(limit, name)
			for i, f in ipairs(store.fluids) do
				if name == nil or f.name == name then
					local n = math.min(limit, f.amount)
					f.amount = f.amount - n
					if f.amount == 0 then table.remove(store.fluids, i) end
					return f.name, n
				end
			end
			return nil, 0
		end
		function store.give(name, n)
			if store.accepts and not store.accepts(name) then return 0 end
			n = math.min(n, store.capacity - store.total())
			if n <= 0 then return 0 end
			for _, f in ipairs(store.fluids) do
				if f.name == name then f.amount = f.amount + n return n end
			end
			if store.single and #store.fluids > 0 then return 0 end
			store.fluids[#store.fluids + 1] = { name = name, amount = n }
			return n
		end
		return store
	end

	local function itemStore(size, items)
		local store = { slots = items or {}, size = size }
		function store.give(item, toSlot)
			local slots = toSlot and { toSlot } or {}
			if not toSlot then for s = 1, size do slots[#slots + 1] = s end end
			for _, s in ipairs(slots) do
				local here = store.slots[s]
				if here == nil then store.slots[s] = { name = item.name, count = item.count } return item.count end
				if here.name == item.name then here.count = here.count + item.count return item.count end
			end
			return 0
		end
		return store
	end

	local function addDevice(name, types, fluids, items)
		local object = {}
		if fluids then
			object.tanks = function()
				local t = {}
				for i, f in ipairs(fluids.fluids) do t[i] = { name = f.name, amount = f.amount } end
				return t
			end
			object.pullFluid = function(from, limit, fluidName)
				local source = devices[from]
				if not source or not source.fluids then error("Source '" .. tostring(from) .. "' is not a tank", 2) end
				local name, n = source.fluids.take(limit or math.huge, fluidName)
				if n == 0 then return 0 end
				local accepted = fluids.give(name, n)
				if accepted < n then source.fluids.give(name, n - accepted) end
				return accepted
			end
			object.pushFluid = function(to, limit, fluidName)
				local target = devices[to]
				if not target or not target.fluids then error("Target '" .. tostring(to) .. "' is not a tank", 2) end
				local name, n = fluids.take(limit or math.huge, fluidName)
				if n == 0 then return 0 end
				local accepted = target.fluids.give(name, n)
				if accepted < n then fluids.give(name, n - accepted) end
				return accepted
			end
		end
		if items then
			object.size = function() return items.size end
			object.list = function()
				local t = {}
				for slot, item in pairs(items.slots) do t[slot] = { name = item.name, count = item.count } end
				return t
			end
			object.getItemDetail = function(slot) return items.slots[slot] end
			object.pushItems = function(to, fromSlot, limit, toSlot)
				local target = devices[to]
				local item = items.slots[fromSlot]
				if not item then return 0 end
				local moved = target.items.give({ name = item.name, count = math.min(limit or item.count, item.count) }, toSlot)
				item.count = item.count - moved
				if item.count == 0 then items.slots[fromSlot] = nil end
				return moved
			end
		end
		devices[name] = { types = types, object = object, fluids = fluids, items = items }
		return devices[name]
	end

	function net.smeltery(fluids)
		addDevice('tconstruct:drain_0', { 'tconstruct:drain', 'fluid_storage' }, fluidStore(fluids))
		addDevice('tconstruct:chute_0', { 'tconstruct:chute', 'inventory' }, nil, itemStore(343))
	end

	function net.caster(name, capacity, castItem, castTags)
		local fluids = fluidStore({}, capacity)
		fluids.single = true
		local items = itemStore(2, castItem and { [1] = { name = castItem, count = 1, tags = castTags } } or {})
		fluids.accepts = function() return items.slots[2] == nil end
		return addDevice(name, { name:match('^(.-)_%d+$'), 'inventory', 'fluid_storage' }, fluids, items)
	end

	function net.reservoir(name, capacity, fluids)
		local store = fluidStore(fluids or {}, capacity)
		store.single = true
		return addDevice(name, { 'miniutilities:drum', 'fluid_storage' }, store)
	end

	function net.fuelTank(name, fluids)
		return addDevice(name, { 'tconstruct:tank', 'fluid_storage' }, fluidStore(fluids or {}, 4000))
	end

	function net.chest(name, size, items)
		return addDevice(name, { 'minecraft:chest', 'inventory' }, nil, itemStore(size, items))
	end

	function net.cool(device, itemName)
		local f = device.fluids.fluids[1]
		device.fluids.fluids = {}
		device.items.slots[2] = { name = itemName or (f.name:gsub('molten_', '') .. '_block'), count = 1 }
	end

	function net.install() installPeripherals(devices) end
	return net
end

test('tinkers: formatOfCast reads gold, sand and red sand casts', function()
	expect(tinkers.formatOfCast('tconstruct:ingot_cast') == 'ingot', 'ingot_cast')
	expect(tinkers.formatOfCast('tconstruct:nugget_sand_cast') == 'nugget', 'nugget_sand_cast')
	expect(tinkers.formatOfCast('tconstruct:gem_red_sand_cast') == 'gem', 'gem_red_sand_cast')
	expect(tinkers.formatOfCast('minecraft:iron_ingot') == nil, 'an item that is not a cast')
	expect(tinkers.formatOfCast('tinkers_reforged:large_round_plate_cast_gold') == 'large_round_plate', 'Reforged gold cast')
	expect(tinkers.formatOfCast('tinkers_reforged:great_blade_cast_red_sand') == 'great_blade', 'Reforged red sand cast')
	expect(tinkers.formatOfCast('tinkers_reforged:cast_ingot') == 'ingot', 'Reforged aluminum cast')
end)

test('tinkers: the cast format comes from its tags first, read once', function()
	local net = fakeTinkers()
	local device = net.caster('tconstruct:table_0', 540, 'mod:weird_thing', { ['tinkers_reforged:casts/multi_use/large_round_plate'] = true })
	net.install()
	local details = 0
	local getItemDetail = device.object.getItemDetail
	device.object.getItemDetail = function(slot) details = details + 1; return getItemDetail(slot) end

	local t = tinkers.Caster:fromName('tconstruct:table_0')
	expect(t:read().format == 'large_round_plate', 'format not read from the tags')
	t:read()
	expect(details == 1, 'tags read ' .. details .. ' times instead of once')
	expect(tinkers.formatOfCastTags({ ['tconstruct:casts/single_use/ingot'] = true }) == 'ingot', 'single use tag')
	expect(tinkers.formatOfCastTags({ ['forge:ingots/iron'] = true }) == nil, 'not a cast tag')
end)

test('tinkers: caster state (idle, busy, blocked) and format', function()
	local net = fakeTinkers()
	local basin = net.caster('tconstruct:basin_0', 810)
	net.caster('tconstruct:table_0', 90, 'tconstruct:ingot_cast')
	net.caster('tconstruct:table_1', 90)
	net.install()

	local b = tinkers.Caster:fromName('tconstruct:basin_0')
	local state = b:read()
	expect(b.kind == 'basin' and state.status == 'idle' and state.format == 'block', 'empty basin: ' .. state.status .. ' ' .. tostring(state.format))

	local t = tinkers.Caster:fromName('tconstruct:table_0')
	state = t:read()
	expect(t.kind == 'table' and state.format == 'ingot' and state.cast == 'tconstruct:ingot_cast', 'table with an ingot cast')

	state = tinkers.Caster:fromName('tconstruct:table_1'):read()
	expect(state.format == nil, 'a table without a cast has no format')

	basin.fluids.fluids = { { name = 'tconstruct:molten_iron', amount = 300 } }
	state = b:read()
	expect(state.status == 'busy' and state.fluid == 'tconstruct:molten_iron' and state.amount == 300, 'basin holding fluid')

	net.cool(basin)
	state = b:read()
	expect(state.status == 'blocked' and state.output.name == 'tconstruct:iron_block', 'basin with a result waiting')
end)

test('tinkers: a caster pours exactly one casting, never a partial one', function()
	local net = fakeTinkers()
	net.smeltery({ { name = 'tconstruct:molten_iron', amount = 1000 }, { name = 'tconstruct:molten_gold', amount = 500 } })
	local basin = net.caster('tconstruct:basin_0', 810)
	local tableDevice = net.caster('tconstruct:table_0', 90, 'tconstruct:ingot_cast')
	net.caster('tconstruct:table_1', 90)
	net.install()

	local smeltery = tinkers.Smeltery:fromNames('tconstruct:drain_0', 'tconstruct:chute_0')
	local b = tinkers.Caster:fromName('tconstruct:basin_0')
	local t = tinkers.Caster:fromName('tconstruct:table_0')

	expect(b:pour(smeltery, 'tconstruct:molten_gold') == 0, 'poured a block from 500 mB of gold')
	expect(#basin.fluids.fluids == 0, 'basin received a partial pour')

	expect(b:pour(smeltery, 'tconstruct:molten_iron') == 810, 'block of iron not poured')
	expect(smeltery:amountOf('tconstruct:molten_iron') == 190, 'iron left: ' .. smeltery:amountOf('tconstruct:molten_iron'))
	expect(b:pour(smeltery, 'tconstruct:molten_iron') == 0, 'poured into a busy basin')

	expect(t:pour(smeltery, 'tconstruct:molten_gold') == 90, 'ingot of gold (not the bottom fluid) not poured')
	expect(tableDevice.fluids.fluids[1].name == 'tconstruct:molten_gold', 'the table got the wrong fluid')

	expect(tinkers.Caster:fromName('tconstruct:table_1'):pour(smeltery, 'tconstruct:molten_iron') == 0, 'poured into a table without a cast')
end)

test('tinkers: cast amounts depend on the format, and on the fluid when it differs', function()
	local amounts = new(tinkers.CastAmounts, {
		{ format = 'block', amount = 810 },
		{ format = 'block', amount = 1000, fluid = 'tconstruct:molten_glass' },
		{ format = 'gear', amount = 360 },
	})
	expect(amounts:get('block', 'tconstruct:molten_iron') == 810, 'format amount')
	expect(amounts:get('block', 'tconstruct:molten_glass') == 1000, 'fluid exception')
	expect(amounts:get('block') == 810, 'no fluid given')
	expect(amounts:get('gear', 'tconstruct:molten_glass') == 360, 'an exception of another format leaked')
	expect(amounts:get('rod', 'tconstruct:molten_iron') == nil and amounts:get(nil) == nil, 'unknown format must give nil')

	local net = fakeTinkers()
	net.smeltery({ { name = 'tconstruct:molten_iron', amount = 500 }, { name = 'tconstruct:molten_glass', amount = 1000 } })
	local tableDevice = net.caster('tconstruct:table_0', 360, 'tconstruct:gear_cast')
	net.caster('tconstruct:basin_0', 1000)
	net.install()
	local smeltery = tinkers.Smeltery:fromNames('tconstruct:drain_0', 'tconstruct:chute_0')
	expect(tinkers.Caster:fromName('tconstruct:table_0'):pour(smeltery, 'tconstruct:molten_iron') == 0,
		'the default amounts know no gear: nothing must be poured')
	expect(tinkers.Caster:fromName('tconstruct:table_0', amounts):pour(smeltery, 'tconstruct:molten_iron') == 360, 'gear not poured')
	expect(tableDevice.fluids.fluids[1].amount == 360, 'wrong gear amount')
	expect(tinkers.Caster:fromName('tconstruct:basin_0', amounts):pour(smeltery, 'tconstruct:molten_glass') == 1000,
		'a glass block takes 1000 mB, not 810')
end)

test('tinkers: collect moves the result to the output, Smeltery insert and melting', function()
	local net = fakeTinkers()
	net.smeltery({})
	local basin = net.caster('tconstruct:basin_0', 810)
	local output = net.chest('minecraft:chest_out', 27)
	local input = net.chest('minecraft:chest_in', 27, { [3] = { name = 'minecraft:raw_iron', count = 5 } })
	net.install()

	local Inventory = require('core.inventory').Inventory
	local b = tinkers.Caster:fromName('tconstruct:basin_0')
	expect(b:collect(Inventory:fromName('minecraft:chest_out')) == 0, 'collected from an empty basin')

	basin.fluids.fluids = { { name = 'tconstruct:molten_iron', amount = 810 } }
	net.cool(basin)
	expect(b:collect(Inventory:fromName('minecraft:chest_out')) == 1, 'result not collected')
	expect(output.items.slots[1].name == 'tconstruct:iron_block' and b:read().status == 'idle', 'basin not idle after collecting')

	local smeltery = tinkers.Smeltery:fromNames('tconstruct:drain_0', 'tconstruct:chute_0')
	expect(smeltery:insert(Inventory:fromName('minecraft:chest_in'), 3, 2) == 2, 'items not inserted')
	local melting = smeltery:melting()
	expect(#melting == 1 and melting[1].name == 'minecraft:raw_iron' and melting[1].count == 2, 'melting items not read')
	expect(input.items.slots[3].count == 3, 'input not decremented')
end)

test('tinkers: MaterialMap finds the fluid from tags, refuses doubtful items', function()
	local map = new(tinkers.MaterialMap, {
		overrides = { { item = 'minecraft:obsidian', fluid = 'tconstruct:molten_obsidian' } },
	})
	local function fluidOf(name, tags)
		local set = {}
		for _, tag in ipairs(tags) do set[tag] = true end
		return map:fluidOf({ name = name, tags = set })
	end

	expect(fluidOf('minecraft:iron_ingot', { 'forge:ingots/iron', 'forge:ingots', 'minecraft:beacon_payment_items' })
		== 'tconstruct:molten_iron', 'iron ingot')
	expect(fluidOf('minecraft:raw_gold_block', { 'forge:storage_blocks/raw_gold' }) == 'tconstruct:molten_gold', 'raw gold block')
	expect(fluidOf('minecraft:deepslate_copper_ore', { 'forge:ores/copper', 'forge:ores_in_ground/deepslate' })
		== 'tconstruct:molten_copper', 'copper ore')
	expect(fluidOf('minecraft:obsidian', {}) == 'tconstruct:molten_obsidian', 'override ignored')
	expect(fluidOf('minecraft:stick', { 'forge:rods/wooden' }) == 'tconstruct:molten_wooden',
		'without a material list, a rod tag names its material as is')
	local strict = new(tinkers.MaterialMap, { fluids = { 'tconstruct:molten_iron', 'tinkers_reforged:molten_duralumin', 'tconstruct:blood' } })
	expect(strict:fluidOf({ name = 'minecraft:stick', tags = { ['forge:rods/wooden'] = true } }) == nil,
		'a material without a known fluid must give nil')
	expect(strict:fluidOf({ name = 'minecraft:iron_ingot', tags = { ['forge:ingots/iron'] = true } }) == 'tconstruct:molten_iron',
		'a known tconstruct fluid')
	expect(strict:fluidOf({ name = 'tinkers_reforged:duralumin_ingot', tags = { ['forge:ingots/duralumin'] = true } })
		== 'tinkers_reforged:molten_duralumin', 'a known fluid of another mod')
	expect(strict:fluidOf({ name = 'mod:weird', tags = { ['forge:ingots/iron'] = true, ['forge:ingots/wooden'] = true } }) == 'tconstruct:molten_iron',
		'a tag naming an unknown material does not hide the known one')
	expect(fluidOf('mod:weird', { 'forge:ingots/iron', 'forge:ingots/gold' }) == nil, 'two materials must give nil')
	expect(fluidOf('mod:nested', { 'forge:ores/iron/deepslate' }) == nil, 'nested tag must give nil')
	expect(map:fluidOf({ name = 'minecraft:dirt' }) == nil, 'item without tags')
end)

test('tinkers: AlloyGuard spots an alloy before it forms', function()
	local guard = new(tinkers.AlloyGuard, {
		{ result = 'tconstruct:molten_bronze', ingredients = { 'tconstruct:molten_copper', 'tconstruct:molten_tin' } },
		{ result = 'tconstruct:molten_rose_gold', ingredients = { 'tconstruct:molten_copper', 'tconstruct:molten_gold' } },
	})
	local formed = guard:wouldForm({ 'tconstruct:molten_tin', 'tconstruct:molten_iron' }, 'tconstruct:molten_copper')
	expect(formed and formed.result == 'tconstruct:molten_bronze', 'bronze not detected')
	formed = guard:wouldForm({ 'tconstruct:molten_copper' }, 'tconstruct:molten_gold')
	expect(formed and formed.result == 'tconstruct:molten_rose_gold', 'rose gold not detected')
	expect(guard:wouldForm({ 'tconstruct:molten_iron' }, 'tconstruct:molten_gold') == nil, 'iron + gold is no alloy')
	expect(guard:wouldForm({}, 'tconstruct:molten_copper') == nil, 'a single ingredient is no alloy')
	-- Copper and gold already there (rose gold forming): iron takes no part in it and must stay allowed.
	expect(guard:wouldForm({ 'tconstruct:molten_copper', 'tconstruct:molten_gold' }, 'tconstruct:molten_iron') == nil,
		'iron blamed for an alloy it takes no part in')
	local more = guard:wouldForm({ 'tconstruct:molten_copper', 'tconstruct:molten_gold' }, 'tconstruct:molten_tin')
	expect(more and more.result == 'tconstruct:molten_bronze', 'tin next to copper must still be refused (bronze)')
end)

-- ============================================================
-- Net module: rednet channel (messages, requests, replies, timeouts)
-- ============================================================

local net = require('modules.net.index')

-- Fake rednet: every send/broadcast lands in SENT (copied, as rednet serialises messages).
-- Callbacks get TSTL's implicit self first: function(_, payload, from).
-- deliver() turns the oldest sent message into the rednet_message event its receiver would see.
local function deepCopy(value)
	if type(value) ~= 'table' then return value end
	local copy = {}
	for k, v in pairs(value) do copy[k] = deepCopy(v) end
	return copy
end

local SENT = {}
local OPENED = {}
rednet = {
	open = function(name) OPENED[#OPENED + 1] = name end,
	close = function() end,
	send = function(to, message, protocol)
		SENT[#SENT + 1] = { to = to, message = deepCopy(message), protocol = protocol }
		return true
	end,
	broadcast = function(message, protocol)
		SENT[#SENT + 1] = { to = 'all', message = deepCopy(message), protocol = protocol }
	end,
	host = function() end,
	lookup = function() return nil end,
}

local function deliver(fromId)
	local sent = table.remove(SENT, 1)
	expect(sent ~= nil, 'nothing was sent')
	return { 'rednet_message', fromId, sent.message, sent.protocol }, sent
end

local function channel(options)
	options = options or {}
	options.protocol = options.protocol or 'test/v1'
	return quiet(function() return new(net.Channel, options) end)
end

test('net: open picks the wireless modem, fails without any modem', function()
	local wired = { isWireless = function() return false end }
	local wireless = { isWireless = function() return true end }
	installPeripherals({
		left = { types = { 'modem', 'peripheral_hub' }, object = wired },
		right = { types = { 'modem' }, object = wireless },
	})
	OPENED = {}
	expect(quiet(function() return channel():open() end) == 'right', 'did not pick the wireless modem')

	installPeripherals({})
	local ok = pcall(function() quiet(function() channel():open() end) end)
	expect(not ok, 'open() without a modem must fail')
end)

test('net: a message reaches its handler, other protocols and foreign messages are left out', function()
	SENT = {}
	local a, b = channel(), channel()
	local got
	b:on('hello', function(_, payload, from) got = { payload = payload, from = from } end)

	a:send(7, 'hello', { n = 1 })
	local event, sent = deliver(1)
	expect(sent.to == 7 and sent.protocol == 'test/v1', 'sent to the wrong computer or protocol')
	expect(b:handleEvent(event) == true and got.payload.n == 1 and got.from == 1, 'handler not called with payload and sender')
	expect(#SENT == 0, 'a plain message must not be answered')

	expect(b:handleEvent({ 'rednet_message', 1, { net = 1, type = 'hello' }, 'other' }) == false, 'other protocol consumed')
	expect(b:handleEvent({ 'rednet_message', 1, 'plain text', 'test/v1' }) == true, 'foreign message not consumed')
	expect(b:handleEvent({ 'mouse_click', 1, 2, 3 }) == false, 'unrelated event consumed')
end)

test('net: a request gets the handler result as its reply', function()
	SENT = {}
	local client, server = channel(), channel()
	server:on('add', function(_, payload) return payload.a + payload.b end)

	local result
	client:request(2, 'add', { a = 2, b = 3 }, function(_, r) result = r end)
	expect(client:pendingCount() == 1, 'request not pending')

	quiet(function() server:handleEvent((deliver(1))) end)
	expect(client:handleEvent((deliver(2))) == true, 'reply not consumed')
	expect(result and result.ok and result.value == 5, 'reply value not received')
	expect(client:pendingCount() == 0, 'request still pending after its reply')
end)

test('net: failed requests (handler error, unknown type) reply with an error', function()
	SENT = {}
	local client, server = channel(), channel()
	server:on('boom', function() error('cannot do that', 0) end)

	local r1, r2
	client:request(2, 'boom', nil, function(_, r) r1 = r end)
	client:request(2, 'nope', nil, function(_, r) r2 = r end)
	quiet(function()
		server:handleEvent((deliver(1)))
		server:handleEvent((deliver(1)))
	end)
	client:handleEvent((deliver(2)))
	client:handleEvent((deliver(2)))
	expect(r1 and not r1.ok and tostring(r1.error):find('cannot do that', 1, true), 'handler error not sent back: ' .. tostring(r1 and r1.error))
	expect(r2 and not r2.ok and tostring(r2.error):find('unknown message type', 1, true), 'unknown type not refused')
end)

test('net: a request times out, a late reply or one from another computer is ignored', function()
	SENT = {}
	local client, server = channel(), channel()
	server:on('slow', function() return 'late' end)

	local calls, result = 0, nil
	client:request(2, 'slow', nil, function(_, r) calls = calls + 1; result = r end, 1)
	local timer = LAST_TIMER

	quiet(function() server:handleEvent((deliver(1))) end)
	local reply = deliver(2)
	reply[2] = 9 -- the reply comes from computer 9, not 2
	client:handleEvent(reply)
	expect(calls == 0, 'a reply from another computer was accepted')

	expect(client:handleEvent({ 'timer', timer }) == true, 'timeout timer not consumed')
	expect(calls == 1 and not result.ok and result.error == 'timeout', 'no timeout error')

	reply[2] = 2
	client:handleEvent(reply)
	expect(calls == 1, 'a late reply called the callback again')
	expect(client:handleEvent({ 'timer', 999 }) == false, 'a foreign timer was consumed')
end)

test('net: peers filter out other computers, broadcasts are never answered', function()
	SENT = {}
	local server = channel({ peers = { 4 } })
	local count = 0
	server:on('ping', function() count = count + 1; return 'pong' end)

	server:handleEvent({ 'rednet_message', 5, { net = 1, type = 'ping', id = 1 }, 'test/v1' })
	expect(count == 0 and #SENT == 0, 'message from a computer outside the peers handled')

	local sender = channel()
	sender:broadcast('ping')
	local event, sent = deliver(4)
	expect(sent.to == 'all', 'broadcast not sent to all')
	server:handleEvent(event)
	expect(count == 1 and #SENT == 0, 'broadcast not handled, or answered')
end)

-- ============================================================
-- Smeltery project: role of the computer, catalogue
-- ============================================================

-- Runs projects/smeltery/main.lua with arguments; returns what it printed. The controller and display
-- loops never return: stand-ins that only print their role replace them.
local function runSmelteryMain(...)
	local printed = {}
	local realController = package.loaded['projects.smeltery.controller.controller']
	local realDisplay = package.loaded['projects.smeltery.display.display']
	package.loaded['projects.smeltery.controller.controller'] = { runController = function() print('role: controller') end }
	package.loaded['projects.smeltery.display.display'] = { runDisplay = function() print('role: display') end }
	local chunk = assert(loadfile(luasDir .. '/projects/smeltery/main.lua'))
	print = function(...)
		local parts = {}
		for i = 1, select('#', ...) do parts[i] = tostring(select(i, ...)) end
		printed[#printed + 1] = table.concat(parts, ' ')
	end
	local ok, err = pcall(chunk, ...)
	print = realPrint
	package.loaded['projects.smeltery.controller.controller'] = realController
	package.loaded['projects.smeltery.display.display'] = realDisplay
	if not ok then error(err, 0) end
	return table.concat(printed, '\n')
end

test('smeltery: the role comes from the argument, then the saved one, then the peripherals', function()
	FILES = {}
	installPeripherals({ ['tconstruct:drain_0'] = { types = { 'tconstruct:drain', 'fluid_storage' }, object = {} } })
	expect(runSmelteryMain():find('role: controller', 1, true), 'a computer next to a drain must be the controller')

	installPeripherals({ top = { types = { 'monitor' }, object = {} } })
	expect(runSmelteryMain():find('role: controller', 1, true), 'the saved role must win over the peripherals')

	expect(runSmelteryMain('display'):find('role: display', 1, true), 'the argument must win')
	expect(runSmelteryMain():find('role: display', 1, true), 'the role given as argument must be saved')

	FILES = {}
	installPeripherals({})
	expect(runSmelteryMain():find('No Smeltery drain nor monitor', 1, true), 'no role without drain nor monitor')
	expect(runSmelteryMain('oops'):find('Usage', 1, true), 'a wrong argument must show the usage')
end)

test('smeltery: main finds core/ and modules/ with the require of CC (program folder only)', function()
	-- In CC:Tweaked, require looks next to the program and in /rom, not at the root. The build adds the
	-- root to package.path on the first line of main.lua; here the root is luasDir.
	local file = assert(io.open(luasDir .. '/projects/smeltery/main.lua'))
	local source = file:read('*a')
	file:close()
	local firstLine = source:match('^[^\n]*')
	expect(firstLine == 'package.path = "/?.lua;/?/init.lua;" .. package.path', 'first line of main.lua: ' .. firstLine)

	local savedPath, savedLoaded = package.path, {}
	for name, value in pairs(package.loaded) do
		if name:match('^core%.') or name:match('^modules%.') or name:match('^projects%.') or name:match('^utils%.') then
			savedLoaded[name] = value
			package.loaded[name] = nil
		end
	end

	package.path = luasDir .. '/projects/smeltery/?.lua'
	local chunk = assert((loadstring or load)(source:gsub('"/%?%.lua;/%?/init%.lua;"', '"' .. luasDir .. '/?.lua;"', 1), '=main'))
	local printed = {}
	print = function(text) printed[#printed + 1] = tostring(text) end
	local ok, err = pcall(chunk, 'oops')
	print = realPrint
	package.path = savedPath
	for name, value in pairs(savedLoaded) do package.loaded[name] = value end

	expect(ok, 'main.lua could not load its modules: ' .. tostring(err))
	expect(table.concat(printed):find('Usage', 1, true), 'main.lua did not run to the end')
end)

test('smeltery: the default catalogue is written once, then read from its file', function()
	FILES = {}
	local catalogue = require('projects.smeltery.shared.catalogue')
	local c = quiet(function() return catalogue.loadCatalogue() end)
	expect(FILES['/smeltery/catalogue.db'] ~= nil, 'catalogue file not written')

	local guard = catalogue.alloyGuardOf(c)
	local bronze = guard:wouldForm({ 'tconstruct:molten_tin' }, 'tconstruct:molten_copper')
	expect(bronze and bronze.result == 'tconstruct:molten_bronze', 'bronze missing from the default catalogue')
	expect(guard:wouldForm({ 'tconstruct:molten_iron' }, 'tconstruct:molten_gold') == nil, 'iron + gold must stay allowed')

	local amounts = catalogue.castAmountsOf(c)
	expect(amounts:get('gear', 'tconstruct:molten_iron') == 360, 'gear amount (360 mB, checked in game)')
	expect(amounts:get('block', 'tconstruct:molten_diamond') == 900, 'diamond block amount')
	expect(amounts:get('pick_head', 'tconstruct:molten_iron') == 180, 'pick head amount')

	local map = catalogue.materialMapOf(c)
	expect(map:fluidOf({ name = 'x:duralumin_ingot', tags = { ['forge:ingots/duralumin'] = true } }) == 'tinkers_reforged:molten_duralumin',
		'a Tinkers Reforged metal must map to its own fluid')

	-- A local change in the file survives the next start.
	local edited = textutils.unserialise(FILES['/smeltery/catalogue.db'])
	edited.overrides = { { item = 'minecraft:obsidian', fluid = 'tconstruct:molten_obsidian' } }
	FILES['/smeltery/catalogue.db'] = textutils.serialise(edited)
	c = quiet(function() return catalogue.loadCatalogue() end)
	expect(#c.overrides == 1 and catalogue.materialMapOf(c):fluidOf({ name = 'minecraft:obsidian' }) == 'tconstruct:molten_obsidian',
		'local override lost')
end)

-- ============================================================
-- Smeltery controller: planner (pure) and controller on fake peripherals
-- ============================================================

os.epoch = os.epoch or function() return 0 end

local planner = require('projects.smeltery.controller.planner')

local IRON, GOLD = 'tconstruct:molten_iron', 'tconstruct:molten_gold'
local COPPER, TIN = 'tconstruct:molten_copper', 'tconstruct:molten_tin'

local IESNIUM = 'materialis:molten_iesnium'
local TEMPERATURES = { [IRON] = 800, [GOLD] = 700, [COPPER] = 500, [TIN] = 525, [IESNIUM] = 1090 }

local function planContext()
	return {
		guard = new(tinkers.AlloyGuard, { { result = 'tconstruct:molten_bronze', ingredients = { COPPER, TIN } } }),
		amounts = new(tinkers.CastAmounts),
		formatPriority = { 'block', 'ingot', 'nugget' },
		meltingTemperature = function(_, fluid) return TEMPERATURES[fluid] end,
		fuelTemperature = 1000,
	}
end

local function snapshot(fields)
	local s = { fluids = {}, meltingFluids = {}, casters = {}, input = {}, outputFree = 10, stored = {}, storable = {} }
	for k, v in pairs(fields) do s[k] = v end
	return s
end

local function kinds(plan)
	local out = {}
	for _, a in ipairs(plan.actions) do
		out[#out + 1] = a.kind .. ':' .. (a.caster or a.name or '') .. (a.fluid and ('/' .. a.fluid:gsub('tconstruct:molten_', '')) or '')
	end
	return table.concat(out, ' ')
end

local basinIdle = { name = 'basin_0', state = { status = 'idle', format = 'block', amount = 0 } }
local tableIdle = { name = 'table_0', state = { status = 'idle', format = 'ingot', amount = 0 } }
local nuggetIdle = { name = 'table_1', state = { status = 'idle', format = 'nugget', amount = 0 } }
local gearIdle = { name = 'table_2', state = { status = 'idle', format = 'gear', amount = 0 } }
local basinBlocked = { name = 'basin_1', state = { status = 'blocked', format = 'block', amount = 0 } }

test('planner: idle does nothing, manual only collects, lock collects and casts but inserts nothing', function()
	local s = snapshot({
		fluids = { { name = IRON, amount = 900 } },
		casters = { basinIdle, basinBlocked },
		input = { { slot = 1, name = 'minecraft:raw_gold', count = 4, fluid = GOLD } },
	})
	expect(#planner.planTick('idle', s, planContext()).actions == 0, 'idle planned something')
	expect(kinds(planner.planTick('manual', s, planContext())) == 'collect:basin_1', 'manual: ' .. kinds(planner.planTick('manual', s, planContext())))
	expect(kinds(planner.planTick('lock', s, planContext())) == 'collect:basin_1 pour:basin_0/iron', 'lock: ' .. kinds(planner.planTick('lock', s, planContext())))
	local auto = kinds(planner.planTick('auto', s, planContext()))
	expect(auto == 'collect:basin_1 pour:basin_0/iron insert:minecraft:raw_gold/gold', 'auto: ' .. auto)
end)

test('planner: only the biggest format a fluid fills, smaller ones once it is below', function()
	local s = snapshot({
		fluids = { { name = IRON, amount = 905 }, { name = GOLD, amount = 20 } },
		casters = { gearIdle, nuggetIdle, tableIdle, basinIdle },
	})
	local plan = planner.planTick('lock', s, planContext())
	-- 905 iron fills a block: only the basin, no ingot meanwhile. 20 gold fills only a nugget.
	expect(kinds(plan) == 'pour:basin_0/iron pour:table_1/gold', 'got ' .. kinds(plan))

	-- 1700 iron while the basin is cooling: wait for it, no ingots.
	local basinBusy = { name = 'basin_0', state = { status = 'busy', format = 'block', amount = 810, fluid = IRON } }
	s = snapshot({ fluids = { { name = IRON, amount = 1700 } }, casters = { basinBusy, tableIdle, nuggetIdle } })
	expect(#planner.planTick('lock', s, planContext()).actions == 0, 'cast ingots while a block was possible: ' .. kinds(planner.planTick('lock', s, planContext())))

	-- 95 iron left: an ingot; the nugget table waits for the next tick.
	s = snapshot({ fluids = { { name = IRON, amount = 95 } }, casters = { basinIdle, tableIdle, nuggetIdle } })
	expect(kinds(planner.planTick('lock', s, planContext())) == 'pour:table_0/iron', 'below a block: ' .. kinds(planner.planTick('lock', s, planContext())))

	-- Two basins and 1700 iron: two blocks at once. A format without caster is skipped.
	local basin2 = { name = 'basin_2', state = { status = 'idle', format = 'block', amount = 0 } }
	s = snapshot({ fluids = { { name = IRON, amount = 1700 } }, casters = { basinIdle, basin2 } })
	expect(kinds(planner.planTick('lock', s, planContext())) == 'pour:basin_0/iron pour:basin_2/iron', 'two basins: ' .. kinds(planner.planTick('lock', s, planContext())))
	s = snapshot({ fluids = { { name = IRON, amount = 1700 } }, casters = { tableIdle } })
	expect(kinds(planner.planTick('lock', s, planContext())) == 'pour:table_0/iron', 'no basin: ingots must be cast')
end)

test('planner: an item hotter than the fuel waits in the input', function()
	local s = snapshot({ input = {
		{ slot = 1, name = 'occultism:raw_iesnium', count = 64, fluid = IESNIUM },
		{ slot = 2, name = 'minecraft:raw_iron', count = 3, fluid = IRON },
	} })
	local plan = planner.planTick('auto', s, planContext())
	expect(kinds(plan) == 'insert:minecraft:raw_iron/iron', 'got ' .. kinds(plan))
	expect(plan.waiting[1].reason == 'heat' and plan.waiting[1].temperature == 1090, 'iesnium must wait for heat')

	local hot = planContext()
	hot.fuelTemperature = 1500
	expect(#planner.planTick('auto', s, hot).actions == 2, 'with blazing blood (1500) iesnium must go in')
	hot.fuelTemperature = nil
	expect(#planner.planTick('auto', s, hot).actions == 2, 'an unknown fuel checks nothing')
end)

test('planner: rejected items leave the input only when an inventory is set for them', function()
	local s = snapshot({ input = {
		{ slot = 1, name = 'occultism:raw_iesnium', count = 64, fluid = IESNIUM },
		{ slot = 2, name = 'minecraft:dirt', count = 5 },
	} })
	local context = planContext()
	context.reject = { heat = true, unknown = false }
	local plan = planner.planTick('auto', s, context)
	expect(kinds(plan) == 'reject:occultism:raw_iesnium' and plan.actions[1].reason == 'heat' and plan.actions[1].temperature == 1090,
		'iesnium not rejected for heat: ' .. kinds(plan))
	expect(plan.waiting[1].name == 'minecraft:dirt' and plan.waiting[1].reason == 'unknown', 'dirt must wait: no unknown output')
	context.reject = { heat = false, unknown = true }
	plan = planner.planTick('auto', s, context)
	expect(kinds(plan) == 'reject:minecraft:dirt' and plan.actions[1].reason == 'unknown', 'dirt not rejected: ' .. kinds(plan))
	expect(#planner.planTick('lock', s, context).actions == 0, 'lock must not touch the input')
end)

test('planner: drain sends every fluid to the reservoirs, then finishes', function()
	local s = snapshot({
		fluids = { { name = IRON, amount = 900 }, { name = GOLD, amount = 40 } },
		casters = { basinIdle, basinBlocked }, storable = { IRON, GOLD },
	})
	local plan = planner.planTick('drain', s, planContext())
	expect(kinds(plan) == 'collect:basin_1 store:/iron store:/gold' and not plan.finished, 'drain: ' .. kinds(plan))

	s = snapshot({ fluids = { { name = COPPER, amount = 50 } }, storable = {} })
	plan = planner.planTick('drain', s, planContext())
	expect(#plan.actions == 0 and plan.finished and plan.alerts[1]:find('no reservoir', 1, true), 'copper without room must alert and finish')

	s = snapshot({ meltingFluids = { IRON } })
	expect(not planner.planTick('drain', s, planContext()).finished, 'drain must wait for what is still melting')
end)

test('planner: purge sends leftovers and alloys only, then finishes', function()
	local context = planContext()
	context.isAlloy = function(_, fluid) return fluid == 'tconstruct:molten_bronze' end
	local s = snapshot({
		fluids = { { name = IRON, amount = 900 }, { name = GOLD, amount = 5 }, { name = 'tconstruct:molten_bronze', amount = 300 } },
		casters = { basinIdle, tableIdle, nuggetIdle }, storable = { IRON, GOLD, 'tconstruct:molten_bronze' },
	})
	local plan = planner.planTick('purge', s, context)
	expect(kinds(plan) == 'store:/gold store:/bronze' and not plan.finished, 'purge: ' .. kinds(plan))

	s = snapshot({ fluids = { { name = IRON, amount = 900 } }, casters = { basinIdle, nuggetIdle }, storable = { IRON } })
	plan = planner.planTick('purge', s, context)
	expect(#plan.actions == 0 and plan.finished, 'nothing to purge must finish')
end)

test('planner: auto purges a leftover only when it blocks an input', function()
	local s = snapshot({
		fluids = { { name = COPPER, amount = 5 } }, casters = { basinIdle, nuggetIdle }, storable = { COPPER },
		input = { { slot = 1, name = 'mod:tin_ingot', count = 4, fluid = TIN } },
	})
	local plan = planner.planTick('auto', s, planContext())
	expect(kinds(plan) == 'store:/copper' and plan.actions[1].why == 'unblock' and plan.waiting[1].reason == 'alloy',
		'5 mB of copper blocking tin must be stored: ' .. kinds(plan))

	s.fluids = { { name = COPPER, amount = 900 } }
	plan = planner.planTick('auto', s, planContext())
	expect(not kinds(plan):find('store', 1, true), 'a castable amount of copper must not be stored: ' .. kinds(plan))

	s = snapshot({ fluids = { { name = COPPER, amount = 5 } }, casters = { basinIdle, nuggetIdle }, storable = { COPPER } })
	expect(#planner.planTick('auto', s, planContext()).actions == 0, 'a leftover that blocks nothing must stay')
end)

test('planner: auto completes a cast from the stock, never pours smaller meanwhile', function()
	local s = snapshot({
		fluids = { { name = IRON, amount = 700 } }, casters = { basinIdle, tableIdle },
		stored = { { fluid = IRON, amount = 300 } },
	})
	local plan = planner.planTick('auto', s, planContext())
	expect(kinds(plan) == 'restore:/iron' and plan.actions[1].amount == 110, '700 + 110 from the stock = a block: ' .. kinds(plan))

	s.stored = { { fluid = IRON, amount = 50 } }
	plan = planner.planTick('auto', s, planContext())
	expect(kinds(plan) == 'pour:table_0/iron', 'not enough stock for a block: ingots as usual: ' .. kinds(plan))

	s.stored = { { fluid = GOLD, amount = 900 } }
	plan = planner.planTick('auto', s, planContext())
	expect(not kinds(plan):find('restore', 1, true), 'gold must not come back while only iron is there')
end)

test('planner: nothing is cast while the output is full', function()
	local s = snapshot({ fluids = { { name = IRON, amount = 900 } }, casters = { basinIdle }, outputFree = 0 })
	local plan = planner.planTick('auto', s, planContext())
	expect(#plan.actions == 0 and plan.alerts[1] and plan.alerts[1]:find('output full', 1, true), 'cast with a full output')
end)

test('planner: unknown items and alloys wait, the guard sees the Smeltery, melting items and this plan', function()
	local s = snapshot({
		fluids = { { name = COPPER, amount = 10 } },
		input = {
			{ slot = 1, name = 'minecraft:stick', count = 3 },
			{ slot = 2, name = 'mod:tin_ingot', count = 2, fluid = TIN },
			{ slot = 5, name = 'mod:tin_ingot', count = 1, fluid = TIN },
			{ slot = 3, name = 'minecraft:raw_iron', count = 8, fluid = IRON },
		},
	})
	local plan = planner.planTick('auto', s, planContext())
	expect(kinds(plan) == 'insert:minecraft:raw_iron/iron', 'got ' .. kinds(plan))
	local reasons = {}
	for _, w in ipairs(plan.waiting) do reasons[w.name] = w end
	expect(reasons['minecraft:stick'].reason == 'unknown' and reasons['minecraft:stick'].count == 3, 'stick must wait as unknown')
	expect(reasons['mod:tin_ingot'].reason == 'alloy' and reasons['mod:tin_ingot'].alloy == 'tconstruct:molten_bronze'
		and reasons['mod:tin_ingot'].count == 3, 'tin must wait (bronze), both stacks counted')

	-- Copper still melting counts as copper.
	s = snapshot({ meltingFluids = { COPPER }, input = { { slot = 1, name = 'mod:tin_ingot', count = 1, fluid = TIN } } })
	expect(#planner.planTick('auto', s, planContext()).actions == 0, 'tin inserted while copper is melting')

	-- Copper and tin both in the input of an empty Smeltery: the first goes in, the second waits.
	s = snapshot({ input = {
		{ slot = 1, name = 'minecraft:copper_ingot', count = 1, fluid = COPPER },
		{ slot = 2, name = 'mod:tin_ingot', count = 1, fluid = TIN },
	} })
	plan = planner.planTick('auto', s, planContext())
	expect(kinds(plan) == 'insert:minecraft:copper_ingot/copper' and plan.waiting[1].reason == 'alloy', 'got ' .. kinds(plan))
end)

test('controller: auto mode casts, melts the input, collects, and keeps its mode', function()
	FILES = {}
	local fake = fakeTinkers()
	fake.smeltery({ { name = IRON, amount = 900 } })
	local basin = fake.caster('tconstruct:basin_0', 810)
	fake.caster('tconstruct:table_0', 90, 'tconstruct:ingot_cast')
	local input = fake.chest('minecraft:chest_in', 27, {
		[2] = { name = 'minecraft:raw_gold', count = 3, tags = { ['forge:raw_materials/gold'] = true } },
		[4] = { name = 'minecraft:stick', count = 1, tags = { ['forge:rods/wooden'] = true } },
	})
	local output = fake.chest('minecraft:chest_out', 27)
	fake.install()

	local controllerModule = require('projects.smeltery.controller.controller')
	local catalogue = require('projects.smeltery.shared.catalogue')
	local config = require('projects.smeltery.controller.config').defaultControllerConfig()
	config.input, config.output = 'minecraft:chest_in', 'minecraft:chest_out'

	local c = quiet(function() return new(controllerModule.Controller, config, catalogue.defaultCatalogue()) end)
	expect(c:getMode() == 'idle', 'the first start must be idle')
	quiet(function() c:tick() end)
	expect(basin.fluids.fluids[1] == nil, 'idle poured')

	quiet(function() c:setMode('auto'); c:tick() end)
	expect(basin.fluids.fluids[1] and basin.fluids.fluids[1].amount == 810, 'no block poured')
	local chute = fake.devices['tconstruct:chute_0'].items.slots
	expect(chute[1] and chute[1].name == 'minecraft:raw_gold' and chute[1].count == 3, 'raw gold not sent to the Smeltery')
	expect(input.items.slots[4] and input.items.slots[4].count == 1, 'the stick must stay in the input')

	local state = c:getState()
	-- 900 mB of iron: a block first (810); the 90 left wait for the next tick to become an ingot.
	expect(state.mode == 'auto' and #state.casters == 2 and state.fluids[1].amount == 90, 'state not built, or wrong iron left')
	expect(fake.devices['tconstruct:table_0'].fluids.fluids[1] == nil, 'an ingot was cast while a block was possible')
	quiet(function() c:tick() end)
	expect(fake.devices['tconstruct:table_0'].fluids.fluids[1].amount == 90, 'the 90 mB left not cast as an ingot')
	expect(state.waiting[1] and state.waiting[1].name == 'minecraft:stick' and state.waiting[1].reason == 'unknown', 'stick not reported')
	expect(#state.alerts == 0, 'unexpected alert: ' .. tostring(state.alerts[1]))

	fake.cool(basin)
	quiet(function() c:tick() end)
	expect(output.items.slots[1] and output.items.slots[1].name == 'tconstruct:iron_block', 'block not collected')

	-- Mode saved: a new controller starts in auto.
	local again = quiet(function() return new(controllerModule.Controller, config, catalogue.defaultCatalogue()) end)
	expect(again:getMode() == 'auto', 'mode not restored')
end)

test('controller: copper is refused while gold is in the Smeltery (rose gold)', function()
	FILES = {}
	local fake = fakeTinkers()
	fake.smeltery({ { name = IRON, amount = 400 }, { name = GOLD, amount = 7000 } })
	fake.caster('tconstruct:basin_0', 810)
	local input = fake.chest('minecraft:chest_in', 27, {
		[1] = { name = 'minecraft:raw_copper', count = 64, tags = { ['forge:raw_materials/copper'] = true, ['forge:raw_materials'] = true } },
	})
	fake.chest('minecraft:chest_out', 27)
	fake.install()

	local controllerModule = require('projects.smeltery.controller.controller')
	local catalogue = require('projects.smeltery.shared.catalogue')
	local config = require('projects.smeltery.controller.config').defaultControllerConfig()
	config.input, config.output = 'minecraft:chest_in', 'minecraft:chest_out'
	local c = quiet(function() return new(controllerModule.Controller, config, catalogue.defaultCatalogue()) end)
	quiet(function() c:setMode('auto'); c:tick() end)

	expect(input.items.slots[1] and input.items.slots[1].count == 64, 'raw copper was sent next to gold')
	local waiting = c:getState().waiting[1]
	expect(waiting and waiting.reason == 'alloy' and waiting.alloy == 'tconstruct:molten_rose_gold', 'copper not reported as waiting for rose gold')
end)

test('controller: an item that finishes melting during the reading is still seen (no rose gold)', function()
	-- In game the reading takes several ticks: copper read as items in the chute can be molten by the
	-- time the fluids are read, or the other way round. It must be seen in one of them, never in none.
	FILES = {}
	local fake = fakeTinkers()
	fake.smeltery({})
	fake.caster('tconstruct:basin_0', 810)
	local input = fake.chest('minecraft:chest_in', 27, {
		[1] = { name = 'minecraft:raw_gold', count = 64, tags = { ['forge:raw_materials/gold'] = true } },
	})
	fake.chest('minecraft:chest_out', 27)
	local chute = fake.devices['tconstruct:chute_0']
	chute.items.slots[1] = { name = 'minecraft:raw_copper', count = 16, tags = { ['forge:raw_materials/copper'] = true } }
	fake.install()

	-- The copper finishes melting right after any peripheral call made once the controller is ticking.
	local drain = fake.devices['tconstruct:drain_0']
	local melted = false
	local function melt()
		if not melted and chute.items.slots[1] then
			melted = true
			chute.items.slots[1] = nil
			drain.fluids.fluids[#drain.fluids.fluids + 1] = { name = COPPER, amount = 1920 }
		end
	end

	local controllerModule = require('projects.smeltery.controller.controller')
	local catalogue = require('projects.smeltery.shared.catalogue')
	local config = require('projects.smeltery.controller.config').defaultControllerConfig()
	config.input, config.output = 'minecraft:chest_in', 'minecraft:chest_out'

	-- Whatever peripheral call comes first, the melting happens right after it.
	for _, first in ipairs({ 'drain', 'chute' }) do
		FILES = {}
		melted = false
		drain.fluids.fluids = {}
		chute.items.slots[1] = { name = 'minecraft:raw_copper', count = 16, tags = { ['forge:raw_materials/copper'] = true } }
		input.items.slots[1] = { name = 'minecraft:raw_gold', count = 64, tags = { ['forge:raw_materials/gold'] = true } }
		local c = quiet(function() return new(controllerModule.Controller, config, catalogue.defaultCatalogue()) end)
		quiet(function() c:setMode('auto'); c:tick() end) -- connect and warm the caches

		local device = first == 'drain' and drain.object or chute.object
		local method = first == 'drain' and 'tanks' or 'list'
		local original = device[method]
		device[method] = function(...)
			local result = original(...)
			melt()
			return result
		end
		melted = false
		drain.fluids.fluids = {}
		chute.items.slots[1] = { name = 'minecraft:raw_copper', count = 16, tags = { ['forge:raw_materials/copper'] = true } }
		input.items.slots[1] = { name = 'minecraft:raw_gold', count = 64, tags = { ['forge:raw_materials/gold'] = true } }
		quiet(function() c:tick() end)
		device[method] = original

		expect(input.items.slots[1] and input.items.slots[1].count == 64,
			'raw gold sent while copper was melting (melting right after the first ' .. method .. '() call)')
	end
end)

test('controller: an unidentifiable melting item pauses the input and poisons no cache', function()
	FILES = {}
	local fake = fakeTinkers()
	fake.smeltery({})
	fake.caster('tconstruct:basin_0', 810)
	local input = fake.chest('minecraft:chest_in', 27, {
		[1] = { name = 'minecraft:raw_gold', count = 64, tags = { ['forge:raw_materials/gold'] = true } },
	})
	fake.chest('minecraft:chest_out', 27)
	local chute = fake.devices['tconstruct:chute_0']
	chute.items.slots[1] = { name = 'minecraft:raw_copper', count = 16, tags = { ['forge:raw_materials/copper'] = true } }
	fake.install()
	-- The copper melts before its detail can be read: list() still showed it, getItemDetail() finds nothing.
	chute.object.getItemDetail = function() return nil end

	local controllerModule = require('projects.smeltery.controller.controller')
	local catalogue = require('projects.smeltery.shared.catalogue')
	local config = require('projects.smeltery.controller.config').defaultControllerConfig()
	config.input, config.output = 'minecraft:chest_in', 'minecraft:chest_out'
	local c = quiet(function() return new(controllerModule.Controller, config, catalogue.defaultCatalogue()) end)
	quiet(function() c:setMode('auto'); c:tick() end)

	expect(input.items.slots[1].count == 64, 'raw gold sent next to an unidentified melting item')
	expect(table.concat(c:getState().alerts, ' '):find('cannot be identified', 1, true), 'no alert for the paused input')

	-- Next tick the copper is readable: it must be recognised (not cached as "melts into nothing").
	chute.object.getItemDetail = function(slot) return chute.items.slots[slot] end
	quiet(function() c:tick() end)
	local waiting = c:getState().waiting[1]
	expect(waiting and waiting.reason == 'alloy' and input.items.slots[1].count == 64, 'copper not recognised after a failed detail')
end)

test('controller: too hot and unknown items go to their own inventories', function()
	FILES = {}
	local fake = fakeTinkers()
	fake.smeltery({})
	fake.caster('tconstruct:basin_0', 810)
	fake.chest('minecraft:chest_in', 27, {
		[1] = { name = 'occultism:raw_iesnium', count = 64, tags = { ['forge:raw_materials/iesnium'] = true } },
		[2] = { name = 'minecraft:dirt', count = 5, tags = {} },
		[3] = { name = 'minecraft:raw_iron', count = 2, tags = { ['forge:raw_materials/iron'] = true } },
	})
	fake.chest('minecraft:chest_out', 27)
	local heat = fake.chest('minecraft:chest_heat', 27)
	local unknown = fake.chest('minecraft:chest_unknown', 27)
	fake.install()

	local controllerModule = require('projects.smeltery.controller.controller')
	local catalogue = require('projects.smeltery.shared.catalogue')
	local config = require('projects.smeltery.controller.config').defaultControllerConfig()
	config.input, config.output = 'minecraft:chest_in', 'minecraft:chest_out'
	config.heatOutput, config.unknownOutput = 'minecraft:chest_heat', 'minecraft:chest_unknown'

	local c = quiet(function() return new(controllerModule.Controller, config, catalogue.defaultCatalogue()) end)
	quiet(function() c:setMode('auto'); c:tick() end)
	expect(heat.items.slots[1] and heat.items.slots[1].name == 'occultism:raw_iesnium' and heat.items.slots[1].count == 64, 'iesnium not moved')
	expect(unknown.items.slots[1] and unknown.items.slots[1].name == 'minecraft:dirt', 'dirt not moved')
	expect(fake.devices['tconstruct:chute_0'].items.slots[1].name == 'minecraft:raw_iron', 'iron not melted')
	expect(#c:getState().waiting == 0 and #c:getState().alerts == 0, 'nothing should wait nor alert')
end)

local function controllerWith(fake, configure)
	local controllerModule = require('projects.smeltery.controller.controller')
	local catalogue = require('projects.smeltery.shared.catalogue')
	local config = require('projects.smeltery.controller.config').defaultControllerConfig()
	config.input, config.output = 'minecraft:chest_in', 'minecraft:chest_out'
	if configure then configure(config) end
	return quiet(function() return new(controllerModule.Controller, config, catalogue.defaultCatalogue()) end)
end

test('controller: the fuel tank gives the heat; an empty tank pauses the input', function()
	FILES = {}
	local fake = fakeTinkers()
	fake.smeltery({})
	fake.caster('tconstruct:basin_0', 810)
	local fuel = fake.fuelTank('tconstruct:seared_fuel_tank_0', { { name = 'tconstruct:blazing_blood', amount = 2000 } })
	local input = fake.chest('minecraft:chest_in', 27, {
		[1] = { name = 'occultism:raw_iesnium', count = 8, tags = { ['forge:raw_materials/iesnium'] = true } },
	})
	fake.chest('minecraft:chest_out', 27)
	fake.install()

	local c = controllerWith(fake)
	quiet(function() c:setMode('auto'); c:tick() end)
	local state = c:getState()
	expect(state.fuel and state.fuel.fluid == 'tconstruct:blazing_blood' and state.fuel.temperature == 1500 and state.heat == 1500,
		'fuel not read from the tank')
	expect(input.items.slots[1] == nil, 'iesnium (1090 K) must go in with blazing blood (1500 K)')

	fuel.fluids.fluids = {}
	input.items.slots[2] = { name = 'minecraft:raw_iron', count = 4, tags = { ['forge:raw_materials/iron'] = true } }
	quiet(function() c:tick() end)
	expect(input.items.slots[2] and input.items.slots[2].count == 4, 'iron sent while the fuel tank is empty')
	expect(table.concat(c:getState().alerts, ' '):find('fuel tank empty', 1, true), 'no alert for the empty fuel tank')
end)

test('controller: manual insert can be forced (alloy, heat) but never for an unknown item', function()
	FILES = {}
	local fake = fakeTinkers()
	fake.smeltery({ { name = COPPER, amount = 900 } })
	fake.caster('tconstruct:basin_0', 810)
	local input = fake.chest('minecraft:chest_in', 27, {
		[1] = { name = 'mod:raw_tin', count = 12, tags = { ['forge:raw_materials/tin'] = true } },
		[2] = { name = 'minecraft:dirt', count = 5, tags = {} },
	})
	fake.chest('minecraft:chest_out', 27)
	fake.install()

	local c = controllerWith(fake)
	quiet(function() c:setMode('manual'); c:tick() end)
	local items = c:getState().inputItems
	expect(items[1].status == 'alloy' and items[1].alloy == 'tconstruct:molten_bronze' and items[2].status == 'unknown',
		'input not assessed: ' .. tostring(items[1] and items[1].status))

	local ok, err = pcall(function() quiet(function() c:insert({ slot = 1 }) end) end)
	expect(not ok and tostring(err.message or err):find('bronze', 1, true), 'alloy insert not refused')
	local moved = quiet(function() return c:insert({ slot = 1, force = true }) end)
	expect(moved == 12 and input.items.slots[1] == nil, 'forced insert did not move the tin')
	quiet(function() c:tick() end) -- serve() ticks after each command
	expect(table.concat(c:getState().log, ' '):find('FORCED insert 12 mod:raw_tin', 1, true), 'forced insert not logged')

	ok = pcall(function() quiet(function() c:insert({ slot = 2, force = true }) end) end)
	expect(not ok and input.items.slots[2].count == 5, 'an unknown item must never be inserted, even forced')
end)

test('controller: manual cast picks an idle caster of the asked format', function()
	FILES = {}
	local fake = fakeTinkers()
	fake.smeltery({ { name = IRON, amount = 900 } })
	local busy = fake.caster('tconstruct:basin_0', 810)
	busy.fluids.fluids = { { name = GOLD, amount = 810 } }
	local free = fake.caster('tconstruct:basin_1', 810)
	fake.chest('minecraft:chest_in', 27)
	fake.chest('minecraft:chest_out', 27)
	fake.install()

	local c = controllerWith(fake)
	quiet(function() c:setMode('manual'); c:tick() end)
	expect(quiet(function() return c:cast({ fluid = IRON, format = 'block' }) end) == 810, 'block not cast')
	expect(free.fluids.fluids[1] and free.fluids.fluids[1].name == IRON, 'the idle basin was not used')
	local ok = pcall(function() quiet(function() c:cast({ fluid = IRON, format = 'block' }) end) end)
	expect(not ok, 'no idle basin left and only 90 mB: the cast must be refused')
end)

test('controller: drain empties the Smeltery into the reservoirs then idles; purge goes back to auto', function()
	FILES = {}
	local fake = fakeTinkers()
	fake.smeltery({ { name = IRON, amount = 1500 }, { name = GOLD, amount = 5 } })
	fake.caster('tconstruct:basin_0', 810)
	fake.caster('tconstruct:table_9', 10, 'tconstruct:nugget_cast')
	local d0 = fake.reservoir('miniutilities:drum_0', 1000)
	local d1 = fake.reservoir('miniutilities:drum_1', 1000)
	local d2 = fake.reservoir('miniutilities:drum_2', 1000)
	fake.chest('minecraft:chest_in', 27)
	fake.chest('minecraft:chest_out', 27)
	fake.install()

	local c = controllerWith(fake)
	quiet(function() c:setMode('auto'); c:setMode('purge'); c:tick() end)
	expect(d0.fluids.fluids[1] and d0.fluids.fluids[1].name == GOLD and d0.fluids.fluids[1].amount == 5, 'the 5 mB gold leftover not purged')
	quiet(function() c:tick() end)
	expect(c:getMode() == 'auto', 'purge did not go back to auto: ' .. c:getMode())

	quiet(function() c:setMode('drain'); c:tick() end)
	local iron = 0
	for _, d in ipairs({ d1, d2 }) do if d.fluids.fluids[1] and d.fluids.fluids[1].name == IRON then iron = iron + d.fluids.fluids[1].amount end end
	expect(iron == 1500, 'iron not drained into two drums: ' .. iron)
	expect(#fake.devices['tconstruct:drain_0'].fluids.fluids == 0, 'the Smeltery is not empty')
	expect(FILES['/smeltery/reservoirs.db'] and FILES['/smeltery/reservoirs.db']:find('1000', 1, true), 'learnt capacity not saved')
	quiet(function() c:tick() end)
	expect(c:getMode() == 'idle', 'drain did not end in idle: ' .. c:getMode())
	expect(#c:getState().reservoirs == 3, 'reservoirs missing from the state')
end)

test('controller: missing peripherals become alerts, manual commands need manual mode', function()
	FILES = {}
	installPeripherals({})
	local controllerModule = require('projects.smeltery.controller.controller')
	local catalogue = require('projects.smeltery.shared.catalogue')
	local config = require('projects.smeltery.controller.config').defaultControllerConfig()

	local c = quiet(function() return new(controllerModule.Controller, config, catalogue.defaultCatalogue()) end)
	quiet(function() c:tick() end)
	local alerts = table.concat(c:getState().alerts, ' | ')
	expect(alerts:find('Smeltery drain', 1, true) and alerts:find('input inventory not set', 1, true), 'alerts: ' .. alerts)

	local ok, err = pcall(function() c:cast({ caster = 'x', fluid = IRON }) end)
	expect(not ok and tostring(err.message or err):find('manual mode', 1, true), 'a cast outside manual mode must fail: ' .. tostring(err))
end)

test('controller: Ctrl+T (Terminated) stops the program instead of becoming an alert', function()
	FILES = {}
	local fake = fakeTinkers()
	fake.smeltery({ { name = IRON, amount = 900 } })
	fake.caster('tconstruct:basin_0', 810)
	fake.install()
	local controllerModule = require('projects.smeltery.controller.controller')
	local catalogue = require('projects.smeltery.shared.catalogue')
	local config = require('projects.smeltery.controller.config').defaultControllerConfig()
	local c = quiet(function() return new(controllerModule.Controller, config, catalogue.defaultCatalogue()) end)
	quiet(function() c:tick() end)

	fake.devices['tconstruct:drain_0'].object.tanks = function() error('Terminated', 0) end
	local ok, err = pcall(function() quiet(function() c:tick() end) end)
	expect(not ok and tostring(err):find('Terminated', 1, true), 'Terminated was swallowed: ' .. tostring(err))
end)

test('controller: the display changes the mode over rednet and gets the new state', function()
	FILES = {}
	SENT = {}
	installPeripherals({})
	local controllerModule = require('projects.smeltery.controller.controller')
	local catalogue = require('projects.smeltery.shared.catalogue')
	local config = require('projects.smeltery.controller.config').defaultControllerConfig()
	local c = quiet(function() return new(controllerModule.Controller, config, catalogue.defaultCatalogue()) end)

	local server, client = channel({ protocol = 'smeltery/v1' }), channel({ protocol = 'smeltery/v1' })
	c:serve(server)

	local result, refused
	client:request(1, 'setMode', { mode = 'lock' }, function(_, r) result = r end)
	client:request(1, 'setMode', { mode = 'turbo' }, function(_, r) refused = r end)
	quiet(function()
		server:handleEvent((deliver(2)))
		server:handleEvent((deliver(2)))
	end)
	client:handleEvent((deliver(1)))
	client:handleEvent((deliver(1)))
	expect(result and result.ok and result.value.mode == 'lock' and c:getMode() == 'lock', 'mode not changed over rednet')
	expect(refused and not refused.ok and tostring(refused.error):find('unknown mode', 1, true), 'an unknown mode must be refused')
end)

-- ============================================================
-- Smeltery display: model helpers and the screen on a fake 79x38 monitor
-- ============================================================

local displayModel = require('projects.smeltery.display.model')

test('display: casters grouped by cast, auto formats first', function()
	local casters = {
		{ name = 'b0', kind = 'basin', status = 'busy', format = 'block', amount = 810 },
		{ name = 'b1', kind = 'basin', status = 'idle', format = 'block', amount = 0 },
		{ name = 't0', kind = 'table', status = 'blocked', format = 'ingot', amount = 0 },
		{ name = 't1', kind = 'table', status = 'idle', format = 'gear', amount = 0 },
		{ name = 't2', kind = 'table', status = 'idle', amount = 0 },
	}
	local groups = displayModel.groupCasters(casters, { 'block', 'ingot', 'nugget' })
	local names = {}
	for i, g in ipairs(groups) do names[i] = g.format end
	expect(table.concat(names, ',') == 'block,ingot,gear,no cast', 'order: ' .. table.concat(names, ','))
	expect(groups[1].free == 1 and groups[1].casting == 1 and groups[1].auto, 'block counts')
	expect(groups[2].ready == 1 and not groups[3].auto, 'ingot ready, gear not auto')
end)

test('display: log lines are shortened by kind', function()
	local line = displayModel.parseLogLine('20:24:54 inserted 64 minecraft:raw_gold (seen: molten_iron)')
	expect(line.time == '20:24:54' and line.kind == 'in' and line.text == 'raw_gold 64', 'insert: ' .. line.text)
	line = displayModel.parseLogLine('20:25:16 poured 810 mB molten_gold into tconstruct:basin_0')
	expect(line.kind == 'cast' and line.text == 'gold 810 > basin_0', 'cast: ' .. line.text)
	line = displayModel.parseLogLine('20:26:02 moved 64 occultism:raw_iesnium to sophisticatedstorage:barrel_3 (needs 1090 K)')
	expect(line.kind == 'reject' and line.text == 'raw_iesnium 64 > needs 1090 K', 'reject: ' .. line.text)
	expect(displayModel.parseLogLine('20:31:40 FORCED insert 12 mod:raw_tin (bronze)').kind == 'forced', 'forced')
	expect(displayModel.fluidLabel('tconstruct:molten_rose_gold') == 'rose gold', 'fluid label')
end)

local function smelteryState(fields)
	local state = {
		mode = 'auto', time = 0, melting = {}, waiting = {}, alerts = {}, log = { '20:24:54 inserted 64 minecraft:raw_gold (seen: x)' },
		fluids = { { name = IRON, amount = 1110 }, { name = GOLD, amount = 2700 } },
		casters = { { name = 'tconstruct:basin_0', kind = 'basin', status = 'busy', format = 'block', amount = 810 } },
		inputItems = {}, autoFormats = { 'block', 'ingot', 'nugget' },
		fuel = { fluid = 'minecraft:lava', amount = 2600, temperature = 1000 }, heat = 1000,
	}
	for k, v in pairs(fields or {}) do state[k] = v end
	return state
end

local function screenFor(calls)
	local screenModule = require('projects.smeltery.display.screen')
	local screen = new(screenModule.SmelteryScreen, {
		setMode = function(_, mode) calls[#calls + 1] = 'setMode ' .. mode end,
		insert = function(_, r) calls[#calls + 1] = 'insert ' .. r.slot .. (r.force and ' force' or '') end,
		cast = function(_, r) calls[#calls + 1] = 'cast ' .. r.fluid .. ' ' .. r.format end,
	})
	local runtime, terminal = runtimeFor(screen.root, 79, 38)
	return screen, runtime, terminal
end

local function screenText(terminal)
	local lines = {}
	for y = 1, 38 do lines[y] = terminal.line(y) end
	return table.concat(lines, '\n')
end

local function touch(runtime, x, y)
	runtime:dispatch({ type = 'mouse_click', x = x, y = y, button = 1 })
	runtime:render()
end

test('display: overview draws the tank, the fuel and the casting; tabs switch screens', function()
	local calls = {}
	local screen, runtime, terminal = screenFor(calls)
	runtime:render()
	expect(screenText(terminal):find('Waiting for the controller', 1, true), 'no waiting message before the first state')

	screen:setState(smelteryState())
	runtime:invalidate({ reason = 'state', kind = 'full' })
	runtime:render()
	local text = screenText(terminal)
	for _, wanted in ipairs({ 'MOLTEN', 'FUEL', 'CASTING', 'gold', 'iron', '3810', 'lava', '2600 mB', '1000 K', 'block', ' AUTO ' }) do
		expect(text:find(wanted, 1, true), 'overview misses "' .. wanted .. '"')
	end

	touch(runtime, 39, 2) -- "Modes" tab
	text = screenText(terminal)
	expect(text:find('Full stop.', 1, true) and text:find('active', 1, true), 'modes tab not shown')
	touch(runtime, 4, 14) -- Activate under IDLE
	expect(calls[1] == 'setMode idle', 'Activate did not ask for idle: ' .. tostring(calls[1]))
end)

test('display: Force asks twice before a forced insert, and can be cancelled', function()
	local calls = {}
	local screen, runtime, terminal = screenFor(calls)
	screen:setState(smelteryState({
		mode = 'manual',
		inputItems = {
			{ slot = 3, name = 'minecraft:raw_iron', count = 8, fluid = IRON, status = 'ok' },
			{ slot = 5, name = 'mod:raw_tin', count = 12, fluid = TIN, status = 'alloy', alloy = 'tconstruct:molten_bronze' },
		},
	}))
	runtime:invalidate({ reason = 'state', kind = 'full' })
	runtime:render()
	touch(runtime, 49, 2) -- "Manual" tab
	expect(screenText(terminal):find('raw_tin', 1, true), 'manual tab does not list the input')

	touch(runtime, 38, 8) -- Insert on the first row
	expect(calls[1] == 'insert 3', 'insert not asked: ' .. tostring(calls[1]))

	touch(runtime, 38, 11) -- Force on the second row
	expect(screenText(terminal):find('step 1 of 2', 1, true) and screenText(terminal):find('bronze', 1, true), 'first confirmation not shown')
	touch(runtime, 38, 8) -- under the dialog: must do nothing
	expect(#calls == 1, 'a button under the dialog was pressed')
	touch(runtime, 19, 22) -- Continue
	expect(screenText(terminal):find('step 2 of 2', 1, true), 'second confirmation not shown')
	expect(#calls == 1, 'inserted after a single confirmation')
	touch(runtime, 19, 22) -- Force insert
	expect(calls[2] == 'insert 5 force', 'forced insert not asked: ' .. tostring(calls[2]))

	touch(runtime, 38, 11)
	touch(runtime, 48, 22) -- Cancel
	expect(not screenText(terminal):find('FORCE INSERT', 1, true) and #calls == 2, 'cancel did not close the dialog')

	touch(runtime, 38, 11)
	touch(runtime, 19, 22)
	FAKE_CLOCK = FAKE_CLOCK + 11
	screen:tick()
	runtime:invalidate({ reason = 'state', kind = 'full' })
	runtime:render()
	expect(not screenText(terminal):find('FORCE INSERT', 1, true) and #calls == 2, 'the second step must expire after 10 s')
end)

-- ============================================================
-- Fluids module: reservoir pool (dynamic, never mixing)
-- ============================================================

local fluids = require('modules.fluids.index')

local function poolNet()
	local fake = fakeTinkers()
	fake.smeltery({ { name = IRON, amount = 3000 }, { name = GOLD, amount = 500 }, { name = COPPER, amount = 40 } })
	local r = {
		fake.reservoir('drum_0', 1000, { { name = GOLD, amount = 200 } }),
		fake.reservoir('drum_1', 1000),
		fake.reservoir('drum_2', 1000),
	}
	fake.install()
	return fake, r
end

local function drainTank()
	return require('core.tank').Tank:fromName('tconstruct:drain_0')
end

test('fluids: a fluid goes to the reservoir already holding it, then to empty ones', function()
	local fake, r = poolNet()
	local pool = new(fluids.ReservoirPool, { 'drum_0', 'drum_1', 'drum_2' })
	pool:refresh()

	expect(pool:store(drainTank(), GOLD, 300) == 300, 'gold not stored')
	expect(r[1].fluids.fluids[1].amount == 500 and #r[2].fluids.fluids == 0, 'gold must join the drum already holding gold')

	expect(pool:store(drainTank(), IRON, 1500) == 1500, 'iron not stored')
	expect(r[2].fluids.fluids[1].name == IRON and r[2].fluids.fluids[1].amount == 1000, 'first empty drum not filled with iron')
	expect(r[3].fluids.fluids[1].name == IRON and r[3].fluids.fluids[1].amount == 500, 'iron did not overflow into the next drum')
	expect(pool:capacities().drum_1 == 1000, 'capacity not learnt when the drum refused more')
	expect(pool:stored(IRON) == 1500 and pool:stored(GOLD) == 500, 'stored amounts')

	-- Every drum is taken: copper has nowhere to go, and nothing is mixed.
	expect(pool:store(drainTank(), COPPER, 40) == 0 and not pool:canStore(COPPER), 'copper stored next to another fluid')
	for i = 1, 3 do expect(#r[i].fluids.fluids == 1, 'drum ' .. i .. ' holds two fluids') end
end)

test('fluids: a reservoir changed since the last reading is checked again before a transfer', function()
	local fake, r = poolNet()
	local pool = new(fluids.ReservoirPool, { 'drum_1', 'drum_2' })
	pool:refresh()
	r[2].fluids.fluids = { { name = COPPER, amount = 10 } } -- someone filled drum_1 meanwhile
	expect(pool:store(drainTank(), IRON, 100) == 100, 'iron not stored')
	expect(r[2].fluids.fluids[1].name == COPPER and r[3].fluids.fluids[1].name == IRON, 'iron poured onto the copper')
end)

test('fluids: assigned reservoirs only take their fluid; take() gives back, smallest stock first', function()
	local fake, r = poolNet()
	local pool = new(fluids.ReservoirPool, { 'drum_1', 'drum_2' }, { assignments = { drum_2 = GOLD } })
	pool:refresh()
	pool:store(drainTank(), IRON, 200)
	expect(r[2].fluids.fluids[1].name == IRON and #r[3].fluids.fluids == 0, 'iron went into the drum assigned to gold')
	pool:store(drainTank(), GOLD, 100)
	expect(r[3].fluids.fluids[1].name == GOLD, 'gold not put in its assigned drum')

	local smeltery = fake.devices['tconstruct:drain_0'].fluids
	local before = 0
	for _, f in ipairs(smeltery.fluids) do if f.name == IRON then before = f.amount end end
	expect(pool:take(drainTank(), IRON, 150) == 150, 'iron not given back')
	local after = 0
	for _, f in ipairs(smeltery.fluids) do if f.name == IRON then after = f.amount end end
	expect(after == before + 150 and pool:stored(IRON) == 50, 'smeltery or pool amounts wrong after take')
	local views = pool:views()
	expect(views[2].assigned == GOLD and views[2].fluid == GOLD and views[1].amount == 50, 'views')
end)

realPrint(('\n%d passed, %d failed'):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
