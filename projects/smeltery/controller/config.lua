--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local ____config = require("core.config")
local Config = ____config.Config
local ____protocol = require("projects.smeltery.shared.protocol")
local MODES = ____protocol.MODES
local ____protocol = require("projects.smeltery.shared.protocol")
local AlloyView = ____protocol.AlloyView
local Mode = ____protocol.Mode
____exports.CONFIG_PATH = "/smeltery/controller.db"
____exports.MODE_PATH = "/smeltery/mode.db"
____exports.RESERVOIRS_PATH = "/smeltery/reservoirs.db"
function ____exports.defaultControllerConfig()
    return {
        input = "",
        output = "",
        heatOutput = "",
        unknownOutput = "",
        drain = "",
        chute = "",
        casters = {},
        craftCasters = {},
        fluidTrash = "",
        fuelTank = "",
        fuel = "minecraft:lava",
        reservoirs = {},
        assignments = {},
        capacities = {},
        smelteryCapacity = 0,
        smelteryCapacitySource = "",
        formatPriority = {"block", "ingot", "nugget"},
        idleSeconds = 30,
        tickSeconds = 1,
        activeTickSeconds = 0.25,
        heartbeatSeconds = 5,
        logSize = 100
    }
end
local OLD_LOG_SIZE = 20
function ____exports.loadControllerConfig(path)
    if path == nil then
        path = ____exports.CONFIG_PATH
    end
    local config = Config:load(
        path,
        ____exports.defaultControllerConfig()
    )
    if config.logSize == OLD_LOG_SIZE then
        config.logSize = ____exports.defaultControllerConfig().logSize
    end
    return config
end
function ____exports.saveControllerConfig(config, path)
    if path == nil then
        path = ____exports.CONFIG_PATH
    end
    Config:save(path, config)
end
local function toMode(value, fallback)
    for ____, mode in ipairs(MODES) do
        if mode == value then
            return mode
        end
    end
    return fallback
end
function ____exports.loadMode(path)
    if path == nil then
        path = ____exports.MODE_PATH
    end
    local saved = Config:load(path, {mode = "idle", previous = "idle"})
    return {
        mode = toMode(saved.mode, "idle"),
        previous = toMode(saved.previous, "idle")
    }
end
function ____exports.saveMode(mode, previous, path)
    if path == nil then
        path = ____exports.MODE_PATH
    end
    Config:save(path, {mode = mode, previous = previous})
end
____exports.ALLOY_PATH = "/smeltery/alloy.db"
function ____exports.loadAlloy(path)
    if path == nil then
        path = ____exports.ALLOY_PATH
    end
    local saved = Config:load(path, {result = "", target = 0, made = 0})
    if saved.result == "" then
        return nil
    end
    local alloy = {result = saved.result, made = saved.made}
    if saved.target > 0 then
        alloy.target = saved.target
    end
    return alloy
end
function ____exports.saveAlloy(alloy, path)
    if path == nil then
        path = ____exports.ALLOY_PATH
    end
    Config:save(path, {result = alloy.result, target = alloy.target or 0, made = alloy.made})
end
function ____exports.clearAlloy(path)
    if path == nil then
        path = ____exports.ALLOY_PATH
    end
    Config:save(path, {result = "", target = 0, made = 0})
end
function ____exports.loadCapacities(path)
    if path == nil then
        path = ____exports.RESERVOIRS_PATH
    end
    local result = {}
    for ____, entry in ipairs(Config:load(path, {capacities = {}}).capacities) do
        result[entry.reservoir] = entry.capacity
    end
    return result
end
function ____exports.saveCapacities(capacities, path)
    if path == nil then
        path = ____exports.RESERVOIRS_PATH
    end
    local entries = {}
    for reservoir in pairs(capacities) do
        entries[#entries + 1] = {reservoir = reservoir, capacity = capacities[reservoir]}
    end
    Config:save(path, {capacities = entries})
end
return ____exports
