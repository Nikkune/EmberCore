-- Installer tests: runs installer/embercore.lua in a fake CC:Tweaked environment (file system with
-- folders, http served from memory) against the real compiled files and manifests, then against
-- synthetic repositories for updates, removals, failures and projects.
--
-- Usage: lua installer.lua <installer.lua> <luas dir> <manifests dir>

local INSTALLER, DIST_DIR, MANIFESTS_DIR = arg[1], arg[2], arg[3]
INSTALLER_TEST_DIR = arg[0]:match('^(.*)[/\\]') or '.'
local BASE_URL = 'https://raw.githubusercontent.com/Nikkune/EmberCore/lua/'

---------------------------------------------------------------------------------------------------
-- Host helpers

local function readHostFile(path)
	local file = io.open(path, 'rb')
	if not file then return nil end
	local content = file:read('*a')
	file:close()
	return content
end

---------------------------------------------------------------------------------------------------
-- Fake CC:Tweaked environment (shared pieces in cc-fake.lua, http served from SERVER)

local fake = dofile(INSTALLER_TEST_DIR .. '/cc-fake.lua')
local decodeJson, encodeJson = fake.decodeJson, fake.encodeJson

SERVER, REQUESTS = {}, {}

http = {}

function http.get(url, headers, binary)
	if binary ~= true then error('installer must download in binary mode') end
	REQUESTS[#REQUESTS + 1] = url
	local path = url:sub(#BASE_URL + 1)
	local content = url:sub(1, #BASE_URL) == BASE_URL and SERVER[path] or nil
	if content == nil then return nil, 'Not Found' end
	return { readAll = function() return content end, close = function() end }
end

local hostPrint = io.write

local installer = assert(loadfile(INSTALLER))

local function run(...)
	OUTPUT, REQUESTS = {}, {}
	local result = installer(...)
	return result, table.concat(OUTPUT, '\n')
end

local function resetComputer()
	FILES, DIRS = {}, {}
end

---------------------------------------------------------------------------------------------------
-- Test runner

local passed, failed = 0, 0

local function check(condition, message)
	if not condition then error(message, 2) end
end

local function test(name, body)
	resetComputer()
	SERVER = {}
	local ok, err = pcall(body)
	if ok then
		passed = passed + 1
		hostPrint('  ok   ' .. name .. '\n')
	else
		failed = failed + 1
		hostPrint('  FAIL ' .. name .. '\n       ' .. tostring(err) .. '\n       output: ' .. table.concat(OUTPUT, ' | ') .. '\n')
	end
end

local function contains(text, part) return text:find(part, 1, true) ~= nil end

local function installedState()
	return textutils.unserialise(FILES['.embercore/installed'] or '{}')
end

local function manifestFiles(id)
	local index = decodeJson(SERVER['manifests/index.json'])
	return decodeJson(SERVER[index.components[id] or index.projects[id]])
end

-- Serves the real compiled runtime and manifests, as the lua branch publishes them.
local function serveRealBuild()
	local index = decodeJson(assert(readHostFile(MANIFESTS_DIR .. '/index.json'), 'manifests/index.json missing'))
	SERVER['manifests/index.json'] = readHostFile(MANIFESTS_DIR .. '/index.json')
	for _, group in ipairs({ index.components, index.projects }) do
		for _, path in pairs(group) do
			local manifestText = assert(readHostFile(MANIFESTS_DIR .. '/' .. path:gsub('^manifests/', '')), path)
			SERVER[path] = manifestText
			for _, file in ipairs(decodeJson(manifestText).files) do
				SERVER[file] = assert(readHostFile(DIST_DIR .. '/' .. file), file)
			end
		end
	end
	return index
end

-- Synthetic repository: components = { [id] = { version, files = {[path]=content}, dependencies, ... } }
local function serveRepository(components)
	local index = { manifestVersion = 1, components = {}, projects = {} }
	SERVER = {}
	for id, spec in pairs(components) do
		local path = 'manifests/' .. id .. '.json'
		local files = {}
		for file, content in pairs(spec.files) do
			files[#files + 1] = file
			SERVER[file] = content
		end
		table.sort(files)
		local manifest = {
			manifestVersion = 1,
			id              = id,
			type            = spec.type or 'component',
			version         = spec.version,
			files           = files,
			dependencies    = spec.dependencies or {},
			entry           = spec.entry,
			install         = spec.install,
		}
		SERVER[path] = encodeJson(manifest)
		if manifest.type == 'project' then index.projects[id] = path else index.components[id] = path end
	end
	SERVER['manifests/index.json'] = encodeJson(index)
end

hostPrint('Installer tests\n')

---------------------------------------------------------------------------------------------------
-- Against the real build

test('install ui installs modules/ui and its dependencies byte for byte', function()
	serveRealBuild()
	local result, out = run('install', 'ui')
	check(result == true, 'install failed: ' .. out)

	local state = installedState()
	check(state['modules/ui'] and state['modules/ui'].explicit == true, 'modules/ui not recorded as explicit')

	local expected = { 'modules/ui' }
	for _, dep in ipairs(manifestFiles('modules/ui').dependencies) do expected[#expected + 1] = dep end

	for _, id in ipairs(expected) do
		check(state[id], id .. ' not installed')
		for _, file in ipairs(manifestFiles(id).files) do
			check(FILES[file] == SERVER[file], file .. ' differs from the published file')
		end
	end

	for id, entry in pairs(state) do
		if id ~= 'modules/ui' then check(entry.explicit == false, id .. ' should be a dependency') end
	end
end)

test('the installed ui loads with require from the computer root', function()
	serveRealBuild()
	run('install', 'ui')

	local loaded = {}
	local function ccRequire(name)
		if loaded[name] ~= nil then return loaded[name] end
		local path = name:gsub('%.', '/') .. '.lua'
		local source = FILES[path]
		if not source then
			-- only the CC APIs ('cc.*') may be missing
			check(name:sub(1, 3) == 'cc.', 'missing module after install: ' .. name)
			return {}
		end
		local chunk = assert(loadstring(source, '@' .. path))
		local env = setmetatable({ require = ccRequire }, { __index = _G })
		setfenv(chunk, env)
		loaded[name] = chunk(name) or true
		return loaded[name]
	end

	local ui = ccRequire('modules.ui.index')
	check(type(ui) == 'table', 'modules.ui.index did not return a table')
end)

test('components with no dependencies can be recorded together (shared empty JSON array)', function()
	serveRealBuild()
	local result, out = run('install', 'config')
	check(result == true and not contains(out, 'Error'), out)
	check(installedState()['core/logger'] and installedState()['utils/helpers'], 'state incomplete')
end)

test('second install downloads only the manifests', function()
	serveRealBuild()
	run('install', 'config')
	local _, out = run('install', 'config')
	check(contains(out, 'already up to date'), 'expected up to date: ' .. out)
	for _, url in ipairs(REQUESTS) do
		check(url:find('/manifests/', 1, true), 'unexpected file download: ' .. url)
	end
end)

test('remove ui removes everything and leaves no empty folders', function()
	serveRealBuild()
	run('install', 'ui')
	local result, out = run('remove', 'ui')
	check(result == true, out)
	check(next(installedState()) == nil, 'state should be empty')
	for file in pairs(FILES) do
		check(file == '.embercore/installed', 'leftover file: ' .. file)
	end
	check(#fs.list('') == 1, 'leftover folders: ' .. table.concat(fs.list(''), ', '))
end)

test('remove refuses a component another one requires', function()
	serveRealBuild()
	run('install', 'config')
	local _, out = run('remove', 'logger')
	check(contains(out, 'core/logger is not installed') == false, out)
	check(contains(out, 'required by core/config'), 'expected refusal: ' .. out)
	check(FILES['core/logger.lua'], 'logger was deleted')
end)

test('list shows installed and available components', function()
	serveRealBuild()
	run('install', 'config')
	local _, out = run('list')
	check(contains(out, '* core/config'), out)
	check(contains(out, '* core/logger') and contains(out, '(dependency)'), out)
	check(contains(out, '  modules/ui'), out)
end)

---------------------------------------------------------------------------------------------------
-- Synthetic repositories

test('unknown and ambiguous ids are rejected', function()
	serveRepository({
		['core/a'] = { version = '1.0.0', files = { ['core/a.lua'] = 'a' } },
		['modules/a'] = { version = '1.0.0', files = { ['modules/a.lua'] = 'a' } },
	})
	local _, out = run('install', 'nope')
	check(contains(out, "Unknown id 'nope'"), out)
	_, out = run('install', 'a')
	check(contains(out, 'Ambiguous') and contains(out, 'core/a, modules/a'), out)
	check(next(FILES) == nil, 'nothing should be written')
end)

test('update replaces changed files, deletes removed ones and prunes old dependencies', function()
	serveRepository({
		['core/a'] = { version = '1.0.0', files = { ['core/a/x.lua'] = 'x1', ['core/a/y.lua'] = 'y1' }, dependencies = { 'core/b' } },
		['core/b'] = { version = '1.0.0', files = { ['core/b.lua'] = 'b1' } },
	})
	run('install', 'core/a')
	check(FILES['core/b.lua'] == 'b1', 'dependency not installed')

	serveRepository({
		['core/a'] = { version = '2.0.0', files = { ['core/a/x.lua'] = 'x2', ['core/a/z.lua'] = 'z2' } },
		['core/b'] = { version = '1.0.0', files = { ['core/b.lua'] = 'b1' } },
	})
	local _, out = run('update')
	check(contains(out, 'Updated core/a 1.0.0 -> 2.0.0'), out)
	check(FILES['core/a/x.lua'] == 'x2' and FILES['core/a/z.lua'] == 'z2', 'files not updated')
	check(FILES['core/a/y.lua'] == nil, 'removed file kept')
	check(FILES['core/b.lua'] == nil and installedState()['core/b'] == nil, 'orphan dependency kept')
	check(contains(out, 'Removed core/b'), out)
end)

test('update installs new dependencies and keeps explicit ones', function()
	serveRepository({
		['core/a'] = { version = '1.0.0', files = { ['core/a.lua'] = 'a1' } },
		['core/c'] = { version = '1.0.0', files = { ['core/c.lua'] = 'c1' } },
	})
	run('install', 'core/a')
	run('install', 'core/c')
	serveRepository({
		['core/a'] = { version = '1.1.0', files = { ['core/a.lua'] = 'a2' }, dependencies = { 'core/c' } },
		['core/c'] = { version = '1.0.0', files = { ['core/c.lua'] = 'c1' } },
	})
	run('update')
	check(installedState()['core/c'].explicit == true, 'core/c lost its explicit flag')
	local _, out = run('update')
	check(contains(out, 'Everything is up to date'), out)
end)

test('a failed download writes nothing for that component', function()
	serveRepository({
		['core/a'] = { version = '1.0.0', files = { ['core/a/x.lua'] = 'x', ['core/a/y.lua'] = 'y' } },
	})
	SERVER['core/a/y.lua'] = nil
	local result, out = run('install', 'core/a')
	check(result == false and contains(out, 'Download failed: core/a/y.lua'), out)
	check(FILES['core/a/x.lua'] == nil, 'partial component written')
	check(installedState()['core/a'] == nil, 'component recorded')
end)

test('a missing dependency fails before anything is written', function()
	serveRepository({
		['core/a'] = { version = '1.0.0', files = { ['core/a.lua'] = 'a' }, dependencies = { 'core/missing' } },
	})
	local _, out = run('install', 'core/a')
	check(contains(out, "Unknown id 'core/missing' (required by core/a)"), out)
	check(next(FILES) == nil, 'nothing should be written')
end)

test('a dependency cycle is reported', function()
	serveRepository({
		['core/a'] = { version = '1.0.0', files = { ['core/a.lua'] = 'a' }, dependencies = { 'core/b' } },
		['core/b'] = { version = '1.0.0', files = { ['core/b.lua'] = 'b' }, dependencies = { 'core/a' } },
	})
	local _, out = run('install', 'core/a')
	check(contains(out, 'Dependency cycle'), out)
end)

test('a deleted file is downloaded again even when the version did not change', function()
	serveRepository({ ['core/a'] = { version = '1.0.0', files = { ['core/a.lua'] = 'a' } } })
	run('install', 'core/a')
	FILES['core/a.lua'] = nil
	run('update')
	check(FILES['core/a.lua'] == 'a', 'file not restored')
end)

test('projects: startup file, preserved files and removal', function()
	serveRepository({
		['core/a'] = { version = '1.0.0', files = { ['core/a.lua'] = 'a' } },
		['projects/p'] = {
			type = 'project', version = '1.0.0', entry = 'projects/p/main.lua',
			files = { ['projects/p/main.lua'] = 'main1', ['projects/p/config.lua'] = 'default' },
			dependencies = { 'core/a' },
			install = { startup = true, preserve = { 'projects/p/config.lua' } },
		},
	})
	local _, out = run('install', 'p')
	check(contains(out, 'Run it with: projects/p/main.lua'), out)
	check(FILES['startup.lua'] == 'shell.run("/projects/p/main.lua")\n', 'startup not written')

	FILES['projects/p/config.lua'] = 'mine'
	serveRepository({
		['core/a'] = { version = '1.0.0', files = { ['core/a.lua'] = 'a' } },
		['projects/p'] = {
			type = 'project', version = '1.1.0', entry = 'projects/p/main.lua',
			files = { ['projects/p/main.lua'] = 'main2', ['projects/p/config.lua'] = 'default2' },
			dependencies = { 'core/a' },
			install = { startup = true, preserve = { 'projects/p/config.lua' } },
		},
	})
	run('update')
	check(FILES['projects/p/main.lua'] == 'main2', 'project not updated')
	check(FILES['projects/p/config.lua'] == 'mine', 'preserved file overwritten')

	run('remove', 'p')
	check(FILES['startup.lua'] == nil, 'startup kept')
	check(FILES['core/a.lua'] == nil, 'dependency kept')
end)

test('a startup.lua written by the user is never removed', function()
	serveRepository({
		['projects/p'] = {
			type = 'project', version = '1.0.0', entry = 'projects/p/main.lua',
			files = { ['projects/p/main.lua'] = 'm' }, install = { startup = true },
		},
	})
	FILES['startup.lua'] = 'print("mine")'
	local _, out = run('install', 'p')
	check(contains(out, 'startup.lua already exists'), out)
	check(FILES['startup.lua'] == 'print("mine")', 'user startup replaced')
	run('remove', 'p')
	check(FILES['startup.lua'] == 'print("mine")', 'user startup deleted')
end)

test('no arguments prints the usage', function()
	local result, out = run()
	check(result == false and contains(out, 'embercore install <id>'), out)
end)

test('disabled http API is reported', function()
	local saved = http
	http = nil
	local _, out = run('list')
	http = saved
	check(contains(out, 'http API is disabled'), out)
end)

hostPrint(string.format('\n%d passed, %d failed\n', passed, failed))
os.exit(failed == 0 and 0 or 1)
