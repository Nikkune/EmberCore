import {Config}                                               from '@core/config';
import {AlloyGuard, CastAmounts, MaterialMap}                from '@modules/tinkers/index';
import type {AlloyRecipe, CastAmount, MaterialOverride}      from '@modules/tinkers/index';

import {DEFAULT_CAST_AMOUNTS}                                 from './castAmountsData';
import {DEFAULT_ALLOYS, DEFAULT_MOLTEN_FLUIDS}                from './catalogueData';
import {DEFAULT_FUELS, DEFAULT_MELTING_TEMPERATURES}           from './temperaturesData';
import type {FluidTemperature}                               from './temperaturesData';

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
	/** Fluid one casting needs, per cast format (and per fluid when it differs). */
	castAmounts: CastAmount[];
	/** Temperature the Smeltery needs to melt items into each fluid. */
	meltingTemperatures: FluidTemperature[];
	/** Temperature each fuel gives. */
	fuels: FluidTemperature[];
}

export function defaultCatalogue(this: void): Catalogue {
	return {
		alloys:       DEFAULT_ALLOYS,
		moltenFluids: DEFAULT_MOLTEN_FLUIDS,
		overrides:    [],
		castAmounts:  DEFAULT_CAST_AMOUNTS,

		meltingTemperatures: DEFAULT_MELTING_TEMPERATURES,
		fuels:               DEFAULT_FUELS,
	};
}

export function loadCatalogue(this: void, path = CATALOGUE_PATH): Catalogue {
	return Config.load(path, defaultCatalogue());
}

export function materialMapOf(this: void, catalogue: Catalogue): MaterialMap {
	return new MaterialMap({fluids: catalogue.moltenFluids, overrides: catalogue.overrides});
}

export function castAmountsOf(this: void, catalogue: Catalogue): CastAmounts {
	return new CastAmounts(catalogue.castAmounts);
}

export function temperatureMap(this: void, temperatures: FluidTemperature[]): Map<string, number> {
	const map = new Map<string, number>();
	for (const entry of temperatures) map.set(entry.fluid, entry.temperature);
	return map;
}

export function alloyGuardOf(this: void, catalogue: Catalogue): AlloyGuard {
	return new AlloyGuard(catalogue.alloys);
}
