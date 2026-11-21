import type {CasterView, SmelteryState} from '../shared/protocol';

/** CC characters of the default font (codes below 32 and the 2x3 drawing block). */
export const Glyph = {
	up:        String.fromCharCode(30),
	down:      String.fromCharCode(31),
	right:     String.fromCharCode(16),
	left:      String.fromCharCode(17),
	dot:       String.fromCharCode(7),
	/** Middle dot (Latin-1), between the parts of a line. */
	mid:       String.fromCharCode(183),
	/** Thin line across the middle of the cell (drawing block, middle pixel row). */
	rule:      String.fromCharCode(0x80 + 4 + 8),
	/** Thin line on the top of the cell (drawing block, top pixel row): an underline for the line above. */
	underline: String.fromCharCode(0x80 + 1 + 2),
} as const;

/** Colors of the molten fluids, from a keyword of their name (the others: OTHER_COLORS). */
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

/** Colors given to the fluids no keyword knows: the same fluid always gets the same one. */
const OTHER_COLORS = [colors.lightBlue, colors.brown, colors.blue, colors.purple, colors.orange, colors.lime, colors.cyan, colors.pink];

export function fluidColor(this: void, fluid: string): number {
	for (const [keyword, color] of FLUID_COLORS) {
		if (fluid.includes(keyword)) return color;
	}
	let hash = 0;
	for (let index = 0; index < fluid.length; index++) hash = (hash * 31 + fluid.charCodeAt(index)) % 9973;
	return OTHER_COLORS[hash % OTHER_COLORS.length]!;
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

/**
 * Casters grouped by cast, by name ('no cast' last): a fixed order, so a row does not move under the
 * finger when its format goes in or out of auto mode.
 */
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
	for (const [, group] of groups) list.push(group);
	const key = (group: CastGroup): string => (group.format === 'no cast' ? '~' : group.format);
	list.sort((a, b) => (key(a) < key(b) ? -1 : key(a) > key(b) ? 1 : 0));

	return list;
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

export type LogKind = 'in' | 'cast' | 'out' | 'store' | 'stock' | 'held' | 'forced' | 'mode' | 'alert' | 'other';

export interface LogLine {
	time: string;
	kind: LogKind;
	text: string;
}

/** 'tconstruct:basin_3' → 'basin 3'; 'minecraft:copper_block' → 'copper block'. */
export function placeLabel(this: void, name: string): string {
	return itemLabel(name).split('_').join(' ');
}

/** The reason at the end of a line, between parentheses: 'moved ... (needs 1090 K)' → 'needs 1090 K'. */
function reasonOf(this: void, body: string): string {
	// No lastIndexOf in TSTL: the last '(' by hand.
	let open = -1;
	for (let index = body.indexOf('('); index >= 0; index = body.indexOf('(', index + 1)) open = index;
	return open >= 0 && body.endsWith(')') ? body.substring(open + 1, body.length - 1) : '';
}

/** A controller log line ('20:24:54 inserted 64 minecraft:raw_gold (seen: ...)') in a short form. */
export function parseLogLine(this: void, line: string): LogLine {
	const time  = line.substring(0, 8);
	const body  = line.substring(9);
	const words = body.split(' ');
	const word  = (index: number): string => words[index] ?? '';

	switch (word(0)) {
		case 'inserted':
			return {time, kind: 'in', text: `${placeLabel(word(2))} x${word(1)}`};
		case 'poured': {
			const format = body.endsWith(')') ? ` (${reasonOf(body)})` : '';
			return {time, kind: 'cast', text: `${fluidLabel(word(3))} ${word(1)} mB > ${placeLabel(word(5))}${format}`};
		}
		case 'collected':
			// 'collected 1 minecraft:copper_block from tconstruct:basin_3' (older: 'collected 1 from basin').
			return word(2) === 'from'
			       ? {time, kind: 'out', text: `x${word(1)} from ${placeLabel(word(3))}`}
			       : {time, kind: 'out', text: `${placeLabel(word(2))} x${word(1)} from ${placeLabel(word(4))}`};
		case 'moved':
			return {time, kind: 'held', text: `${placeLabel(word(2))} x${word(1)} > ${placeLabel(word(4))} (${reasonOf(body)})`};
		case 'stored':
			return {time, kind: 'store', text: `${fluidLabel(word(3))} ${word(1)} mB > reservoirs (${reasonOf(body)})`};
		case 'trashed':
			return {time, kind: 'store', text: `${fluidLabel(word(3))} ${word(1)} mB > trash (from ${words.slice(5).join(' ')})`};
		case 'injected': {
			// 'injected 500 mB lava from drum 1 into the Smeltery (forms obsidian)'
			const into  = words.indexOf('into');
			const from  = words.slice(5, into > 5 ? into : undefined).join(' ');
			const forms = body.includes('(forms ') ? `, ${body.substring(body.indexOf('(forms ') + 1, body.length - 1)}` : '';
			return {time, kind: 'stock', text: `${fluidLabel(word(3))} ${word(1)} mB > Smeltery (from ${placeLabel(from)}${forms})`};
		}
		case 'restored':
			return {time, kind: 'stock', text: `${fluidLabel(word(3))} ${word(1)} mB back ${words.slice(4).join(' ')}`};
		case 'FORCED':
			return {time, kind: 'forced', text: body.substring('FORCED '.length)};
		case 'mode':
			// 'mode drain -> idle': the kind already says "mode".
			return {time, kind: 'mode', text: body.substring('mode '.length)};
		case 'alerts:':
			return {time, kind: 'alert', text: body.substring('alerts: '.length)};
		case 'no':
			return word(1) === 'room' ? {time, kind: 'alert', text: body} : {time, kind: 'other', text: body};
		default:
			return {time, kind: 'other', text: body};
	}
}

/** Short forms of the words of the screen, used when a text does not fit (fit). */
const ABBREVIATIONS: Record<string, string> = {
	nugget: 'nug.', nuggets: 'nug.', ingot: 'ing.', ingots: 'ing.', block: 'blk.', blocks: 'blk.',
	utilities: 'util.', grinding: 'grind.', reservoirs: 'res.', reservoir: 'res.', advanced: 'adv.',
	industrial: 'ind.', storage: 'stor.', smeltery: 'smelt.',
};

/**
 * `text` in at most `width` columns: the known words are shortened from the end ('4 nugget' → '4 nug.'),
 * then the rest is cut (ending with '.') as a last resort.
 */
export function fit(this: void, text: string, width: number): string {
	if (text.length <= width) return text;
	const words = text.split(' ');
	for (let index = words.length - 1; index >= 0 && words.join(' ').length > width; index--) {
		const short = ABBREVIATIONS[words[index]!];
		if (short !== undefined) words[index] = short;
	}
	const fitted = words.join(' ');
	if (fitted.length <= width) return fitted;
	// CC has no ellipsis: a dot ends the cut text.
	return width <= 1 ? fitted.substring(0, width) : `${fitted.substring(0, width - 1)}.`;
}

/** mB an item gives once melted, from its name (blocks 810, nuggets 10, the rest an ingot): an estimate. */
export function itemAmount(this: void, name: string): number {
	if (name.includes('block')) return 810;
	if (name.includes('nugget')) return 10;
	return 90;
}

/** Fluids the foundry is seeing: in the Smeltery, in the reservoirs, reserved; then `extra`. No duplicates. */
export function knownFluids(this: void, state: SmelteryState, extra: (string | undefined)[] = []): string[] {
	const known: string[] = [];
	const add = (fluid: string | undefined): void => {
		if (fluid !== undefined && fluid !== '' && !known.includes(fluid)) known.push(fluid);
	};

	for (const fluid of state.fluids) add(fluid.name);
	for (const reservoir of state.reservoirs) {
		add(reservoir.fluid);
		add(reservoir.assigned);
	}
	for (const fluid of extra) add(fluid);
	return known;
}

