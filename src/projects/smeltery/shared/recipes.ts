import type {AlloyRatio, AlloyRecipe} from '@modules/tinkers/index';

import {MAX_INGREDIENTS}               from './protocol';

/**
 * Editing the alloy recipes of the catalogue. Pure functions, shared by the display (to check a recipe
 * before sending it) and the controller (which checks again, then saves).
 *
 * The catalogue keeps each recipe twice: in `alloyRatios` (with amounts, for alloy mode) and in `alloys`
 * (ingredients only, for the guard that keeps alloys from forming). An edit changes both together.
 */
export interface AlloyRecipes {
	alloys: AlloyRecipe[];
	alloyRatios: AlloyRatio[];
}

/** Why a recipe cannot be saved, or undefined when it can. */
export function recipeProblem(this: void, recipe: AlloyRatio): string | undefined {
	if (typeof recipe.result !== 'string' || recipe.result === '') return 'choose the result';
	if (!(recipe.amount > 0) || recipe.amount % 1 !== 0) return 'the result amount must be positive';
	if (recipe.inputs.length < 2) return 'at least 2 ingredients';
	if (recipe.inputs.length > MAX_INGREDIENTS) return `at most ${MAX_INGREDIENTS} ingredients`;

	const seen = new Set<string>();
	for (const input of recipe.inputs) {
		if (typeof input.fluid !== 'string' || input.fluid === '') return 'choose every ingredient';
		if (!(input.amount > 0) || input.amount % 1 !== 0) return 'every amount must be positive';
		if (input.fluid === recipe.result) return 'the result cannot be an ingredient';
		if (seen.has(input.fluid)) return 'an ingredient is there twice';
		seen.add(input.fluid);
	}

	return undefined;
}

function sameIngredients(this: void, alloy: AlloyRecipe, ratio: AlloyRatio): boolean {
	if (alloy.result !== ratio.result || alloy.ingredients.length !== ratio.inputs.length) return false;
	return ratio.inputs.every((input) => alloy.ingredients.includes(input.fluid));
}

function guardRecipeOf(this: void, ratio: AlloyRatio): AlloyRecipe {
	return {result: ratio.result, ingredients: ratio.inputs.map((input) => input.fluid).sort()};
}

function copyRatio(this: void, ratio: AlloyRatio): AlloyRatio {
	return {result: ratio.result, amount: ratio.amount, inputs: ratio.inputs.map((input) => ({fluid: input.fluid, amount: input.amount}))};
}

/** Removes the guard recipe matching `ratio` (the first one), unless another ratio still needs it. */
function dropGuard(this: void, recipes: AlloyRecipes, ratio: AlloyRatio): void {
	const guard = guardRecipeOf(ratio);
	if (recipes.alloyRatios.some((other) => other !== ratio && sameIngredients(guard, other))) return;
	const index = recipes.alloys.findIndex((alloy) => sameIngredients(alloy, ratio));
	if (index >= 0) recipes.alloys.splice(index, 1);
}

/** Adds a guard recipe for `ratio` unless the same one is already there. */
function addGuard(this: void, recipes: AlloyRecipes, ratio: AlloyRatio): void {
	if (!recipes.alloys.some((alloy) => sameIngredients(alloy, ratio))) recipes.alloys.push(guardRecipeOf(ratio));
}

/** Checks that `index` still holds a recipe of `expected` (the display may have shown an older catalogue). */
export function checkIndex(this: void, recipes: AlloyRecipes, index: number, expected: string | undefined): string | undefined {
	const current = recipes.alloyRatios[index];
	if (index % 1 !== 0 || current === undefined) return `no recipe #${index + 1}`;
	if (expected !== undefined && current.result !== expected) return 'the catalogue changed meanwhile: try again';
	return undefined;
}

/**
 * Adds `recipe` (index undefined) or replaces the one at `index`, in both lists. Returns the index of
 * the saved recipe. The recipe must have been checked (recipeProblem, checkIndex).
 */
export function saveRecipe(this: void, recipes: AlloyRecipes, recipe: AlloyRatio, index?: number): number {
	const saved = copyRatio(recipe);

	if (index === undefined) {
		recipes.alloyRatios.push(saved);
		addGuard(recipes, saved);
		return recipes.alloyRatios.length - 1;
	}

	const old = recipes.alloyRatios[index]!;
	dropGuard(recipes, old);
	recipes.alloyRatios[index] = saved;
	addGuard(recipes, saved);
	return index;
}

/** Deletes the recipe at `index` from both lists. Returns it. */
export function deleteRecipe(this: void, recipes: AlloyRecipes, index: number): AlloyRatio {
	const old = recipes.alloyRatios[index]!;
	dropGuard(recipes, old);
	recipes.alloyRatios.splice(index, 1);
	return old;
}
