import type {CasterView, SmelteryState} from '../shared/protocol';

/** CC characters of the default font (codes below 32 and the 2x3 drawing block). */
export const Glyph = {
	up:        String.fromCharCode(30),
	down:      String.fromCharCode(31),
	right:     String.fromCharCode(16),
	left:      String.fromCharCode(17),
	dot:       String.fromCharCode(7),
	/** Thin line across the middle of the cell (drawing block, middle pixel row). */
	rule:      String.fromCharCode(0x80 + 4 + 8),
	/** Thin line on the top of the cell (drawing block, top pixel row): an underline for the line above. */
	underline: String.fromCharCode(0x80 + 1 + 2),
} as const;

/** Colors of the molten fluids, from a keyword of their name; unknown fluids get magenta. */
const FLUID_COLORS: [string, number][] = [
	['rose_gold', colors.pink],
	['pig_iron', colors.pink],
	['iron', colors.lightGray],
	['gold', colors.yellow],
	['copper', colors.orange],
	['tin', colors.white],
	['silver', colors.white],
	['lead', colors.blue],
	['nickel', colors.lightGray],
	['zinc', colors.lightGray],
	['bronze', colors.brown],
	['brass', colors.yellow],
	['electrum', colors.yellow],
	['cobalt', colors.blue],
	['aluminum', colors.white],
	['steel', colors.gray],
	['netherite', colors.gray],
	['debris', colors.brown],
	['blazing', colors.red],
	['lava', colors.orange],
	['obsidian', colors.purple],
	['emerald', colors.lime],
	['diamond', colors.cyan],
	['quartz', colors.white],
	['glass', colors.white],
	['slime', colors.lime],
	['ender', colors.cyan],
	['manyullyn', colors.purple],
	['hepatizon', colors.purple],
	['amethyst', colors.purple],
	['invar', colors.lightGray],
	['constantan', colors.orange],
	['pewter', colors.lightGray],
	['osmium', colors.lightBlue],
	['platinum', colors.lightBlue],
	['uranium', colors.lime],
	['signalum', colors.red],
	['lumium', colors.yellow],
	['blood', colors.red],
];

const DARK_COLORS = [colors.gray, colors.blue, colors.purple, colors.brown, colors.green, colors.red, colors.black];

export function fluidColor(this: void, fluid: string): number {
	for (const [keyword, color] of FLUID_COLORS) {
		if (fluid.includes(keyword)) return color;
	}
	return colors.magenta;
}

/** Text drawn on a color: white on the dark ones, black otherwise. */
export function textOn(this: void, background: number): number {
	return DARK_COLORS.includes(background) ? colors.white : colors.black;
}

/** 'tconstruct:molten_rose_gold' → 'rose gold'; 'tconstruct:blazing_blood' → 'blazing blood'. */
export function fluidLabel(this: void, fluid: string): string {
	const colon = fluid.indexOf(':');
	let name    = colon >= 0 ? fluid.substring(colon + 1) : fluid;
	if (name.startsWith('molten_')) name = name.substring('molten_'.length);
	return name.split('_').join(' ');
}

/** 'minecraft:raw_iron' → 'raw_iron'. */
export function itemLabel(this: void, item: string): string {
	const colon = item.indexOf(':');
	return colon >= 0 ? item.substring(colon + 1) : item;
}

/** 'large_round_plate' → 'large round plate'. */
export function formatLabel(this: void, format: string): string {
	return format.split('_').join(' ');
}

export interface CastGroup {
	format: string;
	free: number;
	casting: number;
	ready: number;
	/** Used by auto mode. */
	auto: boolean;
}

/** Casters grouped by cast: auto mode's formats first (in its order), then the others by name. */
export function groupCasters(this: void, casters: CasterView[], autoFormats: string[]): CastGroup[] {
	const groups = new Map<string, CastGroup>();

	for (const caster of casters) {
		const format = caster.format ?? 'no cast';
		let group    = groups.get(format);

		if (group === undefined) {
			group = {format, free: 0, casting: 0, ready: 0, auto: autoFormats.includes(format)};
			groups.set(format, group);
		}

		if (caster.status === 'idle') group.free++;
		else if (caster.status === 'busy') group.casting++;
		else group.ready++;
	}

	const list: CastGroup[] = [];
	for (const format of autoFormats) {
		const group = groups.get(format);
		if (group !== undefined) list.push(group);
	}

	const others: CastGroup[] = [];
	for (const [, group] of groups) {
		if (!group.auto) others.push(group);
	}
	others.sort((a, b) => (a.format < b.format ? -1 : a.format > b.format ? 1 : 0));

	return [...list, ...others];
}

export interface AttentionLine {
	/** red: needs the player; orange: waits on its own. */
	color: number;
	title: string;
	detail: string;
}

/** What needs a look: the alerts first, then the items kept in the input. */
export function attentionLines(this: void, state: SmelteryState): AttentionLine[] {
	const lines: AttentionLine[] = [];

	for (const alert of state.alerts) {
		// ': ' and not ':': fluid ids hold one ('no reservoir for tconstruct:molten_tin: it stays...').
		const colon = alert.indexOf(': ');
		lines.push(colon >= 0
		           ? {color: colors.red, title: alert.substring(0, colon), detail: alert.substring(colon + 2).trim()}
		           : {color: colors.red, title: alert, detail: ''});
	}

	for (const item of state.waiting) {
		const name = `${item.count} ${itemLabel(item.name)}`;

		if (item.reason === 'alloy') lines.push({color: colors.orange, title: `${name} waits`, detail: `would form ${fluidLabel(item.alloy ?? '?')}`});
		else if (item.reason === 'heat') lines.push({color: colors.orange, title: `${name} waits`, detail: `needs ${item.temperature ?? '?'} K`});
		else if (item.reason === 'full') lines.push({color: colors.orange, title: `${name} waits`, detail: 'the Smeltery is full'});
		else lines.push({color: colors.orange, title: `${name} waits`, detail: 'melts into nothing known'});
	}

	return lines;
}

export type LogKind = 'in' | 'cast' | 'out' | 'reject' | 'forced' | 'mode' | 'other';

export interface LogLine {
	time: string;
	kind: LogKind;
	text: string;
}

/** A controller log line ('20:24:54 inserted 64 minecraft:raw_gold (seen: ...)') in a short form. */
export function parseLogLine(this: void, line: string): LogLine {
	const time  = line.substring(0, 8);
	const body  = line.substring(9);
	const words = body.split(' ');
	const word  = (index: number): string => words[index] ?? '';

	switch (word(0)) {
		case 'inserted':
			return {time, kind: 'in', text: `${itemLabel(word(2))} ${word(1)}`};
		case 'poured':
			return {time, kind: 'cast', text: `${fluidLabel(word(3))} ${word(1)} > ${itemLabel(word(5))}`};
		case 'collected':
			return {time, kind: 'out', text: `${word(1)} from ${itemLabel(word(3))}`};
		case 'moved': {
			// The reason is the text between the parentheses at the end: '(needs 1090 K)'.
			const open = body.indexOf('(');
			const why  = open >= 0 && body.endsWith(')') ? body.substring(open + 1, body.length - 1) : '';
			return {time, kind: 'reject', text: `${itemLabel(word(2))} ${word(1)} > ${why}`};
		}
		case 'FORCED':
			return {time, kind: 'forced', text: body.substring('FORCED '.length)};
		case 'mode':
			return {time, kind: 'mode', text: body};
		default:
			return {time, kind: 'other', text: body};
	}
}
