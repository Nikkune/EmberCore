--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__StringSlice(self, start, ____end)
    if start == nil or start ~= start then
        start = 0
    end
    if ____end ~= ____end then
        ____end = 0
    end
    if start >= 0 then
        start = start + 1
    end
    if ____end ~= nil and ____end < 0 then
        ____end = ____end - 1
    end
    return string.sub(self, start, ____end)
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

local function __TS__ArrayPushArray(self, items)
    local len = #self
    for i = 1, #items do
        len = len + 1
        self[len] = items[i]
    end
    return len
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

local function __TS__ArrayMap(self, callbackfn, thisArg)
    local result = {}
    for i = 1, #self do
        result[i] = callbackfn(thisArg, self[i], i - 1, self)
    end
    return result
end
-- End of Lua Library inline imports
local ____exports = {}
local ____ui = require("modules.ui.index")
local makeColors = ____ui.makeColors
local UIDrawSurface = ____ui.UIDrawSurface
local ____types = require("modules.ui.types.index")
local BorderCharacters = ____types.BorderCharacters
local BoxStyle = ____types.BoxStyle
local Color = ____types.Color
local Insets = ____types.Insets
local PaddingLike = ____types.PaddingLike
local Point = ____types.Point
local Rect = ____types.Rect
local RenderContext = ____types.RenderContext
local TextStyle = ____types.TextStyle
local TextWrap = ____types.TextWrap
local ____string = require("modules.ui.utils.string")
local splitWords = ____string.splitWords
local ____helpers = require("utils.helpers")
local createOptions = ____helpers.createOptions
function ____exports.intersectRects(self, a, b)
    local x = math.max(a.x, b.x)
    local y = math.max(a.y, b.y)
    local right = math.min(a.x + a.width - 1, b.x + b.width - 1)
    local bottom = math.min(a.y + a.height - 1, b.y + b.height - 1)
    local width = right - x + 1
    local height = bottom - y + 1
    if width <= 0 or height <= 0 then
        return nil
    end
    return {x = x, y = y, width = width, height = height}
end
function ____exports.fillRect(self, draw, options)
    local ____options_clipRect_22
    if options.clipRect then
        ____options_clipRect_22 = ____exports.intersectRects(nil, options.rect, options.clipRect)
    else
        ____options_clipRect_22 = options.rect
    end
    local targetRect = ____options_clipRect_22
    if not targetRect or targetRect.width <= 0 or targetRect.height <= 0 then
        return
    end
    draw:fillRect(targetRect, options.character or " ", options.backgroundColor, options.foregroundColor)
end
____exports["repeat"] = function(self, value, count)
    if count <= 0 or #value == 0 then
        return ""
    end
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
function ____exports.containsPoint(self, rect, point)
    return point.x >= rect.x and point.y >= rect.y and point.x < rect.x + rect.width and point.y < rect.y + rect.height
end
function ____exports.rectRight(self, rect)
    return rect.x + rect.width - 1
end
function ____exports.rectBottom(self, rect)
    return rect.y + rect.height - 1
end
function ____exports.normalizeInsets(self, value)
    if value == nil then
        return {top = 0, right = 0, bottom = 0, left = 0}
    end
    if type(value) == "number" then
        return {top = value, right = value, bottom = value, left = value}
    end
    local horizontal = 0
    local vertical = 0
    if value.horizontal ~= nil then
        horizontal = value.horizontal or 0
    end
    if value.vertical ~= nil then
        vertical = value.vertical or 0
    end
    if value.x ~= nil then
        horizontal = value.x or 0
    end
    if value.y ~= nil then
        vertical = value.y or 0
    end
    local result = {top = vertical, right = horizontal, bottom = vertical, left = horizontal}
    if value.top ~= nil then
        result.top = value.top or 0
    end
    if value.right ~= nil then
        result.right = value.right or 0
    end
    if value.bottom ~= nil then
        result.bottom = value.bottom or 0
    end
    if value.left ~= nil then
        result.left = value.left or 0
    end
    return result
end
function ____exports.shrinkRect(self, rect, insets)
    local top = insets.top or 0
    local right = insets.right or 0
    local bottom = insets.bottom or 0
    local left = insets.left or 0
    local width = math.max(0, rect.width - left - right)
    local height = math.max(0, rect.height - top - bottom)
    return {x = rect.x + left, y = rect.y + top, width = width, height = height}
end
function ____exports.expandRect(self, rect, insets)
    local top = insets.top or 0
    local right = insets.right or 0
    local bottom = insets.bottom or 0
    local left = insets.left or 0
    return {x = rect.x - left, y = rect.y - top, width = rect.width + left + right, height = rect.height + top + bottom}
end
function ____exports.getInnerRect(self, rect, style)
    local result = rect
    local ____opt_0 = style and style.border
    if ____opt_0 and ____opt_0.enabled then
        result = ____exports.shrinkRect(nil, result, {top = 1, right = 1, bottom = 1, left = 1})
    end
    if (style and style.padding) ~= nil then
        result = ____exports.shrinkRect(
            nil,
            result,
            ____exports.normalizeInsets(nil, style.padding)
        )
    end
    return result
end
function ____exports.clipText(self, text, maxWidth)
    if maxWidth <= 0 or #text == 0 then
        return ""
    end
    if #text <= maxWidth then
        return text
    end
    return __TS__StringSlice(text, 0, maxWidth)
end
function ____exports.applyEllipsis(self, text, maxWidth)
    if maxWidth <= 0 then
        return ""
    end
    if #text <= maxWidth then
        return text
    end
    if maxWidth == 1 then
        return "…"
    end
    return __TS__StringSlice(text, 0, maxWidth - 1) .. "…"
end
function ____exports.alignText(self, text, width, alignment)
    if alignment == nil then
        alignment = "left"
    end
    if width <= 0 then
        return ""
    end
    local clipped = ____exports.clipText(nil, text, width)
    if #clipped >= width then
        return clipped
    end
    local remaining = width - #clipped
    if alignment == "right" then
        return ____exports["repeat"](nil, " ", remaining) .. clipped
    end
    if alignment == "center" then
        local left = math.floor(remaining / 2)
        local right = remaining - left
        return (____exports["repeat"](nil, " ", left) .. clipped) .. ____exports["repeat"](nil, " ", right)
    end
    return clipped .. ____exports["repeat"](nil, " ", remaining)
end
function ____exports.clipTextToRect(self, position, text, clipRect)
    if #text == 0 then
        return nil
    end
    if position.y < clipRect.y or position.y >= clipRect.y + clipRect.height then
        return nil
    end
    local textStart = position.x
    local textEnd = position.x + #text - 1
    local clipStart = clipRect.x
    local clipEnd = clipRect.x + clipRect.width - 1
    if textEnd < clipStart or textStart > clipEnd then
        return nil
    end
    local startOffset = math.max(0, clipStart - textStart)
    local visibleStart = textStart + startOffset
    local visibleWidth = clipEnd - visibleStart + 1
    if visibleWidth <= 0 then
        return nil
    end
    return {
        text = __TS__StringSlice(text, startOffset, startOffset + visibleWidth),
        startOffset = startOffset
    }
end
function ____exports.drawTextLine(self, draw, options)
    if options.width <= 0 or #options.text == 0 then
        return
    end
    local ____opt_6 = options.style
    local alignment = ____opt_6 and ____opt_6.alignment or "left"
    local aligned = ____exports.alignText(nil, options.text, options.width, alignment)
    local clipRect = options.clipRect
    local ____makeColors_13 = makeColors
    local ____opt_8 = options.style
    local ____temp_12 = ____opt_8 and ____opt_8.foregroundColor
    local ____opt_10 = options.style
    local withColorsOptions = ____makeColors_13(nil, {foregroundColor = ____temp_12, backgroundColor = ____opt_10 and ____opt_10.backgroundColor})
    if clipRect then
        local clipped = ____exports.clipTextToRect(nil, options.position, aligned, clipRect)
        if not clipped then
            return
        end
        draw:withColors(
            withColorsOptions,
            function()
                draw:writeAt({x = options.position.x + clipped.startOffset, y = options.position.y}, clipped.text)
            end
        )
        return
    end
    draw:withColors(
        withColorsOptions,
        function()
            draw:writeAt(options.position, aligned)
        end
    )
end
function ____exports.splitLines(self, text)
    return __TS__StringSplit(text, "\n")
end
local function pushWrappedLine(self, lines, text, sourceLineIndex)
    lines[#lines + 1] = {text = text, sourceLineIndex = sourceLineIndex}
end
function ____exports.wrapLineByCharacter(self, text, width)
    if width <= 0 then
        return {}
    end
    if #text == 0 then
        return {""}
    end
    local result = {}
    local index = 0
    while index < #text do
        result[#result + 1] = __TS__StringSlice(text, index, index + width)
        index = index + width
    end
    return result
end
function ____exports.wrapLineByWord(self, text, width)
    if width <= 0 then
        return {}
    end
    if #text == 0 then
        return {""}
    end
    local result = {}
    local words = splitWords(nil, text)
    if #words == 0 then
        return {""}
    end
    local current = ""
    for ____, word in ipairs(words) do
        do
            if #current == 0 then
                if #word <= width then
                    current = word
                    goto __continue60
                end
                local chunks = ____exports.wrapLineByCharacter(nil, word, width)
                __TS__ArrayPushArray(result, chunks)
                goto __continue60
            end
            local candidate = (current .. " ") .. word
            if #candidate <= width then
                current = candidate
                goto __continue60
            end
            result[#result + 1] = current
            if #word <= width then
                current = word
                goto __continue60
            end
            local chunks = ____exports.wrapLineByCharacter(nil, word, width)
            __TS__ArrayPushArray(
                result,
                __TS__ArraySlice(
                    chunks,
                    0,
                    math.max(0, #chunks - 1)
                )
            )
            current = chunks[#chunks] or ""
        end
        ::__continue60::
    end
    if #current > 0 or #result == 0 then
        result[#result + 1] = current
    end
    return result
end
function ____exports.wrapText(self, text, width, wrap)
    if wrap == nil then
        wrap = "none"
    end
    if width <= 0 then
        return {}
    end
    local sourceLines = ____exports.splitLines(nil, text)
    local result = {}
    do
        local sourceLineIndex = 0
        while sourceLineIndex < #sourceLines do
            do
                local sourceLine = sourceLines[sourceLineIndex + 1]
                if wrap == "none" then
                    pushWrappedLine(nil, result, sourceLine, sourceLineIndex)
                    goto __continue70
                end
                local wrappedLines = wrap == "word" and ____exports.wrapLineByWord(nil, sourceLine, width) or ____exports.wrapLineByCharacter(nil, sourceLine, width)
                if #wrappedLines == 0 then
                    pushWrappedLine(nil, result, "", sourceLineIndex)
                    goto __continue70
                end
                for ____, line in ipairs(wrappedLines) do
                    pushWrappedLine(nil, result, line, sourceLineIndex)
                end
            end
            ::__continue70::
            sourceLineIndex = sourceLineIndex + 1
        end
    end
    return result
end
function ____exports.resolveTextLines(self, options)
    local width = options.width
    local height = options.height
    local style = options.style
    local wrap = style and style.wrap or "none"
    local ____temp_18 = style and style.ellipsis
    if ____temp_18 == nil then
        ____temp_18 = false
    end
    local ellipsis = ____temp_18
    if width <= 0 then
        return {}
    end
    local lines = ____exports.wrapText(nil, options.text, width, wrap)
    if wrap == "none" then
        lines = __TS__ArrayMap(
            lines,
            function(____, line) return __TS__ObjectAssign(
                {},
                line,
                {text = ellipsis and ____exports.applyEllipsis(nil, line.text, width) or ____exports.clipText(nil, line.text, width)}
            ) end
        )
    end
    if height ~= nil and height >= 0 and #lines > height then
        lines = __TS__ArraySlice(lines, 0, height)
        if ellipsis and height > 0 then
            local lastIndex = #lines - 1
            local lastLine = lines[lastIndex + 1]
            if lastLine then
                lines[lastIndex + 1] = __TS__ObjectAssign(
                    {},
                    lastLine,
                    {text = ____exports.applyEllipsis(nil, lastLine.text, width)}
                )
            end
        end
    end
    return lines
end
function ____exports.drawText(self, context, options)
    local draw = context.draw
    local style = options.style
    local clipRect = options.clipRect
    if options.rect.width <= 0 or options.rect.height <= 0 then
        return
    end
    local ____clipRect_19
    if clipRect then
        ____clipRect_19 = ____exports.intersectRects(nil, options.rect, clipRect)
    else
        ____clipRect_19 = options.rect
    end
    local targetRect = ____clipRect_19
    if not targetRect then
        return
    end
    if options.fillBackground and (style and style.backgroundColor) ~= nil then
        ____exports.fillRect(
            nil,
            draw,
            createOptions(nil, {rect = options.rect, backgroundColor = style.backgroundColor}):with("clipRect", clipRect):done()
        )
    end
    local lines = ____exports.resolveTextLines(
        nil,
        createOptions(nil, {text = options.text, width = options.rect.width, height = options.rect.height}):with("style", style):done()
    )
    local maxLines = math.min(#lines, options.rect.height)
    do
        local index = 0
        while index < maxLines do
            ____exports.drawTextLine(
                nil,
                draw,
                createOptions(nil, {position = {x = options.rect.x, y = options.rect.y + index}, width = options.rect.width, text = lines[index + 1].text}):with("style", style):with("clipRect", clipRect):done()
            )
            index = index + 1
        end
    end
end
function ____exports.drawHorizontalLine(self, draw, position, width, character, foregroundColor, backgroundColor, clipRect)
    ____exports.drawTextLine(
        nil,
        draw,
        createOptions(
            nil,
            {
                position = position,
                width = width,
                text = ____exports["repeat"](nil, character, width),
                style = makeColors(nil, {foregroundColor = foregroundColor, backgroundColor = backgroundColor})
            }
        ):with("clipRect", clipRect):done()
    )
end
function ____exports.drawVerticalLine(self, draw, position, height, character, foregroundColor, backgroundColor, clipRect)
    do
        local index = 0
        while index < height do
            ____exports.drawTextLine(
                nil,
                draw,
                createOptions(
                    nil,
                    {
                        position = {x = position.x, y = position.y + index},
                        width = 1,
                        text = character,
                        style = makeColors(nil, {foregroundColor = foregroundColor, backgroundColor = backgroundColor})
                    }
                ):with("clipRect", clipRect):done()
            )
            index = index + 1
        end
    end
end
function ____exports.drawBorder(self, draw, options)
    local ____options_23 = options
    local rect = ____options_23.rect
    local border = ____options_23.border
    local foregroundColor = ____options_23.foregroundColor
    local backgroundColor = ____options_23.backgroundColor
    local clipRect = ____options_23.clipRect
    if rect.width <= 0 or rect.height <= 0 then
        return
    end
    if rect.width == 1 and rect.height == 1 then
        ____exports.drawTextLine(
            nil,
            draw,
            createOptions(
                nil,
                {
                    position = {x = rect.x, y = rect.y},
                    width = 1,
                    text = border.topLeft,
                    style = makeColors(nil, {foregroundColor = foregroundColor, backgroundColor = backgroundColor})
                }
            ):with("clipRect", clipRect):done()
        )
        return
    end
    if rect.height == 1 then
        local middleWidth = math.max(0, rect.width - 2)
        local top = rect.width == 1 and border.topLeft or (border.topLeft .. ____exports["repeat"](nil, border.horizontal, middleWidth)) .. border.topRight
        ____exports.drawTextLine(
            nil,
            draw,
            createOptions(
                nil,
                {
                    position = {x = rect.x, y = rect.y},
                    width = rect.width,
                    text = top,
                    style = makeColors(nil, {foregroundColor = foregroundColor, backgroundColor = backgroundColor})
                }
            ):with("clipRect", clipRect):done()
        )
        return
    end
    local top = rect.width == 1 and border.vertical or (border.topLeft .. ____exports["repeat"](
        nil,
        border.horizontal,
        math.max(0, rect.width - 2)
    )) .. border.topRight
    local bottom = rect.width == 1 and border.vertical or (border.bottomLeft .. ____exports["repeat"](
        nil,
        border.horizontal,
        math.max(0, rect.width - 2)
    )) .. border.bottomRight
    ____exports.drawTextLine(
        nil,
        draw,
        createOptions(
            nil,
            {
                position = {x = rect.x, y = rect.y},
                width = rect.width,
                text = top,
                style = makeColors(nil, {foregroundColor = foregroundColor, backgroundColor = backgroundColor})
            }
        ):with("clipRect", clipRect):done()
    )
    ____exports.drawTextLine(
        nil,
        draw,
        createOptions(
            nil,
            {
                position = {x = rect.x, y = rect.y + rect.height - 1},
                width = rect.width,
                text = bottom,
                style = makeColors(nil, {foregroundColor = foregroundColor, backgroundColor = backgroundColor})
            }
        ):with("clipRect", clipRect):done()
    )
    do
        local row = 1
        while row < rect.height - 1 do
            do
                if rect.width == 1 then
                    ____exports.drawTextLine(
                        nil,
                        draw,
                        createOptions(
                            nil,
                            {
                                position = {x = rect.x, y = rect.y + row},
                                width = 1,
                                text = border.vertical,
                                style = makeColors(nil, {foregroundColor = foregroundColor, backgroundColor = backgroundColor})
                            }
                        ):with("clipRect", clipRect):done()
                    )
                    goto __continue99
                end
                ____exports.drawTextLine(
                    nil,
                    draw,
                    createOptions(
                        nil,
                        {
                            position = {x = rect.x, y = rect.y + row},
                            width = 1,
                            text = border.vertical,
                            style = makeColors(nil, {foregroundColor = foregroundColor, backgroundColor = backgroundColor})
                        }
                    ):with("clipRect", clipRect):done()
                )
                ____exports.drawTextLine(
                    nil,
                    draw,
                    createOptions(
                        nil,
                        {
                            position = {x = rect.x + rect.width - 1, y = rect.y + row},
                            width = 1,
                            text = border.vertical,
                            style = makeColors(nil, {foregroundColor = foregroundColor, backgroundColor = backgroundColor})
                        }
                    ):with("clipRect", clipRect):done()
                )
            end
            ::__continue99::
            row = row + 1
        end
    end
end
function ____exports.drawBox(self, draw, options)
    local style = options.style
    local backgroundColor = style and style.backgroundColor
    local foregroundColor = style and style.foregroundColor
    local borderStyle = style and style.border
    if backgroundColor ~= nil then
        ____exports.fillRect(
            nil,
            draw,
            createOptions(nil, {rect = options.rect, backgroundColor = backgroundColor}):with("foregroundColor", foregroundColor):with("clipRect", options.clipRect):done()
        )
    end
    if borderStyle and borderStyle.enabled and options.borderCharacters then
        ____exports.drawBorder(
            nil,
            draw,
            createOptions(nil, {rect = options.rect, border = options.borderCharacters}):with("clipRect", options.clipRect):with("backgroundColor", borderStyle.backgroundColor or backgroundColor):with("foregroundColor", borderStyle.foregroundColor or foregroundColor):done()
        )
    end
    return ____exports.getInnerRect(nil, options.rect, style)
end
function ____exports.resolveVisibleRect(self, rect, clipRect)
    local ____clipRect_32
    if clipRect then
        ____clipRect_32 = ____exports.intersectRects(nil, rect, clipRect)
    else
        ____clipRect_32 = rect
    end
    return ____clipRect_32
end
return ____exports
