--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
____exports.REPLY_TYPE = "reply"
function ____exports.isEnvelope(value)
    if type(value) ~= "table" then
        return false
    end
    local message = value
    return message.net == 1 and type(message.type) == "string"
end
return ____exports
