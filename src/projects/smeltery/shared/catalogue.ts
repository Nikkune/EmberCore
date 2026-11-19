import {Config}                                  from '@core/config';
import {AlloyGuard, MaterialMap}                 from '@modules/tinkers/index';
import type {AlloyRecipe, MaterialOverride}      from '@modules/tinkers/index';

import {DEFAULT_ALLOYS, DEFAULT_MOLTEN_FLUIDS}   from './catalogueData';

export const CATALOGUE_PATH = '/smeltery/catalogue.db';

/**
 * What the controller knows about the modpack. Written to CATALOGUE_PATH on the first start, then
 * read from there: local changes go in that file (and later through the display), not in the code.
 */
export interface Catalogue {
	alloys: AlloyRecipe[];
	/** Molten fluids that exist: an item melts into one of them or is left in the input. */
	moltenFluids: string[];
	/** Items whose fluid their tags do not tell. */
	overrides: MaterialOverride[];
}

export function defaultCatalogue(this: void): Catalogue {
	return {
		alloys:       DEFAULT_ALLOYS,
		moltenFluids: DEFAULT_MOLTEN_FLUIDS,
		overrides:    [],
	};
}

export function loadCatalogue(this: void, path = CATALOGUE_PATH): Catalogue {
	return Config.load(path, defaultCatalogue());
}

export function materialMapOf(this: void, catalogue: Catalogue): MaterialMap {
	return new MaterialMap({fluids: catalogue.moltenFluids, overrides: catalogue.overrides});
}

export function alloyGuardOf(this: void, catalogue: Catalogue): AlloyGuard {
	return new AlloyGuard(catalogue.alloys);
}
