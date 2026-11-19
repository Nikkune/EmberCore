--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__ArraySort(self, compareFn)
    if compareFn ~= nil then
        table.sort(
            self,
            function(a, b) return compareFn(nil, a, b) < 0 end
        )
    else
        table.sort(self)
    end
    return self
end

local function __TS__StringStartsWith(self, searchString, position)
    if position == nil or position < 0 then
        position = 0
    end
    return string.sub(self, position + 1, #searchString + position) == searchString
end

local function __TS__StringIncludes(self, searchString, position)
    if not position then
        position = 1
    else
        position = position + 1
    end
    local index = string.find(self, searchString, position, true)
    return index ~= nil
end

local function __TS__CountVarargs(...)
    return select("#", ...)
end

local function __TS__SparseArrayNew(...)
    local sparseArray = {...}
    sparseArray.sparseLength = __TS__CountVarargs(...)
    return sparseArray
end

local function __TS__SparseArrayPush(sparseArray, ...)
    local args = {...}
    local argsLen = __TS__CountVarargs(...)
    local listLen = sparseArray.sparseLength
    for i = 1, argsLen do
        sparseArray[listLen + i] = args[i]
    end
    sparseArray.sparseLength = listLen + argsLen
end

local function __TS__SparseArraySpread(sparseArray)
    local _unpack = unpack or table.unpack
    return _unpack(sparseArray, 1, sparseArray.sparseLength)
end
-- End of Lua Library inline imports
local ____exports = {}
local ____peripheral = require("core.peripheral")
local Peripheral = ____peripheral.Peripheral
local ____config = require("projects.smeltery.controller.config")
local ControllerConfig = ____config.ControllerConfig
local function namesOfType(____type)
    local names = {}
    for ____, name in ipairs(peripheral.getNames()) do
        if Peripheral:hasType(name, ____type) then
            names[#names + 1] = name
        end
    end
    __TS__ArraySort(names)
    return names
end
local function pick(configured, ____type, label, problems)
    if configured ~= "" then
        if peripheral.isPresent(configured) then
            return configured
        end
        problems[#problems + 1] = ((label .. " '") .. configured) .. "' not found on the network"
        return nil
    end
    local first = unpack(
        namesOfType(____type),
        1,
        1
    )
    if first == nil then
        problems[#problems + 1] = ("no " .. label) .. " found on the network"
    end
    return first
end
local function pickInventory(configured, label, problems)
    if configured == "" then
        problems[#problems + 1] = label .. " inventory not set in the controller config"
        return nil
    end
    if not peripheral.isPresent(configured) then
        problems[#problems + 1] = ((label .. " inventory '") .. configured) .. "' not found on the network"
        return nil
    end
    return configured
end
local function findFuelTank()
    for ____, name in ipairs(namesOfType("fluid_storage")) do
        do
            local __continue14
            repeat
                if not __TS__StringStartsWith(name, "tconstruct:") then
                    __continue14 = true
                    break
                end
                if __TS__StringIncludes(name, "drain") or __TS__StringIncludes(name, "table") or __TS__StringIncludes(name, "basin") then
                    __continue14 = true
                    break
                end
                if __TS__StringIncludes(name, "tank") or __TS__StringIncludes(name, "gauge") then
                    return name
                end
                __continue14 = true
            until true
            if not __continue14 then
                break
            end
        end
    end
    return nil
end
function ____exports.discoverNetwork(config)
    local problems = {}
    local network = {casters = {}, reservoirs = {}, problems = problems}
    local drain = pick(config.drain, "tconstruct:drain", "Smeltery drain", problems)
    local chute = pick(config.chute, "tconstruct:chute", "Smeltery chute", problems)
    local input = pickInventory(config.input, "input", problems)
    local output = pickInventory(config.output, "output", problems)
    if drain ~= nil then
        network.drain = drain
    end
    if chute ~= nil then
        network.chute = chute
    end
    if input ~= nil then
        network.input = input
    end
    if output ~= nil then
        network.output = output
    end
    if config.heatOutput ~= "" then
        local heat = pickInventory(config.heatOutput, "heat output", problems)
        if heat ~= nil then
            network.heatOutput = heat
        end
    end
    if config.unknownOutput ~= "" then
        local unknown = pickInventory(config.unknownOutput, "unknown output", problems)
        if unknown ~= nil then
            network.unknownOutput = unknown
        end
    end
    if #config.casters > 0 then
        for ____, name in ipairs(config.casters) do
            if peripheral.isPresent(name) then
                local ____network_casters_0 = network.casters
                ____network_casters_0[#____network_casters_0 + 1] = name
            else
                problems[#problems + 1] = ("caster '" .. name) .. "' not found on the network"
            end
        end
    else
        local ____array_2 = __TS__SparseArrayNew(unpack(namesOfType("tconstruct:table")))
        __TS__SparseArrayPush(
            ____array_2,
            unpack(namesOfType("tconstruct:basin"))
        )
        for ____, name in ipairs({__TS__SparseArraySpread(____array_2)}) do
            local ____network_casters_1 = network.casters
            ____network_casters_1[#____network_casters_1 + 1] = name
        end
    end
    if #network.casters == 0 then
        problems[#problems + 1] = "no casting table nor basin found on the network"
    end
    local ____temp_3
    if config.fuelTank ~= "" then
        ____temp_3 = peripheral.isPresent(config.fuelTank) and config.fuelTank or nil
    else
        ____temp_3 = findFuelTank()
    end
    local fuelTank = ____temp_3
    if config.fuelTank ~= "" and fuelTank == nil then
        problems[#problems + 1] = ("fuel tank '" .. config.fuelTank) .. "' not found on the network"
    end
    if fuelTank ~= nil then
        network.fuelTank = fuelTank
    end
    if #config.reservoirs > 0 then
        for ____, name in ipairs(config.reservoirs) do
            if peripheral.isPresent(name) then
                local ____network_reservoirs_4 = network.reservoirs
                ____network_reservoirs_4[#____network_reservoirs_4 + 1] = name
            else
                problems[#problems + 1] = ("reservoir '" .. name) .. "' not found on the network"
            end
        end
    else
        for ____, name in ipairs(namesOfType("fluid_storage")) do
            do
                local __continue45
                repeat
                    if __TS__StringStartsWith(name, "tconstruct:") or name == fuelTank then
                        __continue45 = true
                        break
                    end
                    local ____network_reservoirs_5 = network.reservoirs
                    ____network_reservoirs_5[#____network_reservoirs_5 + 1] = name
                    __continue45 = true
                until true
                if not __continue45 then
                    break
                end
            end
        end
    end
    return network
end
return ____exports
