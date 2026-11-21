import {Config}                                               from '@core/config';
import {AlloyGuard, CastAmounts, MaterialMap}                from '@modules/tinkers/index';
import type {AlloyRatio, AlloyRecipe, CastAmount, MaterialOverride} from '@modules/tinkers/index';

import {DEFAULT_CAST_AMOUNTS}                                 from './castAmountsData';
import {CAST_RECIPES}                                         from './castRecipesData';
import {DEFAULT_ALLOY_RATIOS, DEFAULT_ALLOYS, DEFAULT_MOLTEN_FLUIDS} from './catalogueData';
import {DEFAULT_FUELS, DEFAULT_MELTING_TEMPERATURES}           from './temperaturesData';
import {MELTING}                                              from './meltingData';
import type {FluidTemperature}                               from './temperaturesData';

export const CATALOGUE_PATH = '/smeltery/catalogue.db';

/**
 * What the controller knows about the modpack. Written to CATALOGUE_PATH on the first start, then
 * read from there: local changes go in that file (and later through the display), not in the code.
 */
export interface Catalogue {
	alloys: AlloyRecipe[];
	/**
	 * The same recipes with their amounts, for alloy mode. A key of its own: a catalogue file written
	 * before it existed gets the default ratios, its own `alloys` stay.
	 */
	alloyRatios: AlloyRatio[];
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
	/**
	 * Capacity of the reservoirs of a peripheral type (CC cannot read it). Only types whose blocks all
	 * hold the same: the Mini Utilities drums share one type for every tier, so they are set by hand.
	 */
	reservoirCapacities: ReservoirCapacity[];
}

export interface ReservoirCapacity {
	type: string;
	capacity: number;
}

/** Measured in game (capacity-probe, 2026-11-20). */
const DEFAULT_RESERVOIR_CAPACITIES: ReservoirCapacity[] = [
	{type: 'mob_grinding_utils:tank', capacity: 32000},
	{type: 'mob_grinding_utils:jumbo_tank', capacity: 1024000},
	{type: 'evilcraft:dark_tank', capacity: 16000},
	{type: 'industrialforegoing:common_black_hole_tank', capacity: 16000},
	{type: 'industrialforegoing:pity_black_hole_tank', capacity: 64000},
	{type: 'industrialforegoing:simple_black_hole_tank', capacity: 1024000},
];

export function defaultCatalogue(this: void): Catalogue {
	return {
		alloys:       DEFAULT_ALLOYS,
		alloyRatios:  DEFAULT_ALLOY_RATIOS,
		moltenFluids: DEFAULT_MOLTEN_FLUIDS,
		overrides:    [],
		castAmounts:  DEFAULT_CAST_AMOUNTS,

		meltingTemperatures: DEFAULT_MELTING_TEMPERATURES,
		fuels:               DEFAULT_FUELS,

		reservoirCapacities: DEFAULT_RESERVOIR_CAPACITIES,
	};
}

export function loadCatalogue(this: void, path = CATALOGUE_PATH): Catalogue {
	return Config.load(path, defaultCatalogue());
}

/** Written back when the display adds, changes or deletes an alloy recipe. */
export function saveCatalogue(this: void, catalogue: Catalogue, path = CATALOGUE_PATH): void {
	Config.save(path, catalogue);
}

/** Every fluid the catalogue names (molten fluids, alloys and their ingredients, fuels), sorted. */
export function catalogueFluids(this: void, catalogue: Catalogue): string[] {
	const fluids = new Set<string>(catalogue.moltenFluids);
	for (const ratio of catalogue.alloyRatios) {
		fluids.add(ratio.result);
		for (const input of ratio.inputs) fluids.add(input.fluid);
	}
	for (const alloy of catalogue.alloys) {
		fluids.add(alloy.result);
		for (const ingredient of alloy.ingredients) fluids.add(ingredient);
	}
	for (const fuel of catalogue.fuels) fluids.add(fuel.fluid);
	return [...fluids].sort();
}

/**
 * Fluid of an item: the catalogue's overrides first, then the melting recipes of the modpack (meltingData),
 * then its tags (forge:ingots/iron).
 */
export function materialMapOf(this: void, catalogue: Catalogue): MaterialMap {
	const overrides: MaterialOverride[] = [];
	for (const [fluid, items] of Object.entries(MELTING)) {
		for (const item of items.split(' ')) overrides.push({item, fluid});
	}
	// Set after the modpack's: an override of the catalogue wins.
	for (const override of catalogue.overrides) overrides.push(override);
	return new MaterialMap({fluids: catalogue.moltenFluids, overrides});
}

/** The catalogue's amounts (and those learnt), then the casting recipes of the modpack (castRecipesData). */
export function castAmountsOf(this: void, catalogue: Catalogue): CastAmounts {
	return new CastAmounts(catalogue.castAmounts, CAST_RECIPES);
}

export function temperatureMap(this: void, temperatures: FluidTemperature[]): Map<string, number> {
	const map = new Map<string, number>();
	for (const entry of temperatures) map.set(entry.fluid, entry.temperature);
	return map;
}

export function alloyGuardOf(this: void, catalogue: Catalogue): AlloyGuard {
	return new AlloyGuard(catalogue.alloys);
}
