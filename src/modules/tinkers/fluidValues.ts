/** Tinkers' Construct 3 fluid amounts, in mB (1 ingot = 90 mB, not 144 as in older versions). */
export const FluidValues = {
	nugget: 10,
	ingot:  90,
	block:  810,
} as const;

/** What a caster produces, named after its cast: 'ingot' for tconstruct:ingot_cast, 'block' for an empty basin. */
export type CastFormat = string;

/** Fluid one casting of `format` needs; with `fluid`, only for that fluid (an exception to the format's amount). */
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
 * Fluid needed by one casting: the amount given for this format and this fluid, otherwise the format's
 * own amount (the basin takes 810 mB of a metal but 1000 of glass), otherwise undefined: a format with no
 * known amount cannot be cast.
 */
export class CastAmounts {
	private readonly byFormat = new Map<CastFormat, number>();
	private readonly byFluid  = new Map<string, number>();

	public constructor(entries: CastAmount[] = DEFAULT_CAST_AMOUNTS) {
		for (const entry of entries) {
			if (entry.fluid === undefined) this.byFormat.set(entry.format, entry.amount);
			else this.byFluid.set(CastAmounts.key(entry.format, entry.fluid), entry.amount);
		}
	}

	private static key(format: CastFormat, fluid: string): string {
		return `${format}|${fluid}`;
	}

	public get(format: CastFormat | undefined, fluid?: string): number | undefined {
		if (format === undefined) return undefined;

		if (fluid !== undefined) {
			const exception = this.byFluid.get(CastAmounts.key(format, fluid));
			if (exception !== undefined) return exception;
		}

		return this.byFormat.get(format);
	}
}
