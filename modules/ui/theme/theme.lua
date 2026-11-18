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
local function ccChar(self, pixels)
    return string.char(128 + pixels)
end
local SINGLE_BORDER = {
    topLeft = ccChar(nil, 1 + 2 + 4 + 16),
    topRight = ccChar(nil, 4 + 16),
    bottomLeft = ccChar(nil, 2 + 8),
    bottomRight = ccChar(nil, 1 + 4),
    horizontal = ccChar(nil, 1 + 2),
    vertical = ccChar(nil, 1 + 4 + 16),
    top = ccChar(nil, 1 + 2),
    bottom = ccChar(nil, 1 + 2 + 4 + 8),
    left = ccChar(nil, 1 + 4 + 16),
    right = ccChar(nil, 1 + 4 + 16),
    inverted = {
        "topRight",
        "bottomLeft",
        "bottomRight",
        "bottom",
        "right"
    },
    rule = ccChar(nil, 4 + 8),
    columnRule = ccChar(nil, 1 + 4 + 16)
}
local DOUBLE_BORDER = {
    topLeft = "#",
    topRight = "#",
    bottomLeft = "#",
    bottomRight = "#",
    horizontal = "=",
    vertical = "H"
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
function ____exports.withAsciiBorders(self, theme)
    return __TS__ObjectAssign(
        {},
        theme,
        {borders = __TS__ObjectAssign({}, theme.borders, {single = ASCII_BORDER, double = ASCII_BORDER})}
    )
end
function ____exports.getRuleCharacter(self, theme)
    return theme.borders.single.rule or theme.borders.single.horizontal
end
function ____exports.getColumnRuleCharacter(self, theme)
    return theme.borders.single.columnRule or theme.borders.single.vertical
end
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
