import {Inventory}                 from '@core/inventory';
import type {ItemSummary}          from '@core/inventory';
import {Tank}                      from '@core/tank';

import {CastAmounts}               from './fluidValues';
import type {CastFormat}           from './fluidValues';
import type {Smeltery}             from './smeltery';

export type CasterKind = 'table' | 'basin';

/**
 * idle:    empty, ready to receive fluid;
 * busy:    holds fluid (filling or cooling);
 * blocked: the result waits in the output slot, nothing can be cast until it is collected.
 */
export type CasterStatus = 'idle' | 'busy' | 'blocked';

export interface CasterState {
	status: CasterStatus;
	/** Item used as a cast (slot 1), if any. */
	cast?: string;
	/** What one casting produces; undefined when it cannot be told (a table without a cast). */
	format?: CastFormat;
	fluid?: string;
	amount: number;
	/** The finished item waiting in the output slot. */
	output?: ItemSummary;
}

const CAST_SLOT   = 1;
const OUTPUT_SLOT = 2;

/**
 * Format of a cast from its tags: every cast, whatever its mod, carries '<ns>:casts/multi_use/<format>'
 * or '<ns>:casts/single_use/<format>', the tags casting recipes use. Undefined without such a tag.
 */
export function formatOfCastTags(this: void, tags: LuaMap<string, boolean> | undefined): CastFormat | undefined {
	if (tags === undefined) return undefined;

	for (const [tag, present] of tags) {
		if (!present) continue;

		for (const marker of [':casts/multi_use/', ':casts/single_use/']) {
			const index = tag.indexOf(marker);
			if (index >= 0) return tag.substring(index + marker.length);
		}
	}

	return undefined;
}

/**
 * Format of a cast from its name, when its tags are not available. Knows the TConstruct names
 * (ingot_cast, ingot_sand_cast, ingot_red_sand_cast) and the Tinkers Reforged ones
 * (great_blade_cast_gold, great_blade_cast_sand, great_blade_cast_red_sand, cast_ingot).
 */
export function formatOfCast(this: void, castName: string): CastFormat | undefined {
	const colon = castName.indexOf(':');
	const path  = colon >= 0 ? castName.substring(colon + 1) : castName;

	for (const suffix of ['_red_sand_cast', '_sand_cast', '_cast', '_cast_gold', '_cast_red_sand', '_cast_sand']) {
		if (path.endsWith(suffix)) {
			return path.substring(0, path.length - suffix.length);
		}
	}

	if (path.startsWith('cast_')) return path.substring('cast_'.length);
	return undefined;
}

/** A casting table or basin: receives fluid by pushFluid, gives its result by pushItems. */
export class Caster {
	public constructor(
		public readonly name: string,
		public readonly kind: CasterKind,
		private readonly tank: Tank,
		private readonly inventory: Inventory,
		private readonly amounts: CastAmounts = new CastAmounts(),
	) {
	}

	/** Format per cast item name: its tags are read once (one more peripheral call), then remembered. */
	private readonly castFormats = new Map<string, CastFormat | false>();

	/** Kind from the peripheral name ('tconstruct:table_0', 'tconstruct:basin_0'). */
	public static fromName(name: string, amounts?: CastAmounts): Caster {
		const kind: CasterKind = name.includes('basin') ? 'basin' : 'table';
		return new Caster(name, kind, Tank.fromName(name), Inventory.fromName(name), amounts);
	}

	public read(): CasterState {
		const items  = this.inventory.list();
		const cast   = items.get(CAST_SLOT);
		const output = items.get(OUTPUT_SLOT);
		const fluids = this.tank.getFluids();
		const fluid  = fluids[0];

		const state: CasterState = {
			status: output !== undefined ? 'blocked' : fluid !== undefined ? 'busy' : 'idle',
			amount: fluid?.amount ?? 0,
		};

		if (cast !== undefined) state.cast = cast.name;
		if (output !== undefined) state.output = {name: output.name, count: output.count};
		if (fluid !== undefined) state.fluid = fluid.name;

		const format = cast !== undefined ? this.formatOf(cast.name) : this.kind === 'basin' ? 'block' : undefined;
		if (format !== undefined) state.format = format;

		return state;
	}

	private formatOf(castName: string): CastFormat | undefined {
		let format = this.castFormats.get(castName);

		if (format === undefined) {
			const detail = this.inventory.getItem(CAST_SLOT);
			format       = (detail?.name === castName ? formatOfCastTags(detail.tags) : undefined) ?? formatOfCast(castName) ?? false;
			this.castFormats.set(castName, format);
		}

		return format === false ? undefined : format;
	}

	/** Fluid one casting of `fluid` needs in this format, or undefined when it is unknown. */
	public amountFor(format: CastFormat | undefined, fluid?: string): number | undefined {
		return this.amounts.get(format, fluid);
	}

	/**
	 * Pours exactly one casting of `fluidName` from the Smeltery. Refuses (returns 0) unless the caster
	 * is idle, its format is known and the Smeltery holds enough: a partial pour would leave the caster
	 * stuck half full. Returns the mB moved.
	 */
	public pour(smeltery: Smeltery, fluidName: string): number {
		const state  = this.read();
		const amount = this.amountFor(state.format, fluidName);

		if (state.status !== 'idle' || amount === undefined) return 0;
		if (smeltery.amountOf(fluidName) < amount) return 0;

		return smeltery.pour(this.tank, fluidName, amount);
	}

	/** Moves the finished item to an inventory. Returns how many items moved (0 when it is full). */
	public collect(target: Inventory): number {
		if (this.inventory.list().get(OUTPUT_SLOT) === undefined) return 0;
		return this.inventory.pushTo(target, OUTPUT_SLOT);
	}
}
