--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
function ____exports.createArray(self, length, factory)
    local result = {}
    do
        local index = 0
        while index < length do
            result[#result + 1] = factory(nil, index)
            index = index + 1
        end
    end
    return result
end
function ____exports.createFilledArray(self, length, value)
    return ____exports.createArray(
        nil,
        length,
        function() return value end
    )
end
return ____exports
