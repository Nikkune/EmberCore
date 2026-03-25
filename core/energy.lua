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
local ____peripheral = require("core.peripheral")
local Peripheral = ____peripheral.Peripheral
____exports.Energy = __TS__Class()
local Energy = ____exports.Energy
Energy.name = "Energy"
function Energy.prototype.____constructor(self, name, peripheralRef)
    self.name = name
    self.peripheralRef = peripheralRef
end
function Energy.fromName(self, name)
    local peripheral = Peripheral:require(name)
    return __TS__New(____exports.Energy, name, peripheral)
end
function Energy.prototype.getStored(self)
    return self.peripheralRef.getEnergy()
end
function Energy.prototype.getCapacity(self)
    return self.peripheralRef.getEnergyCapacity()
end
function Energy.prototype.getFreeSpace(self)
    return self:getCapacity() - self:getStored()
end
function Energy.prototype.getPercent(self)
    local capacity = self:getCapacity()
    if capacity <= 0 then
        return 0
    end
    return self:getStored() / capacity * 100
end
function Energy.prototype.isEmpty(self)
    return self:getStored() <= 0
end
function Energy.prototype.isFull(self)
    return self:getStored() >= self:getCapacity()
end
return ____exports
