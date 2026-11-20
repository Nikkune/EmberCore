-- Reservoir capacity probe (CC:Tweaked). Standalone: needs no EmberCore file.
-- The fluid storages of the modpack do not tell their capacity (tanks() gives the fluid and the amount
-- only): this probe fills each one with water from an infinite source until it refuses more, notes the
-- amount, then pours the water back into the source.
--
-- Install: copy this file to the foundry computer, e.g. <world>/computercraft/computer/<id>/
-- Usage:
--   capacity-probe                 finds the water source (the only storage holding water), then
--                                  measures every other EMPTY fluid storage on the network
--   capacity-probe <source>        same, with the source named (when several storages hold water)
--   capacity-probe <source> <tank> ...  only the named tanks
--   capacity-probe gather <sink> [skip ...]
--                                  pours the water of every storage holding ONLY water into <sink>
--                                  (a big tank), to empty in one go what the probe filled; [skip] are
--                                  storages left alone (the infinite source: it would refill forever)
-- Never touched: the source, every tconstruct:* block (drains, tables, basins, fuel tanks), and any
-- storage that already holds something (it is listed as skipped).
-- Log: /capacity-probe.log (everything printed).

local WATER = 'minecraft:water'
-- pushFluid limit per call, and safety stops (a storage that voids fluid would take water forever).
local LIMIT = 2147483647
local MAX_CALLS = 400
local MAX_TOTAL = 50000000

local logFile = fs.open('/capacity-probe.log', 'w')

local function log(text)
	print(text)
	logFile.writeLine(text)
	logFile.flush()
end

local function isFluidStorage(name)
	return peripheral.hasType(name, 'fluid_storage') == true
end

-- The type that names the model ('miniutilities:drum'), not the generic 'fluid_storage'.
local function modelOf(name)
	local types = { peripheral.getType(name) }
	for _, kind in ipairs(types) do
		if kind ~= 'fluid_storage' and kind ~= 'inventory' and kind ~= 'energy_storage' then return kind end
	end
	return types[1] or '?'
end

-- Every fluid of a storage: name -> amount, the total, and how many tank slots it reports.
local function contents(name)
	local ok, tanks = pcall(peripheral.call, name, 'tanks')
	if not ok or type(tanks) ~= 'table' then return {}, 0, 0, tostring(tanks) end
	local fluids, total, slots = {}, 0, 0
	for _, tank in pairs(tanks) do
		slots = slots + 1
		if type(tank) == 'table' and tank.name and tank.amount then
			fluids[tank.name] = (fluids[tank.name] or 0) + tank.amount
			total = total + tank.amount
		end
	end
	return fluids, total, slots
end

local function describe(fluids)
	local parts = {}
	for fluid, amount in pairs(fluids) do parts[#parts + 1] = amount .. ' mB ' .. fluid end
	return #parts > 0 and table.concat(parts, ', ') or 'empty'
end

-- Moves water from `from` to `to` until refused; returns the mB moved and why it stopped.
local function pour(from, to)
	local moved, calls = 0, 0
	while calls < MAX_CALLS and moved < MAX_TOTAL do
		calls = calls + 1
		local ok, n = pcall(peripheral.call, from, 'pushFluid', to, LIMIT, WATER)
		if not ok then return moved, 'error: ' .. tostring(n) end
		if type(n) ~= 'number' or n <= 0 then return moved, 'refused' end
		moved = moved + n
	end
	return moved, calls >= MAX_CALLS and ('still taking after ' .. MAX_CALLS .. ' calls') or ('still taking after ' .. MAX_TOTAL .. ' mB')
end

local args = { ... }

-- gather: every storage holding only water is emptied into the sink.
if args[1] == 'gather' then
	local sink = args[2]
	log('== Gather water (' .. os.date() .. ') ==')
	if sink == nil or not isFluidStorage(sink) then
		log('Usage: capacity-probe gather <sink> [skip ...] (the sink must be a fluid storage on this network)')
		logFile.close()
		return
	end
	local skip = { [sink] = true }
	for i = 3, #args do skip[args[i]] = true end

	local names = {}
	for _, name in ipairs(peripheral.getNames()) do
		if isFluidStorage(name) and not skip[name] and not name:find('^tconstruct:') then names[#names + 1] = name end
	end
	table.sort(names)

	local gathered, refused = 0, 0
	for _, name in ipairs(names) do
		local fluids, total = contents(name)
		local onlyWater = total > 0 and fluids[WATER] == total
		if onlyWater then
			-- Several rounds: a 4 000 000 mB storage needs more calls than one pour() makes.
			local moved, why, left = 0, 'refused', total
			for _ = 1, 20 do
				local n
				n, why = pour(name, sink)
				moved = moved + n
				left = select(2, contents(name))
				if n == 0 or left == 0 then break end
			end
			gathered = gathered + moved
			if left > 0 then refused = refused + 1 end
			log(('%s: %d mB moved%s'):format(name, moved, left > 0 and (', ' .. left .. ' mB LEFT (' .. why .. ')') or ', empty'))
		elseif total > 0 then
			log(name .. ': left alone, holds ' .. describe(fluids))
		end
	end
	log(('Gathered %d mB into %s (%s).'):format(gathered, sink, describe((contents(sink)))))
	if refused > 0 then log(refused .. ' storage(s) still hold water: the sink is full or refused it.') end
	logFile.close()
	return
end

log('== Capacity probe (' .. os.date() .. ') ==')

local storages = {}
for _, name in ipairs(peripheral.getNames()) do
	if isFluidStorage(name) then storages[#storages + 1] = name end
end
table.sort(storages)
log(#storages .. ' fluid storage(s) on the network')

-- The source: named, or the only storage holding water.
local source = args[1]
if source == nil then
	local holders = {}
	for _, name in ipairs(storages) do
		local fluids = contents(name)
		if fluids[WATER] and not name:find('^tconstruct:') then holders[#holders + 1] = name end
	end
	if #holders ~= 1 then
		log(#holders == 0 and 'No storage holds water: put the infinite water tank on the network.'
			or ('Several storages hold water: name the source, e.g. capacity-probe ' .. holders[1]))
		for _, name in ipairs(holders) do log('  ' .. name .. ' (' .. modelOf(name) .. '): ' .. describe((contents(name)))) end
		logFile.close()
		return
	end
	source = holders[1]
end
if not isFluidStorage(source) then
	log(source .. ' is not a fluid storage on this network.')
	logFile.close()
	return
end
log('source: ' .. source .. ' (' .. modelOf(source) .. '), ' .. describe((contents(source))))

local targets = {}
if #args > 1 then
	for i = 2, #args do targets[#targets + 1] = args[i] end
else
	for _, name in ipairs(storages) do
		if name ~= source and not name:find('^tconstruct:') then targets[#targets + 1] = name end
	end
end

local results = {}
for index, name in ipairs(targets) do
	local model = modelOf(name)
	local fluids, total, slots, err = contents(name)
	if err then
		log(('[%d/%d] %s: unreadable (%s)'):format(index, #targets, name, err))
	elseif total > 0 then
		log(('[%d/%d] %s (%s): SKIPPED, holds %s'):format(index, #targets, name, model, describe(fluids)))
		results[#results + 1] = { name = name, model = model, skipped = true }
	else
		local started = os.clock()
		local moved, why = pour(source, name)
		local _, inside, slotsFull = contents(name)
		local back, backWhy = pour(name, source)
		local _, left = contents(name)
		log(('[%d/%d] %s (%s): %d mB (read back %d mB, %d tank slot(s), %s) in %.1f s; emptied %d mB%s'):format(
			index, #targets, name, model, moved, inside, slotsFull, why, os.clock() - started, back,
			left > 0 and (', ' .. left .. ' mB LEFT (' .. backWhy .. ')') or ''))
		results[#results + 1] = { name = name, model = model, capacity = inside, why = why, left = left }
	end
end

-- Summary by model: one capacity per model, or the differences.
log('')
log('== By model ==')
local models, order = {}, {}
for _, r in ipairs(results) do
	if not models[r.model] then
		models[r.model] = { capacities = {}, skipped = 0, count = 0 }
		order[#order + 1] = r.model
	end
	local entry = models[r.model]
	entry.count = entry.count + 1
	if r.skipped then entry.skipped = entry.skipped + 1
	else entry.capacities[#entry.capacities + 1] = r.capacity .. (r.why ~= 'refused' and '?' or '') end
end
table.sort(order)
for _, model in ipairs(order) do
	local entry = models[model]
	local seen, distinct = {}, {}
	for _, capacity in ipairs(entry.capacities) do
		if not seen[capacity] then
			seen[capacity] = true
			distinct[#distinct + 1] = capacity
		end
	end
	log(('%s x%d: %s mB%s'):format(model, entry.count, #distinct > 0 and table.concat(distinct, ' / ') or '?',
		entry.skipped > 0 and (' (' .. entry.skipped .. ' skipped: not empty)') or ''))
end

local leftovers = 0
for _, r in ipairs(results) do if r.left and r.left > 0 then leftovers = leftovers + 1 end end
if leftovers > 0 then log(leftovers .. ' storage(s) still hold water: the source refused it back, empty them by hand.') end
log('Done. Log: /capacity-probe.log')
logFile.close()
