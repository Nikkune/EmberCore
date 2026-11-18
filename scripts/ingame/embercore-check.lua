-- EmberCore in-game check (CC:Tweaked).
-- Validates in the real game what the tests outside Minecraft cannot prove.
--
-- Install: copy the content of luas/ (core/, modules/, utils/) and this file to the computer, e.g.
--   <world>/computercraft/computer/<id>/
-- then run on the computer:
--   embercore-check peripherals   -- peripheral types, findByType, secondary types
--   embercore-check tanks         -- raw tanks() of every fluid storage (empty-tank holes)
--   embercore-check ui [side] [ascii] -- interactive UI demo on the terminal or on a monitor;
--                                    add "ascii" for +-| borders instead of CC drawing characters
--   embercore-check widgets [side] [ascii] -- layout and data widgets: margins, Box, Panel, Grid,
--                                    Badge, Table (chest content), LogViewer, StatusBar
--   embercore-check all

local root = fs.getDir(shell.getRunningProgram())
package.path = '/' .. root .. '/?.lua;' .. package.path

local args = { ... }
local mode = args[1] or 'all'

-- TypeScriptToLua classes: instantiate with new(Class, ...), call static methods with ':'.
-- Callbacks passed to EmberCore receive an extra first argument (self): function(_, value).
local function new(class, ...)
	local instance = setmetatable({}, class.prototype)
	instance:____constructor(...)
	return instance
end

local function header(title)
	print('')
	print('== ' .. title .. ' ==')
end

local function result(ok, label, detail)
	local previous = term.getTextColor()
	term.setTextColor(ok and colors.lime or colors.red)
	write(ok and '[OK]   ' or '[FAIL] ')
	term.setTextColor(previous)
	print(label .. (detail and (' - ' .. detail) or ''))
end

-- ------------------------------------------------------------
-- Peripherals
-- ------------------------------------------------------------
local function checkPeripherals()
	header('Peripheriques')
	local Peripheral = require('core.peripheral').Peripheral
	local names = peripheral.getNames()

	if #names == 0 then
		print('Aucun peripherique : branchez un moniteur et un coffre (directement ou via modem).')
		return
	end

	for _, name in ipairs(names) do
		print(('%s : %s'):format(name, table.concat({ peripheral.getType(name) }, ', ')))
	end

	local monitor = peripheral.find('monitor')
	if monitor then
		-- Each wrap/find returns a new table in CC: compare peripheral names, not identities.
		local found = Peripheral:findByType('monitor')
		local ok, foundName = pcall(peripheral.getName, found)
		result(ok and foundName == peripheral.getName(monitor), 'findByType("monitor") renvoie le moniteur', ok and foundName or type(found))
	else
		print('(pas de moniteur : findByType("monitor") non teste)')
	end

	result(Peripheral:findByType('embercore_absent') == nil, 'findByType() renvoie nil si absent')
	result(not pcall(function() return Peripheral:requireByType('embercore_absent') end), 'requireByType() leve une erreur si absent')

	local inventoryName = Peripheral:findNameByType('inventory')
	if peripheral.find('inventory') then
		result(inventoryName ~= nil, 'findNameByType("inventory") trouve un inventaire', tostring(inventoryName))
		if inventoryName then
			local ok = pcall(function() return Peripheral:requireType(inventoryName, 'inventory') end)
			result(ok, 'requireType(<inventaire>, "inventory") (type secondaire)', inventoryName .. ' / type principal ' .. tostring(Peripheral:getType(inventoryName)))
			local Inventory = require('core.inventory').Inventory
			local inv = Inventory:fromName(inventoryName)
			result(inv:size() > 0, 'Inventory.fromName(...):size()', tostring(inv:size()))
		end
	else
		print('(pas d\'inventaire : branchez un coffre pour tester les types secondaires)')
	end
end

-- ------------------------------------------------------------
-- Tanks
-- ------------------------------------------------------------
local function checkTanks()
	header('Reservoirs')
	local Tank = require('core.tank').Tank
	local any = false

	for _, name in ipairs(peripheral.getNames()) do
		if peripheral.hasType(name, 'fluid_storage') then
			any = true
			local raw = peripheral.call(name, 'tanks')
			local maxIndex, count = 0, 0
			for index in pairs(raw) do
				count = count + 1
				if index > maxIndex then maxIndex = index end
			end
			print(('%s : tanks() -> %d entree(s), indice max %d, #tanks = %d'):format(name, count, maxIndex, #raw))
			print('  brut : ' .. textutils.serialise(raw, { compact = true }))

			local tank = Tank:fromName(name)
			local listed = #tank:list()
			result(listed == maxIndex, 'Tank:list() voit tous les reservoirs', ('%d liste(s) / %d attendu(s)'):format(listed, maxIndex))
			print('  Tank:getTotalAmount() = ' .. tank:getTotalAmount())
		end
	end

	if not any then
		print('Aucun stockage de fluide. Pour tester les "trous" : un bloc a plusieurs reservoirs')
		print('(ex. une cuve moddee) avec le 1er vide et un autre rempli.')
	end
end

-- ------------------------------------------------------------
-- UI
-- ------------------------------------------------------------
local function checkUi(side, ascii)
	local ui = require('modules.ui.index')
	local C = require('modules.ui.components')

	local target, monitorSide = term.current(), nil
	if side then
		target = peripheral.wrap(side)
		monitorSide = side
		assert(target and peripheral.hasType(side, 'monitor'), 'pas de moniteur sur "' .. side .. '"')
		target.setTextScale(0.5)
	end

	local status = new(C.LabelComponent, { text = 'Cliquez. Q (clavier) pour quitter.' })
	local function setStatus(text)
		status:setText(text)
	end

	local group = new(C.RadioGroup, 'a')
	local theme = {
		name = 'check',
		palette = ui.defaultTheme.palette,
		borders = ui.defaultTheme.borders,
		components = { button = { border = { enabled = true }, colors = { default = colors.gray, active = colors.blue } } },
	}
	if ascii then
		theme = ui.withAsciiBorders(nil, theme)
	end

	local page = new(C.PaginationComponent, {
		page = 3, totalItems = 50, pageSize = 10,
		onPageChange = function(_, p) setStatus('Page -> ' .. p) end,
	})
	local bar = new(C.ProgressBarComponent, { value = 5, maxValue = 10, width = 20, label = 'Charge' })

	local root = new(C.StackComponent, { direction = 'column', spacing = 1, padding = 1 }, {}, {
		new(C.StackComponent, { direction = 'row', spacing = 1 }, {}, {
			new(C.ButtonComponent, { label = 'Bouton A', onPress = function() setStatus('A presse') end }),
			new(C.ButtonComponent, { label = 'Bouton B', onPress = function() setStatus('B presse') end }),
			new(C.ToggleButtonComponent, { label = 'Bascule', onToggle = function(_, v) setStatus('Bascule = ' .. tostring(v)) end }),
		}),
		new(C.CheckboxComponent, { label = 'Case a cocher', checked = false, onChange = function(_, v) setStatus('Case = ' .. tostring(v)) end }),
		new(C.RadioComponent, { label = 'Option A', value = 'a', onSelect = function(_, v) if v then setStatus('Radio A') end end }, {}, group),
		new(C.RadioComponent, { label = 'Option B', value = 'b', onSelect = function(_, v) if v then setStatus('Radio B') end end }, {}, group),
		bar,
		page,
		new(C.SeparatorComponent, { label = 'etat' }),
		status,
	})

	local surface = side and ui.ComputerCraftSurfaceAdapter:fromMonitor(target) or ui.ComputerCraftSurfaceAdapter:fromTerminal()
	local runtime = new(ui.UIRuntime, {
		root = root, eventBus = new(ui.BasicUIEventBus), theme = theme, surface = surface, surfaceKind = side and 'monitor' or 'terminal',
	})

	-- run() renders, translates CC events, dispatches them and redraws what changed.
	-- Callbacks from Lua receive an extra first argument (self): function(_, raw).
	local timer = os.startTimer(1)
	runtime:run({
		monitor = monitorSide,
		onEvent = function(_, raw)
			if raw[1] == 'char' and (raw[2] == 'q' or raw[2] == 'Q') then
				runtime:stop()
			elseif raw[1] == 'timer' and raw[2] == timer then
				bar:setValue((bar.value + 1) % 11)
				timer = os.startTimer(1)
			end
		end,
	})

	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.white)
	if side then target.setBackgroundColor(colors.black); target.clear() end
	term.clear()
	term.setCursorPos(1, 1)
	print('Fin du test UI.')
end

-- ------------------------------------------------------------
-- Widgets: layout (margin, Box, Panel, Grid) and live data (Table, LogViewer, StatusBar)
-- ------------------------------------------------------------
local function readChestRows(Inventory, Peripheral)
	local name = Peripheral:findNameByType('inventory')
	if not name then
		return { { item = '(pas de coffre)', qte = '-' } }, 'aucun'
	end

	local totals, order = {}, {}
	for _, item in pairs(Inventory:fromName(name):list()) do
		local short = item.name:gsub('^[^:]*:', '')
		if not totals[short] then
			totals[short] = 0
			order[#order + 1] = short
		end
		totals[short] = totals[short] + item.count
	end
	table.sort(order, function(a, b) return totals[a] > totals[b] end)

	local rows = {}
	for i = 1, math.min(#order, 4) do
		rows[i] = { item = order[i], qte = tostring(totals[order[i]]) }
	end
	if #rows == 0 then rows[1] = { item = '(coffre vide)', qte = '0' } end
	return rows, name
end

local function checkWidgets(side, ascii)
	local ui = require('modules.ui.index')
	local C = require('modules.ui.components')
	local Inventory = require('core.inventory').Inventory
	local Peripheral = require('core.peripheral').Peripheral

	local target, monitorSide = term.current(), nil
	if side then
		target = peripheral.wrap(side)
		monitorSide = side
		assert(target and peripheral.hasType(side, 'monitor'), 'pas de moniteur sur "' .. side .. '"')
		target.setTextScale(0.5)
	end

	local theme = {
		name = 'widgets',
		palette = ui.defaultTheme.palette,
		borders = ui.defaultTheme.borders,
		components = {
			box = { border = { enabled = true } },
			panel = { border = { enabled = true } },
			badge = { text = { alignment = 'center' } },
		},
	}
	if ascii then theme = ui.withAsciiBorders(nil, theme) end

	local clicks = 0
	local rows, chestName = readChestRows(Inventory, Peripheral)

	local log = new(C.LogViewerComponent, { entries = {}, height = 4, width = 34 })
	local status = new(C.StatusBarComponent, { segments = {} })
	local tbl = new(C.TableComponent, {
		columns = { { key = 'item', title = 'Objet (' .. chestName .. ')' }, { key = 'qte', title = 'Qte', alignment = 'right' } },
		rows = rows,
		foregroundColor = colors.yellow,
		backgroundColor = colors.blue,
	})

	local function badge(label, color)
		return new(C.BadgeComponent, { label = label, backgroundColor = color, foregroundColor = colors.black, margin = { right = 1 } })
	end

	local root = new(C.StackComponent, { direction = 'column', spacing = 1, padding = 1 }, {}, {
		new(C.StackComponent, { direction = 'row', spacing = 2 }, {}, {
			new(C.BoxComponent, { title = 'Box + marges', padding = { left = 1, right = 1 } }, {}, {
				new(C.StackComponent, { direction = 'column' }, {}, {
					new(C.LabelComponent, { text = 'sans marge' }),
					new(C.LabelComponent, { text = 'margin left = 3', margin = { left = 3 } }),
					new(C.LabelComponent, { text = 'margin top = 1', margin = { top = 1 } }),
				}),
			}),
			new(C.PanelComponent, { title = 'Panel' }, {}, {
				new(C.StackComponent, { direction = 'row' }, {}, {
					badge('OK', colors.lime), badge('WARN', colors.orange), badge('ERR', colors.red),
				}),
			}),
		}),
		new(C.GridComponent, { columns = 3, columnSpacing = 1 }, {}, {
			badge('Grid 1', colors.lightBlue), badge('Grid 2', colors.cyan), badge('Grid 3', colors.lightBlue),
			badge('Grid 4', colors.cyan), badge('Grid 5', colors.lightBlue), badge('Grid 6', colors.cyan),
		}),
		tbl,
		log,
		status,
	})

	local surface = side and ui.ComputerCraftSurfaceAdapter:fromMonitor(target) or ui.ComputerCraftSurfaceAdapter:fromTerminal()
	local runtime = new(ui.UIRuntime, {
		root = root, eventBus = new(ui.BasicUIEventBus), theme = theme, surface = surface, surfaceKind = side and 'monitor' or 'terminal',
	})

	local function updateStatus()
		status:setSegments({
			{ text = ' ' .. textutils.formatTime(os.time(), true) .. ' ', backgroundColor = colors.gray },
			{ text = ' clics: ' .. clicks .. ' ', backgroundColor = colors.blue },
			{ text = ' Q: quitter ' },
		})
	end
	updateStatus()
	log:addEntry({ level = 'info', message = 'Demo widgets demarree' })

	local timer = os.startTimer(1)
	runtime:run({
		monitor = monitorSide,
		onEvent = function(_, raw)
			local name = raw[1]
			if name == 'char' and (raw[2] == 'q' or raw[2] == 'Q') then
				runtime:stop()
			elseif name == 'timer' and raw[2] == timer then
				updateStatus()
				tbl:setRows((readChestRows(Inventory, Peripheral)))
				timer = os.startTimer(1)
			elseif (name == 'mouse_click' and not monitorSide) or (name == 'monitor_touch' and raw[2] == monitorSide) then
				clicks = clicks + 1
				log:addEntry({ level = clicks % 3 == 0 and 'warn' or 'info', message = ('clic %d en %d,%d'):format(clicks, raw[3], raw[4]) }, 4)
				updateStatus()
			end
		end,
	})

	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.white)
	if side then target.setBackgroundColor(colors.black); target.clear() end
	term.clear()
	term.setCursorPos(1, 1)
	print('Fin de la demo widgets.')
end


if mode == 'peripherals' or mode == 'all' then checkPeripherals() end
if mode == 'tanks' or mode == 'all' then checkTanks() end
local uiSide, uiAscii = nil, false
for i = 2, #args do
	if args[i] == 'ascii' then uiAscii = true else uiSide = args[i] end
end

if mode == 'ui' then checkUi(uiSide, uiAscii)
elseif mode == 'widgets' then checkWidgets(uiSide, uiAscii)
elseif mode == 'all' then
	print('')
	print('Test interactif : "embercore-check ui" (terminal) ou "embercore-check ui <cote>" (moniteur),')
	print('ajoutez "ascii" pour comparer avec les bordures +-|.')
	print('Mise en page et donnees : "embercore-check widgets [cote]".')
end
