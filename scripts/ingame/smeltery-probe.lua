-- Project Smeltery probe (CC:Tweaked).
-- Answers in the real game what the Smeltery design depends on. Standalone: needs no EmberCore file.
--
-- Install: copy this file to the foundry computer, e.g. <world>/computercraft/computer/<id>/
-- Usage:
--   smeltery-probe                 scan (read only): every peripheral, its types, its methods,
--                                  its fluids (tanks) and its items (list)
--   smeltery-probe extract <drain> <target> [fluid] [mB]
--                                  Q1: can the drain give a fluid that is not the default one?
--                                  pushes [mB] (default 10) with no fluid name to <target> (an empty
--                                  tank) to learn the default fluid, then [mB] of [fluid] (default: a
--                                  fluid other than the default one); gives everything back after each step
--   smeltery-probe candidates <drain> [mB]
--                                  scan, then the extract test on every empty fluid storage that is not
--                                  a drain, a table, a basin or a Mekanism basicFluidTank
--   smeltery-probe cast <drain> <caster> [fluid] [mB] [output]
--                                  Q2: can we cast with pushFluid alone, without a faucet?
--                                  pushes up to [mB] (default 810) of [fluid] (default: the first fluid
--                                  listed) into <caster> (casting table or basin), waits for the result,
--                                  then moves it to [output] (a chest) when given
--
-- Every run also writes its full report to /smeltery-probe-<mode>.log on the computer.

local args = { ... }
local mode = args[1] or 'scan'
local logPath = '/smeltery-probe-' .. mode .. '.log'
local logLines = {}

local function log(line)
	line = line or ''
	logLines[#logLines + 1] = line
	print(line)
end

-- Detail lines go to the log only: the terminal is too small for full method lists.
local function detail(line)
	logLines[#logLines + 1] = line
end

local function saveLog()
	local handle = fs.open(logPath, 'w')
	if handle then
		handle.write(table.concat(logLines, '\n') .. '\n')
		handle.close()
		print('Report written to ' .. logPath)
	else
		print('Could not write ' .. logPath)
	end
end

local function call(target, method, ...)
	if type(target[method]) ~= 'function' then return false, 'no method ' .. method end
	return pcall(target[method], ...)
end

local function serialize(value)
	local ok, text = pcall(textutils.serialize, value)
	return ok and text or tostring(value)
end

-- tanks() may contain nil holes: walk every index up to the highest one.
-- Mekanism tanks have no tanks(), only their own getStored(): read that one as a single tank.
local function readTanks(target)
	if type(target.tanks) ~= 'function' and type(target.getStored) == 'function' then
		local ok, stored = call(target, 'getStored')
		if not ok then return nil, stored end
		if type(stored) ~= 'table' or not stored.name or stored.name == 'minecraft:empty' or (stored.amount or 0) == 0 then
			return { false }
		end
		return { { name = stored.name, amount = stored.amount } }
	end

	local ok, raw = call(target, 'tanks')
	if not ok then return nil, raw end

	local count = 0
	for index in pairs(raw) do
		if type(index) == 'number' and index > count then count = index end
	end

	local tanks = {}
	for index = 1, count do
		tanks[index] = raw[index] or false
	end
	return tanks
end

local function describeTanks(tanks)
	local parts = {}
	for index, tank in ipairs(tanks) do
		if tank and tank.name then
			parts[#parts + 1] = string.format('#%d %s %d mB', index, tank.name, tank.amount or 0)
		else
			parts[#parts + 1] = string.format('#%d empty', index)
		end
	end
	return #parts > 0 and table.concat(parts, ', ') or '(no tank)'
end

local function amountOf(tanks, fluid)
	local total = 0
	for _, tank in ipairs(tanks or {}) do
		if tank and tank.name == fluid then total = total + (tank.amount or 0) end
	end
	return total
end

local function need(name)
	local wrapped = peripheral.wrap(name)
	if not wrapped then
		log('[FAIL] no peripheral named ' .. tostring(name) .. ' (run the scan to see the names)')
	end
	return wrapped
end

local function header(title)
	log('')
	log('== ' .. title .. ' ==')
end

----------------------------------------------------------------------------------------------------
-- scan
----------------------------------------------------------------------------------------------------

local function scan()
	header('Smeltery probe: scan (' .. os.date() .. ')')
	log('Computer #' .. os.getComputerID() .. (os.getComputerLabel() and (' "' .. os.getComputerLabel() .. '"') or ''))

	local names = peripheral.getNames()
	table.sort(names)
	log(#names .. ' peripherals')

	local fluidNames, inventoryNames = {}, {}

	for _, name in ipairs(names) do
		local types = { peripheral.getType(name) }
		local methods = peripheral.getMethods(name) or {}
		table.sort(methods)
		local wrapped = peripheral.wrap(name)

		log('')
		log('- ' .. name .. '  [' .. table.concat(types, ', ') .. ']')
		detail('  methods: ' .. table.concat(methods, ' '))

		if type(wrapped.tanks) == 'function' then
			local tanks, err = readTanks(wrapped)
			if tanks then
				log('  fluids: ' .. describeTanks(tanks))
				detail('  raw tanks: ' .. serialize(tanks))
			else
				log('  tanks() failed: ' .. tostring(err))
			end
			fluidNames[#fluidNames + 1] = name
		elseif type(wrapped.getStored) == 'function' then
			local tanks = readTanks(wrapped)
			if tanks then log('  fluids (Mekanism getStored): ' .. describeTanks(tanks)) end
			fluidNames[#fluidNames + 1] = name .. ' (Mekanism)'
		end

		if type(wrapped.list) == 'function' then
			local okSize, size = call(wrapped, 'size')
			local okList, items = call(wrapped, 'list')
			local used = 0
			if okList then for _ in pairs(items) do used = used + 1 end end
			log(string.format('  items: %s slots, %d used', okSize and tostring(size) or '?', used))
			if okList then detail('  raw list: ' .. serialize(items)) end
			inventoryNames[#inventoryNames + 1] = name
		end

		-- Mekanism exposes its own getters next to (or instead of) the generic fluid_storage.
		for _, getter in ipairs({ 'getStored', 'getCapacity', 'getFilledPercentage', 'getTier' }) do
			if type(wrapped[getter]) == 'function' then
				local ok, value = call(wrapped, getter)
				detail('  ' .. getter .. '(): ' .. (ok and serialize(value) or ('error ' .. tostring(value))))
			end
		end
	end

	header('Summary')
	log('Fluid storages (' .. #fluidNames .. '): ' .. table.concat(fluidNames, ', '))
	log('Inventories (' .. #inventoryNames .. '): ' .. table.concat(inventoryNames, ', '))
end

----------------------------------------------------------------------------------------------------
-- extract (Q1)
----------------------------------------------------------------------------------------------------

local function extract(drainName, targetName, fluidArg, amountArg)
	header('Smeltery probe: extract (' .. os.date() .. ')')
	if not drainName or not targetName then
		log('usage: smeltery-probe extract <drain> <target> [fluid] [mB]')
		return
	end

	local drain, target = need(drainName), need(targetName)
	if not drain or not target then return end
	local amount = tonumber(amountArg) or 10

	local drainBefore = readTanks(drain)
	local targetBefore = readTanks(target)
	if not drainBefore then log('[FAIL] ' .. drainName .. ' has no tanks()') return end
	if not targetBefore then log('[FAIL] ' .. targetName .. ' has no tanks()') return end

	log('drain before:  ' .. describeTanks(drainBefore))
	log('target before: ' .. describeTanks(targetBefore))

	for _, tank in ipairs(targetBefore) do
		if tank and tank.name then
			log('[STOP] the target is not empty: use an empty tank so that nothing gets mixed')
			return
		end
	end

	local fluids = {}
	for _, tank in ipairs(drainBefore) do
		if tank and tank.name and (tank.amount or 0) > 0 then fluids[#fluids + 1] = tank.name end
	end
	if #fluids == 0 then log('[STOP] the smeltery holds no fluid') return end
	log('fluid order as listed by tanks(): ' .. table.concat(fluids, ' > '))

	-- Gives back to the smeltery whatever sits in the target, so each step starts from an empty tank.
	local function giveBack()
		for _, tank in ipairs(readTanks(target) or {}) do
			if tank and tank.name and (tank.amount or 0) > 0 then
				-- The drain pulls: a Mekanism tank has no pushFluid of its own.
				local okBack, back = call(drain, 'pullFluid', targetName, tank.amount, tank.name)
				log(string.format('   back: %s %s', tank.name, okBack and (tostring(back) .. ' mB') or ('error ' .. tostring(back))))
			end
		end
	end

	-- Step 1: unnamed extraction, to learn which fluid the drain gives by default.
	log('')
	log(string.format('1) pushFluid(%s, %d) with no fluid name', targetName, amount))
	local defaultFluid
	local ok1, moved1 = call(drain, 'pushFluid', targetName, amount)
	if ok1 then
		local after = readTanks(target) or {}
		defaultFluid = after[1] and after[1].name
		log('   moved: ' .. tostring(moved1) .. ' mB, default fluid = ' .. tostring(defaultFluid))
		if defaultFluid then
			local position
			for index, name in ipairs(fluids) do if name == defaultFluid then position = index end end
			log('   that is #' .. tostring(position) .. ' of ' .. #fluids .. ' in the tanks() order')
		end
	else
		log('   error: ' .. tostring(moved1))
	end
	giveBack()

	-- Step 2: named extraction of a fluid that is NOT the default one; otherwise the test proves nothing.
	local fluid = fluidArg
	if not fluid then
		for index = #fluids, 1, -1 do
			if fluids[index] ~= defaultFluid then fluid = fluids[index] break end
		end
	end
	log('')
	if not fluid then
		log('[STOP] Q1 not tested: the smeltery must hold at least two different fluids')
	else
		if fluid == defaultFluid then
			log('[WARN] ' .. fluid .. ' is the default fluid: the result will not tell much')
		end
		log(string.format('2) pushFluid(%s, %d, %s)', targetName, amount, fluid))
		local ok, moved = call(drain, 'pushFluid', targetName, amount, fluid)
		if not ok then
			log('[FAIL] error: ' .. tostring(moved))
		else
			local after = readTanks(target) or {}
			local got = after[1] and after[1].name
			log('   moved: ' .. tostring(moved) .. ' mB, target now: ' .. describeTanks(after))
			if moved > 0 and got == fluid then
				log('[OK]   Q1 = YES: the drain gave the requested fluid')
			elseif moved > 0 then
				log('[FAIL] Q1 = NO: asked for ' .. fluid .. ', got ' .. tostring(got))
			else
				log('[FAIL] Q1 = NO: nothing moved (the drain refuses a named extraction of this fluid)')
			end
		end
		giveBack()
	end

	log('')
	log('drain after:  ' .. describeTanks(readTanks(drain)))
	log('target after: ' .. describeTanks(readTanks(target)))

	-- The smeltery may refuse a fluid when full: say so instead of leaving it silently.
	for _, tank in ipairs(readTanks(target) or {}) do
		if tank and tank.name and (tank.amount or 0) > 0 then
			log('[WARN] ' .. tank.amount .. ' mB of ' .. tank.name .. ' stayed in ' .. targetName)
		end
	end
end

----------------------------------------------------------------------------------------------------
-- cast (Q2)
----------------------------------------------------------------------------------------------------

local function cast(drainName, casterName, fluidArg, amountArg, outputName)
	header('Smeltery probe: cast (' .. os.date() .. ')')
	if not drainName or not casterName then
		log('usage: smeltery-probe cast <drain> <caster> [fluid] [mB] [output]')
		return
	end

	local drain, caster = need(drainName), need(casterName)
	local output = outputName and need(outputName) or nil
	if not drain or not caster or (outputName and not output) then return end
	local amount = tonumber(amountArg) or 810

	local casterTypes = { peripheral.getType(casterName) }
	log('caster types: ' .. table.concat(casterTypes, ', '))
	log('caster has tanks(): ' .. tostring(type(caster.tanks) == 'function')
		.. ', list(): ' .. tostring(type(caster.list) == 'function')
		.. ', pushItems(): ' .. tostring(type(caster.pushItems) == 'function'))

	local drainBefore = readTanks(drain)
	if not drainBefore then log('[FAIL] ' .. drainName .. ' has no tanks()') return end
	log('drain before:  ' .. describeTanks(drainBefore))

	local fluid = fluidArg
	if not fluid then
		for _, tank in ipairs(drainBefore) do
			if tank and tank.name and (tank.amount or 0) > 0 then fluid = tank.name break end
		end
	end
	if not fluid then log('[STOP] the smeltery holds no fluid') return end

	if type(caster.list) == 'function' then
		local ok, items = call(caster, 'list')
		log('caster items before: ' .. (ok and serialize(items) or tostring(items)))
	end

	log('')
	log(string.format('1) pushFluid(%s, %d, %s)', casterName, amount, fluid))
	local ok, moved = call(drain, 'pushFluid', casterName, amount, fluid)
	if not ok then
		log('[FAIL] Q2 = NO: error ' .. tostring(moved))
		return
	end
	log('   moved: ' .. tostring(moved) .. ' mB (the caster takes only what its recipe needs)')
	log('   drain ' .. fluid .. ': ' .. amountOf(drainBefore, fluid) .. ' -> ' .. amountOf(readTanks(drain), fluid) .. ' mB')
	if moved == 0 then
		log('[FAIL] Q2 = NO: the caster refused the fluid (no cast? no recipe? or no fluid access)')
		return
	end
	if type(caster.tanks) == 'function' then
		log('   caster tanks: ' .. describeTanks(readTanks(caster) or {}))
	end

	log('')
	log('2) waiting for the result (up to 60 s)')
	if type(caster.list) ~= 'function' then
		log('[WARN] the caster is not an inventory for CC: the result cannot be collected with pushItems')
		return
	end

	local started = os.clock()
	local resultSlot, resultItem
	while os.clock() - started < 60 do
		local okList, items = call(caster, 'list')
		local tanks = type(caster.tanks) == 'function' and readTanks(caster) or {}
		local liquid = 0
		for _, tank in ipairs(tanks) do if tank then liquid = liquid + (tank.amount or 0) end end

		if okList and liquid == 0 then
			-- With a cast, slot 1 holds the cast and the result appears in another slot (or replaces it).
			for slot, item in pairs(items) do
				if item and item.name ~= nil and not item.name:find('_cast$') and not item.name:find('sand_cast') then
					resultSlot, resultItem = slot, item
				end
			end
			if resultSlot then break end
		end
		sleep(0.5)
	end

	if not resultSlot then
		log('[FAIL] no result seen after 60 s; caster items: ' .. serialize(select(2, call(caster, 'list'))))
		return
	end
	log(string.format('   result after %.1f s: %dx %s in slot %d', os.clock() - started, resultItem.count, resultItem.name, resultSlot))
	log('[OK]   Q2 = YES: pushFluid alone casts')

	if output then
		log('')
		log(string.format('3) pushItems(%s, %d)', outputName, resultSlot))
		local okPush, pushed = call(caster, 'pushItems', outputName, resultSlot)
		log('   ' .. (okPush and (tostring(pushed) .. ' item(s) moved') or ('error ' .. tostring(pushed))))
		local okList, items = call(caster, 'list')
		log('   caster items after: ' .. (okList and serialize(items) or tostring(items)))
	end
end

----------------------------------------------------------------------------------------------------

local ok, err = pcall(function()
	if mode == 'scan' then
		scan()
	elseif mode == 'extract' then
		extract(args[2], args[3], args[4], args[5])
	elseif mode == 'candidates' then
		-- Runs the extract test on every empty fluid storage that is not part of the smeltery itself.
		local drainName = args[2]
		if not drainName then
			log('usage: smeltery-probe candidates <drain> [mB]')
			return
		end
		scan()
		local names = peripheral.getNames()
		table.sort(names)
		local tested = 0
		for _, name in ipairs(names) do
			local wrapped = peripheral.wrap(name)
			local isFluid = type(wrapped.tanks) == 'function' or type(wrapped.getStored) == 'function'
			local skip = name:find('^tconstruct:drain') or name:find('^tconstruct:table') or name:find('^tconstruct:basin')
				or name:find('^basicFluidTank')
			if isFluid and not skip then
				extract(drainName, name, nil, args[3])
				tested = tested + 1
			end
		end
		header('Candidates tested: ' .. tested)
	elseif mode == 'cast' then
		cast(args[2], args[3], args[4], args[5], args[6])
	else
		log('unknown mode ' .. mode .. ' (scan, extract, cast)')
	end
end)
if not ok then
	log('[ERROR] ' .. tostring(err))
end
saveLog()
