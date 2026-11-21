--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local ____inventory = require("core.inventory")
local ItemSummary = ____inventory.ItemSummary
local ____tank = require("core.tank")
local FluidStack = ____tank.FluidStack
local ____index = require("modules.fluids.index")
local ReservoirView = ____index.ReservoirView
local ____index = require("modules.tinkers.index")
local AlloyRatio = ____index.AlloyRatio
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
    queueOrder = "queueOrder",
    cancelOrder = "cancelOrder",
    insertReady = "insertReady",
    queueCraft = "queueCraft",
    trashFluid = "trashFluid",
    setAlloy = "setAlloy",
    setFormat = "setFormat",
    setReservoir = "setReservoir",
    saveRecipe = "saveRecipe",
    deleteRecipe = "deleteRecipe",
    getFluids = "getFluids",
    setSmelteryCapacity = "setSmelteryCapacity"
}
____exports.HISTORY_SECONDS = 30
____exports.HISTORY_SIZE = 20
____exports.MAX_INGREDIENTS = 4
return ____exports
