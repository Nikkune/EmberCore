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
local ____errors = require("core.errors")
local InventoryError = ____errors.InventoryError
local ____peripheral = require("core.peripheral")
local Peripheral = ____peripheral.Peripheral
____exports.Inventory = __TS__Class()
local Inventory = ____exports.Inventory
Inventory.name = "Inventory"
function Inventory.prototype.____constructor(self, name, peripheralRef)
    self.name = name
    self.peripheralRef = peripheralRef
end
function Inventory.fromName(self, name)
    local peripheral = Peripheral:require(name)
    return __TS__New(____exports.Inventory, name, peripheral)
end
function Inventory.prototype.size(self)
    return self.peripheralRef.size()
end
function Inventory.prototype.list(self)
    return self.peripheralRef.list()
end
function Inventory.prototype.getItem(self, slot)
    if slot < 1 or slot > self:size() then
        error(
            __TS__New(
                InventoryError,
                ((("Slot " .. tostring(slot)) .. " is out of bounds for inventory '") .. self.name) .. "'",
                {
                    inventory = self.name,
                    slot = slot,
                    size = self:size(),
                    action = "get_item"
                }
            ),
            0
        )
    end
    return self.peripheralRef.getItemDetail(slot)
end
function Inventory.prototype.isEmpty(self)
    local items = self:list()
    return (next(items)) == nil
end
function Inventory.prototype.hasItem(self, itemName)
    return self:findFirstSlotByName(itemName) ~= nil
end
function Inventory.prototype.findFirstSlotByName(self, itemName)
    local items = self:list()
    for slot, item in pairs(items) do
        if item.name == itemName then
            return slot
        end
    end
    return nil
end
function Inventory.prototype.countItem(self, itemName)
    local total = 0
    local items = self:list()
    for ____, item in pairs(items) do
        if item.name == itemName then
            total = total + item.count
        end
    end
    return total
end
function Inventory.prototype.countAllItems(self)
    local total = 0
    local items = self:list()
    for ____, item in pairs(items) do
        total = total + item.count
    end
    return total
end
function Inventory.prototype.pushTo(self, target, fromSlot, limit, toSlot)
    if fromSlot < 1 or fromSlot > self:size() then
        error(
            __TS__New(
                InventoryError,
                "Cannot push from invalid slot " .. tostring(fromSlot),
                {inventory = self.name, target = target.name, fromSlot = fromSlot, action = "push_to"}
            ),
            0
        )
    end
    return self.peripheralRef.pushItems(target.name, fromSlot, limit, toSlot)
end
function Inventory.prototype.pullFrom(self, source, fromSlot, limit, toSlot)
    if fromSlot < 1 or fromSlot > source:size() then
        error(
            __TS__New(
                InventoryError,
                "Cannot pull from invalid slot " .. tostring(fromSlot),
                {inventory = self.name, source = source.name, fromSlot = fromSlot, action = "pull_from"}
            ),
            0
        )
    end
    return self.peripheralRef.pullItems(source.name, fromSlot, limit, toSlot)
end
function Inventory.prototype.moveFirstItemByName(self, target, itemName, limit)
    local slot = self:findFirstSlotByName(itemName)
    if slot == nil then
        return 0
    end
    return self:pushTo(target, slot, limit)
end
function Inventory.prototype.moveAllOfItem(self, target, itemName)
    local moved = 0
    for slot, item in pairs(self:list()) do
        do
            local __continue25
            repeat
                if item.name ~= itemName then
                    __continue25 = true
                    break
                end
                local amount = self.peripheralRef.pushItems(target.name, slot)
                moved = moved + amount
                if amount < item.count then
                    break
                end
                __continue25 = true
            until true
            if not __continue25 then
                break
            end
        end
    end
    return moved
end
function Inventory.prototype.getUsedSlots(self)
    local result = {}
    local items = self:list()
    for slot in pairs(items) do
        result[#result + 1] = slot
    end
    return result
end
function Inventory.prototype.getFreeSlotCount(self)
    return self:size() - #self:getUsedSlots()
end
return ____exports
