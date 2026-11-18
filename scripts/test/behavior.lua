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

realPrint(('\n%d passed, %d failed'):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
