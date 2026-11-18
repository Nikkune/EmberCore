-- EmberCore installer for CC:Tweaked.
--
--   embercore install <id>   install a component or project and its dependencies
--   embercore update         update everything installed to the published versions
--   embercore remove <id>    remove a component (and the dependencies nothing else needs)
--   embercore list           list available components and what is installed
--
-- <id> is a full id ("modules/ui", "core/config") or its last part when unique ("ui", "config").
-- Files are installed at the root of the computer, so require("core.config") works as is.
-- What is installed is recorded in /.embercore/installed (textutils.serialise format).

local REPOSITORY = "Nikkune/EmberCore"
local BRANCH     = "lua"
local BASE_URL   = "https://raw.githubusercontent.com/" .. REPOSITORY .. "/" .. BRANCH .. "/"
local STATE_PATH = "/.embercore/installed"

---------------------------------------------------------------------------------------------------
-- Output

local function say(colour, text)
	if term.isColour and term.isColour() and colour then
		local previous = term.getTextColour()
		term.setTextColour(colour)
		print(text)
		term.setTextColour(previous)
	else
		print(text)
	end
end

local function info(text) say(colours.lightGrey, text) end
local function ok(text) say(colours.lime, text) end
local function warn(text) say(colours.orange, text) end

-- Errors raised with fail() are user-facing: printed without a stack trace.
local FAILURE = {}

local function fail(text)
	error({ [FAILURE] = true, message = text }, 0)
end

---------------------------------------------------------------------------------------------------
-- Network

local function fetch(path)
	local url = BASE_URL .. path
	local response, reason = http.get(url, nil, true)

	if not response then
		fail("Download failed: " .. path .. " (" .. tostring(reason) .. ")")
	end

	local content = response.readAll() or ""
	response.close()

	return content
end

local function fetchJson(path)
	local content = fetch(path)
	local data    = textutils.unserialiseJSON(content)

	if type(data) ~= "table" then
		fail("Invalid JSON: " .. path)
	end

	return data
end

---------------------------------------------------------------------------------------------------
-- Files

local function readFile(path)
	local file = fs.open(path, "rb")
	if not file then return nil end

	local content = file.readAll()
	file.close()

	return content
end

local function writeFile(path, content)
	local parent = fs.getDir(path)
	if parent ~= "" and not fs.exists(parent) then fs.makeDir(parent) end

	local file = fs.open(path, "wb")
	if not file then fail("Cannot write " .. path) end

	file.write(content)
	file.close()
end

-- Deletes a file, then its parent folders while they are empty.
local function deleteFile(path)
	if fs.exists(path) then fs.delete(path) end

	local dir = fs.getDir(path)

	while dir ~= "" and fs.exists(dir) and fs.isDir(dir) and #fs.list(dir) == 0 do
		fs.delete(dir)
		dir = fs.getDir(dir)
	end
end

---------------------------------------------------------------------------------------------------
-- Installed state: { [id] = { version, type, files, dependencies, explicit } }

local function loadState()
	local content = readFile(STATE_PATH)
	if not content then return {} end

	local state = textutils.unserialise(content)
	if type(state) ~= "table" then
		warn("Unreadable " .. STATE_PATH .. ", starting from an empty state")
		return {}
	end

	return state
end

local function saveState(state)
	writeFile(STATE_PATH, textutils.serialise(state))
end

local function copyList(list)
	local copy = {}
	for i, value in ipairs(list or {}) do copy[i] = value end
	return copy
end

local function sortedKeys(map)
	local keys = {}
	for key in pairs(map) do keys[#keys + 1] = key end
	table.sort(keys)
	return keys
end

---------------------------------------------------------------------------------------------------
-- Index and manifests

local function manifestPath(index, id)
	return (index.components or {})[id] or (index.projects or {})[id]
end

-- Resolves "ui" to "modules/ui" when exactly one id ends with "/ui".
local function resolveId(index, name)
	if manifestPath(index, name) then return name end

	local matches = {}

	for _, group in ipairs({ index.components or {}, index.projects or {} }) do
		for id in pairs(group) do
			if id:sub(-(#name + 1)) == "/" .. name then matches[#matches + 1] = id end
		end
	end

	table.sort(matches)

	if #matches == 1 then return matches[1] end
	if #matches == 0 then fail("Unknown id '" .. name .. "' (see: embercore list)") end

	fail("Ambiguous id '" .. name .. "': " .. table.concat(matches, ", "))
end

-- Returns the manifests of the given ids and all their dependencies, dependencies first.
local function resolvePlan(index, ids)
	local manifests = {}
	local order     = {}
	local visiting  = {}

	local function visit(id, requiredBy)
		if manifests[id] then return end

		if visiting[id] then fail("Dependency cycle through " .. id) end

		local path = manifestPath(index, id)
		if not path then
			fail("Unknown id '" .. id .. "'" .. (requiredBy and (" (required by " .. requiredBy .. ")") or ""))
		end

		visiting[id] = true

		local manifest = fetchJson(path)
		for _, dependency in ipairs(manifest.dependencies or {}) do
			visit(dependency, id)
		end

		visiting[id]  = nil
		manifests[id] = manifest
		order[#order + 1] = manifest
	end

	for _, id in ipairs(ids) do visit(id) end

	return order
end

---------------------------------------------------------------------------------------------------
-- Install / remove one component

local function contains(list, value)
	for _, item in ipairs(list or {}) do
		if item == value then return true end
	end
	return false
end

-- The startup.lua the installer writes for a project (only this exact content is ever removed).
local function startupFor(entry)
	return 'shell.run("/' .. entry .. '")\n'
end

local function isUpToDate(entry, manifest)
	if not entry or entry.version ~= manifest.version then return false end

	for _, file in ipairs(manifest.files or {}) do
		if not fs.exists(file) then return false end
	end

	return true
end

-- Downloads every file first, so a network error never leaves a component half written.
local function applyManifest(state, manifest, explicit)
	local id    = manifest.id
	local entry = state[id]

	if isUpToDate(entry, manifest) then
		if explicit then entry.explicit = true end
		return false
	end

	local preserve = (manifest.install and manifest.install.preserve) or {}
	local contents = {}

	for _, file in ipairs(manifest.files or {}) do
		if not (contains(preserve, file) and fs.exists(file)) then
			contents[file] = fetch(file)
		end
	end

	for _, file in ipairs(manifest.files or {}) do
		local content = contents[file]
		if content ~= nil and readFile(file) ~= content then writeFile(file, content) end
	end

	-- Files of the previous version that are gone from the new one.
	for _, file in ipairs((entry and entry.files) or {}) do
		if not contains(manifest.files, file) then deleteFile(file) end
	end

	if manifest.type == "project" and manifest.install and manifest.install.startup and manifest.entry then
		local startup = startupFor(manifest.entry)
		local current = readFile("startup.lua")

		if current == nil then
			writeFile("startup.lua", startup)
		elseif current ~= startup then
			warn("startup.lua already exists, not replaced (start it with " .. manifest.entry .. ")")
		end
	end

	-- Copies: textutils.unserialiseJSON returns one shared table for every empty array, and
	-- textutils.serialise refuses a table that appears twice.
	state[id] = {
		version      = manifest.version,
		type         = manifest.type,
		files        = copyList(manifest.files),
		dependencies = copyList(manifest.dependencies),
		entry        = manifest.entry,
		explicit     = explicit or (entry ~= nil and entry.explicit) or false,
	}
	saveState(state)

	if entry then
		ok("Updated " .. id .. " " .. tostring(entry.version) .. " -> " .. manifest.version)
	else
		ok("Installed " .. id .. " " .. manifest.version)
	end

	return true
end

local function dependents(state, id)
	local result = {}

	for _, other in ipairs(sortedKeys(state)) do
		if other ~= id and contains(state[other].dependencies, id) then result[#result + 1] = other end
	end

	return result
end

local function removeEntry(state, id)
	local entry = state[id]

	for _, file in ipairs(entry.files or {}) do deleteFile(file) end

	if entry.type == "project" and entry.entry and readFile("startup.lua") == startupFor(entry.entry) then
		deleteFile("startup.lua")
	end

	state[id] = nil
	saveState(state)
	ok("Removed " .. id)
end

-- Removes the dependencies installed automatically that nothing needs any more.
local function pruneOrphans(state)
	local removed = true

	while removed do
		removed = false

		for _, id in ipairs(sortedKeys(state)) do
			if not state[id].explicit and #dependents(state, id) == 0 then
				removeEntry(state, id)
				removed = true
			end
		end
	end
end

---------------------------------------------------------------------------------------------------
-- Commands

local commands = {}

function commands.install(name)
	if not name then fail("Usage: embercore install <id>") end

	local index = fetchJson("manifests/index.json")
	local id    = resolveId(index, name)
	local state = loadState()
	local plan  = resolvePlan(index, { id })
	local changed = 0

	for _, manifest in ipairs(plan) do
		if applyManifest(state, manifest, manifest.id == id) then changed = changed + 1 end
	end

	if changed == 0 then info(id .. " is already up to date") end

	local installed = state[id]
	if installed and installed.type == "project" and installed.entry then
		info("Run it with: " .. installed.entry)
	end
end

function commands.update()
	local state = loadState()
	local ids   = {}

	if next(state) == nil then
		info("Nothing installed")
		return
	end

	local index = fetchJson("manifests/index.json")

	for _, id in ipairs(sortedKeys(state)) do
		if manifestPath(index, id) then
			ids[#ids + 1] = id
		else
			warn(id .. " is no longer published, kept as is")
		end
	end

	local plan    = resolvePlan(index, ids)
	local changed = 0

	for _, manifest in ipairs(plan) do
		local entry = state[manifest.id]
		if applyManifest(state, manifest, entry ~= nil and entry.explicit) then changed = changed + 1 end
	end

	pruneOrphans(state)

	if changed == 0 then info("Everything is up to date") end
end

function commands.remove(name)
	if not name then fail("Usage: embercore remove <id>") end

	local state = loadState()
	local id    = name

	if not state[id] then
		local matches = {}
		for _, installed in ipairs(sortedKeys(state)) do
			if installed:sub(-(#name + 1)) == "/" .. name then matches[#matches + 1] = installed end
		end

		if #matches == 0 then fail(name .. " is not installed") end
		if #matches > 1 then fail("Ambiguous id '" .. name .. "': " .. table.concat(matches, ", ")) end
		id = matches[1]
	end

	local users = dependents(state, id)
	if #users > 0 then
		fail(id .. " is required by " .. table.concat(users, ", "))
	end

	removeEntry(state, id)
	pruneOrphans(state)
end

function commands.list()
	local state = loadState()
	local ok_, index = pcall(fetchJson, "manifests/index.json")

	if not ok_ then
		warn("Cannot reach the repository, showing installed components only")
		index = { components = {}, projects = {} }
	end

	local ids = {}
	for id in pairs(index.components or {}) do ids[id] = true end
	for id in pairs(index.projects or {}) do ids[id] = true end
	for id in pairs(state) do ids[id] = true end

	for _, id in ipairs(sortedKeys(ids)) do
		local entry = state[id]

		if entry then
			say(colours.lime, "* " .. id .. " " .. tostring(entry.version) .. (entry.explicit and "" or " (dependency)"))
		else
			say(colours.lightGrey, "  " .. id)
		end
	end
end

---------------------------------------------------------------------------------------------------
-- Entry point

local function usage()
	print("Usage:")
	print("  embercore install <id>")
	print("  embercore update")
	print("  embercore remove <id>")
	print("  embercore list")
end

local function main(...)
	local args    = { ... }
	local command = commands[args[1] or ""]

	if not command then
		usage()
		return false
	end

	if not http then
		fail("The http API is disabled on this server")
	end

	command(args[2])
	return true
end

local success, result = pcall(main, ...)

if not success then
	if type(result) == "table" and result[FAILURE] then
		say(colours.red, result.message)
	else
		say(colours.red, "Error: " .. tostring(result))
	end
	return false
end

return result
