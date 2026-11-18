-- Minimal CC:Tweaked-like environment for behaviour tests run outside Minecraft.
-- Terminal and peripheral objects use dot-call functions (no self), exactly like CC:Tweaked,
-- so code that wrongly calls them with ':' fails here as it would in game.

unpack = unpack or table.unpack
table.unpack = table.unpack or unpack

local colorCount = 0
colors = setmetatable({}, {
	__index = function(t, k)
		colorCount = colorCount + 1
		rawset(t, k, 2 ^ colorCount)
		return t[k]
	end,
})
colours = colors

local function expectNumber(value, index)
	if type(value) ~= 'number' then
		error(('bad argument #%d (number expected, got %s)'):format(index, type(value)), 3)
	end
end

--- Creates a fake terminal/monitor of the given size. Cells are stored as {char, fg, bg}.
function makeTerminal(width, height)
	local t = { grid = {}, fg = colors.white, bg = colors.black, x = 1, y = 1 }

	t.getSize = function() return width, height end
	t.setCursorPos = function(x, y) expectNumber(x, 1); expectNumber(y, 2); t.x, t.y = x, y end
	t.getCursorPos = function() return t.x, t.y end
	t.write = function(text)
		if type(text) ~= 'string' and type(text) ~= 'number' then
			error('bad argument #1 (string expected, got ' .. type(text) .. ')', 2)
		end
		text = tostring(text)
		for i = 1, #text do
			local cx = t.x + i - 1
			if cx >= 1 and cx <= width and t.y >= 1 and t.y <= height then
				t.grid[t.y] = t.grid[t.y] or {}
				t.grid[t.y][cx] = { text:sub(i, i), t.fg, t.bg }
			end
		end
		t.x = t.x + #text
	end
	t.blit = function(text) t.write(text) end
	t.clear = function() t.grid = {} end
	t.clearLine = function() t.grid[t.y] = {} end
	t.setTextColor = function(c) expectNumber(c, 1); t.fg = c end
	t.setTextColour = t.setTextColor
	t.getTextColor = function() return t.fg end
	t.getTextColour = t.getTextColor
	t.setBackgroundColor = function(c) expectNumber(c, 1); t.bg = c end
	t.setBackgroundColour = t.setBackgroundColor
	t.getBackgroundColor = function() return t.bg end
	t.getBackgroundColour = t.getBackgroundColor
	t.isColor = function() return true end
	t.isColour = t.isColor

	-- Test helpers (not part of the CC API).
	t.cell = function(x, y) return t.grid[y] and t.grid[y][x] end
	t.line = function(y)
		local row = {}
		for x = 1, width do
			local c = t.cell(x, y)
			row[x] = c and c[1] or ' '
		end
		return table.concat(row)
	end

	return t
end

CURRENT_TERMINAL = makeTerminal(51, 19)

term = setmetatable({
	current = function() return CURRENT_TERMINAL end,
}, {
	__index = function(_, k)
		return function(...) return CURRENT_TERMINAL[k](...) end
	end,
})

--- Fake peripheral API backed by a table { name = { types = {...}, object = {...} } }.
function installPeripherals(devices)
	local function hasType(name, wanted)
		local device = devices[name]
		if not device then return nil end
		for _, t in ipairs(device.types) do
			if t == wanted then return true end
		end
		return false
	end

	peripheral = {
		getNames = function()
			local names = {}
			for name in pairs(devices) do names[#names + 1] = name end
			table.sort(names)
			return names
		end,
		isPresent = function(name) return devices[name] ~= nil end,
		getType = function(name)
			local device = devices[name]
			if device then return table.unpack(device.types) end
		end,
		hasType = hasType,
		getName = function(object)
			for name, device in pairs(devices) do
				if device.object == object then return name end
			end
			error("bad argument #1 (table is not a peripheral)", 2)
		end,
		wrap = function(name)
			local device = devices[name]
			return device and device.object
		end,
		find = function(wanted)
			local found = {}
			for _, name in ipairs(peripheral.getNames()) do
				if hasType(name, wanted) then found[#found + 1] = devices[name].object end
			end
			return table.unpack(found)
		end,
	}
end

installPeripherals({})

textutils = { serialise = tostring, unserialise = function() return nil end }
sleep = function() end
os.pullEvent = os.pullEvent or function() end
os.date = os.date
