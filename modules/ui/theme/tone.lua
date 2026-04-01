--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
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
local ____types = require("modules.ui.types.index")
local Color = ____types.Color
local ColorStyle = ____types.ColorStyle
local MaybeProps = ____types.MaybeProps
local Theme = ____types.Theme
local Tone = ____types.Tone
local ____helpers = require("utils.helpers")
local createOptions = ____helpers.createOptions
function ____exports.makeColors(self, style)
    return createOptions(nil, {}):with("backgroundColor", style.backgroundColor):with("foregroundColor", style.foregroundColor):done()
end
function ____exports.resolveToneColors(self, theme, tone)
    repeat
        local ____switch3 = tone
        local ____cond3 = ____switch3 == "primary"
        if ____cond3 then
            return {backgroundColor = theme.palette.primary, foregroundColor = theme.palette.text}
        end
        ____cond3 = ____cond3 or ____switch3 == "success"
        if ____cond3 then
            return {backgroundColor = theme.palette.success, foregroundColor = theme.palette.text}
        end
        ____cond3 = ____cond3 or ____switch3 == "warning"
        if ____cond3 then
            return {backgroundColor = theme.palette.warning, foregroundColor = theme.palette.text}
        end
        ____cond3 = ____cond3 or ____switch3 == "info"
        if ____cond3 then
            return {backgroundColor = theme.palette.info, foregroundColor = theme.palette.text}
        end
        ____cond3 = ____cond3 or ____switch3 == "error"
        if ____cond3 then
            return {backgroundColor = theme.palette.error, foregroundColor = theme.palette.text}
        end
        ____cond3 = ____cond3 or ____switch3 == "default"
        do
            return {backgroundColor = theme.palette.surface, foregroundColor = theme.palette.text}
        end
    until true
end
function ____exports.makeToneColorOverride(self, tone, theme, foregroundColor, backgroundColor)
    local toneColors = ____exports.resolveToneColors(nil, theme, tone)
    return ____exports.makeColors(nil, {foregroundColor = foregroundColor or toneColors.foregroundColor, backgroundColor = backgroundColor or toneColors.backgroundColor})
end
function ____exports.applyTone(self, style, theme, tone)
    local toneColors = ____exports.resolveToneColors(nil, theme, tone)
    return __TS__ObjectAssign({}, toneColors, style)
end
return ____exports
