/** Tinkers' Construct 3 fluid amounts, in mB (1 ingot = 90 mB, not 144 as in older versions). */
export const FluidValues = {
	nugget: 10,
	ingot:  90,
	block:  810,
} as const;

/** What a caster produces, named after its cast: 'ingot' for tconstruct:ingot_cast, 'block' for an empty basin. */
export type CastFormat = string;

/** Fluid needed for one casting of each known format. A format missing here cannot be planned. */
export const DEFAULT_FORMAT_AMOUNTS: Readonly<Record<CastFormat, number>> = {
	nugget: FluidValues.nugget,
	ingot:  FluidValues.ingot,
	block:  FluidValues.block,
};
