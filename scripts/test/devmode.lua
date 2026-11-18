-- Dev mode tests: runs installer/embercore-dev.lua in a fake CC:Tweaked environment whose http goes
-- through curl to the real dev server started by devmode.ts, and changes the served files on disk
-- while the program "runs".
--
-- Usage: lua devmode.lua <embercore-dev.lua> <server url> <served folder on this machine>

local CLIENT, URL, SERVED = arg[1], arg[2], arg[3]
local TEST_DIR = arg[0]:match('^(.*)[/\\]') or '.'

dofile(TEST_DIR .. '/cc-fake.lua')

local hostPrint = io.write

---------------------------------------------------------------------------------------------------
-- Host files (what the dev server serves)

local function writeHost(path, content)
	local file = assert(io.open(SERVED .. '/' .. path, 'wb'))
	file:write(content)
	file:close()
end

local function readHost(path)
	local file = io.open(SERVED .. '/' .. path, 'rb')
	if not file then return nil end
	local content = file:read('*a')
	file:close()
	return content
end

---------------------------------------------------------------------------------------------------
-- http through curl

local CURL_HTTP = {}

function CURL_HTTP.get(url, headers, binary)
	if binary ~= true then error('dev mode must download in binary mode') end
	local out    = os.tmpname()
	local status = io.popen("curl -s --max-time 30 -o '" .. out .. "' -w '%{http_code}' '" .. url .. "'"):read('*a')
	if status ~= '200' then
		os.remove(out)
		return nil, 'HTTP ' .. tostring(status)
	end
	local file    = io.open(out, 'rb')
	local content = file:read('*a')
	file:close()
	os.remove(out)
	return { readAll = function() return content end, close = function() end }
end

textutils.urlEncode = function(text)
	return (text:gsub('[^%w%-%._~]', function(c)
		if c == ' ' then return '+' end
		return string.format('%%%02X', c:byte())
	end))
end

---------------------------------------------------------------------------------------------------
-- Coroutines: os.pullEvent, sleep, parallel.waitForAny

local SLEEPS = 0
local MAX_SLEEPS = 0

os.pullEvent = function(filter) return coroutine.yield(filter) end

function sleep()
	SLEEPS = SLEEPS + 1
	if SLEEPS > MAX_SLEEPS then error('STOP_TEST', 0) end
end

parallel = {}

-- Enough for the dev mode: resume each function until it waits for an event; return as soon as
-- one of them finishes. No events are ever queued, so a function waiting forever just stays there.
function parallel.waitForAny(...)
	local routines = {}
	for i, fn in ipairs({ ... }) do routines[i] = coroutine.create(fn) end

	for _, routine in ipairs(routines) do
		local ok, err = coroutine.resume(routine)
		if not ok then error(err, 0) end
		if coroutine.status(routine) == 'dead' then return end
	end

	error('every function is waiting for an event that never comes', 0)
end

---------------------------------------------------------------------------------------------------
-- shell.run: the "program" is a test step

local RUNS = {}
local onRun

shell = {}

function shell.run(...)
	RUNS[#RUNS + 1] = { ... }
	return onRun(#RUNS, ...)
end

term.setBackgroundColour = function() end
term.clear               = function() end
term.setCursorPos        = function() end

---------------------------------------------------------------------------------------------------
-- Runner

local passed, failed = 0, 0

local function check(condition, message)
	if not condition then error(message, 2) end
end

local function contains(text, part) return text:find(part, 1, true) ~= nil end

local client = assert(loadfile(CLIENT))

-- Runs the client until a step raises STOP_TEST.
local function runClient(...)
	OUTPUT, RUNS, SLEEPS = {}, {}, 0
	local ok, err = pcall(client, ...)
	if ok then return err end
	if err ~= 'STOP_TEST' then error(err, 0) end
	return 'stopped'
end

local function test(name, body)
	http = CURL_HTTP
	MAX_SLEEPS = 0
	local ok, err = pcall(body)
	if ok then
		passed = passed + 1
		hostPrint('  ok   ' .. name .. '\n')
	else
		failed = failed + 1
		hostPrint('  FAIL ' .. name .. '\n       ' .. tostring(err) .. '\n       output: ' .. table.concat(OUTPUT, ' | ') .. '\n')
	end
end

local function devState()
	return textutils.unserialise(FILES['.embercore/dev'] or '{}')
end

hostPrint('Dev mode tests\n')

test('no arguments and no saved state prints the usage', function()
	FILES, DIRS = {}, {}
	local result = runClient()
	check(result == false and contains(table.concat(OUTPUT, '\n'), 'embercore-dev <url> <program>'), 'no usage')
end)

test('syncs, runs the program, then updates, deletes and restarts on change', function()
	FILES, DIRS = { ['mine.lua'] = 'my own file' }, {}

	onRun = function(index, ...)
		if index == 1 then
			local args = { ... }
			check(args[1] == 'prog' and args[2] == 'x', 'program arguments')
			check(FILES['a.lua'] == readHost('a.lua'), 'a.lua not synced')
			check(FILES['sub/b.lua'] == readHost('sub/b.lua'), 'sub/b.lua not synced')
			check(devState().url == URL, 'url not saved')

			writeHost('a.lua', 'return "a2"')
			os.remove(SERVED .. '/sub/b.lua')
			writeHost('c.lua', 'return "c1"')
			return true
		end

		check(FILES['a.lua'] == 'return "a2"', 'a.lua not updated')
		check(FILES['sub/b.lua'] == nil, 'sub/b.lua not deleted')
		check(not fs.exists('sub'), 'empty folder kept')
		check(FILES['c.lua'] == 'return "c1"', 'c.lua not added')
		check(FILES['mine.lua'] == 'my own file', 'a file the dev mode did not write was touched')
		error('STOP_TEST', 0)
	end

	check(runClient(URL .. '/', 'prog', 'x') == 'stopped', 'client ended on its own')
	check(#RUNS == 2, 'expected 2 runs, got ' .. #RUNS)
	check(contains(table.concat(OUTPUT, '\n'), 'restarting'), 'no restart message')
end)

test('without arguments it reuses the saved server and program', function()
	onRun = function(_, ...)
		local args = { ... }
		check(args[1] == 'prog' and args[2] == 'x', 'saved program not reused')
		error('STOP_TEST', 0)
	end
	check(runClient() == 'stopped', 'did not run')
end)

test('a program name alone keeps the saved server', function()
	onRun = function(_, ...)
		local args = { ... }
		check(args[1] == 'other' and args[2] == nil, 'new program not used')
		error('STOP_TEST', 0)
	end
	check(runClient('other') == 'stopped', 'did not run')
	check(devState().url == URL, 'server forgotten')
end)

test('a failing program waits for the next change instead of quitting', function()
	onRun = function(index)
		if index == 1 then
			writeHost('a.lua', 'return "a3"')
			return false
		end
		check(FILES['a.lua'] == 'return "a3"', 'not updated after the failure')
		error('STOP_TEST', 0)
	end
	check(runClient('prog') == 'stopped', 'did not restart')
	check(contains(table.concat(OUTPUT, '\n'), 'Program failed'), 'no failure message')
end)

test('paths outside the computer are refused', function()
	FILES, DIRS = {}, {}
	http = {
		get = function(url)
			local body = url:find('/manifest', 1, true) and '{"revision":1,"files":{"../evil.lua":"h"}}' or 'x'
			return { readAll = function() return body end, close = function() end }
		end,
	}
	onRun = function() error('program must not run', 0) end
	check(runClient(URL, 'prog') == 'stopped', 'expected a retry')
	check(contains(table.concat(OUTPUT, '\n'), 'refused path ../evil.lua'), 'path not refused')
	check(FILES['../evil.lua'] == nil and FILES['evil.lua'] == nil, 'file written')
end)

test('an empty manifest never deletes the synced files', function()
	FILES, DIRS = { ['a.lua'] = 'kept' }, {}
	FILES['.embercore/dev'] = textutils.serialise({ url = URL, program = { 'prog' }, files = { ['a.lua'] = 'h' } })
	http = {
		get = function()
			local body = '{"revision":0,"files":{}}'
			return { readAll = function() return body end, close = function() end }
		end,
	}
	check(runClient() == 'stopped', 'expected a retry')
	check(FILES['a.lua'] == 'kept', 'file deleted')
	check(contains(table.concat(OUTPUT, '\n'), 'no files yet'), 'no message')
end)

test('an unreachable server is retried, not fatal', function()
	FILES, DIRS = {}, {}
	MAX_SLEEPS = 2
	check(runClient('http://127.0.0.1:1', 'prog') == 'stopped', 'expected retries')
	check(SLEEPS == 3, 'expected 3 attempts, got ' .. SLEEPS)
end)

hostPrint(string.format('\n%d passed, %d failed\n', passed, failed))
os.exit(failed == 0 and 0 or 1)
