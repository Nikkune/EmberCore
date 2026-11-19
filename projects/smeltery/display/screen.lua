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

local function __TS__ArrayForEach(self, callbackFn, thisArg)
    for i = 1, #self do
        callbackFn(thisArg, self[i], i - 1, self)
    end
end

local function __TS__ArrayIndexOf(self, searchElement, fromIndex)
    if fromIndex == nil then
        fromIndex = 0
    end
    local len = #self
    if len == 0 then
        return -1
    end
    if fromIndex >= len then
        return -1
    end
    if fromIndex < 0 then
        fromIndex = len + fromIndex
        if fromIndex < 0 then
            fromIndex = 0
        end
    end
    for i = fromIndex + 1, len do
        if self[i] == searchElement then
            return i - 1
        end
    end
    return -1
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

local Map
do
    Map = __TS__Class()
    Map.name = "Map"
    function Map.prototype.____constructor(self, entries)
        self[Symbol.toStringTag] = "Map"
        self.items = {}
        self.size = 0
        self.nextKey = {}
        self.previousKey = {}
        if entries == nil then
            return
        end
        local iterable = entries
        if iterable[Symbol.iterator] then
            local iterator = iterable[Symbol.iterator](iterable)
            while true do
                local result = iterator:next()
                if result.done then
                    break
                end
                local value = result.value
                self:set(value[1], value[2])
            end
        else
            local array = entries
            for ____, kvp in ipairs(array) do
                self:set(kvp[1], kvp[2])
            end
        end
    end
    function Map.prototype.clear(self)
        self.items = {}
        self.nextKey = {}
        self.previousKey = {}
        self.firstKey = nil
        self.lastKey = nil
        self.size = 0
    end
    function Map.prototype.delete(self, key)
        local contains = self:has(key)
        if contains then
            self.size = self.size - 1
            local next = self.nextKey[key]
            local previous = self.previousKey[key]
            if next ~= nil and previous ~= nil then
                self.nextKey[previous] = next
                self.previousKey[next] = previous
            elseif next ~= nil then
                self.firstKey = next
                self.previousKey[next] = nil
            elseif previous ~= nil then
                self.lastKey = previous
                self.nextKey[previous] = nil
            else
                self.firstKey = nil
                self.lastKey = nil
            end
            self.nextKey[key] = nil
            self.previousKey[key] = nil
        end
        self.items[key] = nil
        return contains
    end
    function Map.prototype.forEach(self, callback)
        for ____, key in __TS__Iterator(self:keys()) do
            callback(nil, self.items[key], key, self)
        end
    end
    function Map.prototype.get(self, key)
        return self.items[key]
    end
    function Map.prototype.has(self, key)
        return self.nextKey[key] ~= nil or self.lastKey == key
    end
    function Map.prototype.set(self, key, value)
        local isNewValue = not self:has(key)
        if isNewValue then
            self.size = self.size + 1
        end
        self.items[key] = value
        if self.firstKey == nil then
            self.firstKey = key
            self.lastKey = key
        elseif isNewValue then
            self.nextKey[self.lastKey] = key
            self.previousKey[key] = self.lastKey
            self.lastKey = key
        end
        return self
    end
    Map.prototype[Symbol.iterator] = function(self)
        return self:entries()
    end
    function Map.prototype.entries(self)
        local items = self.items
        local nextKey = self.nextKey
        local key = self.firstKey
        return {
            [Symbol.iterator] = function(self)
                return self
            end,
            next = function(self)
                local result = {done = not key, value = {key, items[key]}}
                key = nextKey[key]
                return result
            end
        }
    end
    function Map.prototype.keys(self)
        local nextKey = self.nextKey
        local key = self.firstKey
        return {
            [Symbol.iterator] = function(self)
                return self
            end,
            next = function(self)
                local result = {done = not key, value = key}
                key = nextKey[key]
                return result
            end
        }
    end
    function Map.prototype.values(self)
        local items = self.items
        local nextKey = self.nextKey
        local key = self.firstKey
        return {
            [Symbol.iterator] = function(self)
                return self
            end,
            next = function(self)
                local result = {done = not key, value = items[key]}
                key = nextKey[key]
                return result
            end
        }
    end
    Map[Symbol.species] = Map
end

local function __TS__ArraySlice(self, first, last)
    local len = #self
    first = first or 0
    if first < 0 then
        first = len + first
        if first < 0 then
            first = 0
        end
    else
        if first > len then
            first = len
        end
    end
    last = last or len
    if last < 0 then
        last = len + last
        if last < 0 then
            last = 0
        end
    else
        if last > len then
            last = len
        end
    end
    local out = {}
    first = first + 1
    last = last + 1
    local n = 1
    while first < last do
        out[n] = self[first]
        first = first + 1
        n = n + 1
    end
    return out
end

local function __TS__StringSubstring(self, start, ____end)
    if ____end ~= ____end then
        ____end = 0
    end
    if ____end ~= nil and start > ____end then
        start, ____end = ____end, start
    end
    if start >= 0 then
        start = start + 1
    else
        start = 1
    end
    if ____end ~= nil and ____end < 0 then
        ____end = 0
    end
    return string.sub(self, start, ____end)
end

local function __TS__StringPadEnd(self, maxLength, fillString)
    if fillString == nil then
        fillString = " "
    end
    if maxLength ~= maxLength then
        maxLength = 0
    end
    if maxLength == -math.huge or maxLength == math.huge then
        error("Invalid string length", 0)
    end
    if #self >= maxLength or #fillString == 0 then
        return self
    end
    maxLength = maxLength - #self
    if maxLength > #fillString then
        fillString = fillString .. string.rep(
            fillString,
            math.floor(maxLength / #fillString)
        )
    end
    return self .. string.sub(
        fillString,
        1,
        math.floor(maxLength)
    )
end

local function __TS__CountVarargs(...)
    return select("#", ...)
end

local function __TS__ArrayReduce(self, callbackFn, ...)
    local len = #self
    local k = 0
    local accumulator = nil
    if __TS__CountVarargs(...) ~= 0 then
        accumulator = ...
    elseif len > 0 then
        accumulator = self[1]
        k = 1
    else
        error("Reduce of empty array with no initial value", 0)
    end
    for i = k + 1, len do
        accumulator = callbackFn(
            nil,
            accumulator,
            self[i],
            i - 1,
            self
        )
    end
    return accumulator
end

local function __TS__StringPadStart(self, maxLength, fillString)
    if fillString == nil then
        fillString = " "
    end
    if maxLength ~= maxLength then
        maxLength = 0
    end
    if maxLength == -math.huge or maxLength == math.huge then
        error("Invalid string length", 0)
    end
    if #self >= maxLength or #fillString == 0 then
        return self
    end
    maxLength = maxLength - #self
    if maxLength > #fillString then
        fillString = fillString .. string.rep(
            fillString,
            math.floor(maxLength / #fillString)
        )
    end
    return string.sub(
        fillString,
        1,
        math.floor(maxLength)
    ) .. self
end

local function __TS__ArrayReverse(self)
    local i = 1
    local j = #self
    while i < j do
        local temp = self[j]
        self[j] = self[i]
        self[i] = temp
        i = i + 1
        j = j - 1
    end
    return self
end

local function __TS__ArrayFind(self, predicate, thisArg)
    for i = 1, #self do
        local elem = self[i]
        if predicate(thisArg, elem, i - 1, self) then
            return elem
        end
    end
    return nil
end

local function __TS__ArrayFilter(self, callbackfn, thisArg)
    local result = {}
    local len = 0
    for i = 1, #self do
        if callbackfn(thisArg, self[i], i - 1, self) then
            len = len + 1
            result[len] = self[i]
        end
    end
    return result
end

local __TS__StringSplit
do
    local sub = string.sub
    local find = string.find
    function __TS__StringSplit(source, separator, limit)
        if limit == nil then
            limit = 4294967295
        end
        if limit == 0 then
            return {}
        end
        local result = {}
        local resultIndex = 1
        if separator == nil or separator == "" then
            for i = 1, #source do
                result[resultIndex] = sub(source, i, i)
                resultIndex = resultIndex + 1
            end
        else
            local currentPos = 1
            while resultIndex <= limit do
                local startPos, endPos = find(source, separator, currentPos, true)
                if not startPos then
                    break
                end
                result[resultIndex] = sub(source, currentPos, startPos - 1)
                resultIndex = resultIndex + 1
                currentPos = endPos + 1
            end
            if resultIndex <= limit then
                result[resultIndex] = sub(source, currentPos)
            end
        end
        return result
    end
end

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

local function __TS__ObjectAssign(target, ...)
    local sources = {...}
    for i = 1, #sources do
        local source = sources[i]
        for key in pairs(source) do
            target[key] = source[key]
        end
    end
    return target
end
-- End of Lua Library inline imports
local ____exports = {}
local ____components = require("modules.ui.components")
local ButtonComponent = ____components.ButtonComponent
local PaginationComponent = ____components.PaginationComponent
local ____types = require("modules.ui.types.index")
local Rect = ____types.Rect
local ____protocol = require("projects.smeltery.shared.protocol")
local AlloyOption = ____protocol.AlloyOption
local CastRequest = ____protocol.CastRequest
local InputItemView = ____protocol.InputItemView
local InsertRequest = ____protocol.InsertRequest
local Mode = ____protocol.Mode
local SetAlloyRequest = ____protocol.SetAlloyRequest
local SetFormatRequest = ____protocol.SetFormatRequest
local SmelteryState = ____protocol.SmelteryState
local ____protocol = require("projects.smeltery.shared.protocol")
local MODES = ____protocol.MODES
local ____model = require("projects.smeltery.display.model")
local attentionLines = ____model.attentionLines
local fluidColor = ____model.fluidColor
local fluidLabel = ____model.fluidLabel
local formatLabel = ____model.formatLabel
local Glyph = ____model.Glyph
local groupCasters = ____model.groupCasters
local itemLabel = ____model.itemLabel
local parseLogLine = ____model.parseLogLine
local textOn = ____model.textOn
local ____model = require("projects.smeltery.display.model")
local CastGroup = ____model.CastGroup
local LogKind = ____model.LogKind
local ____widgets = require("projects.smeltery.display.widgets")
local AbsoluteLayout = ____widgets.AbsoluteLayout
local PaintComponent = ____widgets.PaintComponent
local ____widgets = require("projects.smeltery.display.widgets")
local Painter = ____widgets.Painter
____exports.SCREEN_WIDTH = 79
____exports.SCREEN_HEIGHT = 38
local TABS = {
    {"overview", "Overview"},
    {"modes", "Modes"},
    {"manual", "Manual"},
    {"stock", "Stock"},
    {"log", "Log"}
}
local TABS_X = 23
local MODE_CARDS = {
    idle = {color = colors.lightGray, lines = {"Full stop.", "Nothing moves."}},
    auto = {color = colors.lime, lines = {"Melts the input", "and casts pure", "metals."}},
    manual = {color = colors.orange, lines = {"You insert and", "cast from the", "Manual tab."}},
    lock = {color = colors.red, lines = {"Nothing new goes", "in; the casts", "under way finish."}},
    drain = {color = colors.lightBlue, lines = {"Every fluid to", "the reservoirs,", "then idle."}},
    purge = {color = colors.purple, lines = {"Leftovers and", "alloys to the", "reservoirs."}},
    alloy = {color = colors.magenta, lines = {}},
    melt = {color = colors.cyan, lines = {"Melts the input", "into the stock,", "casts nothing."}}
}
local LOG_COLORS = {
    ["in"] = colors.lightBlue,
    cast = colors.white,
    out = colors.lime,
    reject = colors.orange,
    forced = colors.red,
    mode = colors.yellow,
    other = colors.lightGray
}
local CASTS_PER_PAGE = 4
local ALLOYS_PER_PAGE = 8
local INGOT = 90
local ITEMS_PER_PAGE = 6
local RESERVOIRS_PER_PAGE = 8
local DEFAULT_CAPACITY = 16000
local LOG_LINES = 13
local CONFIRM_SECONDS = 10
local OFFLINE_SECONDS = 12
local function cardPlace(index)
    return {
        x = 3 + index % 4 * 19,
        y = 8 + math.floor(index / 4) * 12
    }
end
local FULL_SCREEN = {x = 1, y = 1, width = ____exports.SCREEN_WIDTH, height = ____exports.SCREEN_HEIGHT}
____exports.SmelteryScreen = __TS__Class()
local SmelteryScreen = ____exports.SmelteryScreen
SmelteryScreen.name = "SmelteryScreen"
function SmelteryScreen.prototype.____constructor(self, actions)
    self.actions = actions
    self.root = __TS__New(AbsoluteLayout, ____exports.SCREEN_WIDTH, ____exports.SCREEN_HEIGHT)
    self.lastState = -math.huge
    self.tab = "overview"
    self.castPage = 1
    self.itemPage = 1
    self.stockPage = 1
    self.picking = false
    self.alloyPage = 1
    self.pickIngots = 16
    self.nonstop = false
    self.logOffset = 0
    self.allButtons = {}
    self.tabButtons = __TS__New(Map)
    self.modeButtons = __TS__New(Map)
    self.itemButtons = {}
    self.fluidButtons = {}
    self.formatButtons = {}
    self.autoButtons = {}
    self.alloyButtons = {}
    self.root:place(
        __TS__New(
            PaintComponent,
            {paint = function(____, painter) return self:paint(painter) end}
        ),
        FULL_SCREEN
    )
    local tabX = TABS_X
    for ____, ____value in ipairs(TABS) do
        local tab = ____value[1]
        local label = ____value[2]
        self.tabButtons:set(
            tab,
            self:button(
                label,
                {x = tabX, y = 2, width = #label, height = 1},
                function() return self:showTab(tab) end
            )
        )
        tabX = tabX + (#label + 4)
    end
    __TS__ArrayForEach(
        MODES,
        function(____, mode, index)
            local card = cardPlace(index)
            self.modeButtons:set(
                mode,
                self:button(
                    " Activate ",
                    {x = card.x + 1, y = card.y + 6, width = 10, height = 1},
                    function() return self.actions:setMode(mode) end
                )
            )
        end
    )
    self.castPages = self.root:place(
        __TS__New(
            PaginationComponent,
            {
                page = 1,
                pageSize = CASTS_PER_PAGE,
                totalItems = 0,
                foregroundColor = colors.lightGray,
                backgroundColor = colors.black,
                onPageChange = function(____, page)
                    self.castPage = page
                end
            }
        ),
        {x = 59, y = 19, width = 11, height = 1}
    )
    do
        local row = 0
        while row < CASTS_PER_PAGE do
            local index = row
            local ____self_autoButtons_0 = self.autoButtons
            ____self_autoButtons_0[#____self_autoButtons_0 + 1] = self:button(
                "",
                {x = 71, y = 7 + index * 3, width = 6, height = 1},
                function() return self:toggleAuto(index) end
            )
            row = row + 1
        end
    end
    self.stockPages = self.root:place(
        __TS__New(
            PaginationComponent,
            {
                page = 1,
                pageSize = RESERVOIRS_PER_PAGE,
                totalItems = 0,
                foregroundColor = colors.lightGray,
                backgroundColor = colors.black,
                onPageChange = function(____, page)
                    self.stockPage = page
                end
            }
        ),
        {x = 3, y = 35, width = 11, height = 1}
    )
    do
        local row = 0
        while row < ITEMS_PER_PAGE do
            local index = row
            local ____self_itemButtons_1 = self.itemButtons
            ____self_itemButtons_1[#____self_itemButtons_1 + 1] = self:button(
                "",
                {x = 37, y = 8 + index * 3, width = 8, height = 1},
                function() return self:pressItem(index) end
            )
            row = row + 1
        end
    end
    self.itemPages = self.root:place(
        __TS__New(
            PaginationComponent,
            {
                page = 1,
                pageSize = ITEMS_PER_PAGE,
                totalItems = 0,
                foregroundColor = colors.lightGray,
                backgroundColor = colors.black,
                onPageChange = function(____, page)
                    self.itemPage = page
                end
            }
        ),
        {x = 3, y = 27, width = 11, height = 1}
    )
    do
        local row = 0
        while row < 5 do
            local index = row
            local ____self_fluidButtons_2 = self.fluidButtons
            ____self_fluidButtons_2[#____self_fluidButtons_2 + 1] = self:button(
                "",
                {x = 58, y = 10 + index * 2, width = 20, height = 1},
                function() return self:pickFluid(index) end
            )
            local ____self_formatButtons_3 = self.formatButtons
            ____self_formatButtons_3[#____self_formatButtons_3 + 1] = self:button(
                "",
                {x = 53, y = 22 + index * 2, width = 25, height = 1},
                function() return self:pickFormat(index) end
            )
            row = row + 1
        end
    end
    self.castButton = self:button(
        "",
        {x = 53, y = 34, width = 25, height = 1},
        function() return self:pressCast() end
    )
    self.logUp = self:button(
        (" " .. Glyph.up) .. " ",
        {x = 70, y = 5, width = 3, height = 1},
        function() return self:scrollLog(1) end
    )
    self.logDown = self:button(
        (" " .. Glyph.down) .. " ",
        {x = 74, y = 5, width = 3, height = 1},
        function() return self:scrollLog(-1) end
    )
    local alloyCard = cardPlace(__TS__ArrayIndexOf(MODES, "alloy"))
    self.changeAlloy = self:button(
        " Change alloy ",
        {x = alloyCard.x + 1, y = alloyCard.y + 9, width = 14, height = 1},
        function() return self:openPicker() end
    )
    do
        local row = 0
        while row < ALLOYS_PER_PAGE do
            local index = row
            local ____self_alloyButtons_4 = self.alloyButtons
            ____self_alloyButtons_4[#____self_alloyButtons_4 + 1] = self:button(
                "",
                {x = 8, y = 7 + index * 3, width = 24, height = 1},
                function() return self:pickAlloy(index) end
            )
            row = row + 1
        end
    end
    self.alloyPages = self.root:place(
        __TS__New(
            PaginationComponent,
            {
                page = 1,
                pageSize = ALLOYS_PER_PAGE,
                totalItems = 0,
                foregroundColor = colors.lightGray,
                backgroundColor = colors.black,
                onPageChange = function(____, page)
                    self.alloyPage = page
                end
            }
        ),
        {x = 3, y = 32, width = 11, height = 1}
    )
    self.lessButton = self:button(
        " - ",
        {x = 53, y = 22, width = 3, height = 1},
        function() return self:stepIngots(-1) end
    )
    self.moreButton = self:button(
        " + ",
        {x = 69, y = 22, width = 3, height = 1},
        function() return self:stepIngots(1) end
    )
    self.nonstopButton = self:button(
        " Until stopped ",
        {x = 53, y = 24, width = 15, height = 1},
        function() return self:toggleNonstop() end
    )
    self.selectButton = self:button(
        "",
        {x = 53, y = 30, width = 21, height = 1},
        function() return self:selectAlloy() end
    )
    self.closePicker = self:button(
        " Cancel ",
        {x = 53, y = 32, width = 8, height = 1},
        function() return self:cancelPicker() end
    )
    self.root:place(
        __TS__New(
            PaintComponent,
            {paint = function(____, painter) return self:paintConfirm(painter) end}
        ),
        FULL_SCREEN
    )
    self.confirmYes = self:button(
        "",
        {x = 18, y = 22, width = 16, height = 1},
        function() return self:confirmStep() end
    )
    self.confirmNo = self:button(
        " Cancel ",
        {x = 47, y = 22, width = 8, height = 1},
        function() return self:cancelConfirm() end
    )
    self:sync()
end
function SmelteryScreen.prototype.setState(self, state)
    self.state = state
    self.lastState = os.clock()
    self:sync()
end
function SmelteryScreen.prototype.notify(self, text, color)
    if color == nil then
        color = colors.lightGray
    end
    self.message = {
        text = text,
        color = color,
        ["until"] = os.clock() + 6
    }
end
function SmelteryScreen.prototype.tick(self)
    if self.confirm ~= nil and self.confirm.step == 2 and os.clock() > self.confirm.deadline then
        self.confirm = nil
        self:notify("force cancelled: not confirmed in time")
    end
    self:sync()
end
function SmelteryScreen.prototype.showTab(self, tab)
    self.tab = tab
    self.picking = false
    self:sync()
end
function SmelteryScreen.prototype.alloyOptions(self)
    local ____opt_5 = self.state
    return ____opt_5 and ____opt_5.alloyOptions or ({})
end
function SmelteryScreen.prototype.openPicker(self)
    local ____opt_7 = self.state
    local alloy = ____opt_7 and ____opt_7.alloy
    self.picking = true
    local ____temp_13 = alloy and alloy.result
    if ____temp_13 == nil then
        local ____opt_11 = self:alloyOptions()[1]
        ____temp_13 = ____opt_11 and ____opt_11.result
    end
    self.picked = ____temp_13
    self.nonstop = alloy ~= nil and alloy.target == nil
    if (alloy and alloy.target) ~= nil then
        self.pickIngots = math.max(
            1,
            math.floor(alloy.target / INGOT + 0.5)
        )
    end
    self:sync()
end
function SmelteryScreen.prototype.cancelPicker(self)
    self.picking = false
    self:sync()
end
function SmelteryScreen.prototype.pickAlloy(self, row)
    local option = self:alloyOptions()[(self.alloyPage - 1) * ALLOYS_PER_PAGE + row + 1]
    if option ~= nil then
        self.picked = option.result
    end
    self:sync()
end
function SmelteryScreen.prototype.stepIngots(self, direction)
    local step = direction > 0 and (self.pickIngots >= 9 and 9 or 1) or (self.pickIngots > 9 and 9 or 1)
    self.pickIngots = math.max(1, self.pickIngots + direction * step)
    self.nonstop = false
    self:sync()
end
function SmelteryScreen.prototype.toggleNonstop(self)
    self.nonstop = not self.nonstop
    self:sync()
end
function SmelteryScreen.prototype.selectAlloy(self)
    local result = self.picked
    if result == nil then
        return
    end
    local request = {result = result, activate = true}
    if not self.nonstop then
        request.target = self.pickIngots * INGOT
    end
    self.actions:setAlloy(request)
    self.picking = false
    self:sync()
end
function SmelteryScreen.prototype.pageItems(self)
    local ____opt_16 = self.state
    local items = ____opt_16 and ____opt_16.inputItems or ({})
    local start = (self.itemPage - 1) * ITEMS_PER_PAGE
    return __TS__ArraySlice(items, start, start + ITEMS_PER_PAGE)
end
function SmelteryScreen.prototype.pressItem(self, row)
    local item = self:pageItems()[row + 1]
    if item == nil then
        return
    end
    if item.status == "ok" then
        self.actions:insert({slot = item.slot})
    elseif item.status == "alloy" or item.status == "heat" then
        self.confirm = {item = item, step = 1, deadline = 0}
    end
    self:sync()
end
function SmelteryScreen.prototype.confirmStep(self)
    local confirm = self.confirm
    if confirm == nil then
        return
    end
    if confirm.step == 1 then
        self.confirm = {
            item = confirm.item,
            step = 2,
            deadline = os.clock() + CONFIRM_SECONDS
        }
    else
        self.confirm = nil
        self.actions:insert({slot = confirm.item.slot, force = true})
    end
    self:sync()
end
function SmelteryScreen.prototype.cancelConfirm(self)
    self.confirm = nil
    self:sync()
end
function SmelteryScreen.prototype.fluids(self)
    local ____opt_18 = self.state
    return __TS__ArraySlice(____opt_18 and ____opt_18.fluids or ({}), 0, #self.fluidButtons)
end
function SmelteryScreen.prototype.castGroups(self)
    local ____groupCasters_25 = groupCasters
    local ____opt_20 = self.state
    local ____temp_24 = ____opt_20 and ____opt_20.casters or ({})
    local ____opt_22 = self.state
    return ____groupCasters_25(____temp_24, ____opt_22 and ____opt_22.autoFormats or ({}))
end
function SmelteryScreen.prototype.pickFluid(self, row)
    local ____opt_26 = self:fluids()[row + 1]
    self.fluid = ____opt_26 and ____opt_26.name
    self:sync()
end
function SmelteryScreen.prototype.pickFormat(self, row)
    local ____opt_28 = self:castGroups()[row + 1]
    self.format = ____opt_28 and ____opt_28.format
    self:sync()
end
function SmelteryScreen.prototype.toggleAuto(self, row)
    local group = self:castGroups()[(self.castPage - 1) * CASTS_PER_PAGE + row + 1]
    if group ~= nil and group.format ~= "no cast" then
        self.actions:setFormat({format = group.format, auto = not group.auto})
    end
end
function SmelteryScreen.prototype.pressCast(self)
    if self.fluid ~= nil and self.format ~= nil then
        self.actions:cast({fluid = self.fluid, format = self.format})
    end
end
function SmelteryScreen.prototype.scrollLog(self, delta)
    local ____opt_30 = self.state
    local lines = ____opt_30 and #____opt_30.log or 0
    self.logOffset = math.max(
        0,
        math.min(
            math.max(0, lines - LOG_LINES),
            self.logOffset + delta
        )
    )
    self:sync()
end
function SmelteryScreen.prototype.button(self, label, rect, onPress)
    local button = self.root:place(
        __TS__New(ButtonComponent, {
            label = label,
            padding = 0,
            foregroundColor = colors.white,
            backgroundColor = colors.black,
            onPress = onPress
        }),
        rect
    )
    local ____self_allButtons_32 = self.allButtons
    ____self_allButtons_32[#____self_allButtons_32 + 1] = button
    return button
end
function SmelteryScreen.prototype.show(self, button, visible, label, foreground, background)
    local patch = {visible = visible}
    if label ~= nil then
        patch.label = label
    end
    if foreground ~= nil then
        patch.foregroundColor = foreground
    end
    if background ~= nil then
        patch.backgroundColor = background
    end
    button:setProps(patch)
end
function SmelteryScreen.prototype.sync(self)
    local state = self.state
    local modal = self.confirm ~= nil
    for ____, ____value in __TS__Iterator(self.tabButtons) do
        local tab = ____value[1]
        local button = ____value[2]
        self:show(button, true, nil, tab == self.tab and colors.white or colors.gray)
    end
    local cards = self.tab == "modes" and state ~= nil and not self.picking
    local picker = self.tab == "modes" and state ~= nil and self.picking
    for ____, ____value in __TS__Iterator(self.modeButtons) do
        local mode = ____value[1]
        local button = ____value[2]
        self:show(
            button,
            cards and state.mode ~= mode,
            " Activate ",
            colors.black,
            MODE_CARDS[mode].color
        )
    end
    self:show(
        self.changeAlloy,
        cards,
        " Change alloy ",
        colors.white,
        colors.gray
    )
    local options = self:alloyOptions()
    self.alloyPages:setProps({visible = picker and #options > ALLOYS_PER_PAGE, totalItems = #options})
    self.alloyPage = math.min(
        self.alloyPage,
        math.max(
            1,
            math.ceil(#options / ALLOYS_PER_PAGE)
        )
    )
    local pageOptions = __TS__ArraySlice(options, (self.alloyPage - 1) * ALLOYS_PER_PAGE, self.alloyPage * ALLOYS_PER_PAGE)
    __TS__ArrayForEach(
        self.alloyButtons,
        function(____, button, row)
            local option = pageOptions[row + 1]
            local label = option ~= nil and __TS__StringPadEnd(
                __TS__StringSubstring(
                    fluidLabel(option.result),
                    0,
                    24
                ),
                24
            ) or ""
            local color = (option and option.result) == self.picked and colors.white or colors.lightGray
            self:show(
                button,
                picker and option ~= nil,
                label,
                color,
                colors.black
            )
        end
    )
    self:show(
        self.lessButton,
        picker,
        " - ",
        colors.white,
        colors.gray
    )
    self:show(
        self.moreButton,
        picker,
        " + ",
        colors.white,
        colors.gray
    )
    self:show(
        self.nonstopButton,
        picker,
        " Until stopped ",
        self.nonstop and colors.black or colors.lightGray,
        self.nonstop and colors.magenta or colors.gray
    )
    local pickedLabel = self.picked ~= nil and fluidLabel(self.picked) or ""
    self:show(
        self.selectButton,
        picker and self.picked ~= nil,
        __TS__StringPadEnd(
            __TS__StringSubstring(" Select " .. pickedLabel, 0, 21),
            21
        ),
        colors.black,
        colors.magenta
    )
    self:show(
        self.closePicker,
        picker,
        " Cancel ",
        colors.black,
        colors.lightGray
    )
    local groups = self:castGroups()
    self.castPages:setProps({visible = self.tab == "overview" and #groups > CASTS_PER_PAGE, totalItems = #groups})
    self.castPage = math.min(
        self.castPage,
        math.max(
            1,
            math.ceil(#groups / CASTS_PER_PAGE)
        )
    )
    local pageGroups = __TS__ArraySlice(groups, (self.castPage - 1) * CASTS_PER_PAGE, self.castPage * CASTS_PER_PAGE)
    __TS__ArrayForEach(
        self.autoButtons,
        function(____, button, row)
            local group = pageGroups[row + 1]
            local shown = self.tab == "overview" and group ~= nil and group.format ~= "no cast"
            if (group and group.auto) == true then
                self:show(
                    button,
                    shown,
                    " AUTO ",
                    colors.black,
                    colors.lime
                )
            else
                self:show(
                    button,
                    shown,
                    " off  ",
                    colors.lightGray,
                    colors.gray
                )
            end
        end
    )
    local reservoirCount = state and #state.reservoirs or 0
    self.stockPages:setProps({visible = self.tab == "stock" and reservoirCount > RESERVOIRS_PER_PAGE, totalItems = reservoirCount})
    self.stockPage = math.min(
        self.stockPage,
        math.max(
            1,
            math.ceil(reservoirCount / RESERVOIRS_PER_PAGE)
        )
    )
    local manual = self.tab == "manual"
    local items = self:pageItems()
    local itemCount = state and #state.inputItems or 0
    self.itemPages:setProps({visible = manual and itemCount > ITEMS_PER_PAGE, totalItems = itemCount})
    __TS__ArrayForEach(
        self.itemButtons,
        function(____, button, row)
            local item = items[row + 1]
            if not manual or item == nil or item.status == "unknown" then
                self:show(button, false)
            elseif item.status == "ok" then
                self:show(
                    button,
                    true,
                    " Insert ",
                    colors.black,
                    colors.lime
                )
            else
                self:show(
                    button,
                    true,
                    " Force  ",
                    colors.white,
                    colors.red
                )
            end
        end
    )
    local fluids = self:fluids()
    __TS__ArrayForEach(
        self.fluidButtons,
        function(____, button, row)
            local fluid = fluids[row + 1]
            local label = fluid == nil and "" or fluidLabel(fluid.name)
            local color = (fluid and fluid.name) == self.fluid and colors.white or colors.lightGray
            self:show(
                button,
                manual and fluid ~= nil,
                __TS__StringPadEnd(label, 20),
                color
            )
        end
    )
    __TS__ArrayForEach(
        self.formatButtons,
        function(____, button, row)
            local group = groups[row + 1]
            local label = group == nil and "" or (__TS__StringPadEnd(
                formatLabel(group.format),
                16
            ) .. " x") .. tostring(group.free)
            local color = (group and group.format) == self.format and colors.white or colors.lightGray
            self:show(
                button,
                manual and group ~= nil,
                __TS__StringPadEnd(label, 25),
                color
            )
        end
    )
    local canCast = self.fluid ~= nil and self.format ~= nil
    local castLabel = canCast and (((" Cast " .. fluidLabel(self.fluid)) .. " ") .. formatLabel(self.format)) .. " " or " Pick a fluid and a cast "
    self:show(
        self.castButton,
        manual,
        __TS__StringSubstring(castLabel, 0, 25),
        colors.black,
        canCast and colors.orange or colors.gray
    )
    self:show(
        self.logUp,
        self.tab == "log",
        nil,
        colors.lightGray,
        colors.gray
    )
    self:show(
        self.logDown,
        self.tab == "log",
        nil,
        colors.lightGray,
        colors.gray
    )
    local confirm = self.confirm
    self:show(
        self.confirmYes,
        modal,
        (confirm and confirm.step) == 2 and " Force insert " or " Continue ",
        colors.white,
        (confirm and confirm.step) == 2 and colors.red or colors.orange
    )
    self:show(
        self.confirmNo,
        modal,
        " Cancel ",
        colors.black,
        colors.lightGray
    )
    for ____, button in ipairs(self.allButtons) do
        if button ~= self.confirmYes and button ~= self.confirmNo then
            button:setProps({disabled = modal})
        end
    end
    self.castPages:setProps({disabled = modal})
    self.itemPages:setProps({disabled = modal})
    self.stockPages:setProps({disabled = modal})
    self.alloyPages:setProps({disabled = modal})
end
function SmelteryScreen.prototype.paint(self, p)
    p:fill(
        1,
        1,
        ____exports.SCREEN_WIDTH,
        ____exports.SCREEN_HEIGHT,
        colors.black
    )
    self:paintHeader(p)
    local state = self.state
    if state == nil then
        p:text(27, 18, "Waiting for the controller...", colors.lightGray)
        p:text(22, 20, "Is the foundry computer running main?", colors.gray)
        return
    end
    if self.tab == "overview" then
        self:paintOverview(p, state)
    elseif self.tab == "modes" then
        self:paintModes(p, state)
    elseif self.tab == "manual" then
        self:paintManual(p, state)
    elseif self.tab == "stock" then
        self:paintStock(p, state)
    else
        self:paintLog(p, state)
    end
    local message = self.message
    if message ~= nil and os.clock() < message["until"] then
        p:text(
            3,
            36,
            __TS__StringSubstring(message.text, 0, 75),
            message.color
        )
    elseif self.tab ~= "log" then
        self:paintLastAction(p, state)
    end
end
function SmelteryScreen.prototype.paintHeader(self, p)
    p:text(3, 2, Glyph.up, colors.orange)
    p:text(5, 2, "S M E L T E R Y", colors.white)
    local x = TABS_X
    for ____, ____value in ipairs(TABS) do
        local tab = ____value[1]
        local label = ____value[2]
        if tab == self.tab then
            p:text(
                x,
                3,
                string.rep(
                    Glyph.underline,
                    math.floor(#label)
                ),
                colors.orange
            )
        end
        x = x + (#label + 4)
    end
    local ____opt_49 = self.state
    local mode = ____opt_49 and ____opt_49.mode
    if mode ~= nil then
        p:text(
            67,
            2,
            (" " .. string.upper(mode)) .. " ",
            colors.black,
            MODE_CARDS[mode].color
        )
    end
    local online = os.clock() - self.lastState < OFFLINE_SECONDS
    p:text(76, 2, Glyph.dot, online and colors.lime or colors.red)
end
function SmelteryScreen.prototype.title(self, p, x, y, text, width)
    p:text(x, y, text, colors.orange)
    p:text(
        x + #text + 1,
        y,
        string.rep(
            Glyph.rule,
            math.floor(math.max(0, width - #text - 1))
        ),
        colors.gray
    )
end
function SmelteryScreen.prototype.frame(self, p, x, y, width, height)
    p:fill(
        x,
        y,
        width + 2,
        1,
        colors.gray
    )
    p:fill(
        x,
        y + height + 1,
        width + 2,
        1,
        colors.gray
    )
    p:fill(
        x,
        y + 1,
        1,
        height,
        colors.gray
    )
    p:fill(
        x + width + 1,
        y + 1,
        1,
        height,
        colors.gray
    )
end
function SmelteryScreen.prototype.paintOverview(self, p, state)
    self:title(
        p,
        3,
        5,
        "MOLTEN",
        22
    )
    local tankX = 3
    local tankY = 7
    local tankW = 18
    local tankH = 25
    self:frame(
        p,
        tankX,
        tankY,
        tankW,
        tankH
    )
    local total = __TS__ArrayReduce(
        state.fluids,
        function(____, sum, fluid) return sum + fluid.amount end,
        0
    )
    local bottom = tankY + tankH
    for ____, fluid in ipairs(state.fluids) do
        if bottom <= tankY then
            break
        end
        local rows = math.min(
            bottom - tankY,
            math.max(
                1,
                math.floor(tankH * fluid.amount / math.max(total, 1) + 0.5)
            )
        )
        local color = fluidColor(fluid.name)
        p:fill(
            tankX + 1,
            bottom - rows + 1,
            tankW,
            rows,
            color
        )
        p:text(
            tankX + 2,
            bottom - math.floor((rows - 1) / 2),
            __TS__StringSubstring(
                fluidLabel(fluid.name),
                0,
                tankW - 2
            ),
            textOn(color),
            color
        )
        bottom = bottom - rows
    end
    local legendY = 8
    for ____, fluid in ipairs(__TS__ArraySlice(
        __TS__ArrayReverse({unpack(state.fluids)}),
        0,
        8
    )) do
        p:fill(
            24,
            legendY,
            1,
            1,
            fluidColor(fluid.name)
        )
        p:text(
            26,
            legendY,
            __TS__StringPadStart(
                tostring(fluid.amount) .. " mB",
                8
            ),
            colors.white
        )
        legendY = legendY + 2
    end
    p:text(
        24,
        26,
        tostring(total) .. " mB",
        colors.white
    )
    p:text(24, 27, "molten", colors.gray)
    local melting = __TS__ArrayReduce(
        state.melting,
        function(____, sum, item) return sum + item.count end,
        0
    )
    p:text(24, 29, "melting", colors.gray)
    p:text(
        24,
        30,
        (tostring(melting) .. " item") .. (melting == 1 and "" or "s"),
        colors.lightGray
    )
    self:title(
        p,
        37,
        5,
        "FUEL",
        10
    )
    self:frame(
        p,
        37,
        tankY,
        6,
        tankH
    )
    local fuel = state.fuel
    if fuel ~= nil then
        local rows = math.min(
            tankH,
            math.floor(tankH * fuel.amount / 4000 + 0.5)
        )
        do
            local row = 0
            while row < rows do
                p:fill(
                    38,
                    tankY + tankH - row,
                    6,
                    1,
                    row % 5 == 0 and colors.red or colors.orange
                )
                row = row + 1
            end
        end
        p:text(
            46,
            26,
            fuel.fluid ~= nil and __TS__StringSubstring(
                fluidLabel(fuel.fluid),
                0,
                10
            ) or "empty",
            fuel.fluid ~= nil and colors.orange or colors.red
        )
        p:text(
            46,
            27,
            tostring(fuel.amount) .. " mB",
            colors.white
        )
    else
        p:text(46, 26, "no tank", colors.gray)
    end
    p:text(
        46,
        29,
        state.heat ~= nil and tostring(state.heat) .. " K" or "? K",
        colors.white
    )
    p:text(46, 30, "heat", colors.gray)
    self:title(
        p,
        53,
        5,
        "CASTING",
        25
    )
    local groups = self:castGroups()
    local start = (self.castPage - 1) * CASTS_PER_PAGE
    __TS__ArrayForEach(
        __TS__ArraySlice(groups, start, start + CASTS_PER_PAGE),
        function(____, group, index)
            local y = 7 + index * 3
            p:text(
                53,
                y,
                __TS__StringSubstring(
                    formatLabel(group.format),
                    0,
                    17
                ),
                group.auto and colors.white or colors.lightGray
            )
            local x = 53
            local blocks = {{group.free, colors.gray}, {group.casting, group.auto and colors.orange or colors.gray}, {group.ready, group.auto and colors.yellow or colors.gray}}
            for ____, ____value in ipairs(blocks) do
                local count = ____value[1]
                local color = ____value[2]
                do
                    local n = 0
                    while n < count and x < 75 do
                        p:fill(
                            x,
                            y + 1,
                            2,
                            1,
                            color
                        )
                        x = x + 3
                        n = n + 1
                    end
                end
            end
            p:text(
                x + 1,
                y + 1,
                tostring(group.free + group.casting + group.ready),
                colors.gray
            )
        end
    )
    if #groups == 0 then
        p:text(53, 7, "no caster found", colors.gray)
    end
    p:fill(
        53,
        21,
        1,
        1,
        colors.gray
    )
    p:text(55, 21, "free", colors.gray)
    p:fill(
        61,
        21,
        1,
        1,
        colors.orange
    )
    p:text(63, 21, "casting", colors.gray)
    p:fill(
        72,
        21,
        1,
        1,
        colors.yellow
    )
    p:text(74, 21, "ready", colors.gray)
    p:text(53, 23, "Touch AUTO/off: auto casts", colors.gray)
    p:text(53, 24, "only into the AUTO ones.", colors.gray)
    local lines = attentionLines(state)
    if #lines > 0 then
        self:title(
            p,
            53,
            25,
            "ATTENTION",
            25
        )
        __TS__ArrayForEach(
            __TS__ArraySlice(lines, 0, 3),
            function(____, line, index)
                local y = 27 + index * 3
                p:text(53, y, Glyph.up, line.color)
                p:text(
                    55,
                    y,
                    __TS__StringSubstring(line.title, 0, 23),
                    colors.white
                )
                p:text(
                    55,
                    y + 1,
                    __TS__StringSubstring(line.detail, 0, 23),
                    colors.gray
                )
            end
        )
        if #lines > 3 then
            p:text(
                55,
                36,
                ("+ " .. tostring(#lines - 3)) .. " more in Log",
                colors.gray
            )
        end
    end
end
function SmelteryScreen.alloyLines(self, state)
    if state.alloy == nil then
        return {"No alloy chosen:", "pick one with", "Change alloy."}
    end
    local label = fluidLabel(state.alloy.result)
    return {#(("Only " .. label) .. ",") <= 16 and ("Only " .. label) .. "," or label, "dosed from input", "and stock."}
end
function SmelteryScreen.prototype.paintModes(self, p, state)
    if self.picking then
        self:paintPicker(p, state)
        return
    end
    __TS__ArrayForEach(
        MODES,
        function(____, mode, index)
            local card = MODE_CARDS[mode]
            local ____cardPlace_result_51 = cardPlace(index)
            local x = ____cardPlace_result_51.x
            local y = ____cardPlace_result_51.y
            local active = state.mode == mode
            local lines = mode == "alloy" and ____exports.SmelteryScreen:alloyLines(state) or card.lines
            p:fill(
                x,
                y,
                17,
                1,
                card.color
            )
            p:text(
                x + 1,
                y,
                string.upper(mode),
                colors.black,
                card.color
            )
            __TS__ArrayForEach(
                lines,
                function(____, line, row) return p:text(
                    x + 1,
                    y + 2 + row,
                    __TS__StringSubstring(line, 0, 16),
                    active and colors.white or colors.lightGray
                ) end
            )
            if not active then
                return
            end
            local alloy = state.alloy
            if mode ~= "alloy" or alloy == nil then
                p:text(x + 1, y + 6, Glyph.dot .. " active", colors.lime)
            elseif alloy.target == nil then
                p:text(
                    x + 1,
                    y + 6,
                    __TS__StringSubstring(
                        ((Glyph.dot .. " ") .. tostring(math.floor(alloy.made / INGOT))) .. " ingots made",
                        0,
                        16
                    ),
                    colors.lime
                )
            else
                local target = math.max(
                    1,
                    math.floor(alloy.target / INGOT + 0.5)
                )
                p:text(
                    x + 1,
                    y + 6,
                    __TS__StringSubstring(
                        ((((Glyph.dot .. " ") .. tostring(math.floor(alloy.made / INGOT))) .. "/") .. tostring(target)) .. " ingots",
                        0,
                        16
                    ),
                    colors.lime
                )
                p:fill(
                    x + 1,
                    y + 7,
                    15,
                    1,
                    colors.gray
                )
                p:fill(
                    x + 1,
                    y + 7,
                    math.min(
                        15,
                        math.floor(15 * alloy.made / alloy.target)
                    ),
                    1,
                    card.color
                )
            end
        end
    )
    p:text(3, 34, "Touch Activate to switch; the controller confirms live.", colors.gray)
end
function SmelteryScreen.prototype.paintPicker(self, p, state)
    self:title(
        p,
        3,
        5,
        "ALLOY",
        44
    )
    local options = self:alloyOptions()
    local start = (self.alloyPage - 1) * ALLOYS_PER_PAGE
    __TS__ArrayForEach(
        __TS__ArraySlice(options, start, start + ALLOYS_PER_PAGE),
        function(____, option, index)
            local y = 7 + index * 3
            local picked = option.result == self.picked
            if picked then
                p:text(3, y, Glyph.right, colors.white)
            end
            p:fill(
                5,
                y,
                2,
                1,
                fluidColor(option.result)
            )
            if option.temperature ~= nil then
                p:text(
                    8,
                    y + 1,
                    ("needs " .. tostring(option.temperature)) .. " K",
                    colors.red
                )
            elseif option.fromStock > 0 then
                p:text(
                    8,
                    y + 1,
                    ("from stock: " .. tostring(math.floor(option.fromStock / INGOT))) .. " ing",
                    colors.lime
                )
            else
                p:text(8, y + 1, "put in the input", colors.gray)
            end
        end
    )
    if #options == 0 then
        p:text(3, 7, "No alloy in the catalogue.", colors.gray)
    end
    if #options > ALLOYS_PER_PAGE then
        p:text(15, 32, "ready first", colors.gray)
    end
    local option = __TS__ArrayFind(
        options,
        function(____, candidate) return candidate.result == self.picked end
    )
    if option == nil then
        return
    end
    local label = fluidLabel(option.result)
    self:title(
        p,
        53,
        5,
        __TS__StringSubstring(
            string.upper(label),
            0,
            20
        ),
        25
    )
    p:text(53, 7, "recipe", colors.gray)
    local function count(____, amount)
        return amount % INGOT == 0 and tostring(amount / INGOT) .. " " or ""
    end
    __TS__ArrayForEach(
        option.inputs,
        function(____, input, index)
            local y = 9 + index
            p:fill(
                53,
                y,
                2,
                1,
                fluidColor(input.fluid)
            )
            p:text(
                56,
                y,
                __TS__StringSubstring(
                    count(nil, input.amount) .. fluidLabel(input.fluid),
                    0,
                    14
                ),
                colors.white
            )
            p:text(
                71,
                y,
                __TS__StringPadStart(
                    tostring(input.amount) .. " mB",
                    6
                ),
                colors.gray
            )
        end
    )
    local resultY = 9 + #option.inputs
    p:text(
        56,
        resultY,
        __TS__StringSubstring(
            ((Glyph.right .. " ") .. count(nil, option.amount)) .. label,
            0,
            14
        ),
        colors.pink
    )
    p:text(
        71,
        resultY,
        __TS__StringPadStart(
            tostring(option.amount) .. " mB",
            6
        ),
        colors.gray
    )
    local stockY = resultY + 2
    p:text(53, stockY, "in stock", colors.gray)
    __TS__ArrayForEach(
        option.inputs,
        function(____, input, index)
            local stored = __TS__ArrayReduce(
                __TS__ArrayFilter(
                    state.reservoirs,
                    function(____, reservoir) return reservoir.fluid == input.fluid end
                ),
                function(____, sum, reservoir) return sum + reservoir.amount end,
                0
            )
            p:text(
                53,
                stockY + 1 + index,
                __TS__StringSubstring(
                    fluidLabel(input.fluid),
                    0,
                    15
                ),
                colors.white
            )
            p:text(
                69,
                stockY + 1 + index,
                __TS__StringPadStart(
                    tostring(stored) .. " mB",
                    8
                ),
                colors.lightGray
            )
        end
    )
    local ingots = math.floor(option.fromStock / INGOT)
    p:text(
        53,
        stockY + 1 + #option.inputs,
        ("= " .. tostring(ingots)) .. " ingots now",
        ingots > 0 and colors.lime or colors.gray
    )
    p:text(53, 20, "amount", colors.gray)
    p:text(
        58,
        22,
        self.nonstop and "nonstop" or tostring(self.pickIngots) .. " ingots",
        self.nonstop and colors.gray or colors.white
    )
    local back = ____exports.SmelteryScreen:endsOnItsOwn(state.mode) and "the previous mode" or string.upper(state.mode)
    p:text(
        53,
        25,
        self.nonstop and "runs until changed" or __TS__StringSubstring("then back to " .. back, 0, 25),
        colors.gray
    )
end
function SmelteryScreen.endsOnItsOwn(self, mode)
    return mode == "drain" or mode == "purge" or mode == "alloy"
end
function SmelteryScreen.prototype.paintManual(self, p, state)
    self:title(
        p,
        3,
        5,
        "INSERT",
        44
    )
    local items = self:pageItems()
    if state.mode ~= "manual" then
        p:text(3, 7, "Switch to manual mode to insert and cast.", colors.orange)
    end
    __TS__ArrayForEach(
        items,
        function(____, item, row)
            local y = 8 + row * 3
            p:text(
                3,
                y,
                __TS__StringSubstring(
                    itemLabel(item.name),
                    0,
                    32
                ),
                colors.white
            )
            p:text(
                3,
                y + 1,
                __TS__StringSubstring(
                    (((tostring(item.count) .. " ") .. Glyph.dot) .. " ") .. (item.fluid ~= nil and fluidLabel(item.fluid) or "no fluid"),
                    0,
                    32
                ),
                colors.gray
            )
            if item.status == "unknown" then
                p:text(37, y, "unknown", colors.gray)
            elseif item.status == "alloy" then
                p:text(
                    37,
                    y + 1,
                    __TS__StringSubstring(
                        fluidLabel(item.alloy or "alloy"),
                        0,
                        12
                    ),
                    colors.red
                )
            elseif item.status == "heat" then
                p:text(
                    37,
                    y + 1,
                    tostring(item.temperature or "?") .. " K",
                    colors.red
                )
            end
        end
    )
    if #state.inputItems == 0 then
        p:text(3, 8, "The input is empty.", colors.gray)
    end
    self:title(
        p,
        53,
        5,
        "CAST",
        25
    )
    p:text(53, 8, "fluid", colors.gray)
    __TS__ArrayForEach(
        self:fluids(),
        function(____, fluid, row)
            local y = 10 + row * 2
            p:text(53, y, fluid.name == self.fluid and Glyph.right or " ", colors.white)
            p:fill(
                55,
                y,
                2,
                1,
                fluidColor(fluid.name)
            )
        end
    )
    p:text(53, 20, "into", colors.gray)
    __TS__ArrayForEach(
        __TS__ArraySlice(
            self:castGroups(),
            0,
            5
        ),
        function(____, group, row)
            p:text(53, 22 + row * 2, group.format == self.format and Glyph.right or " ", colors.white)
        end
    )
end
function SmelteryScreen.prototype.paintStock(self, p, state)
    local reservoirs = state.reservoirs
    self:title(
        p,
        3,
        5,
        "RESERVOIRS",
        48
    )
    local known = 0
    local scale = 0
    for ____, reservoir in ipairs(reservoirs) do
        do
            local __continue170
            repeat
                if reservoir.capacity == nil then
                    __continue170 = true
                    break
                end
                known = known + 1
                scale = math.max(scale, reservoir.capacity)
                __continue170 = true
            until true
            if not __continue170 then
                break
            end
        end
    end
    if scale == 0 then
        scale = DEFAULT_CAPACITY
    end
    local start = (self.stockPage - 1) * RESERVOIRS_PER_PAGE
    __TS__ArrayForEach(
        __TS__ArraySlice(reservoirs, start, start + RESERVOIRS_PER_PAGE),
        function(____, reservoir, index)
            local x = 3 + index % 4 * 12
            local y = 7 + math.floor(index / 4) * 14
            local height = 7
            self:frame(
                p,
                x,
                y,
                6,
                height
            )
            local fluid = reservoir.fluid
            if fluid ~= nil then
                local rows = math.min(
                    height,
                    math.max(
                        1,
                        math.floor(height * reservoir.amount / (reservoir.capacity or scale) + 0.5)
                    )
                )
                p:fill(
                    x + 1,
                    y + height + 1 - rows,
                    6,
                    rows,
                    fluidColor(fluid)
                )
            end
            if reservoir.capacity ~= nil and reservoir.amount >= reservoir.capacity then
                p:text(
                    x + 1,
                    y + 1,
                    " FULL ",
                    colors.black,
                    colors.white
                )
            end
            local label = fluid ~= nil and fluidLabel(fluid) or (reservoir.assigned ~= nil and "for " .. fluidLabel(reservoir.assigned) or "free")
            p:text(
                x,
                y + height + 3,
                __TS__StringSubstring(label, 0, 11),
                fluid ~= nil and colors.white or colors.gray
            )
            if fluid ~= nil then
                p:text(
                    x,
                    y + height + 4,
                    tostring(reservoir.amount) .. " mB",
                    colors.lightGray
                )
            elseif reservoir.assigned ~= nil then
                p:text(x, y + height + 4, "assigned", colors.gray)
            end
            p:text(
                x,
                y + height + 5,
                __TS__StringSubstring(
                    table.concat(
                        __TS__StringSplit(
                            itemLabel(reservoir.name),
                            "_"
                        ),
                        " "
                    ),
                    0,
                    11
                ),
                colors.gray
            )
        end
    )
    if #reservoirs == 0 then
        p:text(3, 7, "No reservoir found.", colors.gray)
    end
    self:title(
        p,
        55,
        5,
        "TOTALS",
        23
    )
    local totals = {}
    for ____, reservoir in ipairs(reservoirs) do
        do
            local __continue180
            repeat
                if reservoir.fluid == nil then
                    __continue180 = true
                    break
                end
                local entry = __TS__ArrayFind(
                    totals,
                    function(____, candidate) return candidate.fluid == reservoir.fluid end
                )
                if entry ~= nil then
                    entry.amount = entry.amount + reservoir.amount
                else
                    totals[#totals + 1] = {fluid = reservoir.fluid, amount = reservoir.amount}
                end
                __continue180 = true
            until true
            if not __continue180 then
                break
            end
        end
    end
    __TS__ArraySort(
        totals,
        function(____, a, b) return b.amount - a.amount end
    )
    __TS__ArrayForEach(
        __TS__ArraySlice(totals, 0, 5),
        function(____, total, index)
            local y = 7 + index * 3
            p:fill(
                55,
                y,
                2,
                1,
                fluidColor(total.fluid)
            )
            p:text(
                58,
                y,
                __TS__StringSubstring(
                    fluidLabel(total.fluid),
                    0,
                    20
                ),
                colors.white
            )
            p:text(
                58,
                y + 1,
                (__TS__StringPadEnd(
                    tostring(total.amount) .. " mB",
                    10
                ) .. tostring(math.floor(total.amount / 90))) .. " ing",
                colors.gray
            )
        end
    )
    if #totals > 5 then
        p:text(
            58,
            22,
            ("+ " .. tostring(#totals - 5)) .. " more",
            colors.gray
        )
    end
    if #totals == 0 then
        p:text(55, 7, "Nothing stored.", colors.gray)
    end
    self:title(
        p,
        55,
        23,
        "FREE",
        23
    )
    local empty = __TS__ArrayFilter(
        reservoirs,
        function(____, reservoir) return reservoir.fluid == nil end
    )
    local free = #__TS__ArrayFilter(
        empty,
        function(____, reservoir) return reservoir.assigned == nil end
    )
    local assigned = __TS__ArrayFilter(
        empty,
        function(____, reservoir) return reservoir.assigned ~= nil end
    )
    p:text(
        55,
        25,
        tostring(free) .. " free",
        colors.white
    )
    if #assigned == 1 then
        p:text(
            56 + #(tostring(free) .. " free"),
            25,
            __TS__StringSubstring(
                "+ 1 for " .. fluidLabel(assigned[1].assigned),
                0,
                16
            ),
            colors.gray
        )
    elseif #assigned > 1 then
        p:text(
            56 + #(tostring(free) .. " free"),
            25,
            ("+ " .. tostring(#assigned)) .. " assigned",
            colors.gray
        )
    end
    p:text(
        55,
        27,
        (("capacity known for " .. tostring(known)) .. "/") .. tostring(#reservoirs),
        colors.gray
    )
    p:text(55, 28, "(learnt when one fills)", colors.gray)
    local alerts = __TS__ArrayFilter(
        state.alerts,
        function(____, alert) return __TS__StringStartsWith(alert, "no reservoir") or __TS__StringStartsWith(alert, "stock of") end
    )
    if #alerts > 0 then
        self:title(
            p,
            55,
            31,
            "ATTENTION",
            23
        )
        local line = unpack(
            attentionLines(__TS__ObjectAssign({}, state, {alerts = alerts, waiting = {}})),
            1,
            1
        )
        if line ~= nil then
            p:text(55, 33, Glyph.up, colors.orange)
            p:text(
                57,
                33,
                __TS__StringSubstring(line.title, 0, 21),
                colors.white
            )
            p:text(
                57,
                34,
                __TS__StringSubstring(line.detail, 0, 21),
                colors.gray
            )
        end
        if #alerts > 1 then
            p:text(
                57,
                35,
                ("+ " .. tostring(#alerts - 1)) .. " more",
                colors.gray
            )
        end
    end
end
function SmelteryScreen.prototype.paintLog(self, p, state)
    self:title(
        p,
        3,
        5,
        "LOG",
        65
    )
    local lines = state.log
    local ____end = #lines - self.logOffset
    local start = math.max(0, ____end - LOG_LINES)
    __TS__ArrayForEach(
        __TS__ArraySlice(lines, start, ____end),
        function(____, raw, index)
            local line = parseLogLine(raw)
            local y = 8 + index * 2
            p:text(3, y, line.time, colors.gray)
            p:text(
                13,
                y,
                line.kind == "other" and "" or __TS__StringPadEnd(line.kind, 7),
                LOG_COLORS[line.kind]
            )
            p:text(
                21,
                y,
                __TS__StringSubstring(line.text, 0, 56),
                line.kind == "forced" and colors.red or colors.white
            )
        end
    )
    if #lines == 0 then
        p:text(3, 8, "Nothing yet.", colors.gray)
    end
end
function SmelteryScreen.prototype.paintLastAction(self, p, state)
    local last
    do
        local index = #state.log - 1
        while index >= 0 and last == nil do
            local line = state.log[index + 1]
            if line ~= nil and __TS__StringSubstring(line, 8, 11) ~= "   " then
                last = line
            end
            index = index - 1
        end
    end
    if last == nil then
        return
    end
    local line = parseLogLine(last)
    p:text(3, 36, line.time, colors.gray)
    p:text(
        12,
        36,
        __TS__StringSubstring((line.kind == "other" and "" or line.kind .. " ") .. line.text, 0, 60),
        colors.lightGray
    )
end
function SmelteryScreen.prototype.paintConfirm(self, p)
    local confirm = self.confirm
    if confirm == nil then
        return
    end
    local x = 15
    local y = 13
    local width = 49
    local height = 11
    local color = confirm.step == 2 and colors.red or colors.orange
    self:frame(
        p,
        x,
        y,
        width,
        height
    )
    p:fill(
        x,
        y,
        width + 2,
        1,
        color
    )
    p:fill(
        x,
        y + height + 1,
        width + 2,
        1,
        color
    )
    p:fill(
        x,
        y + 1,
        1,
        height,
        color
    )
    p:fill(
        x + width + 1,
        y + 1,
        1,
        height,
        color
    )
    p:fill(
        x + 1,
        y + 1,
        width,
        height,
        colors.black
    )
    local item = confirm.item
    local what = item.status == "alloy" and ("will form " .. fluidLabel(item.alloy or "an alloy")) .. "." or ("needs " .. tostring(item.temperature or "?")) .. " K: it may not melt."
    p:text(x + 3, y + 2, "FORCE INSERT", color)
    p:text(
        x + 16,
        y + 2,
        ("step " .. tostring(confirm.step)) .. " of 2",
        colors.gray
    )
    p:text(
        x + 3,
        y + 4,
        __TS__StringSubstring(
            (tostring(item.count) .. " ") .. itemLabel(item.name),
            0,
            45
        ),
        colors.white
    )
    p:text(
        x + 3,
        y + 5,
        __TS__StringSubstring(what, 0, 45),
        colors.lightGray
    )
    if confirm.step == 1 then
        p:text(x + 3, y + 7, "Check what will happen before going on.", colors.gray)
    else
        p:text(x + 3, y + 7, item.status == "alloy" and "An alloy cannot be undone." or "It stays in the Smeltery until hot enough.", colors.gray)
        p:text(
            x + 21,
            y + 10,
            tostring(math.max(
                0,
                math.ceil(confirm.deadline - os.clock())
            )) .. " s",
            colors.gray
        )
    end
end
return ____exports
