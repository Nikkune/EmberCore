--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
function ____exports.assignIfDefined(self, target, key, value)
    if value ~= nil then
        target[key] = value
    end
end
function ____exports.withDefined(self, target, key, value)
    ____exports.assignIfDefined(nil, target, key, value)
    return target
end
function ____exports.createOptions(self, base)
    return {
        with = function(self, key, value)
            ____exports.withDefined(nil, base, key, value)
            return self
        end,
        done = function(self)
            return base
        end
    }
end
return ____exports
