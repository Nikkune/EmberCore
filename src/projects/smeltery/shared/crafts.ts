import {COMPOSITE_MATERIALS, COMPOSITE_PARTS, CRAFT_RECIPES} from './craftRecipesData';

/** A casting onto an item, for the craft table and basin. */
export interface CraftRecipe {
	kind: string;
	/** The item on the caster ('minecraft:apple', '#minecraft:planks'), '' for the empty table. */
	input: string;
	fluid: string;
	/** mB of one casting. */
	amount: number;
	result: string;
	/** The item is used up by each casting. */
	consumed: boolean;
	/** Composite casting: the material the part becomes ('tconstruct:nahuatl')... */
	material?: string;
	/** ...and the one it must be made of ('tconstruct:wood'): the table refuses the fluid otherwise. */
	from?: string;
}

/** How many recipes craftRecipeAt knows: those of CRAFT_RECIPES, then every part with every composite. */
export function craftRecipeCount(this: void): number {
	return CRAFT_RECIPES.length + COMPOSITE_PARTS.length * COMPOSITE_MATERIALS.length;
}

/**
 * The recipe at an index (what QueueCraftRequest names): CRAFT_RECIPES first, then the composite castings,
 * part by part (a wooden tool handle and 1000 mB of obsidian make a nahuatl tool handle). Undefined past the end.
 */
export function craftRecipeAt(this: void, index: number): CraftRecipe | undefined {
	if (index % 1 !== 0 || index < 0 || index >= craftRecipeCount()) return undefined;

	const plain = CRAFT_RECIPES[index];
	if (plain !== undefined) {
		const [kind, input, fluid, amount, result, consumed] = plain;
		return {kind, input, fluid, amount, result, consumed};
	}

	const rest      = index - CRAFT_RECIPES.length;
	const part      = COMPOSITE_PARTS[Math.floor(rest / COMPOSITE_MATERIALS.length)];
	const composite = COMPOSITE_MATERIALS[rest % COMPOSITE_MATERIALS.length];
	if (part === undefined || composite === undefined) return undefined;

	const [item, cost]             = part;
	const [from, fluid, unit, to] = composite;
	// The part leaves the cast slot as the same item in the new material.
	return {kind: 'table', input: item, fluid, amount: unit * cost, result: item, consumed: true, material: to, from};
}
