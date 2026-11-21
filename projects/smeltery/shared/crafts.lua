--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local ____craftRecipesData = require("projects.smeltery.shared.craftRecipesData")
local COMPOSITE_MATERIALS = ____craftRecipesData.COMPOSITE_MATERIALS
local COMPOSITE_PARTS = ____craftRecipesData.COMPOSITE_PARTS
local CRAFT_RECIPES = ____craftRecipesData.CRAFT_RECIPES
function ____exports.craftRecipeCount()
    return #CRAFT_RECIPES + #COMPOSITE_PARTS * #COMPOSITE_MATERIALS
end
function ____exports.craftRecipeAt(index)
    if index % 1 ~= 0 or index < 0 or index >= ____exports.craftRecipeCount() then
        return nil
    end
    local plain = CRAFT_RECIPES[index + 1]
    if plain ~= nil then
        local kind, input, fluid, amount, result, consumed = unpack(plain, 1, 6)
        return {
            kind = kind,
            input = input,
            fluid = fluid,
            amount = amount,
            result = result,
            consumed = consumed
        }
    end
    local rest = index - #CRAFT_RECIPES
    local part = COMPOSITE_PARTS[math.floor(rest / #COMPOSITE_MATERIALS) + 1]
    local composite = COMPOSITE_MATERIALS[rest % #COMPOSITE_MATERIALS + 1]
    if part == nil or composite == nil then
        return nil
    end
    local item, cost = unpack(part, 1, 2)
    local from, fluid, unit, to = unpack(composite, 1, 4)
    return {
        kind = "table",
        input = item,
        fluid = fluid,
        amount = unit * cost,
        result = item,
        consumed = true,
        material = to,
        from = from
    }
end
return ____exports
