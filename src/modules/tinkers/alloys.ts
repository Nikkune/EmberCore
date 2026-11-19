export interface AlloyRecipe {
	/** Alloy fluid, e.g. 'tconstruct:molten_bronze'. */
	result: string;
	/** Every fluid the Smeltery needs at once to make it, e.g. molten copper and molten tin. */
	ingredients: string[];
}

/**
 * Prevents accidental alloys: the Smeltery alloys on its own as soon as it holds every ingredient
 * of a recipe, so the check must happen BEFORE an item goes in, not after the alloy appeared.
 */
export class AlloyGuard {
	public constructor(private readonly recipes: AlloyRecipe[]) {
	}

	/**
	 * The recipe that would form if `adding` joined the fluids already there (in the Smeltery or still
	 * melting), or undefined when adding it is safe. Only recipes `adding` is an ingredient of count: an
	 * alloy the fluids already there make on their own is not caused by it (iron next to copper and gold).
	 */
	public wouldForm(present: string[], adding: string): AlloyRecipe | undefined {
		const fluids = new Set<string>(present);
		fluids.add(adding);

		for (const recipe of this.recipes) {
			if (recipe.ingredients.length === 0 || !recipe.ingredients.includes(adding)) continue;

			let complete = true;
			for (const ingredient of recipe.ingredients) {
				if (!fluids.has(ingredient)) {
					complete = false;
					break;
				}
			}

			if (complete) return recipe;
		}

		return undefined;
	}
}
