--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
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
-- End of Lua Library inline imports
local ____exports = {}
function ____exports.materialLabel(material)
    local name = __TS__StringSubstring(
        material,
        (string.find(material, ":", nil, true) or 0) - 1 + 1
    )
    local hash = (string.find(name, "#", nil, true) or 0) - 1
    local base = table.concat(
        __TS__StringSplit(
            hash >= 0 and __TS__StringSubstring(name, 0, hash) or name,
            "_"
        ),
        " "
    )
    local variant = hash >= 0 and table.concat(
        __TS__StringSplit(
            __TS__StringSubstring(name, hash + 1),
            "_"
        ),
        " "
    ) or ""
    return (variant == "" or variant == "default" or variant == "composite") and base or (variant .. " ") .. base
end
return ____exports
