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

local function __TS__StringAccess(self, index)
    if index >= 0 and index < #self then
        return string.sub(self, index + 1, index + 1)
    end
end
-- End of Lua Library inline imports
local ____exports = {}
local ____ui = require("modules.ui.index")
local makeColors = ____ui.makeColors
local ____types = require("modules.ui.types.index")
local Color = ____types.Color
local Point = ____types.Point
local Rect = ____types.Rect
local Size = ____types.Size
local function ____repeat(self, value, count)
    local result = ""
    do
        local index = 0
        while index < count do
            result = result .. value
            index = index + 1
        end
    end
    return result
end
____exports.ComputerCraftSurfaceAdapter = __TS__Class()
local ComputerCraftSurfaceAdapter = ____exports.ComputerCraftSurfaceAdapter
ComputerCraftSurfaceAdapter.name = "ComputerCraftSurfaceAdapter"
function ComputerCraftSurfaceAdapter.prototype.____constructor(self, target)
    self.target = target
end
function ComputerCraftSurfaceAdapter.fromTerminal(self, target)
    if target then
        return __TS__New(____exports.ComputerCraftSurfaceAdapter, target)
    end
    local current = term.current()
    local wrappedTarget = {
        getSize = function() return current.getSize() end,
        clear = function() return current.clear() end,
        clearLine = function() return current.clearLine() end,
        setCursorPos = function(____, x, y) return current.setCursorPos(x, y) end,
        getCursorPos = function() return current.getCursorPos() end,
        write = function(____, text) return current.write(text) end,
        setTextColor = function(____, color) return current.setTextColor(color) end,
        getTextColor = function() return current.getTextColor() end,
        setBackgroundColor = function(____, color) return current.setBackgroundColor(color) end,
        getBackgroundColor = function() return current.getBackgroundColor() end,
        isColor = function() return current.isColor() end
    }
    return __TS__New(____exports.ComputerCraftSurfaceAdapter, wrappedTarget)
end
function ComputerCraftSurfaceAdapter.fromMonitor(self, target)
    return __TS__New(____exports.ComputerCraftSurfaceAdapter, target)
end
function ComputerCraftSurfaceAdapter.prototype.getSize(self)
    local width, height = table.unpack(
        self.target:getSize(),
        1,
        2
    )
    return {width = width, height = height}
end
function ComputerCraftSurfaceAdapter.prototype.getWidth(self)
    return self:getSize().width
end
function ComputerCraftSurfaceAdapter.prototype.getHeight(self)
    return self:getSize().height
end
function ComputerCraftSurfaceAdapter.prototype.clear(self, backgroundColor)
    if backgroundColor == nil then
        self.target:clear()
        return
    end
    self:withColors(
        {backgroundColor = backgroundColor},
        function()
            self.target:clear()
        end
    )
end
function ComputerCraftSurfaceAdapter.prototype.clearLine(self, y, backgroundColor)
    if y < 1 or y > self:getHeight() then
        return
    end
    local currentCursor = self:getCursor()
    self:withColors(
        makeColors(nil, {backgroundColor = backgroundColor}),
        function()
            self.target:setCursorPos(1, y)
            self.target:clearLine()
        end
    )
    self:setCursor(currentCursor)
end
function ComputerCraftSurfaceAdapter.prototype.setCursor(self, position)
    self.target:setCursorPos(position.x, position.y)
end
function ComputerCraftSurfaceAdapter.prototype.getCursor(self)
    local x, y = table.unpack(
        self.target:getCursorPos(),
        1,
        2
    )
    return {x = x, y = y}
end
function ComputerCraftSurfaceAdapter.prototype.write(self, text)
    self.target:write(text)
end
function ComputerCraftSurfaceAdapter.prototype.writeAt(self, position, text)
    self:withCursor(
        position,
        function()
            self.target:write(text)
        end
    )
end
function ComputerCraftSurfaceAdapter.prototype.blitAt(self, position, text, textColors, backgroundColors)
    local target = self.target
    self:withCursor(
        position,
        function()
            local blit = target.blit
            if type(blit) == "function" then
                blit(target, text, textColors, backgroundColors)
                return
            end
            self.target:write(text)
        end
    )
end
function ComputerCraftSurfaceAdapter.prototype.fillRect(self, rect, character, backgroundColor, foregroundColor)
    if character == nil then
        character = " "
    end
    if rect.width <= 0 or rect.height <= 0 then
        return
    end
    local fillCharacter = #character > 0 and __TS__StringAccess(character, 0) or " "
    local line = ____repeat(nil, fillCharacter, rect.width)
    self:withColors(
        makeColors(nil, {backgroundColor = backgroundColor, foregroundColor = foregroundColor}),
        function()
            do
                local row = 0
                while row < rect.height do
                    self:writeAt({x = rect.x, y = rect.y + row}, line)
                    row = row + 1
                end
            end
        end
    )
end
function ComputerCraftSurfaceAdapter.prototype.strokeRect(self, rect, character, backgroundColor, foregroundColor)
    if character == nil then
        character = "#"
    end
    if rect.width <= 0 or rect.height <= 0 then
        return
    end
    if rect.width == 1 and rect.height == 1 then
        self:withColors(
            makeColors(nil, {backgroundColor = backgroundColor, foregroundColor = foregroundColor}),
            function()
                self:writeAt(
                    {x = rect.x, y = rect.y},
                    __TS__StringAccess(character, 0) or "#"
                )
            end
        )
        return
    end
    local strokeCharacter = #character > 0 and __TS__StringAccess(character, 0) or "#"
    self:withColors(
        makeColors(nil, {backgroundColor = backgroundColor, foregroundColor = foregroundColor}),
        function()
            local horizontal = ____repeat(nil, strokeCharacter, rect.width)
            self:writeAt({x = rect.x, y = rect.y}, horizontal)
            if rect.height > 1 then
                self:writeAt({x = rect.x, y = rect.y + rect.height - 1}, horizontal)
            end
            do
                local row = 1
                while row < rect.height - 1 do
                    self:writeAt({x = rect.x, y = rect.y + row}, strokeCharacter)
                    if rect.width > 1 then
                        self:writeAt({x = rect.x + rect.width - 1, y = rect.y + row}, strokeCharacter)
                    end
                    row = row + 1
                end
            end
        end
    )
end
function ComputerCraftSurfaceAdapter.prototype.setForegroundColor(self, color)
    self.target:setTextColor(color)
end
function ComputerCraftSurfaceAdapter.prototype.getForegroundColor(self)
    return self.target:getTextColor()
end
function ComputerCraftSurfaceAdapter.prototype.setBackgroundColor(self, color)
    self.target:setBackgroundColor(color)
end
function ComputerCraftSurfaceAdapter.prototype.getBackgroundColor(self)
    return self.target:getBackgroundColor()
end
function ComputerCraftSurfaceAdapter.prototype.withColors(self, options, fn)
    local previousForeground = self:getForegroundColor()
    local previousBackground = self:getBackgroundColor()
    if options.foregroundColor ~= nil then
        self:setForegroundColor(options.foregroundColor)
    end
    if options.backgroundColor ~= nil then
        self:setBackgroundColor(options.backgroundColor)
    end
    do
        pcall(function()
            fn(nil)
        end)
        do
            self:setForegroundColor(previousForeground)
            self:setBackgroundColor(previousBackground)
        end
    end
end
function ComputerCraftSurfaceAdapter.prototype.isColorSupported(self)
    return self.target:isColor()
end
function ComputerCraftSurfaceAdapter.prototype.withCursor(self, position, fn)
    local previousCursor = self:getCursor()
    do
        pcall(function()
            self:setCursor(position)
            fn(nil)
        end)
        do
            self:setCursor(previousCursor)
        end
    end
end
return ____exports
