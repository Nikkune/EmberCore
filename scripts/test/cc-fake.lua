-- Fake CC:Tweaked pieces shared by the Lua tests: JSON as textutils does it, a file system
-- with folders (FILES[path] = content, DIRS[path] = true), textutils, colours, term and a print
-- that records into OUTPUT. Returns { decodeJson, encodeJson }.

---------------------------------------------------------------------------------------------------
-- Minimal JSON decoder (what textutils.unserialiseJSON does in game)

EMPTY_JSON_ARRAY = {}

local function decodeJson(text)
	local pos = 1

	local function skip() pos = text:find('[^%s]', pos) or #text + 1 end

	local value

	local function str()
		local out = {}
		pos = pos + 1
		while true do
			local c = text:sub(pos, pos)
			if c == '"' then pos = pos + 1; return table.concat(out) end
			if c == '\\' then
				local e = text:sub(pos + 1, pos + 1)
				local map = { n = '\n', t = '\t', r = '\r', b = '\b', f = '\f', ['/'] = '/', ['\\'] = '\\', ['"'] = '"' }
				if e == 'u' then
					out[#out + 1] = string.char(tonumber(text:sub(pos + 2, pos + 5), 16) % 256)
					pos = pos + 6
				else
					out[#out + 1] = map[e]
					pos = pos + 2
				end
			elseif c == '' then
				error('unterminated string')
			else
				out[#out + 1] = c
				pos = pos + 1
			end
		end
	end

	function value()
		skip()
		local c = text:sub(pos, pos)
		if c == '{' then
			local obj = {}
			pos = pos + 1
			skip()
			if text:sub(pos, pos) == '}' then pos = pos + 1; return obj end
			while true do
				skip()
				local key = str()
				skip(); pos = pos + 1 -- ':'
				obj[key] = value()
				skip()
				local sep = text:sub(pos, pos); pos = pos + 1
				if sep == '}' then return obj end
			end
		elseif c == '[' then
			local arr = {}
			pos = pos + 1
			skip()
			-- Like CC:Tweaked: every empty array is the same shared table (textutils.empty_json_array).
			if text:sub(pos, pos) == ']' then pos = pos + 1; return EMPTY_JSON_ARRAY end
			while true do
				arr[#arr + 1] = value()
				skip()
				local sep = text:sub(pos, pos); pos = pos + 1
				if sep == ']' then return arr end
			end
		elseif c == '"' then
			return str()
		elseif text:sub(pos, pos + 3) == 'true' then pos = pos + 4; return true
		elseif text:sub(pos, pos + 4) == 'false' then pos = pos + 5; return false
		elseif text:sub(pos, pos + 3) == 'null' then pos = pos + 4; return nil
		else
			local number = text:match('^-?%d+%.?%d*[eE]?[-+]?%d*', pos)
			if not number or number == '' then error('bad JSON at ' .. pos) end
			pos = pos + #number
			return tonumber(number)
		end
	end

	local ok, result = pcall(value)
	if ok then return result end
	return nil
end

local function encodeJson(v)
	local t = type(v)
	if t == 'string' then return string.format('%q', v) end
	if t ~= 'table' then return tostring(v) end
	if #v > 0 or next(v) == nil then
		local parts = {}
		for i = 1, #v do parts[i] = encodeJson(v[i]) end
		return '[' .. table.concat(parts, ',') .. ']'
	end
	local parts = {}
	for k, x in pairs(v) do parts[#parts + 1] = string.format('%q', k) .. ':' .. encodeJson(x) end
	return '{' .. table.concat(parts, ',') .. '}'
end

---------------------------------------------------------------------------------------------------
-- Fake CC:Tweaked environment

FILES, DIRS, OUTPUT = {}, {}, {}

local function norm(path)
	path = path:gsub('\\', '/'):gsub('/+', '/'):gsub('^/', ''):gsub('/$', '')
	return path
end

local function isDir(path)
	path = norm(path)
	if path == '' or DIRS[path] then return true end
	for file in pairs(FILES) do
		if file:sub(1, #path + 1) == path .. '/' then return true end
	end
	return false
end

fs = {}

function fs.getDir(path)
	path = norm(path)
	return path:match('^(.*)/[^/]*$') or ''
end

function fs.exists(path) return FILES[norm(path)] ~= nil or isDir(path) end
function fs.isDir(path) return isDir(path) end

function fs.makeDir(path)
	path = norm(path)
	while path ~= '' do
		DIRS[path] = true
		path = fs.getDir(path)
	end
end

function fs.list(path)
	path = norm(path)
	local prefix, seen, out = path == '' and '' or path .. '/', {}, {}
	local function add(p)
		if p:sub(1, #prefix) == prefix and #p > #prefix then
			local name = p:sub(#prefix + 1):match('^[^/]+')
			if not seen[name] then seen[name] = true; out[#out + 1] = name end
		end
	end
	for file in pairs(FILES) do add(file) end
	for dir in pairs(DIRS) do add(dir) end
	table.sort(out)
	return out
end

function fs.delete(path)
	path = norm(path)
	FILES[path], DIRS[path] = nil, nil
	for file in pairs(FILES) do if file:sub(1, #path + 1) == path .. '/' then FILES[file] = nil end end
	for dir in pairs(DIRS) do if dir:sub(1, #path + 1) == path .. '/' then DIRS[dir] = nil end end
end

function fs.open(path, mode)
	path = norm(path)
	if mode == 'r' or mode == 'rb' then
		if FILES[path] == nil then return nil end
		return { readAll = function() return FILES[path] end, close = function() end }
	end
	if not isDir(fs.getDir(path)) then error('parent folder missing for ' .. path) end
	local buffer = {}
	return {
		write = function(s) buffer[#buffer + 1] = s end,
		close = function() FILES[path] = table.concat(buffer) end,
	}
end

-- Like CC:Tweaked, a table that appears twice is an error, even without a cycle.
local function serialise(value, indent, seen)
	indent = indent or ''
	seen = seen or {}
	local t = type(value)
	if t == 'string' then return string.format('%q', value) end
	if t ~= 'table' then return tostring(value) end
	if seen[value] then error('Cannot serialize table with repeated entries', 0) end
	seen[value] = true
	local keys = {}
	for k in pairs(value) do keys[#keys + 1] = k end
	table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
	local parts = {}
	for _, k in ipairs(keys) do
		local key = type(k) == 'number' and ('[' .. k .. ']') or ('[' .. string.format('%q', k) .. ']')
		parts[#parts + 1] = indent .. '  ' .. key .. ' = ' .. serialise(value[k], indent .. '  ', seen)
	end
	return '{\n' .. table.concat(parts, ',\n') .. '\n' .. indent .. '}'
end

textutils = {
	serialise          = serialise,
	unserialise        = function(s)
		local chunk = loadstring('return ' .. s)
		if not chunk then return nil end
		local ok, v = pcall(chunk)
		return ok and v or nil
	end,
	unserialiseJSON    = decodeJson,
}

colours = {}
for i, name in ipairs({ 'white', 'orange', 'magenta', 'lightBlue', 'yellow', 'lime', 'pink', 'grey', 'lightGrey',
	'cyan', 'purple', 'blue', 'brown', 'green', 'red', 'black' }) do
	colours[name] = 2 ^ (i - 1)
end
colours.gray, colours.lightGray = colours.grey, colours.lightGrey
colors = colours
term = {
	isColour      = function() return true end,
	getTextColour = function() return 1 end,
	setTextColour = function() end,
}

function print(...)
	local parts = {}
	for i = 1, select('#', ...) do parts[i] = tostring(select(i, ...)) end
	OUTPUT[#OUTPUT + 1] = table.concat(parts, ' ')
end

return { decodeJson = decodeJson, encodeJson = encodeJson }
