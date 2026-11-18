-- Loads compiled EmberCore Lua modules outside Minecraft, with stubbed CC:Tweaked APIs.
-- Usage: lua cc-loader.lua <installDir> <module> [<module> ...]
-- A module prefixed with '@' is only compiled (loadfile), not executed (used for project entrypoints).
-- Exits with code 1 if any module fails to load.

local installDir = arg[1]
if not installDir then
	io.stderr:write('usage: cc-loader.lua <installDir> <module>...\n')
	os.exit(2)
end

-- Only the simulated install directory is searchable: a file missing from the manifests must fail.
package.path = installDir .. '/?.lua'
package.cpath = ''

unpack = unpack or table.unpack

-- A stub that tolerates any field access or call, enough for module top-level code.
local stub
stub = setmetatable({}, {
	__index = function() return stub end,
	__call = function() return stub end,
})

local function api()
	return setmetatable({}, { __index = function() return stub end })
end

colors = setmetatable({}, { __index = function() return 1 end })
colours = colors
for _, name in ipairs({ 'term', 'peripheral', 'fs', 'textutils', 'parallel', 'keys', 'http', 'shell',
	'window', 'paintutils', 'settings', 'rednet', 'redstone', 'rs', 'vector', 'multishell', 'turtle' }) do
	_G[name] = api()
end
for _, name in ipairs({ 'pullEvent', 'pullEventRaw', 'queueEvent', 'startTimer', 'cancelTimer', 'epoch',
	'getComputerID', 'getComputerLabel', 'setComputerLabel', 'sleep' }) do
	os[name] = os[name] or stub
end
sleep = stub
printError = stub
write = stub
read = stub

-- Mimic CC:Tweaked's require: a module that requires itself (directly or not) is an error,
-- whereas plain Lua 5.2 would recurse.
-- The "in progress" marker lives outside package.loaded: the native require would otherwise
-- treat it as an already-loaded module and never read the file.
local loading = {}
local baseRequire = require
require = function(name)
	if package.loaded[name] ~= nil then
		return package.loaded[name]
	end
	if loading[name] then
		error("loop or previous error loading module '" .. name .. "'", 2)
	end
	loading[name] = true
	local ok, result = pcall(baseRequire, name)
	loading[name] = nil
	if not ok then
		error(result, 0)
	end
	return result
end

local failures = 0
for i = 2, #arg do
	local name = arg[i]
	local ok, err
	if name:sub(1, 1) == '@' then
		local path = installDir .. '/' .. name:sub(2):gsub('%.', '/') .. '.lua'
		local chunk, loadErr = loadfile(path)
		ok, err = chunk ~= nil, loadErr
	else
		ok, err = pcall(require, name)
	end
	if not ok then
		failures = failures + 1
		print('FAIL ' .. name .. ': ' .. tostring(err))
	end
end

os.exit(failures == 0 and 0 or 1)
