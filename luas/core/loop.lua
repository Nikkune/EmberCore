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
local log = __TS__New(Logger, "Loop", "info")
____exports.Loop = __TS__Class()
local Loop = ____exports.Loop
Loop.name = "Loop"
function Loop.prototype.____constructor(self)
end
function Loop.sleep(self, seconds)
    if seconds < 0 then
        error(
            __TS__New(RuntimeError, "Sleep duration cannot be negative", {seconds = seconds, action = "sleep"}),
            0
        )
    end
    sleep(seconds)
end
function Loop.forever(self, task, intervalSeconds)
    if intervalSeconds == nil then
        intervalSeconds = 0
    end
    while true do
        task(nil)
        if intervalSeconds > 0 then
            self:sleep(intervalSeconds)
        end
    end
end
function Loop.every(self, intervalSeconds, task)
    if intervalSeconds < 0 then
        error(
            __TS__New(RuntimeError, "Loop interval cannot be negative", {intervalSeconds = intervalSeconds, action = "every"}),
            0
        )
    end
    while true do
        task(nil)
        self:sleep(intervalSeconds)
    end
end
Loop["until"] = function(self, condition, task, intervalSeconds)
    if intervalSeconds == nil then
        intervalSeconds = 0
    end
    if intervalSeconds < 0 then
        error(
            __TS__New(RuntimeError, "Loop interval cannot be negative", {intervalSeconds = intervalSeconds, action = "until"}),
            0
        )
    end
    while not condition(nil) do
        task(nil)
        if intervalSeconds > 0 then
            self:sleep(intervalSeconds)
        end
    end
end
function Loop.retry(self, task, options)
    local attempts = options.attempts
    local delaySeconds = options.delaySeconds or 0
    local label = options.label or "retry_task"
    if attempts <= 0 then
        return Results:err(__TS__New(RuntimeError, "Retry attempts must be greater than 0", {attempts = attempts, action = "retry", label = label}))
    end
    local lastError
    do
        local attempt = 1
        while attempt <= attempts do
            local result = task(nil)
            if result.ok then
                if attempt > 1 then
                    log:info("Retry succeeded", {action = "retry", label = label, attempt = attempt, status = "ok"})
                end
                return result
            end
            lastError = result.error
            log:warn("Retry attempt failed", {
                action = "retry",
                label = label,
                attempt = attempt,
                attempts = attempts,
                code = result.error.code,
                status = "failed"
            })
            if attempt < attempts and delaySeconds > 0 then
                self:sleep(delaySeconds)
            end
            attempt = attempt + 1
        end
    end
    return Results:err(lastError or __TS__New(RuntimeError, "All retry attempts failed", {action = "retry", label = label, attempts = attempts, status = "failed"}))
end
return ____exports
