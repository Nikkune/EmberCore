--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__Class(self)
    local c = {prototype = {}}
    c.prototype.__index = c.prototype
    c.prototype.constructor = c
    return c
end

local function __TS__New(target, ...)
    local instance = setmetatable({}, target.prototype)
    instance:____constructor(...)
    return instance
end
-- End of Lua Library inline imports
local ____exports = {}
local ____inventory = require("core.inventory")
local Inventory = ____inventory.Inventory
local ____inventory = require("core.inventory")
local ItemSummary = ____inventory.ItemSummary
local ____tank = require("core.tank")
local Tank = ____tank.Tank
local ____tank = require("core.tank")
local FluidStack = ____tank.FluidStack
____exports.Smeltery = __TS__Class()
local Smeltery = ____exports.Smeltery
Smeltery.name = "Smeltery"
function Smeltery.prototype.____constructor(self, drain, chute)
    self.drain = drain
    self.chute = chute
end
function Smeltery.fromNames(self, drainName, chuteName)
    return __TS__New(
        ____exports.Smeltery,
        Tank:fromName(drainName),
        Inventory:fromName(chuteName)
    )
end
function Smeltery.prototype.fluids(self)
    return self.drain:getFluids()
end
function Smeltery.prototype.amountOf(self, fluidName)
    return self.drain:getAmount(fluidName)
end
function Smeltery.prototype.melting(self)
    local result = {}
    for ____, item in pairs(self.chute:list()) do
        result[#result + 1] = {name = item.name, count = item.count}
    end
    return result
end
function Smeltery.prototype.insert(self, source, slot, limit)
    return source:pushTo(self.chute, slot, limit)
end
function Smeltery.prototype.pour(self, target, fluidName, amount)
    return self.drain:pushTo(target, amount, fluidName)
end
return ____exports
