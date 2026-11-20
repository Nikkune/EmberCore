package.path = "/?.lua;/?/init.lua;" .. package.path
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local __TS__StringSplit
do
    local sub = string.sub
    local find = string.find
    function __TS__StringSplit(source, separator, limit)
        if limit == nil then
            limit = 4294967295
        end
        if limit == 0 then
            return {}
        end
        local result = {}
        local resultIndex = 1
        if separator == nil or separator == "" then
            for i = 1, #source do
                result[resultIndex] = sub(source, i, i)
                resultIndex = resultIndex + 1
            end
        else
            local currentPos = 1
            while resultIndex <= limit do
                local startPos, endPos = find(source, separator, currentPos, true)
                if not startPos then
                    break
                end
                result[resultIndex] = sub(source, currentPos, startPos - 1)
                resultIndex = resultIndex + 1
                currentPos = endPos + 1
            end
            if resultIndex <= limit then
                result[resultIndex] = sub(source, currentPos)
            end
        end
        return result
    end
end

local function __TS__ArrayFilter(self, callbackfn, thisArg)
    local result = {}
    local len = 0
    for i = 1, #self do
        if callbackfn(thisArg, self[i], i - 1, self) then
            len = len + 1
            result[len] = self[i]
        end
    end
    return result
end
-- End of Lua Library inline imports
local ____exports = {}
local ____config = require("core.config")
local Config = ____config.Config
local ____peripheral = require("core.peripheral")
local Peripheral = ____peripheral.Peripheral
local ROLE_PATH = "/smeltery/role.db"
local ROLE_MODULES = {controller = "projects.smeltery.controller.controller", display = "projects.smeltery.display.display"}
local function isRole(value)
    return value == "controller" or value == "display"
end
local function isInstalled(role)
    return fs.exists(("/" .. table.concat(
        __TS__StringSplit(ROLE_MODULES[role], "."),
        "/"
    )) .. ".lua")
end
local function detectRole()
    for ____, name in ipairs(peripheral.getNames()) do
        if Peripheral:hasType(name, "tconstruct:drain") then
            return "controller"
        end
    end
    return Peripheral:findNameByType("monitor") ~= nil and "display" or nil
end
local function resolveRole(argument)
    local saved = Config:load(ROLE_PATH, {role = ""})
    local installed = __TS__ArrayFilter(
        {"controller", "display"},
        function(____, role) return isInstalled(role) end
    )
    local ____temp_0
    if #installed == 1 then
        ____temp_0 = installed[1]
    else
        ____temp_0 = nil
    end
    local only = ____temp_0
    local role = isRole(argument) and argument or (isRole(saved.role) and saved.role or (only or detectRole()))
    if role ~= nil and role ~= saved.role then
        Config:save(ROLE_PATH, {role = role})
    end
    return role
end
local argument = ...
if argument ~= nil and not isRole(argument) then
    print("Usage: main [controller|display]")
else
    local role = resolveRole(argument)
    if role == nil then
        print("No Smeltery drain nor monitor found: start with \"main controller\" or \"main display\".")
    elseif not isInstalled(role) then
        print((("The " .. role) .. " is not installed on this computer: embercore install smeltery-") .. role)
    elseif role == "controller" then
        require(ROLE_MODULES.controller).runController()
    else
        require(ROLE_MODULES.display).runDisplay()
    end
end
return ____exports
