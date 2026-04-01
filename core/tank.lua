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
local ____helpers = require("utils.helpers")
local createOptions = ____helpers.createOptions
local ____errors = require("core.errors")
local TankError = ____errors.TankError
local ____peripheral = require("core.peripheral")
local Peripheral = ____peripheral.Peripheral
local function mapToFluidTank(self, raw)
    if not raw then
        return nil
    end
    return createOptions(nil, {}):with("name", raw.name):with("amount", raw.amount):with("capacity", raw.capacity):with("displayName", raw.displayName):done()
end
____exports.Tank = __TS__Class()
local Tank = ____exports.Tank
Tank.name = "Tank"
function Tank.prototype.____constructor(self, name, peripheralRef)
    self.name = name
    self.peripheralRef = peripheralRef
end
function Tank.fromName(self, name)
    local peripheral = Peripheral:require(name)
    return __TS__New(____exports.Tank, name, peripheral)
end
function Tank.prototype.list(self)
    local rawTanks = self.peripheralRef.tanks()
    local result = {}
    for ____, raw in ipairs(rawTanks) do
        result[#result + 1] = mapToFluidTank(nil, raw)
    end
    return result
end
function Tank.prototype.getTank(self, slot)
    local tanks = self:list()
    if slot < 1 or slot > #tanks then
        error(
            __TS__New(
                TankError,
                ((("Tank slot " .. tostring(slot)) .. " is out of bounds for '") .. self.name) .. "'",
                {tank = self.name, slot = slot, size = #tanks, action = "get_tank"}
            ),
            0
        )
    end
    return tanks[slot]
end
function Tank.prototype.isEmpty(self)
    for ____, tank in ipairs(self:list()) do
        if tank and (tank.amount or 0) > 0 then
            return false
        end
    end
    return true
end
function Tank.prototype.getTotalAmount(self)
    local total = 0
    for ____, tank in ipairs(self:list()) do
        if tank and tank.amount then
            total = total + tank.amount
        end
    end
    return total
end
function Tank.prototype.getAmount(self, fluidName)
    local total = 0
    for ____, tank in ipairs(self:list()) do
        if (tank and tank.name) == fluidName and tank.amount then
            total = total + tank.amount
        end
    end
    return total
end
function Tank.prototype.hasFluid(self, fluidName)
    return self:getAmount(fluidName) > 0
end
function Tank.prototype.getFluids(self)
    local result = {}
    for ____, tank in ipairs(self:list()) do
        if tank and tank.name and (tank.amount or 0) > 0 then
            result[#result + 1] = {name = tank.name, amount = tank.amount or 0}
        end
    end
    return result
end
function Tank.prototype.pushTo(self, target, limit, fluidName)
    if limit <= 0 then
        error(
            __TS__New(TankError, "Fluid push limit must be greater than 0", {
                tank = self.name,
                target = target.name,
                fluidName = fluidName,
                limit = limit,
                action = "push_to"
            }),
            0
        )
    end
    return self.peripheralRef.pushFluid(target.name, limit, fluidName)
end
function Tank.prototype.pullFrom(self, source, limit, fluidName)
    if limit <= 0 then
        error(
            __TS__New(TankError, "Fluid pull limit must be greater than 0", {
                tank = self.name,
                source = source.name,
                fluidName = fluidName,
                limit = limit,
                action = "pull_from"
            }),
            0
        )
    end
    return self.peripheralRef.pullFluid(source.name, limit, fluidName)
end
return ____exports
