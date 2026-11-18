-- EmberCore dev mode for CC:Tweaked: keeps this computer in sync with "npm run dev" on your machine
-- and restarts your program each time a file changes.
--
--   embercore-dev <url> <program> [args...]   first time: dev server URL and program to run
--   embercore-dev <program> [args...]         same server, another program
--   embercore-dev                             same server and program as last time
--
-- Files are written at the root of the computer (like the installer). Only files this dev mode
-- downloaded are ever deleted. Ctrl+T stops it. State: /.embercore/dev

local STATE_PATH = "/.embercore/dev"

---------------------------------------------------------------------------------------------------
-- Output

local function say(colour, text)
	if term.isColour and term.isColour() then
		local previous = term.getTextColour()
		term.setTextColour(colour)
		print(text)
		term.setTextColour(previous)
	else
		print(text)
	end
end

local function info(text) say(colours.lightGrey, "[dev] " .. text) end
local function warn(text) say(colours.orange, "[dev] " .. text) end

---------------------------------------------------------------------------------------------------
-- Files and state

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
	if not file then error("Cannot write " .. path, 0) end
	file.write(content)
	file.close()
end

local function deleteFile(path)
	if fs.exists(path) then fs.delete(path) end

	local dir = fs.getDir(path)
	while dir ~= "" and fs.exists(dir) and fs.isDir(dir) and #fs.list(dir) == 0 do
		fs.delete(dir)
		dir = fs.getDir(dir)
	end
end

local function loadState()
	local content = readFile(STATE_PATH)
	local state   = content and textutils.unserialise(content)
	if type(state) ~= "table" then state = {} end
	state.files = type(state.files) == "table" and state.files or {}
	return state
end

local function saveState(state)
	writeFile(STATE_PATH, textutils.serialise(state))
end

-- Paths come from the network: keep them inside the computer and away from the ROM.
local function isSafePath(path)
	return type(path) == "string" and path ~= "" and path:sub(1, 1) ~= "/"
		and not path:find("..", 1, true) and not path:find("\\", 1, true)
		and path:sub(1, 4) ~= "rom/" and path:sub(1, 1) ~= "."
end

---------------------------------------------------------------------------------------------------
-- Network

local function get(state, path)
	local response, reason = http.get(state.url .. path, nil, true)
	if not response then return nil, reason end
	local content = response.readAll() or ""
	response.close()
	return content
end

local function getJson(state, path)
	local content, reason = get(state, path)
	if not content then return nil, reason end
	local data = textutils.unserialiseJSON(content)
	if type(data) ~= "table" then return nil, "invalid JSON from " .. path end
	return data
end

---------------------------------------------------------------------------------------------------
-- Sync: returns the number of files written or deleted, or nil and a reason

local function sync(state)
	local manifest, reason = getJson(state, "/manifest")
	if not manifest then return nil, reason end

	local files = manifest.files
	if type(files) ~= "table" or next(files) == nil then
		return nil, "the dev server has no files yet (still compiling?)"
	end

	-- Download everything that changed before writing anything.
	local downloads = {}
	for path, hash in pairs(files) do
		if not isSafePath(path) then return nil, "refused path " .. tostring(path) end

		if state.files[path] ~= hash or not fs.exists(path) then
			local content, err = get(state, "/files/" .. textutils.urlEncode(path))
			if not content then return nil, "download failed: " .. path .. " (" .. tostring(err) .. ")" end
			downloads[path] = content
		end
	end

	local changed = 0

	for path, content in pairs(downloads) do
		if readFile(path) ~= content then
			writeFile(path, content)
			changed = changed + 1
		end
		state.files[path] = files[path]
	end

	for path in pairs(state.files) do
		if files[path] == nil then
			deleteFile(path)
			state.files[path] = nil
			changed = changed + 1
		end
	end

	state.revision = manifest.revision
	saveState(state)

	return changed
end

---------------------------------------------------------------------------------------------------
-- Program and watcher

local function runProgram(state)
	term.setBackgroundColour(colours.black)
	term.setTextColour(colours.white)
	term.clear()
	term.setCursorPos(1, 1)

	local success = shell.run((table.unpack or unpack)(state.program))

	if success then
		info("Program ended. Waiting for changes (Ctrl+T to quit)")
	else
		warn("Program failed. Fix it, it restarts on the next change (Ctrl+T to quit)")
	end

	while true do os.pullEvent("embercore_dev_idle") end
end

-- Returns once files changed (so the program restarts).
local function watch(state)
	local offline = false

	while true do
		local answer, reason = getJson(state, "/wait?revision=" .. tostring(state.revision or -1))

		if not answer then
			if not offline then warn("Dev server unreachable (" .. tostring(reason) .. "), retrying") end
			offline = true
			sleep(2)
		elseif answer.revision ~= state.revision then
			if offline then info("Dev server back") end
			offline = false

			local changed, err = sync(state)
			if changed == nil then
				warn("Sync failed: " .. tostring(err))
				sleep(2)
			elseif changed > 0 then
				return
			end
		else
			offline = false
		end
	end
end

---------------------------------------------------------------------------------------------------
-- Entry point

local function usage()
	print("Usage:")
	print("  embercore-dev <url> <program> [args...]")
	print("  embercore-dev <program> [args...]")
	print("  embercore-dev")
end

local function main(...)
	local args  = { ... }
	local state = loadState()

	if args[1] and args[1]:match("^https?://") then
		state.url = table.remove(args, 1):gsub("/+$", "")
	end

	if #args > 0 then state.program = args end

	if not state.url or type(state.program) ~= "table" or #state.program == 0 then
		usage()
		return false
	end

	if not http then
		warn("The http API is disabled on this server")
		return false
	end

	saveState(state)
	info("Server " .. state.url .. ", program: " .. table.concat(state.program, " "))

	while true do
		local changed, reason = sync(state)

		if changed == nil then
			warn("Sync failed: " .. tostring(reason) .. ", retrying")
			sleep(2)
		else
			if changed > 0 then info(changed .. " file(s) updated") end

			parallel.waitForAny(
				function() runProgram(state) end,
				function() watch(state) end
			)

			info("Files changed, restarting")
		end
	end
end

return main(...)
