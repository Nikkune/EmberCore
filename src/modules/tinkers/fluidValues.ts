/** Tinkers' Construct 3 fluid amounts, in mB (1 ingot = 90 mB, not 144 as in older versions). */
export const FluidValues = {
	nugget: 10,
	ingot:  90,
	block:  810,
} as const;

/** What a caster produces, named after its cast: 'ingot' for tconstruct:ingot_cast, 'block' for an empty basin. */
export type CastFormat = string;

/**
 * Fluid one casting of `format` needs; with `fluid`, only for that fluid (an exception to the format's
 * amount). An amount of 0 with a fluid: that format has no recipe for it (quartz makes no ingot).
 */
export interface CastAmount {
	format: CastFormat;
	amount: number;
	fluid?: string;
}

/** Metal amounts only. A modpack's real amounts come from its casting recipes (see the Smeltery catalogue). */
export const DEFAULT_CAST_AMOUNTS: CastAmount[] = [
	{format: 'nugget', amount: FluidValues.nugget},
	{format: 'ingot', amount: FluidValues.ingot},
	{format: 'block', amount: FluidValues.block},
];

/**
 * Every format a fluid has a casting recipe for, with the mB of one casting: 'ingot:90 nugget:10 block:810'
 * by fluid name (a modpack's recipes, read from its data).
 */
export type CastRecipes = Record<string, string>;

/**
 * Fluid needed by one casting: the amount given for this format and this fluid (or learnt: none), otherwise
 * the fluid's casting recipes when they are known (a format they do not list has no recipe), otherwise the
 * format's own amount (the basin takes 810 mB of a metal but 1000 of glass), otherwise undefined: a format
 * with no known amount cannot be cast.
 */
export class CastAmounts {
	private readonly byFormat = new Map<CastFormat, number>();
	private readonly byFluid  = new Map<string, number>();
	private readonly recipes  = new Map<string, Map<CastFormat, number>>();

	public constructor(entries: CastAmount[] = DEFAULT_CAST_AMOUNTS, recipes: CastRecipes = {}) {
		for (const entry of entries) {
			if (entry.fluid === undefined) this.byFormat.set(entry.format, entry.amount);
			else this.byFluid.set(CastAmounts.key(entry.format, entry.fluid), entry.amount);
		}

		for (const [fluid, list] of Object.entries(recipes)) {
			const casts = new Map<CastFormat, number>();
			for (const pair of list.split(' ')) {
				const colon  = pair.indexOf(':');
				const amount = colon > 0 ? Number(pair.substring(colon + 1)) : 0;
				if (amount > 0) casts.set(pair.substring(0, colon), amount);
			}
			this.recipes.set(fluid, casts);
		}
	}

	/** `format` has no recipe for `fluid`: get() answers undefined for them from now on. */
	public forbid(format: CastFormat, fluid: string): void {
		this.byFluid.set(CastAmounts.key(format, fluid), 0);
	}

	private static key(format: CastFormat, fluid: string): string {
		return `${format}|${fluid}`;
	}

	public get(format: CastFormat | undefined, fluid?: string): number | undefined {
		if (format === undefined) return undefined;

		if (fluid !== undefined) {
			const exception = this.byFluid.get(CastAmounts.key(format, fluid));
			if (exception !== undefined) return exception > 0 ? exception : undefined;

			const known = this.recipes.get(fluid);
			if (known !== undefined) return known.get(format);
		}

		return this.byFormat.get(format);
	}
}
