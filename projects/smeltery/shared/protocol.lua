--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local ____inventory = require("core.inventory")
local ItemSummary = ____inventory.ItemSummary
local ____tank = require("core.tank")
local FluidStack = ____tank.FluidStack
local ____index = require("modules.fluids.index")
local ReservoirView = ____index.ReservoirView
local ____index = require("modules.tinkers.index")
local CasterKind = ____index.CasterKind
local CasterStatus = ____index.CasterStatus
____exports.PROTOCOL = "smeltery/v1"
____exports.CONTROLLER_HOSTNAME = "smeltery-controller"
____exports.MODES = {
    "idle",
    "auto",
    "manual",
    "lock",
    "drain",
    "purge",
    "alloy",
    "melt"
}
____exports.Messages = {
    state = "state",
    getState = "getState",
    setMode = "setMode",
    insert = "insert",
    cast = "cast",
    setAlloy = "setAlloy",
    setFormat = "setFormat"
}
return ____exports
