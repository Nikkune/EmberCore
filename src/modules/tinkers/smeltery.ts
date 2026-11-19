import {Inventory}                 from '@core/inventory';
import type {ItemSummary}          from '@core/inventory';
import {Tank}                      from '@core/tank';
import type {FluidStack}           from '@core/tank';

/**
 * A Smeltery seen through one of its drains (fluids) and its chute (items being melted).
 * Every drain of a Smeltery gives the same view: one is enough.
 */
export class Smeltery {
	public constructor(public readonly drain: Tank, public readonly chute: Inventory) {
	}

	public static fromNames(drainName: string, chuteName: string): Smeltery {
		return new Smeltery(Tank.fromName(drainName), Inventory.fromName(chuteName));
	}

	/**
	 * Molten fluids, bottom first: an unnamed extraction would take the first one.
	 * The Smeltery does not report its capacity.
	 */
	public fluids(): FluidStack[] {
		return this.drain.getFluids();
	}

	public amountOf(fluidName: string): number {
		return this.drain.getAmount(fluidName);
	}

	/** Items still melting (the chute exposes the Smeltery's melting slots). */
	public melting(): ItemSummary[] {
		const result: ItemSummary[] = [];

		for (const [, item] of pairs(this.chute.list())) {
			result.push({name: item.name, count: item.count});
		}

		return result;
	}

	/** Moves items from an inventory into the Smeltery. Returns how many went in (0 when it is full). */
	public insert(source: Inventory, slot: number, limit?: number): number {
		return source.pushTo(this.chute, slot, limit);
	}

	/** Pours up to `amount` mB of one fluid into a tank (caster, reservoir). Returns the mB moved. */
	public pour(target: Tank, fluidName: string, amount: number): number {
		return this.drain.pushTo(target, amount, fluidName);
	}
}
