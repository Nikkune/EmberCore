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

local __TS__Symbol, Symbol
do
    local symbolMetatable = {__tostring = function(self)
        return ("Symbol(" .. (self.description or "")) .. ")"
    end}
    function __TS__Symbol(description)
        return setmetatable({description = description}, symbolMetatable)
    end
    Symbol = {
        asyncDispose = __TS__Symbol("Symbol.asyncDispose"),
        dispose = __TS__Symbol("Symbol.dispose"),
        iterator = __TS__Symbol("Symbol.iterator"),
        hasInstance = __TS__Symbol("Symbol.hasInstance"),
        species = __TS__Symbol("Symbol.species"),
        toStringTag = __TS__Symbol("Symbol.toStringTag")
    }
end

local __TS__Iterator
do
    local function iteratorGeneratorStep(self)
        local co = self.____coroutine
        local status, value = coroutine.resume(co)
        if not status then
            error(value, 0)
        end
        if coroutine.status(co) == "dead" then
            return
        end
        return true, value
    end
    local function iteratorIteratorStep(self)
        local result = self:next()
        if result.done then
            return
        end
        return true, result.value
    end
    local function iteratorStringStep(self, index)
        index = index + 1
        if index > #self then
            return
        end
        return index, string.sub(self, index, index)
    end
    function __TS__Iterator(iterable)
        if type(iterable) == "string" then
            return iteratorStringStep, iterable, 0
        elseif iterable.____coroutine ~= nil then
            return iteratorGeneratorStep, iterable
        elseif iterable[Symbol.iterator] then
            local iterator = iterable[Symbol.iterator](iterable)
            return iteratorIteratorStep, iterator
        else
            return ipairs(iterable)
        end
    end
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
    return self.peripheralRef:size()
end
function Inventory.prototype.list(self)
    return self.peripheralRef:list()
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
    return self.peripheralRef:getItemDetail(slot)
end
function Inventory.prototype.isEmpty(self)
    local items = self:list()
    return (next(nil, items)) == nil
end
function Inventory.prototype.hasItem(self, itemName)
    return self:findFirstSlotByName(itemName) ~= nil
end
function Inventory.prototype.findFirstSlotByName(self, itemName)
    local items = self:list()
    for ____, ____value in __TS__Iterator(pairs(nil, items)) do
        local slot = ____value[1]
        local item = ____value[2]
        if item.name == itemName then
            return slot
        end
    end
    return nil
end
function Inventory.prototype.countItem(self, itemName)
    local total = 0
    local items = self:list()
    for ____, ____value in __TS__Iterator(pairs(nil, items)) do
        local item = ____value[2]
        if item.name == itemName then
            total = total + item.count
        end
    end
    return total
end
function Inventory.prototype.countAllItems(self)
    local total = 0
    local items = self:list()
    for ____, ____value in __TS__Iterator(pairs(nil, items)) do
        local item = ____value[2]
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
    return self.peripheralRef:pushItems(target.name, fromSlot, limit, toSlot)
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
    return self.peripheralRef:pullItems(source.name, fromSlot, limit, toSlot)
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
    while true do
        local slot = self:findFirstSlotByName(itemName)
        if slot == nil then
            break
        end
        local amount = self:pushTo(target, slot)
        if amount <= 0 then
            break
        end
        moved = moved + amount
    end
    return moved
end
function Inventory.prototype.getUsedSlots(self)
    local result = {}
    local items = self:list()
    for ____, ____value in __TS__Iterator(pairs(nil, items)) do
        local slot = ____value[1]
        result[#result + 1] = slot
    end
    return result
end
function Inventory.prototype.getFreeSlotCount(self)
    return self:size() - #self:getUsedSlots()
end
return ____exports
