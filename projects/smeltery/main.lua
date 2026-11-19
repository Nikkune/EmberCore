package.path = "/?.lua;/?/init.lua;" .. package.path
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local ____config = require("core.config")
local Config = ____config.Config
local ____peripheral = require("core.peripheral")
local Peripheral = ____peripheral.Peripheral
local ____controller = require("projects.smeltery.controller.controller")
local runController = ____controller.runController
local ____display = require("projects.smeltery.display.display")
local runDisplay = ____display.runDisplay
local ROLE_PATH = "/smeltery/role.db"
local function isRole(value)
    return value == "controller" or value == "display"
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
    local role = isRole(argument) and argument or (isRole(saved.role) and saved.role or detectRole())
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
    if role == "controller" then
        runController()
    elseif role == "display" then
        runDisplay()
    else
        print("No Smeltery drain nor monitor found: start with \"main controller\" or \"main display\".")
    end
end
return ____exports
