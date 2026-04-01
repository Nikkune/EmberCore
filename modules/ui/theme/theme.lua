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
local BorderCharacters = ____types.BorderCharacters
local BorderPreset = ____types.BorderPreset
local Theme = ____types.Theme
local ThemeComponentStyles = ____types.ThemeComponentStyles
local ASCII_BORDER = {
    topLeft = "+",
    topRight = "+",
    bottomLeft = "+",
    bottomRight = "+",
    horizontal = "-",
    vertical = "|"
}
local SINGLE_BORDER = {
    topLeft = "┌",
    topRight = "┐",
    bottomLeft = "└",
    bottomRight = "┘",
    horizontal = "─",
    vertical = "│"
}
local DOUBLE_BORDER = {
    topLeft = "╔",
    topRight = "╗",
    bottomLeft = "╚",
    bottomRight = "╝",
    horizontal = "═",
    vertical = "║"
}
local COLORED_BORDER = {
    topLeft = " ",
    topRight = " ",
    bottomLeft = " ",
    bottomRight = " ",
    horizontal = " ",
    vertical = " "
}
____exports.defaultTheme = {name = "default", palette = {
    backgroundColor = colors.black,
    surface = colors.black,
    panel = colors.gray,
    text = colors.white,
    muted = colors.lightGray,
    primary = colors.blue,
    secondary = colors.cyan,
    accent = colors.orange,
    error = colors.red,
    success = colors.lime,
    warning = colors.yellow,
    info = colors.lightBlue,
    border = colors.lightGray,
    selection = colors.blue
}, borders = {ascii = ASCII_BORDER, single = SINGLE_BORDER, double = DOUBLE_BORDER, colored = COLORED_BORDER}, components = {}}
function ____exports.getBorderCharacters(self, theme, preset)
    if preset == nil then
        preset = "ascii"
    end
    return theme.borders[preset]
end
function ____exports.mergeComponentStyle(self, base, override)
    if not base and not override then
        return nil
    end
    local ____base_0 = base
    if ____base_0 == nil then
        ____base_0 = {}
    end
    return __TS__ObjectAssign({}, ____base_0, override or ({}))
end
function ____exports.mergeThemeComponentStyles(self, base, override)
    if not base and not override then
        return nil
    end
    return __TS__ObjectAssign({}, base or ({}), override or ({}))
end
return ____exports
