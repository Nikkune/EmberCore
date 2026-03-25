--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__New(target, ...)
    local instance = setmetatable({}, target.prototype)
    instance:____constructor(...)
    return instance
end

local function __TS__Class(self)
    local c = {prototype = {}}
    c.prototype.__index = c.prototype
    c.prototype.constructor = c
    return c
end
-- End of Lua Library inline imports
local ____exports = {}
local ____logger = require("core.logger")
local Logger = ____logger.Logger
local ____errors = require("core.errors")
local RuntimeError = ____errors.RuntimeError
local ____result = require("core.result")
local Results = ____result.Results
local log = __TS__New(Logger, "Parallel", "info")
____exports.Parallel = __TS__Class()
local Parallel = ____exports.Parallel
Parallel.name = "Parallel"
function Parallel.prototype.____constructor(self)
end
function Parallel.all(self, ...)
    local tasks = {...}
    if #tasks == 0 then
        error(
            __TS__New(RuntimeError, "Parallel.all requires at least one task", {action = "parallel_all"}),
            0
        )
    end
    log:debug("Running parallel all", {action = "parallel_all", taskCount = #tasks, status = "start"})
    parallel.waitForAll(table.unpack(tasks))
    log:debug("Parallel all completed", {action = "parallel_all", taskCount = #tasks, status = "done"})
end
function Parallel.any(self, ...)
    local tasks = {...}
    if #tasks == 0 then
        error(
            __TS__New(RuntimeError, "Parallel.any requires at least one task", {action = "parallel_any"}),
            0
        )
    end
    log:debug("Running parallel any", {action = "parallel_any", taskCount = #tasks, status = "start"})
    local completedIndex = parallel.waitForAny(table.unpack(tasks))
    log:debug("Parallel any completed", {action = "parallel_any", taskCount = #tasks, completedIndex = completedIndex, status = "done"})
    return completedIndex
end
function Parallel.race(self, ...)
    return self:any(...)
end
function Parallel.tryAll(self, ...)
    local tasks = {...}
    return Results:try(function()
        self:all(table.unpack(tasks))
    end)
end
function Parallel.tryAny(self, ...)
    local tasks = {...}
    return Results:try(function() return self:any(table.unpack(tasks)) end)
end
function Parallel.withHeartbeat(self, task, heartbeat)
    self:all(task, heartbeat)
end
function Parallel.daemon(self, task)
    self:any(
        task,
        function()
            while true do
                sleep(999999)
            end
        end
    )
    error(
        __TS__New(RuntimeError, "Parallel.daemon unexpectedly returned", {action = "parallel_daemon"}),
        0
    )
end
function Parallel.service(self, mainTask, ...)
    self:all(mainTask, ...)
end
return ____exports
