import type {ReservoirView}                  from '@modules/fluids/index';
import type {AlloyRatio}                     from '@modules/tinkers/index';
import {ButtonComponent, PaginationComponent} from '@modules/ui/components';
import type {Rect}                           from '@modules/ui/types';

import type {AlloyOption, CastRequest, DeleteRecipeRequest, InputItemView, InsertRequest, Mode, SaveRecipeRequest, SetAlloyRequest, SetReservoirRequest, SetFormatRequest, SetSmelteryCapacityRequest, SmelteryState} from '../shared/protocol';
import {MAX_INGREDIENTS, MODES}              from '../shared/protocol';
import {recipeProblem}                       from '../shared/recipes';

import {attentionLines, fit, fluidColor, fluidLabel, formatLabel, Glyph, groupCasters, itemAmount, knownFluids, parseLogLine, placeLabel} from './model';
import type {CastGroup, LogKind, LogLine} from './model';
import {AbsoluteLayout, PaintComponent, Pixels} from './widgets';
import type {Painter}                        from './widgets';

export const SCREEN_WIDTH  = 100;
export const SCREEN_HEIGHT = 52;

/**
 * The neon palette: the 16 CC colors redefined on the monitor (setPaletteColour). The names below say
 * what each slot is used for; the fluids keep the slots of their color names.
 */
export const PALETTE: [number, number][] = [
	[colors.black, 0x0b0b1e],
	[colors.green, 0x1a1a44],
	[colors.gray, 0x50508a],
	[colors.lightGray, 0xc8c8e0],
	[colors.white, 0xe8e8ff],
	[colors.cyan, 0x3ef0ff],
	[colors.magenta, 0xff3ea5],
	[colors.yellow, 0xffe14a],
	[colors.purple, 0x7a5cff],
	[colors.lime, 0x4dff8a],
	[colors.red, 0xff4a5a],
	[colors.pink, 0xff9ec8],
	[colors.orange, 0xff8a3d],
	[colors.blue, 0x3d6bff],
	[colors.lightBlue, 0x8fb8ff],
	[colors.brown, 0xa0704a],
];

/** Colors by use. */
const N = {
	bg:      colors.black,
	panel:   colors.green,
	dim:     colors.gray,
	soft:    colors.lightGray,
	text:    colors.white,
	cyan:    colors.cyan,
	magenta: colors.magenta,
	yellow:  colors.yellow,
	purple:  colors.purple,
	lime:    colors.lime,
	red:     colors.red,
	orange:  colors.orange,
} as const;

type Tab = 'overview' | 'modes' | 'manual' | 'stock' | 'log';

/** What the screen asks the controller; the answers come back through setState(). */
export interface ScreenActions {
	setMode(mode: Mode): void;
	insert(request: InsertRequest): void;
	cast(request: CastRequest): void;
	setFormat(request: SetFormatRequest): void;
	setAlloy(request: SetAlloyRequest): void;
	setReservoir(request: SetReservoirRequest): void;
	setSmelteryCapacity(request: SetSmelteryCapacityRequest): void;
	/** `saved` runs once the controller accepted the recipe (the editor stays open otherwise). */
	saveRecipe(request: SaveRecipeRequest, saved: () => void): void;
	deleteRecipe(request: DeleteRecipeRequest): void;
}

/** A two-step confirmation: a forced insert, or deleting a recipe. */
type Confirm = ({kind: 'force'; item: InputItemView} | {kind: 'delete'; option: AlloyOption}) & {
	step: 1 | 2;
	/** os.clock() after which the second step is cancelled. */
	deadline: number;
};

/** Stock tab: the reservoir being reserved, and the fluid chosen for it (undefined: free). */
interface Assigning {
	reservoir: string;
	fluid?: string | undefined;
	/** Set by hand, in mB; undefined: auto (learnt, or given by its type). */
	capacity?: number | undefined;
}

/** A recipe being written in the editor; a fluid is undefined until chosen. */
interface EditorState {
	/** Recipe replaced on save; undefined: a new one. */
	index?: number | undefined;
	expected?: string | undefined;
	result?: string | undefined;
	amount: number;
	inputs: {fluid?: string | undefined; amount: number}[];
	/** What the fluid list fills: the result, an ingredient (0-based), or nothing yet. */
	slot?: 'result' | number | undefined;
	step: number;
}

type LogFilter = 'all' | 'in' | 'cast' | 'out' | 'store' | 'mode' | 'alert';

const TABS: [Tab, string][] = [['overview', 'OVERVIEW'], ['modes', 'MODES'], ['manual', 'MANUAL'], ['stock', 'STOCK'], ['log', 'LOG']];
const TABS_X = 34;

const MODE_COLORS: Record<Mode, number> = {
	idle:   N.soft,
	auto:   N.lime,
	manual: N.yellow,
	lock:   N.red,
	drain:  N.cyan,
	purge:  N.purple,
	alloy:  N.magenta,
	melt:   colors.lightBlue,
};

/** Card texts: 19 columns at most. The alloy card names the chosen alloy (alloyLines). */
const MODE_LINES: Record<Mode, string[]> = {
	idle:   ['Full stop.', 'Nothing moves.'],
	auto:   ['Melts the input and', 'casts pure metals', 'into AUTO casts.'],
	manual: ['You insert and cast', 'from the Manual tab.'],
	lock:   ['Nothing new goes in;', 'casts under way', 'finish.'],
	drain:  ['Every fluid to the', 'reservoirs, then', 'idle.'],
	purge:  ['Leftovers and', 'alloys to the', 'reservoirs.'],
	alloy:  [],
	melt:   ['Melts the input', 'into the stock,', 'casts nothing.'],
};

const LOG_COLORS: Record<LogKind, number> = {
	in:     N.cyan,
	cast:   N.text,
	out:    N.lime,
	store:  colors.lightBlue,
	stock:  N.magenta,
	held:   N.yellow,
	forced: N.red,
	mode:   N.purple,
	alert:  N.red,
	other:  N.dim,
};

const LOG_FILTERS: [LogFilter, string, number][] = [
	['all', 'ALL', N.text], ['in', 'IN', N.cyan], ['cast', 'CAST', N.text], ['out', 'OUT', N.lime],
	['store', 'STORE', colors.lightBlue], ['mode', 'MODE', N.purple], ['alert', 'ALERT', N.red],
];

const CASTS_PER_PAGE  = 5;
const ALLOYS_PER_PAGE = 10;
/** mB of an ingot: the amounts of alloy mode are chosen in ingots. */
const INGOT = 90;
const ITEMS_PER_PAGE  = 8;
const RESERVOIRS_PER_PAGE = 15;
/** The fluid picker (full screen): 4 columns of 18 fluids a page, and the KNOWN ones above. */
const PICKER_COLUMNS = 4;
const PICKER_ROWS    = 18;
const PICKER_PAGE    = PICKER_COLUMNS * PICKER_ROWS;
const PICKER_KNOWN   = 4;
const LETTERS        = 'abcdefghijklmnopqrstuvwxyz';
/** Steps of the recipe editor's - and + (mB). */
const STEPS = [10, 90, 1000];
/** Steps of the Smeltery capacity's - and + (mB). */
const CAPACITY_STEPS = [10, 90, 1000, 10000, 100000];
/** Smallest amount of a recipe line. */
const MIN_AMOUNT = 10;
/** Capacities ◀ ▶ go through on the Stock tab (the reservoirs of the modpack); before them, auto. */
const CAPACITIES = [16000, 32000, 64000, 256000, 1024000, 4096000];
/** Level of a reservoir whose capacity is not known yet: the biggest known one, or this. */
const DEFAULT_CAPACITY = 16000;
/** A fuel tank (seared tank) holds 4 buckets. */
const FUEL_TANK = 4000;
const LOG_LINES       = 20;
const CONFIRM_SECONDS = 10;
const OFFLINE_SECONDS = 12;

/** Mode cards, four per row: the top-left corner of the `index`-th one. */
function cardPlace(this: void, index: number): {x: number; y: number} {
	return {x: 3 + (index % 4) * 24, y: 5 + Math.floor(index / 4) * 21};
}

/** 20000 → '20k', 1500 → '1.5k', 900 → '900'. */
function shortAmount(this: void, amount: number): string {
	if (amount < 1000) return `${Math.round(amount)}`;
	const thousands = amount / 1000;
	return `${thousands >= 10 || thousands % 1 === 0 ? Math.round(thousands) : Math.round(thousands * 10) / 10}k`;
}

/** Which log kinds a filter keeps. */
function keeps(this: void, filter: LogFilter, kind: LogKind): boolean {
	if (filter === 'all') return true;
	if (filter === 'store') return kind === 'store' || kind === 'stock';
	if (filter === 'alert') return kind === 'alert' || kind === 'forced' || kind === 'held';
	return kind === filter;
}

/** A reservoir name on two lines of `width`: the name, then the rest of it or its mod. */
function reservoirLines(this: void, name: string, width: number): [string, string] {
	const colon = name.indexOf(':');
	const mod   = colon >= 0 ? name.substring(0, colon).split('_').join(' ') : '';
	const label = placeLabel(name);
	if (label.length <= width) return [label, fit(mod, width)];

	const words = label.split(' ');
	let first   = '';
	let index   = 0;
	while (index < words.length && (first === '' ? words[index]!.length : first.length + 1 + words[index]!.length) <= width) {
		first = first === '' ? words[index]! : `${first} ${words[index]!}`;
		index++;
	}
	if (first === '') return [fit(label, width), fit(mod, width)];
	return [first, fit(words.slice(index).join(' '), width)];
}

const FULL_SCREEN: Rect = {x: 1, y: 1, width: SCREEN_WIDTH, height: SCREEN_HEIGHT};

/**
 * The monitor of the Smeltery, drawn to the character (100 x 52 at text scale 0.5) in the neon palette:
 * paint components draw, EmberCore buttons and paginations take the touches. All coordinates are 1-based,
 * as on the monitor.
 */
export class SmelteryScreen {
	public readonly root = new AbsoluteLayout(SCREEN_WIDTH, SCREEN_HEIGHT);

	private state?: SmelteryState | undefined;
	private lastState = -Infinity;
	private tab: Tab  = 'overview';
	private castPage  = 1;
	private itemPage  = 1;
	private stockPage = 1;
	private logPage   = 1;
	private logFilter: LogFilter = 'all';
	/** Overview: the capacity panel is open, with the value being set. */
	private capacityDraft?: number | undefined;
	private capacityStep = 1000;
	/** Modes tab: the alloy picker is open instead of the cards. */
	private picking   = false;
	private alloyPage = 1;
	/** Recipe picked in the list (AlloyOption.index). */
	private picked?: number | undefined;
	private editor?: EditorState | undefined;
	private assigning?: Assigning | undefined;
	private choicePage = 1;
	/** The fluid picker covers the screen (for the reservoir being assigned, or the slot of the editor). */
	private choosing = false;
	/** Every fluid of the catalogue (sorted), once the controller sent it. */
	private allFluids?: string[] | undefined;
	private pickIngots = 16;
	private nonstop    = false;
	private fluid?: string | undefined;
	private format?: string | undefined;
	private confirm?: Confirm | undefined;
	private message?: {text: string; color: number; until: number} | undefined;

	private readonly allButtons: ButtonComponent[] = [];
	private readonly tabButtons                    = new Map<Tab, ButtonComponent>();
	private readonly modeButtons                   = new Map<Mode, ButtonComponent>();
	private readonly itemButtons: ButtonComponent[] = [];
	private readonly fluidButtons: ButtonComponent[] = [];
	private readonly formatButtons: ButtonComponent[] = [];
	private readonly autoButtons: ButtonComponent[] = [];
	private readonly castButton: ButtonComponent;
	private readonly switchManual: ButtonComponent;
	private readonly filterButtons = new Map<LogFilter, ButtonComponent>();
	private readonly logPages: PaginationComponent;
	private readonly confirmYes: ButtonComponent;
	private readonly confirmNo: ButtonComponent;
	private readonly castPages: PaginationComponent;
	private readonly setCapacity: ButtonComponent;
	private readonly capacityLessButton: ButtonComponent;
	private readonly capacityMoreButton: ButtonComponent;
	private readonly capacityStepButtons: ButtonComponent[] = [];
	private readonly capacitySave: ButtonComponent;
	private readonly capacityAuto: ButtonComponent;
	private readonly capacityCancel: ButtonComponent;
	private readonly changeAlloy: ButtonComponent;
	private readonly alloyButtons: ButtonComponent[] = [];
	private readonly alloyPages: PaginationComponent;
	private readonly lessButton: ButtonComponent;
	private readonly moreButton: ButtonComponent;
	private readonly nonstopButton: ButtonComponent;
	private readonly selectButton: ButtonComponent;
	private readonly closePicker: ButtonComponent;
	private readonly itemPages: PaginationComponent;
	private readonly stockPages: PaginationComponent;
	private readonly reservoirButtons: ButtonComponent[] = [];
	private readonly pickerButtons: ButtonComponent[] = [];
	private readonly knownButtons: ButtonComponent[] = [];
	private readonly letterButtons: ButtonComponent[] = [];
	private readonly pickerFree: ButtonComponent;
	private readonly pickerCancel: ButtonComponent;
	private readonly choicePages: PaginationComponent;
	private readonly chooseButton: ButtonComponent;
	private readonly freeButton: ButtonComponent;
	private readonly capacityLess: ButtonComponent;
	private readonly capacityMore: ButtonComponent;
	private readonly panelSave: ButtonComponent;
	private readonly panelCancel: ButtonComponent;
	private readonly editButton: ButtonComponent;
	private readonly newButton: ButtonComponent;
	private readonly deleteButton: ButtonComponent;
	private readonly resultButton: ButtonComponent;
	private readonly resultLess: ButtonComponent;
	private readonly resultMore: ButtonComponent;
	private readonly inputButtons: ButtonComponent[] = [];
	private readonly inputLess: ButtonComponent[] = [];
	private readonly inputMore: ButtonComponent[] = [];
	private readonly inputRemove: ButtonComponent[] = [];
	private readonly addInput: ButtonComponent;
	private readonly stepButtons: ButtonComponent[] = [];

	public constructor(private readonly actions: ScreenActions) {
		this.root.place(new PaintComponent({paint: (painter) => this.paint(painter)}), FULL_SCREEN);

		let tabX = TABS_X;
		for (const [tab, label] of TABS) {
			this.tabButtons.set(tab, this.button(label, {x: tabX, y: 2, width: label.length, height: 1}, () => this.showTab(tab)));
			tabX += label.length + 4;
		}

		// TSTL compiles `for (let ...)` to one shared Lua variable: closures must capture a per-iteration const.
		MODES.forEach((mode, index) => {
			const card = cardPlace(index);
			this.modeButtons.set(mode, this.button(' ACTIVATE ', {x: card.x + 2, y: card.y + 16, width: 10, height: 1}, () => this.actions.setMode(mode)));
		});

		// Overview: the AUTO / off switch of each cast, the capacity panel.
		this.castPages = this.pagination(CASTS_PER_PAGE, {x: 86, y: 44, width: 11, height: 1}, (page) => {
			this.castPage = page;
		});
		for (let row = 0; row < CASTS_PER_PAGE; row++) {
			const index = row;
			this.autoButtons.push(this.button('', {x: 91, y: 26 + index * 3, width: 6, height: 1}, () => this.toggleAuto(index)));
		}
		this.setCapacity        = this.button(' SET CAPACITY ', {x: 6, y: 44, width: 14, height: 1}, () => this.openCapacity());
		this.capacityLessButton = this.button(' - ', {x: 56, y: 17, width: 3, height: 1}, () => this.stepSmelteryCapacity(-1));
		this.capacityMoreButton = this.button(' + ', {x: 80, y: 17, width: 3, height: 1}, () => this.stepSmelteryCapacity(1));
		let capacityX = 59;
		for (const step of CAPACITY_STEPS) {
			const label = ` ${step} `;
			const rect  = {x: capacityX, y: 22, width: label.length, height: 1};
			this.capacityStepButtons.push(this.button(label, rect, () => this.setCapacityStep(step)));
			capacityX += label.length + 1;
		}
		this.capacitySave   = this.button(' SAVE ', {x: 54, y: 34, width: 6, height: 1}, () => this.saveCapacity(false));
		this.capacityAuto   = this.button(' AUTO ', {x: 63, y: 34, width: 6, height: 1}, () => this.saveCapacity(true));
		this.capacityCancel = this.button(' CANCEL ', {x: 72, y: 34, width: 8, height: 1}, () => this.closeCapacity());

		// Manual.
		this.switchManual = this.button(' SWITCH TO MANUAL ', {x: 78, y: 6, width: 18, height: 1}, () => this.actions.setMode('manual'));
		for (let row = 0; row < ITEMS_PER_PAGE; row++) {
			const index = row;
			this.itemButtons.push(this.button('', {x: 50, y: 14 + index * 4, width: 8, height: 1}, () => this.pressItem(index)));
		}
		this.itemPages = this.pagination(ITEMS_PER_PAGE, {x: 6, y: 45, width: 11, height: 1}, (page) => {
			this.itemPage = page;
		});
		for (let row = 0; row < 5; row++) {
			const index = row;
			this.fluidButtons.push(this.button('', {x: 69, y: 14 + index * 2, width: 28, height: 1}, () => this.pickFluid(index)));
			this.formatButtons.push(this.button('', {x: 66, y: 27 + index * 2, width: 31, height: 1}, () => this.pickFormat(index)));
		}
		this.castButton = this.button('', {x: 66, y: 39, width: 31, height: 1}, () => this.pressCast());

		// Log.
		LOG_FILTERS.forEach(([filter, label], index) => {
			this.filterButtons.set(filter, this.button(` ${label} `, {x: 3 + index * 10, y: 5, width: label.length + 2, height: 1}, () => this.setLogFilter(filter)));
		});
		this.logPages = this.pagination(LOG_LINES, {x: 86, y: 5, width: 11, height: 1}, (page) => {
			this.logPage = page;
		});

		// Stock: the name of each reservoir is its button (touch it to reserve the reservoir).
		this.stockPages = this.pagination(RESERVOIRS_PER_PAGE, {x: 6, y: 45, width: 11, height: 1}, (page) => {
			this.stockPage = page;
		});
		for (let slot = 0; slot < RESERVOIRS_PER_PAGE; slot++) {
			const index = slot;
			const place = SmelteryScreen.reservoirPlace(index);
			this.reservoirButtons.push(this.button('', {x: place.x, y: place.y + 6, width: 11, height: 1}, () => this.pressReservoir(index)));
		}

		// The alloy card and its picker (Modes tab).
		const alloyCard  = cardPlace(MODES.indexOf('alloy'));
		this.changeAlloy = this.button(' CHANGE ALLOY ', {x: alloyCard.x + 2, y: alloyCard.y + 14, width: 14, height: 1}, () => this.openPicker());
		for (let row = 0; row < ALLOYS_PER_PAGE; row++) {
			const index = row;
			this.alloyButtons.push(this.button('', {x: 10, y: 7 + index * 3, width: 36, height: 1}, () => this.pickAlloy(index)));
		}
		this.alloyPages    = this.pagination(ALLOYS_PER_PAGE, {x: 10, y: 44, width: 11, height: 1}, (page) => {
			this.alloyPage = page;
		});
		this.lessButton    = this.button(' - ', {x: 65, y: 21, width: 3, height: 1}, () => this.stepIngots(-1));
		this.moreButton    = this.button(' + ', {x: 81, y: 21, width: 3, height: 1}, () => this.stepIngots(1));
		this.nonstopButton = this.button(' NONSTOP ', {x: 87, y: 21, width: 9, height: 1}, () => this.toggleNonstop());
		this.selectButton  = this.button(' ACTIVATE ', {x: 65, y: 26, width: 10, height: 1}, () => this.selectAlloy());
		this.closePicker   = this.button(' BACK ', {x: 78, y: 26, width: 6, height: 1}, () => this.cancelPicker());
		this.editButton    = this.button(' EDIT ', {x: 65, y: 36, width: 6, height: 1}, () => this.openEditor(this.pickedOption()));
		this.newButton     = this.button(' NEW ', {x: 73, y: 36, width: 5, height: 1}, () => this.openEditor(undefined));
		this.deleteButton  = this.button(' DELETE ', {x: 80, y: 36, width: 8, height: 1}, () => this.askDelete());

		// The fluid list, on the right: Stock (reserve a reservoir) and the recipe editor.
		this.chooseButton = this.button(' CHOOSE FLUID ', {x: 70, y: 13, width: 14, height: 1}, () => this.openFluidPicker());
		this.freeButton   = this.button(' FREE ', {x: 86, y: 13, width: 6, height: 1}, () => this.choose(undefined));
		this.capacityLess = this.button(` ${Glyph.left} `, {x: 70, y: 39, width: 3, height: 1}, () => this.stepCapacity(-1));
		this.capacityMore = this.button(` ${Glyph.right} `, {x: 94, y: 39, width: 3, height: 1}, () => this.stepCapacity(1));
		this.panelSave    = this.button(' SAVE ', {x: 70, y: 43, width: 6, height: 1}, () => this.savePanel());
		this.panelCancel  = this.button(' CANCEL ', {x: 79, y: 43, width: 8, height: 1}, () => this.cancelPanel());

		// The recipe editor.
		this.resultButton = this.button('', {x: 9, y: 9, width: 20, height: 1}, () => this.pickSlot('result'));
		this.resultLess   = this.button(' - ', {x: 31, y: 9, width: 3, height: 1}, () => this.stepAmount('result', -1));
		this.resultMore   = this.button(' + ', {x: 44, y: 9, width: 3, height: 1}, () => this.stepAmount('result', 1));
		for (let row = 0; row < MAX_INGREDIENTS; row++) {
			const index = row;
			const y     = 14 + index * 2;
			this.inputButtons.push(this.button('', {x: 9, y, width: 20, height: 1}, () => this.pickSlot(index)));
			this.inputLess.push(this.button(' - ', {x: 31, y, width: 3, height: 1}, () => this.stepAmount(index, -1)));
			this.inputMore.push(this.button(' + ', {x: 44, y, width: 3, height: 1}, () => this.stepAmount(index, 1)));
			this.inputRemove.push(this.button(' x ', {x: 49, y, width: 3, height: 1}, () => this.removeInput(index)));
		}
		this.addInput = this.button(' + INGREDIENT ', {x: 6, y: 22, width: 14, height: 1}, () => this.addIngredient());
		let stepX = 12;
		for (const step of STEPS) {
			const label = ` ${step} `;
			this.stepButtons.push(this.button(label, {x: stepX, y: 25, width: label.length, height: 1}, () => this.setStep(step)));
			stepX += label.length + 1;
		}

		// The fluid picker, over the whole screen.
		for (let cell = 0; cell < PICKER_PAGE; cell++) {
			const index = cell;
			const x     = 9 + Math.floor(index / PICKER_ROWS) * 23;
			this.pickerButtons.push(this.button('', {x, y: 13 + index % PICKER_ROWS, width: 20, height: 1}, () => this.pressPicker(index)));
		}
		for (let cell = 0; cell < PICKER_KNOWN; cell++) {
			const index = cell;
			this.knownButtons.push(this.button('', {x: 9 + index * 23, y: 10, width: 20, height: 1}, () => this.pressKnown(index)));
		}
		for (let letter = 0; letter < LETTERS.length; letter++) {
			const index = letter;
			const label = ` ${LETTERS.charAt(index).toUpperCase()} `;
			this.letterButtons.push(this.button(label, {x: 6 + index * 3, y: 7, width: 3, height: 1}, () => this.jumpTo(index)));
		}
		this.pickerFree   = this.button(' FREE ', {x: 86, y: 7, width: 6, height: 1}, () => this.choose(undefined));
		this.pickerCancel = this.button(' CANCEL ', {x: 87, y: 45, width: 8, height: 1}, () => this.closeFluidPicker());
		this.choicePages  = this.pagination(PICKER_PAGE, {x: 6, y: 45, width: 11, height: 1}, (page) => {
			this.choicePage = page;
		});

		// Added last: drawn and hit above everything else.
		this.root.place(new PaintComponent({paint: (painter) => this.paintConfirm(painter)}), FULL_SCREEN);
		this.confirmYes = this.button('', {x: 28, y: 28, width: 16, height: 1}, () => this.confirmStep());
		this.confirmNo  = this.button(' CANCEL ', {x: 57, y: 28, width: 8, height: 1}, () => this.cancelConfirm());

		this.sync();
	}

	public setState(state: SmelteryState): void {
		this.state     = state;
		this.lastState = os.clock();
		this.sync();
	}

	/** A short message in the bottom line (command results, errors). */
	public notify(text: string, color: number = N.soft): void {
		this.message = {text, color, until: os.clock() + 6};
	}

	/** Called every second: countdowns and the online dot. */
	public tick(): void {
		if (this.confirm !== undefined && this.confirm.step === 2 && os.clock() > this.confirm.deadline) {
			this.notify(`${this.confirm.kind === 'force' ? 'force' : 'delete'} cancelled: not confirmed in time`);
			this.confirm = undefined;
		}
		this.sync();
	}

	/** Every fluid of the catalogue, from the controller (asked at start and after a recipe change). */
	public setFluids(fluids: string[]): void {
		this.allFluids = fluids;
		this.sync();
	}

	// ------------------------------------------------------------------ actions

	private showTab(tab: Tab): void {
		this.tab           = tab;
		this.picking       = false;
		this.editor        = undefined;
		this.assigning     = undefined;
		this.capacityDraft = undefined;
		this.choosing      = false;
		this.sync();
	}

	// ------------------------------------------------------ Smeltery capacity

	private openCapacity(): void {
		this.capacityDraft = this.state?.smelteryCapacity ?? 10000;
		this.sync();
	}

	private closeCapacity(): void {
		this.capacityDraft = undefined;
		this.sync();
	}

	private stepSmelteryCapacity(direction: number): void {
		if (this.capacityDraft === undefined) return;
		this.capacityDraft = Math.max(this.capacityStep, this.capacityDraft + direction * this.capacityStep);
		this.sync();
	}

	private setCapacityStep(step: number): void {
		this.capacityStep = step;
		this.sync();
	}

	/** Save: the value set; auto: forgotten, learnt again the next time the Smeltery is full. */
	private saveCapacity(auto: boolean): void {
		const draft = this.capacityDraft;
		if (draft === undefined) return;
		this.actions.setSmelteryCapacity(auto ? {} : {capacity: draft});
		this.capacityDraft = undefined;
		this.sync();
	}

	// ------------------------------------------------------------------ stock

	/** Stock tab: the top-left corner of the place of the `index`-th reservoir of the page. */
	private static reservoirPlace(index: number): {x: number; y: number} {
		return {x: 6 + (index % 5) * 12, y: 7 + Math.floor(index / 5) * 13};
	}

	/** Holding a fluid first (the fullest first), then reserved, then free; by name inside each. */
	private sortedReservoirs(): ReservoirView[] {
		const rank = (reservoir: ReservoirView): number => (reservoir.fluid !== undefined ? 0 : reservoir.assigned !== undefined ? 1 : 2);
		return [...(this.state?.reservoirs ?? [])].sort((a, b) => {
			if (rank(a) !== rank(b)) return rank(a) - rank(b);
			if (a.amount !== b.amount) return b.amount - a.amount;
			return a.name < b.name ? -1 : a.name > b.name ? 1 : 0;
		});
	}

	private pageReservoirs(): ReservoirView[] {
		const start = (this.stockPage - 1) * RESERVOIRS_PER_PAGE;
		return this.sortedReservoirs().slice(start, start + RESERVOIRS_PER_PAGE);
	}

	private pressReservoir(slot: number): void {
		const reservoir = this.pageReservoirs()[slot];
		if (reservoir === undefined) return;
		this.assigning  = {
			reservoir: reservoir.name,
			fluid:     reservoir.assigned,
			capacity:  reservoir.capacitySource === 'set' ? reservoir.capacity : undefined,
		};
		this.choicePage = 1;
		this.sync();
	}

	/** Fluids the foundry is seeing (the Smeltery, the reservoirs, the recipe being written): shown first. */
	private knownChoices(): string[] {
		const state = this.state;
		if (state === undefined) return [];
		// Only the fluids chosen: an undefined in a Lua array would leave no hole and hide the ones after it.
		const extra: string[] = [];
		const editor = this.editor;
		if (editor !== undefined) {
			for (const fluid of [editor.result, ...editor.inputs.map((input) => input.fluid)]) if (fluid !== undefined) extra.push(fluid);
		}
		return knownFluids(state, extra);
	}

	/** Every fluid (catalogue and known), by name: the pages of the picker. */
	private pickerFluids(): string[] {
		const fluids = [...(this.allFluids ?? [])];
		for (const fluid of this.knownChoices()) if (!fluids.includes(fluid)) fluids.push(fluid);
		return fluids.sort((a, b) => {
			const left = fluidLabel(a), right = fluidLabel(b);
			return left < right ? -1 : left > right ? 1 : a < b ? -1 : a > b ? 1 : 0;
		});
	}

	/** The name of a fluid in the picker; two fluids of the same name show their mod. */
	private pickerLabel(fluid: string, fluids: string[]): string {
		const label = fluidLabel(fluid);
		if (fluids.filter((other) => fluidLabel(other) === label).length < 2) return label;
		const colon = fluid.indexOf(':');
		return `${label} (${colon > 0 ? fluid.substring(0, colon).split('_')[0]! : '?'})`;
	}

	private pagePickerFluids(fluids: string[]): string[] {
		const start = (this.choicePage - 1) * PICKER_PAGE;
		return fluids.slice(start, start + PICKER_PAGE);
	}

	private openFluidPicker(): void {
		this.choosing   = true;
		this.choicePage = 1;
		this.sync();
	}

	private closeFluidPicker(): void {
		this.choosing = false;
		this.sync();
	}

	/** A letter: the page where the fluids from that letter on start. */
	private jumpTo(letter: number): void {
		const fluids = this.pickerFluids();
		const wanted = LETTERS.charAt(letter);
		let index    = fluids.findIndex((fluid) => fluidLabel(fluid).substring(0, 1) >= wanted);
		if (index < 0) index = fluids.length - 1;
		this.choicePage = Math.max(1, Math.floor(index / PICKER_PAGE) + 1);
		this.sync();
	}

	private pressPicker(cell: number): void {
		const fluid = this.pagePickerFluids(this.pickerFluids())[cell];
		if (fluid !== undefined) this.choose(fluid);
	}

	private pressKnown(cell: number): void {
		const fluid = this.knownChoices()[cell];
		if (fluid !== undefined) this.choose(fluid);
	}

	/** The fluid for the reservoir (undefined: free) or for the slot of the editor; closes the picker. */
	private choose(fluid: string | undefined): void {
		const editor = this.editor;
		if (this.assigning !== undefined) {
			this.assigning.fluid = fluid;
		}
		else if (editor !== undefined && fluid !== undefined) {
			if (editor.slot === 'result') editor.result = fluid;
			else if (editor.slot !== undefined && editor.inputs[editor.slot] !== undefined) editor.inputs[editor.slot]!.fluid = fluid;
		}
		this.choosing = false;
		this.sync();
	}

	/** The fluid now chosen for what the list fills (undefined: free, or nothing chosen). */
	private chosenFluid(): string | undefined {
		if (this.assigning !== undefined) return this.assigning.fluid;
		const editor = this.editor;
		if (editor === undefined || editor.slot === undefined) return undefined;
		return editor.slot === 'result' ? editor.result : editor.inputs[editor.slot]?.fluid;
	}

	private savePanel(): void {
		const assigning = this.assigning;
		if (assigning !== undefined) {
			const request: SetReservoirRequest = {reservoir: assigning.reservoir};
			if (assigning.fluid !== undefined) request.fluid = assigning.fluid;
			if (assigning.capacity !== undefined) request.capacity = assigning.capacity;
			this.actions.setReservoir(request);
			this.assigning = undefined;
		}
		else if (this.editor !== undefined) {
			this.saveEditor();
		}
		this.sync();
	}

	/** Stock tab: ◀ ▶ through auto and the capacities of the modpack's reservoirs. */
	private stepCapacity(direction: number): void {
		const assigning = this.assigning;
		if (assigning === undefined) return;

		const current = assigning.capacity;
		if (direction > 0) {
			assigning.capacity = current === undefined ? CAPACITIES[0] : CAPACITIES.find((capacity) => capacity > current) ?? current;
		}
		else if (current !== undefined) {
			const smaller = CAPACITIES.filter((capacity) => capacity < current);
			assigning.capacity = smaller[smaller.length - 1];
		}
		this.sync();
	}

	private cancelPanel(): void {
		this.assigning = undefined;
		this.editor    = undefined;
		this.choosing  = false;
		this.sync();
	}

	// --------------------------------------------------------- recipe editor

	private pickedOption(): AlloyOption | undefined {
		return this.alloyOptions().find((option) => option.index === this.picked);
	}

	/** Edits a copy of `option`, or starts a new recipe (two ingredients of an ingot each). */
	private openEditor(option: AlloyOption | undefined): void {
		this.editor = option !== undefined
		              ? {
				index: option.index, expected: option.result, result: option.result, amount: option.amount,
				inputs: option.inputs.map((input) => ({fluid: input.fluid, amount: input.amount})), step: INGOT,
			}
		              : {amount: INGOT, inputs: [{amount: INGOT}, {amount: INGOT}], slot: 'result', step: INGOT};
		// A new recipe starts with its result.
		this.choosing   = option === undefined;
		this.choicePage = 1;
		this.sync();
	}

	private pickSlot(slot: 'result' | number): void {
		if (this.editor === undefined) return;
		this.editor.slot = slot;
		this.choosing    = true;
		this.choicePage  = 1;
		this.sync();
	}

	private stepAmount(slot: 'result' | number, direction: number): void {
		const editor = this.editor;
		if (editor === undefined) return;
		const line = slot === 'result' ? editor : editor.inputs[slot];
		if (line === undefined) return;
		line.amount = Math.max(MIN_AMOUNT, line.amount + direction * editor.step);
		this.sync();
	}

	private removeInput(index: number): void {
		const editor = this.editor;
		if (editor === undefined) return;
		editor.inputs.splice(index, 1);
		if (editor.slot === index) editor.slot = undefined;
		else if (typeof editor.slot === 'number' && editor.slot > index) editor.slot--;
		this.sync();
	}

	private addIngredient(): void {
		const editor = this.editor;
		if (editor === undefined || editor.inputs.length >= MAX_INGREDIENTS) return;
		editor.inputs.push({amount: INGOT});
		editor.slot     = editor.inputs.length - 1;
		this.choosing   = true;
		this.choicePage = 1;
		this.sync();
	}

	private setStep(step: number): void {
		if (this.editor !== undefined) this.editor.step = step;
		this.sync();
	}

	/** The recipe written in the editor, or why it cannot be saved. */
	private editedRecipe(): {recipe?: AlloyRatio; problem?: string} {
		const editor = this.editor;
		if (editor === undefined) return {problem: 'no recipe'};
		if (editor.result === undefined) return {problem: 'choose the result'};

		const inputs: {fluid: string; amount: number}[] = [];
		for (const input of editor.inputs) {
			if (input.fluid === undefined) return {problem: 'choose every ingredient'};
			inputs.push({fluid: input.fluid, amount: input.amount});
		}
		const recipe: AlloyRatio = {result: editor.result, amount: editor.amount, inputs};
		const problem = recipeProblem(recipe);
		return problem !== undefined ? {problem} : {recipe};
	}

	private saveEditor(): void {
		const editor = this.editor;
		const {recipe, problem} = this.editedRecipe();
		if (editor === undefined || recipe === undefined) {
			this.notify(problem ?? 'cannot save', N.red);
			return;
		}

		const request: SaveRecipeRequest = {recipe};
		if (editor.index !== undefined) {
			request.index = editor.index;
			if (editor.expected !== undefined) request.expected = editor.expected;
		}
		// A new recipe goes at the end of the catalogue.
		const index = editor.index ?? this.alloyOptions().length;
		this.actions.saveRecipe(request, () => {
			this.editor = undefined;
			this.picked = index;
			this.sync();
		});
	}

	private askDelete(): void {
		const option = this.pickedOption();
		if (option !== undefined) this.confirm = {kind: 'delete', option, step: 1, deadline: 0};
		this.sync();
	}

	// ------------------------------------------------------------------ alloys

	private alloyOptions(): AlloyOption[] {
		return this.state?.alloyOptions ?? [];
	}

	private openPicker(): void {
		const alloy   = this.state?.alloy;
		const options = this.alloyOptions();
		this.picking  = true;
		this.picked   = (options.find((option) => option.result === alloy?.result) ?? options[0])?.index;
		this.nonstop  = alloy !== undefined && alloy.target === undefined;
		if (alloy?.target !== undefined) this.pickIngots = Math.max(1, Math.round(alloy.target / INGOT));
		this.sync();
	}

	private cancelPicker(): void {
		this.picking = false;
		this.sync();
	}

	private pickAlloy(row: number): void {
		const option = this.alloyOptions()[(this.alloyPage - 1) * ALLOYS_PER_PAGE + row];
		if (option !== undefined) this.picked = option.index;
		this.sync();
	}

	/** One ingot at a time up to 9, then a block (9 ingots) at a time. */
	private stepIngots(direction: number): void {
		const step      = direction > 0 ? (this.pickIngots >= 9 ? 9 : 1) : (this.pickIngots > 9 ? 9 : 1);
		this.pickIngots = Math.max(1, this.pickIngots + direction * step);
		this.nonstop    = false;
		this.sync();
	}

	private toggleNonstop(): void {
		this.nonstop = !this.nonstop;
		this.sync();
	}

	private selectAlloy(): void {
		const result = this.pickedOption()?.result;
		if (result === undefined) return;
		const request: SetAlloyRequest = {result, activate: true};
		if (!this.nonstop) request.target = this.pickIngots * INGOT;
		this.actions.setAlloy(request);
		this.picking = false;
		this.sync();
	}

	// ------------------------------------------------------------------ manual

	private pageItems(): InputItemView[] {
		const items = this.state?.inputItems ?? [];
		const start = (this.itemPage - 1) * ITEMS_PER_PAGE;
		return items.slice(start, start + ITEMS_PER_PAGE);
	}

	private pressItem(row: number): void {
		const item = this.pageItems()[row];
		if (item === undefined) return;

		if (item.status === 'ok') this.actions.insert({slot: item.slot});
		else if (item.status === 'alloy' || item.status === 'heat') this.confirm = {kind: 'force', item, step: 1, deadline: 0};
		this.sync();
	}

	private confirmStep(): void {
		const confirm = this.confirm;
		if (confirm === undefined) return;

		if (confirm.step === 1) {
			this.confirm = {...confirm, step: 2, deadline: os.clock() + CONFIRM_SECONDS};
		}
		else if (confirm.kind === 'force') {
			this.confirm = undefined;
			this.actions.insert({slot: confirm.item.slot, force: true});
		}
		else {
			this.confirm = undefined;
			this.picked  = undefined;
			this.actions.deleteRecipe({index: confirm.option.index, expected: confirm.option.result});
		}
		this.sync();
	}

	private cancelConfirm(): void {
		this.confirm = undefined;
		this.sync();
	}

	private fluids(): {name: string; amount: number}[] {
		return (this.state?.fluids ?? []).slice(0, this.fluidButtons.length);
	}

	private castGroups(): CastGroup[] {
		return groupCasters(this.state?.casters ?? [], this.state?.autoFormats ?? []);
	}

	private pickFluid(row: number): void {
		this.fluid = this.fluids()[row]?.name;
		this.sync();
	}

	private pickFormat(row: number): void {
		this.format = this.castGroups()[row]?.format;
		this.sync();
	}

	/** Overview, CASTERS: the format of that row goes in or out of auto mode. */
	private toggleAuto(row: number): void {
		const group = this.castGroups()[(this.castPage - 1) * CASTS_PER_PAGE + row];
		if (group !== undefined && group.format !== 'no cast') this.actions.setFormat({format: group.format, auto: !group.auto});
	}

	private pressCast(): void {
		if (this.fluid !== undefined && this.format !== undefined) this.actions.cast({fluid: this.fluid, format: this.format});
	}

	// ------------------------------------------------------------------ log

	private setLogFilter(filter: LogFilter): void {
		this.logFilter = filter;
		this.logPage   = 1;
		this.sync();
	}

	/** The log lines the filter keeps, oldest first (the caster list printed at start is left out). */
	private logLines(): LogLine[] {
		const lines: LogLine[] = [];
		for (const raw of this.state?.log ?? []) {
			if (raw.substring(8, 11) === '   ') continue;
			const line = parseLogLine(raw);
			if (keeps(this.logFilter, line.kind)) lines.push(line);
		}
		return lines;
	}

	/** Page 1: the latest lines. */
	private pageLogLines(): LogLine[] {
		const lines = this.logLines();
		const end   = Math.max(0, lines.length - (this.logPage - 1) * LOG_LINES);
		return lines.slice(Math.max(0, end - LOG_LINES), end);
	}

	// ------------------------------------------------------------- button state

	private button(label: string, rect: Rect, onPress: () => void): ButtonComponent {
		const button = this.root.place(new ButtonComponent({
			label, padding: 0, foregroundColor: N.text, backgroundColor: N.bg, onPress,
		}), rect);
		this.allButtons.push(button);
		return button;
	}

	private pagination(pageSize: number, rect: Rect, onPageChange: (page: number) => void): PaginationComponent {
		return this.root.place(new PaginationComponent({
			page: 1, pageSize, totalItems: 0, foregroundColor: N.soft, backgroundColor: N.bg, onPageChange,
		}), rect);
	}

	private show(button: ButtonComponent, visible: boolean, label?: string, foreground?: number, background?: number): void {
		const patch: {visible: boolean; label?: string; foregroundColor?: number; backgroundColor?: number} = {visible};
		if (label !== undefined) patch.label = label;
		if (foreground !== undefined) patch.foregroundColor = foreground;
		if (background !== undefined) patch.backgroundColor = background;
		button.setProps(patch);
	}

	/** A neon button: filled when `on`, its color on the background otherwise. */
	private neon(button: ButtonComponent, visible: boolean, label: string | undefined, color: number, on: boolean): void {
		this.show(button, visible, label, on ? N.bg : color, on ? color : N.bg);
	}

	/** Puts every button and pagination in line with the tab, the state and the dialog. */
	private sync(): void {
		const state = this.state;
		const modal = this.confirm !== undefined;
		const ready = state !== undefined;

		for (const [tab, button] of this.tabButtons) this.show(button, true, undefined, tab === this.tab ? N.magenta : N.dim, N.bg);

		const editing = this.tab === 'modes' && ready && this.editor !== undefined;
		const cards   = this.tab === 'modes' && ready && !this.picking && !editing;
		const picker  = this.tab === 'modes' && ready && this.picking && !editing;
		for (const [mode, button] of this.modeButtons) this.neon(button, cards && state.mode !== mode, ' ACTIVATE ', MODE_COLORS[mode], true);
		this.neon(this.changeAlloy, cards, ' CHANGE ALLOY ', N.magenta, false);

		this.syncPicker(picker);
		this.syncEditor(editing);
		this.syncChoices(editing);
		this.syncOverview();
		this.syncStock();
		this.syncManual();
		this.syncLog();

		const confirm = this.confirm;
		const yes = confirm?.kind === 'delete' ? (confirm.step === 2 ? ' DELETE ' : ' CONTINUE ') : (confirm?.step === 2 ? ' FORCE INSERT ' : ' CONTINUE ');
		this.neon(this.confirmYes, modal, yes, confirm?.step === 2 ? N.red : N.yellow, true);
		this.neon(this.confirmNo, modal, ' CANCEL ', N.soft, false);

		// Under the dialog, nothing else can be pressed.
		for (const button of this.allButtons) {
			if (button !== this.confirmYes && button !== this.confirmNo) button.setProps({disabled: modal});
		}
		const paginations = [this.castPages, this.itemPages, this.stockPages, this.alloyPages, this.choicePages, this.logPages];
		for (const pages of paginations) pages.setProps({disabled: modal});
		if (this.pickerOpen() && this.state !== undefined) this.hideUnderPicker();
	}

	private syncPicker(picker: boolean): void {
		const options = this.alloyOptions();
		this.alloyPage = Math.min(this.alloyPage, Math.max(1, Math.ceil(options.length / ALLOYS_PER_PAGE)));
		this.alloyPages.setProps({visible: picker && options.length > ALLOYS_PER_PAGE, totalItems: options.length, page: this.alloyPage});
		const pageOptions = options.slice((this.alloyPage - 1) * ALLOYS_PER_PAGE, this.alloyPage * ALLOYS_PER_PAGE);
		// The name of each alloy is its button (the ingredients under it are painted).
		this.alloyButtons.forEach((button, row) => {
			const option = pageOptions[row];
			const picked = option !== undefined && option.index === this.picked;
			const label  = option !== undefined ? fit(fluidLabel(option.result).toUpperCase(), 36).padEnd(36) : '';
			this.show(button, picker && option !== undefined, label, picked ? N.magenta : N.text, picked ? N.panel : N.bg);
		});
		this.neon(this.lessButton, picker, ' - ', N.cyan, true);
		this.neon(this.moreButton, picker, ' + ', N.cyan, true);
		this.neon(this.nonstopButton, picker, ' NONSTOP ', N.magenta, this.nonstop);
		const pickedOption = this.pickedOption();
		this.neon(this.selectButton, picker && pickedOption !== undefined, ' ACTIVATE ', N.magenta, true);
		this.neon(this.closePicker, picker, ' BACK ', N.soft, false);
		this.neon(this.editButton, picker && pickedOption !== undefined, ' EDIT ', N.purple, false);
		this.neon(this.newButton, picker, ' NEW ', N.purple, false);
		this.neon(this.deleteButton, picker && pickedOption !== undefined, ' DELETE ', N.red, false);
	}

	private syncOverview(): void {
		const overview = this.tab === 'overview' && this.state !== undefined;
		const panel    = overview && this.capacityDraft !== undefined;
		const groups   = this.castGroups();

		this.castPage = Math.min(this.castPage, Math.max(1, Math.ceil(groups.length / CASTS_PER_PAGE)));
		const castsPaged = overview && !panel && groups.length > CASTS_PER_PAGE;
		this.castPages.setProps({visible: castsPaged, totalItems: groups.length, page: this.castPage});
		const pageGroups = groups.slice((this.castPage - 1) * CASTS_PER_PAGE, this.castPage * CASTS_PER_PAGE);
		this.autoButtons.forEach((button, row) => {
			const group = pageGroups[row];
			const shown = overview && !panel && group !== undefined && group.format !== 'no cast';
			this.neon(button, shown, group?.auto === true ? ' AUTO ' : ' off  ', group?.auto === true ? N.lime : N.dim, group?.auto === true);
		});

		this.neon(this.setCapacity, overview, ' SET CAPACITY ', N.cyan, panel);
		this.neon(this.capacityLessButton, panel, ' - ', N.cyan, true);
		this.neon(this.capacityMoreButton, panel, ' + ', N.cyan, true);
		this.capacityStepButtons.forEach((button, index) => {
			this.neon(button, panel, undefined, N.purple, CAPACITY_STEPS[index] === this.capacityStep);
		});
		this.neon(this.capacitySave, panel, ' SAVE ', N.lime, true);
		this.neon(this.capacityAuto, panel, ' AUTO ', N.purple, false);
		this.neon(this.capacityCancel, panel, ' CANCEL ', N.soft, false);
	}

	private syncStock(): void {
		const stock = this.tab === 'stock' && this.state !== undefined;
		const count = this.state?.reservoirs.length ?? 0;
		this.stockPage = Math.min(this.stockPage, Math.max(1, Math.ceil(count / RESERVOIRS_PER_PAGE)));
		this.stockPages.setProps({visible: stock && count > RESERVOIRS_PER_PAGE, totalItems: count, page: this.stockPage});

		// The first line of the name of a reservoir is its button.
		const page = this.pageReservoirs();
		this.reservoirButtons.forEach((button, slot) => {
			const reservoir = page[slot];
			if (!stock || reservoir === undefined) {
				this.show(button, false);
				return;
			}
			const [first] = reservoirLines(reservoir.name, 11);
			const color   = reservoir.name === this.assigning?.reservoir ? N.yellow : reservoir.fluid !== undefined ? N.cyan : N.text;
			this.show(button, true, first.padEnd(11), color, N.bg);
		});
	}

	private syncManual(): void {
		const state   = this.state;
		const tab     = this.tab === 'manual' && state !== undefined;
		const manual  = tab && state.mode === 'manual';
		const count   = state?.inputItems.length ?? 0;
		// The input may have shrunk: never a page past the last one.
		this.itemPage = Math.min(this.itemPage, Math.max(1, Math.ceil(count / ITEMS_PER_PAGE)));
		const items   = this.pageItems();
		const groups  = this.castGroups();

		this.neon(this.switchManual, tab && !manual, ' SWITCH TO MANUAL ', N.yellow, true);
		this.itemPages.setProps({visible: tab && count > ITEMS_PER_PAGE, totalItems: count, page: this.itemPage});
		this.itemButtons.forEach((button, row) => {
			const item = items[row];
			if (!manual || item === undefined || item.status === 'unknown') this.show(button, false);
			else if (item.status === 'ok') this.neon(button, true, ' INSERT ', N.lime, true);
			else this.neon(button, true, ' FORCE  ', N.red, true);
		});

		const fluids = this.fluids();
		this.fluidButtons.forEach((button, row) => {
			const fluid = fluids[row];
			const label = fluid === undefined ? '' : fit(`${fluidLabel(fluid.name)} ${fluid.amount} mB`, 28);
			this.show(button, manual && fluid !== undefined, label.padEnd(28), fluid?.name === this.fluid ? N.text : N.soft, N.bg);
		});

		this.formatButtons.forEach((button, row) => {
			const group = groups[row];
			const total = group === undefined ? 0 : group.free + group.casting + group.ready;
			const label = group === undefined ? '' : `${fit(formatLabel(group.format), 16).padEnd(17)}${group.free} free / ${total}`;
			this.show(button, manual && group !== undefined, label.padEnd(31), group?.format === this.format ? N.text : N.soft, N.bg);
		});

		const canCast   = this.fluid !== undefined && this.format !== undefined;
		const castLabel = canCast ? fit(` POUR ${fluidLabel(this.fluid!)} INTO ${formatLabel(this.format!)} `.toUpperCase(), 31) : ' PICK A FLUID AND A CAST ';
		this.neon(this.castButton, manual, castLabel, canCast ? N.orange : N.dim, canCast);
	}

	private syncLog(): void {
		const log = this.tab === 'log' && this.state !== undefined;
		for (const [filter, label, color] of LOG_FILTERS) this.neon(this.filterButtons.get(filter)!, log, ` ${label} `, color, filter === this.logFilter);

		const lines = this.logLines().length;
		this.logPage = Math.min(this.logPage, Math.max(1, Math.ceil(lines / LOG_LINES)));
		// A filter goes back to page 1 itself: the pagination is given the page, not left on its own.
		this.logPages.setProps({visible: log && lines > LOG_LINES, totalItems: lines, page: this.logPage});
	}

	/** The buttons of the recipe editor. */
	private syncEditor(editing: boolean): void {
		const editor = this.editor;
		const shown  = editing && editor !== undefined;
		const slotColor = (slot: 'result' | number): number => (editor?.slot === slot ? N.yellow : N.text);

		const result = editor?.result !== undefined ? fluidLabel(editor.result) : 'choose...';
		this.show(this.resultButton, shown, fit(result, 20).padEnd(20), editor?.result !== undefined ? slotColor('result') : N.dim, N.bg);
		this.neon(this.resultLess, shown, ' - ', N.cyan, true);
		this.neon(this.resultMore, shown, ' + ', N.cyan, true);

		for (let row = 0; row < MAX_INGREDIENTS; row++) {
			const input   = editor?.inputs[row];
			const visible = shown && input !== undefined;
			const label   = input?.fluid !== undefined ? fluidLabel(input.fluid) : 'choose...';
			const color   = input?.fluid !== undefined ? slotColor(row) : N.dim;
			this.show(this.inputButtons[row]!, visible, fit(label, 20).padEnd(20), color, N.bg);
			this.neon(this.inputLess[row]!, visible, ' - ', N.cyan, true);
			this.neon(this.inputMore[row]!, visible, ' + ', N.cyan, true);
			this.neon(this.inputRemove[row]!, visible, ' x ', N.red, true);
		}
		this.neon(this.addInput, shown && (editor?.inputs.length ?? 0) < MAX_INGREDIENTS, ' + INGREDIENT ', N.purple, false);
		this.stepButtons.forEach((button, index) => this.neon(button, shown, undefined, N.purple, editor?.step === STEPS[index]));
	}

	/** The panel on the right (Stock or editor): Choose / Free, capacity, Save / Cancel; and the fluid picker. */
	private syncChoices(editing: boolean): void {
		const assigning = this.tab === 'stock' && this.assigning !== undefined && this.state !== undefined;
		const picking   = this.pickerOpen() && this.state !== undefined;

		this.neon(this.chooseButton, assigning, ' CHOOSE FLUID ', N.cyan, true);
		this.neon(this.freeButton, assigning, ' FREE ', N.soft, this.assigning?.fluid === undefined);
		this.neon(this.capacityLess, assigning, undefined, N.cyan, true);
		this.neon(this.capacityMore, assigning, undefined, N.cyan, true);

		const panel   = assigning || editing;
		const savable = assigning || this.editedRecipe().recipe !== undefined;
		this.neon(this.panelSave, panel, ' SAVE ', savable ? N.lime : N.dim, true);
		this.neon(this.panelCancel, panel, ' CANCEL ', N.soft, false);

		const fluids = picking ? this.pickerFluids() : [];
		this.choicePage = Math.min(this.choicePage, Math.max(1, Math.ceil(fluids.length / PICKER_PAGE)));
		// A letter changes the page too: the pagination shows it.
		this.choicePages.setProps({visible: picking && fluids.length > PICKER_PAGE, totalItems: fluids.length, page: this.choicePage});

		const chosen = this.chosenFluid();
		const page   = this.pagePickerFluids(fluids);
		this.pickerButtons.forEach((button, cell) => {
			const fluid = page[cell];
			const label = fluid === undefined ? '' : fit(this.pickerLabel(fluid, fluids), 19).padEnd(20);
			this.show(button, picking && fluid !== undefined, label, fluid === chosen ? N.yellow : N.soft, N.bg);
		});
		const known = this.knownChoices();
		this.knownButtons.forEach((button, cell) => {
			const fluid = known[cell];
			const label = fluid === undefined ? '' : fit(this.pickerLabel(fluid, fluids), 19).padEnd(20);
			this.show(button, picking && fluid !== undefined, label, fluid === chosen ? N.yellow : N.text, N.bg);
		});

		// The letters of this page are lit; a letter no fluid starts with is dim.
		const onPage = new Set(page.map((fluid) => fluidLabel(fluid).substring(0, 1)));
		const used   = new Set(fluids.map((fluid) => fluidLabel(fluid).substring(0, 1)));
		this.letterButtons.forEach((button, index) => {
			const letter = LETTERS.charAt(index);
			this.neon(button, picking, undefined, used.has(letter) ? N.purple : N.dim, onPage.has(letter));
		});
		this.neon(this.pickerFree, picking && assigning, ' FREE ', N.soft, chosen === undefined);
		this.neon(this.pickerCancel, picking, ' CANCEL ', N.soft, false);
	}

	/** While the fluid picker is open, only it (and the tabs) can be seen and pressed. */
	private hideUnderPicker(): void {
		const picker = new Set<ButtonComponent>([...this.pickerButtons, ...this.knownButtons, ...this.letterButtons]);
		picker.add(this.pickerFree);
		picker.add(this.pickerCancel);
		for (const button of this.tabButtons.values()) picker.add(button);
		for (const button of this.allButtons) if (!picker.has(button)) button.setProps({visible: false});
		const under = [this.castPages, this.itemPages, this.stockPages, this.alloyPages, this.logPages];
		for (const pages of under) pages.setProps({visible: false});
	}

	// ------------------------------------------------------------------ drawing

	/** Neon brackets: the four corners of a frame, and its title at the top. */
	private bracket(p: Painter, x: number, y: number, width: number, height: number, color: number, title?: string): void {
		const right = x + width - 1, bottom = y + height - 1;
		p.pixel(x, y, 1 + 2 + 4 + 16, color);
		p.pixel(x + 1, y, 1 + 2, color);
		p.pixel(right - 1, y, 1 + 2, color);
		p.pixel(right, y, 1 + 2 + 8 + 32, color);
		p.pixel(x, bottom, 1 + 4 + 16 + 32, color);
		p.pixel(x + 1, bottom, 16 + 32, color);
		p.pixel(right - 1, bottom, 16 + 32, color);
		p.pixel(right, bottom, 2 + 8 + 16 + 32, color);
		if (title !== undefined) p.text(x + 3, y, ` ${fit(title, width - 6)} `, color);
	}

	/** A bar of `width` cells, `part` (0 to 1) of it in `color`. */
	private bar(p: Painter, x: number, y: number, width: number, part: number, color: number): void {
		p.fill(x, y, width, 1, N.panel);
		const filled = part > 0 ? Math.max(1, Math.round(width * Math.min(1, part))) : 0;
		p.fill(x, y, filled, 1, color);
	}

	private paint(p: Painter): void {
		p.fill(1, 1, SCREEN_WIDTH, SCREEN_HEIGHT, N.bg);
		this.paintHeader(p);

		const state = this.state;
		if (state === undefined) {
			p.text(36, 24, 'Waiting for the controller...', N.cyan);
			p.text(31, 26, 'Is the foundry computer running main?', N.dim);
			return;
		}

		if (this.pickerOpen()) {
			this.paintFluidPicker(p);
			this.paintFooter(p, state);
			return;
		}

		if (this.tab === 'overview') this.paintOverview(p, state);
		else if (this.tab === 'modes') this.paintModes(p, state);
		else if (this.tab === 'manual') this.paintManual(p, state);
		else if (this.tab === 'stock') this.paintStock(p, state);
		else this.paintLog(p, state);

		this.paintFooter(p, state);
	}

	private paintHeader(p: Painter): void {
		p.text(3, 2, Glyph.up, N.cyan);
		p.text(5, 2, 'SMELTERY//OS', N.cyan);

		let x = TABS_X;
		for (const [tab, label] of TABS) {
			if (tab === this.tab) p.text(x, 3, Glyph.underline.repeat(label.length), N.magenta);
			x += label.length + 4;
		}

		const mode = this.state?.mode;
		if (mode !== undefined) p.text(84, 2, `${Glyph.dot} ${mode.toUpperCase()}`, MODE_COLORS[mode]);

		const online = os.clock() - this.lastState < OFFLINE_SECONDS;
		p.text(93, 2, online ? 'LINK' : 'LOST', online ? N.cyan : N.red);
		p.fill(98, 2, 1, 1, online ? N.cyan : N.red);
	}

	/** The band at the bottom: a message, the first thing that needs a look, or the last action. */
	private paintFooter(p: Painter, state: SmelteryState): void {
		p.fill(1, 49, SCREEN_WIDTH, 4, N.panel);
		const message = this.message;
		if (message !== undefined && os.clock() < message.until) {
			p.text(3, 50, fit(message.text, 96), message.color, N.panel);
			return;
		}

		if (this.tab === 'log') {
			const shown = this.pageLogLines().length;
			p.text(3, 50, `${shown} of ${this.logLines().length} lines ${Glyph.mid} touch a filter to narrow`, N.dim, N.panel);
			return;
		}

		const lines = attentionLines(state);
		const first = lines[0];
		if (first !== undefined) {
			const more = lines.length > 1 ? ` (+${lines.length - 1} in LOG)` : '';
			const text = `!! ${first.title}${first.detail !== '' ? `: ${first.detail}` : ''}`;
			p.text(3, 50, `${fit(text, 94 - more.length)}${more}`, first.color === colors.red ? N.magenta : N.yellow, N.panel);
			return;
		}

		let last: string | undefined;
		for (let index = state.log.length - 1; index >= 0 && last === undefined; index--) {
			const line = state.log[index];
			if (line !== undefined && line.substring(8, 11) !== '   ') last = line;
		}
		if (last === undefined) return;
		const line = parseLogLine(last);
		p.text(3, 50, line.time, N.dim, N.panel);
		if (line.kind !== 'other') p.text(13, 50, line.kind.toUpperCase(), LOG_COLORS[line.kind], N.panel);
		p.text(21, 50, fit(line.text, 78), N.text, N.panel);
	}

	// ------------------------------------------------------------------ overview

	private paintOverview(p: Painter, state: SmelteryState): void {
		const draft    = this.capacityDraft;
		const capacity = draft ?? state.smelteryCapacity;
		const total    = state.fluids.reduce((sum, fluid) => sum + fluid.amount, 0);

		// The molten total over the last 10 minutes.
		this.bracket(p, 3, 5, 46, 16, N.cyan, `MOLTEN ${Glyph.mid} 10 MIN`);
		const points = [...(state.history ?? []), total];
		const scale  = capacity ?? Math.max(1, ...points);
		const curve  = new Pixels(9, 7, 27, 13);
		const width  = 27 * 2 - 1, height = 13 * 3 - 1;
		curve.line(0, height, width, height, N.dim);
		const place = (index: number): [number, number] => [
			points.length === 1 ? width : Math.round(index * width / (points.length - 1)),
			height - Math.round(height * Math.min(1, points[index]! / scale)),
		];
		for (let index = 1; index < points.length; index++) {
			const [x0, y0] = place(index - 1);
			const [x1, y1] = place(index);
			curve.line(x0, y0, x1, y1, N.cyan);
		}
		if (points.length === 1) {
			const [x0, y0] = place(0);
			curve.set(x0, y0, N.cyan);
		}
		curve.paint(p);
		p.text(5, 7, shortAmount(scale), N.dim);
		p.text(5, 19, '0', N.dim);
		p.text(38, 7, fit(`${total} mB`, 10), N.text);
		p.text(38, 8, capacity !== undefined ? fit(`${Math.round(100 * total / capacity)} % cap`, 10) : 'cap ?', capacity !== undefined ? N.cyan : N.dim);
		const melting = state.melting.reduce((sum, item) => sum + item.count, 0);
		p.text(38, 10, 'melting', N.dim);
		p.text(38, 11, fit(`${melting} item${melting === 1 ? '' : 's'}`, 10), N.soft);

		// The fluids, top first (as in the Smeltery), and the fuel.
		this.bracket(p, 3, 23, 46, 24, N.purple, 'STACK');
		const stack = [...state.fluids].reverse();
		stack.slice(0, 4).forEach((fluid, index) => {
			const y      = 26 + index * 3;
			const color  = fluidColor(fluid.name);
			const amount = `${fluid.amount} mB`;
			p.text(6, y, fit(fluidLabel(fluid.name).toUpperCase(), 38 - amount.length), color);
			p.text(46 - amount.length, y, amount, N.text);
			this.bar(p, 6, y + 1, 40, fluid.amount / scale, color);
		});
		if (stack.length > 4) p.text(6, 37, `+ ${stack.length - 4} more`, N.dim);
		if (stack.length === 0) p.text(6, 26, 'The Smeltery is empty.', N.dim);

		p.text(6, 40, 'FUEL', N.yellow);
		const fuel = state.fuel;
		if (fuel !== undefined) {
			const name = fuel.fluid !== undefined ? fluidLabel(fuel.fluid) : 'empty';
			p.text(11, 40, fit(`${name} ${fuel.amount} mB ${Glyph.mid} ${state.heat ?? '?'} K`, 35), N.text);
			this.bar(p, 6, 41, 40, fuel.amount / FUEL_TANK, N.yellow);
		}
		else {
			p.text(11, 40, fit(`no fuel tank ${Glyph.mid} ${state.heat ?? '?'} K assumed`, 35), N.dim);
		}

		if (draft !== undefined) {
			this.paintCapacity(p, state, draft);
			return;
		}
		this.paintFlow(p, state);
		this.paintCasters(p);
	}

	/** What is left to melt in the input, and what the molten metal will be cast into. */
	private paintFlow(p: Painter, state: SmelteryState): void {
		this.bracket(p, 51, 5, 48, 16, N.magenta, `INPUT ${Glyph.right} OUTPUT`);

		const items  = state.inputItems.filter((item) => item.status !== 'unknown');
		const count  = items.reduce((sum, item) => sum + item.count, 0);
		const amount = items.reduce((sum, item) => sum + item.count * itemAmount(item.name), 0);
		p.text(54, 7, 'TO MELT', N.magenta);
		p.text(63, 7, count === 0 ? 'the input is empty' : fit(`${count} items ${Glyph.mid} ~${amount} mB`, 34), count === 0 ? N.dim : N.text);
		const input = state.input;
		if (input !== undefined) this.bar(p, 54, 8, 30, input.used / Math.max(1, input.size), N.magenta);
		const seconds = state.inputSeconds;
		const eta     = count === 0 ? '' : seconds === undefined ? 'waiting' : seconds <= 0 ? 'done' : `~${Math.max(1, Math.ceil(seconds / 60))} min`;
		p.text(86, 8, fit(eta, 12), N.magenta);

		p.text(54, 10, 'WILL BECOME', N.cyan);
		p.text(67, 10, '(AUTO casts)', N.dim);
		const forecast = [...(state.forecast ?? [])].sort((a, b) => b.amount - a.amount);
		forecast.slice(0, 3).forEach((entry, index) => {
			const y     = 12 + index * 2;
			const color = fluidColor(entry.fluid);
			p.fill(54, y, 1, 1, color);
			p.text(56, y, fit(fluidLabel(entry.fluid), 9), color);
			p.text(66, y, `${entry.amount}`.padStart(5), N.dim);
			const casts = entry.casts.map((cast) => `${cast.count} ${formatLabel(cast.format)}`).join(' ');
			p.text(72, y, `${Glyph.right} ${fit(casts !== '' ? casts : 'stock', 24)}`, N.text);
		});

		const left = forecast.reduce((sum, entry) => sum + entry.left, 0);
		const more = forecast.length > 3 ? ` (+${forecast.length - 3} more)` : '';
		if (forecast.length === 0) p.text(54, 19, 'nothing molten', N.dim);
		else if (left > 0) p.text(54, 19, fit(`${left} mB to the stock${more}`, 43), N.orange);
		else p.text(54, 19, fit(`nothing left over${more}`, 43), N.lime);
	}

	/** The casters by cast, a block each, and the AUTO / off switch of each cast (buttons). */
	private paintCasters(p: Painter): void {
		this.bracket(p, 51, 23, 48, 24, N.lime, 'CASTERS');
		const groups = this.castGroups();
		groups.slice((this.castPage - 1) * CASTS_PER_PAGE, this.castPage * CASTS_PER_PAGE).forEach((group, index) => {
			const y = 26 + index * 3;
			p.text(54, y, fit(formatLabel(group.format).toUpperCase(), 11), group.auto ? N.text : N.dim);
			let x = 66;
			const blocks: [number, number][] = [
				[group.casting, group.auto ? N.orange : N.dim],
				[group.ready, group.auto ? N.yellow : N.dim],
				[group.free, N.panel],
			];
			for (const [count, color] of blocks) {
				for (let n = 0; n < count && x < 88; n++) {
					p.fill(x, y, 2, 1, color);
					x += 3;
				}
			}
		});
		if (groups.length === 0) p.text(54, 26, 'no caster found', N.dim);

		p.fill(54, 42, 2, 1, N.orange);
		p.text(57, 42, 'casting', N.dim);
		p.fill(66, 42, 2, 1, N.yellow);
		p.text(69, 42, 'ready', N.dim);
		p.fill(76, 42, 2, 1, N.panel);
		p.text(79, 42, 'free', N.dim);
		p.text(54, 44, fit('touch AUTO to switch a cast', groups.length > CASTS_PER_PAGE ? 30 : 43), N.dim);
	}

	/** Overview, SET CAPACITY: the value being set (the curve and the stack preview it). */
	private paintCapacity(p: Painter, state: SmelteryState, draft: number): void {
		this.bracket(p, 51, 5, 48, 42, N.cyan, 'SMELTERY CAPACITY');
		p.text(54, 8, 'Total room for molten metal.', N.text);
		p.text(54, 9, 'Read it in the Smeltery screen.', N.dim);

		p.text(54, 12, 'NOW', N.dim);
		const capacity = state.smelteryCapacity;
		const source   = state.smelteryCapacitySource === 'learnt' ? 'learnt (it was full)' : 'set by hand';
		p.text(59, 12, capacity !== undefined ? fit(`${capacity} mB ${Glyph.mid} ${source}`, 38) : 'unknown', capacity !== undefined ? N.cyan : N.dim);

		p.text(66, 17, `${draft} mB`, N.text);
		p.text(54, 22, 'STEP', N.dim);
		p.text(54, 26, 'The curve and the stack preview it.', N.dim);
		p.text(54, 28, 'AUTO: forget it, learn it again the', N.dim);
		p.text(54, 29, 'next time the Smeltery is full.', N.dim);
	}

	// ------------------------------------------------------------------ modes

	/** Text of the alloy card: the chosen alloy. */
	private static alloyLines(state: SmelteryState): string[] {
		if (state.alloy === undefined) return ['No alloy chosen:', 'touch CHANGE ALLOY.'];
		return [fit(`Only ${fluidLabel(state.alloy.result).toUpperCase()},`, 19), 'dosed from the input', 'and the stock.'];
	}

	private paintModes(p: Painter, state: SmelteryState): void {
		if (this.editor !== undefined) {
			this.paintEditor(p, this.editor);
			return;
		}
		if (this.picking) {
			this.paintPicker(p, state);
			return;
		}

		MODES.forEach((mode, index) => {
			const color  = MODE_COLORS[mode];
			const {x, y} = cardPlace(index);
			const active = state.mode === mode;
			this.bracket(p, x, y, 23, 19, color);
			if (active) {
				p.fill(x + 2, y + 1, 19, 1, color);
				p.text(x + 3, y + 1, mode.toUpperCase(), N.bg, color);
			}
			else {
				p.text(x + 3, y + 1, mode.toUpperCase(), color);
			}

			const lines = mode === 'alloy' ? SmelteryScreen.alloyLines(state) : MODE_LINES[mode];
			lines.forEach((line, row) => p.text(x + 2, y + 3 + row, fit(line, 19), active ? N.text : N.dim));

			const alloy = state.alloy;
			if (mode === 'alloy' && alloy !== undefined && active) {
				if (alloy.target === undefined) {
					p.text(x + 2, y + 8, fit(`${Math.floor(alloy.made / INGOT)} ingots made`, 19), N.magenta);
				}
				else {
					const target = Math.max(1, Math.round(alloy.target / INGOT));
					p.text(x + 2, y + 8, fit(`${Math.floor(alloy.made / INGOT)}/${target} ingots`, 19), N.magenta);
					this.bar(p, x + 2, y + 9, 19, alloy.made / alloy.target, N.magenta);
				}
			}
			if (active) {
				const minutes = state.modeSince !== undefined ? Math.max(0, Math.floor((state.time - state.modeSince) / 60000)) : undefined;
				p.text(x + 2, y + 16, fit(`${Glyph.dot} ACTIVE${minutes !== undefined ? ` ${Glyph.mid} ${minutes} min` : ''}`, 19), N.lime);
			}
		});
		p.text(3, 47, 'Touch ACTIVATE: the controller confirms live.', N.dim);
	}

	/** Modes tab, Change alloy: the alloys (those the stock can make first), the recipe and the amount. */
	private paintPicker(p: Painter, state: SmelteryState): void {
		this.bracket(p, 3, 5, 58, 42, N.magenta, `ALLOYS ${Glyph.mid} READY FIRST`);
		const options = this.alloyOptions();
		const start   = (this.alloyPage - 1) * ALLOYS_PER_PAGE;
		const amount  = (mB: number): string => (mB % INGOT === 0 ? `${mB / INGOT}` : `${mB} mB`);

		options.slice(start, start + ALLOYS_PER_PAGE).forEach((option, index) => {
			const y      = 7 + index * 3;
			const picked = option.index === this.picked;
			const back   = picked ? N.panel : N.bg;
			if (picked) {
				p.fill(5, y, 55, 2, N.panel);
				p.text(5, y, Glyph.right, N.magenta, N.panel);
			}
			p.fill(7, y, 2, 1, fluidColor(option.result));
			const inputs = option.inputs.map((input) => `${fluidLabel(input.fluid)} ${amount(input.amount)}`).join(' + ');
			p.text(10, y + 1, fit(inputs, 36), N.dim, back);

			let status: [string, number];
			if (option.temperature !== undefined) status = [`${option.temperature} K!`, N.red];
			else if (option.fromStock > 0) status = [`stock: ${Math.floor(option.fromStock / INGOT)} ing`, N.lime];
			else status = ['input', N.dim];
			p.text(59 - status[0].length, y, status[0], status[1], back);
		});
		if (options.length === 0) p.text(6, 7, 'No alloy in the catalogue: touch NEW.', N.dim);

		this.bracket(p, 63, 31, 36, 16, N.purple, 'CATALOGUE');
		const sameName = options.length - new Set(options.map((option) => option.result)).size;
		p.text(65, 33, fit(`${options.length} recipes${sameName > 0 ? ` ${Glyph.mid} ${sameName} share a name` : ''}`, 32), N.text);

		const option = this.pickedOption();
		if (option === undefined) return;

		const label = fluidLabel(option.result);
		this.bracket(p, 63, 5, 36, 24, N.cyan, label.toUpperCase());
		const count = (mB: number): string => (mB % INGOT === 0 ? `${mB / INGOT} ` : '');
		option.inputs.forEach((input, index) => {
			const y = 7 + index;
			p.fill(65, y, 2, 1, fluidColor(input.fluid));
			p.text(68, y, fit(`${count(input.amount)}${fluidLabel(input.fluid)}`, 20), N.text);
			p.text(90, y, `${input.amount} mB`.padStart(7), N.dim);
		});
		const resultY = 7 + option.inputs.length;
		p.text(68, resultY, fit(`${Glyph.right} ${count(option.amount)}${label}`, 20), colors.pink);
		p.text(90, resultY, `${option.amount} mB`.padStart(7), N.dim);

		const stockY = resultY + 2;
		p.text(65, stockY, 'IN STOCK', N.dim);
		option.inputs.forEach((input, index) => {
			const stored = state.reservoirs
				.filter((reservoir) => reservoir.fluid === input.fluid)
				.reduce((sum, reservoir) => sum + reservoir.amount, 0);
			p.text(65, stockY + 1 + index, fit(fluidLabel(input.fluid), 20), N.text);
			p.text(86, stockY + 1 + index, `${stored} mB`.padStart(11), N.cyan);
		});
		const ingots = Math.floor(option.fromStock / INGOT);
		p.text(65, stockY + 1 + option.inputs.length, `= ${ingots} ingots now`, ingots > 0 ? N.lime : N.dim);

		p.text(65, 20, 'AMOUNT', N.dim);
		p.text(70, 21, this.nonstop ? 'nonstop' : `${this.pickIngots} ingots`, this.nonstop ? N.dim : N.text);
		const back = SmelteryScreen.endsOnItsOwn(state.mode) ? 'the previous mode' : state.mode.toUpperCase();
		p.text(65, 23, fit(this.nonstop ? 'runs until changed' : `then back to ${back}`, 32), N.dim);
	}

	private static endsOnItsOwn(mode: Mode): boolean {
		return mode === 'drain' || mode === 'purge' || mode === 'alloy';
	}

	/** Modes tab, Edit or New: the recipe on the left, the fluid list on the right. */
	private paintEditor(p: Painter, editor: EditorState): void {
		this.bracket(p, 3, 5, 62, 42, N.magenta, editor.index !== undefined ? 'EDIT RECIPE' : 'NEW RECIPE');

		p.text(6, 7, 'RESULT', N.dim);
		if (editor.slot === 'result') p.text(4, 9, Glyph.right, N.yellow);
		if (editor.result !== undefined) p.fill(6, 9, 2, 1, fluidColor(editor.result));
		p.text(35, 9, `${editor.amount} mB`.padStart(8), N.text);

		p.text(6, 12, 'INGREDIENTS', N.dim);
		editor.inputs.forEach((input, row) => {
			const y = 14 + row * 2;
			if (editor.slot === row) p.text(4, y, Glyph.right, N.yellow);
			if (input.fluid !== undefined) p.fill(6, y, 2, 1, fluidColor(input.fluid));
			p.text(35, y, `${input.amount} mB`.padStart(8), N.text);
		});
		if (editor.inputs.length < MAX_INGREDIENTS) p.text(22, 22, `(up to ${MAX_INGREDIENTS})`, N.dim);

		p.text(6, 25, 'STEP', N.dim);
		p.text(31, 25, 'mB', N.dim);

		const {recipe, problem} = this.editedRecipe();
		if (recipe !== undefined) {
			const amount = (mB: number, fluid: string): string => `${mB % INGOT === 0 ? `${mB / INGOT} ing` : `${mB} mB`} ${fluidLabel(fluid)}`;
			p.text(6, 28, 'ready to save', N.lime);
			p.text(6, 30, fit(recipe.inputs.map((input) => amount(input.amount, input.fluid)).join(' + '), 56), N.soft);
			p.text(6, 31, fit(`makes ${amount(recipe.amount, recipe.result)}`, 56), colors.pink);
		}
		else {
			p.text(6, 28, fit(`cannot save: ${problem ?? '?'}`, 56), N.red);
		}

		this.bracket(p, 67, 5, 32, 42, N.cyan, 'FLUIDS');
		p.text(70, 7, 'Touch the result or an', N.dim);
		p.text(70, 8, 'ingredient: the fluid', N.dim);
		p.text(70, 9, 'picker opens.', N.dim);
	}

	/** Is the fluid picker over the screen now. */
	private pickerOpen(): boolean {
		if (!this.choosing) return false;
		if (this.tab === 'stock') return this.assigning !== undefined;
		return this.tab === 'modes' && this.editor !== undefined && this.editor.slot !== undefined;
	}

	/** The fluid picker: letters, the KNOWN fluids, then every fluid by name, 4 columns a page. */
	private paintFluidPicker(p: Painter): void {
		const editor = this.editor;
		let target: string;
		if (this.assigning !== undefined) target = placeLabel(this.assigning.reservoir);
		else if (editor?.slot === 'result') target = 'the result';
		else target = `ingredient ${(typeof editor?.slot === 'number' ? editor.slot : 0) + 1}`;
		this.bracket(p, 3, 5, 96, 43, N.cyan, `CHOOSE FLUID ${Glyph.mid} for ${target}`);

		const fluids = this.pickerFluids();
		const chosen = this.chosenFluid();
		const mark   = (x: number, y: number, fluid: string): void => {
			p.fill(x, y, 2, 1, fluidColor(fluid));
			if (fluid === chosen) p.text(x - 1, y, Glyph.right, N.yellow);
		};

		p.text(6, 9, 'KNOWN', N.yellow);
		const known = this.knownChoices();
		known.slice(0, PICKER_KNOWN).forEach((fluid, index) => mark(6 + index * 23, 10, fluid));
		if (known.length === 0) p.text(9, 10, 'nothing seen yet', N.dim);

		const page = this.pagePickerFluids(fluids);
		const from = page[0] !== undefined ? fluidLabel(page[0]).substring(0, 1).toUpperCase() : '';
		p.text(6, 12, `ALL FLUIDS${from !== '' ? ` ${Glyph.mid} from ${from}` : ''}`, N.dim);
		page.forEach((fluid, index) => mark(6 + Math.floor(index / PICKER_ROWS) * 23, 13 + index % PICKER_ROWS, fluid));
		if (this.allFluids === undefined) p.text(9, 13, 'loading...', N.dim);

		const start = (this.choicePage - 1) * PICKER_PAGE;
		const count = fluids.length > PICKER_PAGE ? `${start + 1}-${start + page.length} of ${fluids.length}` : `${fluids.length} fluids`;
		p.text(fluids.length > PICKER_PAGE ? 20 : 6, 45, fit(`${count} ${Glyph.mid} a letter jumps to its page`, 60), N.dim);
	}

	// ------------------------------------------------------------------ manual

	private paintManual(p: Painter, state: SmelteryState): void {
		const manual = state.mode === 'manual';
		const ink    = manual ? N.text : N.dim;

		p.fill(3, 5, 96, 3, N.panel);
		p.fill(3, 5, 1, 3, manual ? N.lime : N.yellow);
		if (manual) p.text(6, 6, fit(`MANUAL MODE ${Glyph.mid} touch INSERT, or pick a fluid and a cast`, 90), N.lime, N.panel);
		else p.text(6, 6, fit(`MANUAL MODE IS OFF ${Glyph.mid} insert and cast need it`, 70), N.yellow, N.panel);

		this.bracket(p, 3, 10, 58, 37, manual ? N.cyan : N.dim, 'INSERT');
		this.pageItems().forEach((item, row) => {
			const y = 13 + row * 4;
			p.text(6, y, fit(placeLabel(item.name).toUpperCase(), 42), ink);
			let detail = `x${item.count} ${Glyph.right} ${item.fluid !== undefined ? fluidLabel(item.fluid) : 'no fluid'}`;
			let color  = manual ? N.soft : N.dim;
			if (item.status === 'alloy') {
				detail += ` ${Glyph.mid} would form ${fluidLabel(item.alloy ?? 'an alloy')}`;
				color = manual ? N.red : N.dim;
			}
			else if (item.status === 'heat') {
				detail += ` ${Glyph.mid} needs ${item.temperature ?? '?'} K`;
				color = manual ? N.red : N.dim;
			}
			p.text(6, y + 1, fit(detail, 42), color);
		});
		if (state.inputItems.length === 0) p.text(6, 13, 'The input is empty.', N.dim);

		this.bracket(p, 63, 10, 36, 37, manual ? N.orange : N.dim, 'CAST');
		p.text(66, 12, 'FLUID', N.dim);
		this.fluids().forEach((fluid, row) => {
			const y = 14 + row * 2;
			if (fluid.name === this.fluid) p.text(64, y, Glyph.right, N.yellow);
			p.fill(66, y, 2, 1, manual ? fluidColor(fluid.name) : N.dim);
			if (!manual) p.text(69, y, fit(`${fluidLabel(fluid.name)} ${fluid.amount} mB`, 28), N.dim);
		});
		p.text(66, 25, 'INTO', N.dim);
		const groups = this.castGroups();
		groups.slice(0, 5).forEach((group, row) => {
			const y = 27 + row * 2;
			if (group.format === this.format) p.text(64, y, Glyph.right, N.yellow);
			if (!manual) p.text(66, y, `${fit(formatLabel(group.format), 16).padEnd(17)}${group.free} free / ${group.free + group.casting + group.ready}`, N.dim);
		});
	}

	// ------------------------------------------------------------------ stock

	private paintStock(p: Painter, state: SmelteryState): void {
		const reservoirs = state.reservoirs;

		// Reservoirs: a tube each, filled to its capacity once known (type, set by hand, or learnt).
		this.bracket(p, 3, 5, 62, 43, N.cyan, `RESERVOIRS ${Glyph.mid} FULL FIRST`);
		let known = 0;
		let scale = 0;
		for (const reservoir of reservoirs) {
			if (reservoir.capacity === undefined) continue;
			known++;
			scale = Math.max(scale, reservoir.capacity);
		}
		if (scale === 0) scale = DEFAULT_CAPACITY;

		this.pageReservoirs().forEach((reservoir, index) => {
			const {x, y} = SmelteryScreen.reservoirPlace(index);
			const fluid  = reservoir.fluid;
			const color  = fluid !== undefined ? fluidColor(fluid) : N.dim;

			// A tube of 8 x 12 pixels (4 x 4 cells): its outline, and the fluid inside.
			const tube = new Pixels(x + 1, y, 4, 4);
			tube.rect(0, 0, 1, 12, color);
			tube.rect(7, 0, 1, 12, color);
			tube.rect(0, 11, 8, 1, color);
			if (fluid !== undefined && reservoir.amount > 0) {
				const rows = Math.min(11, Math.max(1, Math.round(11 * reservoir.amount / (reservoir.capacity ?? scale))));
				tube.rect(1, 11 - rows, 6, rows, color);
			}
			tube.paint(p);
			if (reservoir.capacity !== undefined && reservoir.amount >= reservoir.capacity) p.text(x + 6, y, 'FULL', N.yellow);
			if (reservoir.name === this.assigning?.reservoir) p.text(x - 1, y + 6, Glyph.right, N.yellow);

			let label: [string, number];
			if (fluid !== undefined && reservoir.assigned !== undefined && reservoir.assigned !== fluid) label = [`for ${fluidLabel(reservoir.assigned)}`, N.orange];
			else if (fluid !== undefined) label = [`${reservoir.amount} mB`, N.text];
			else if (reservoir.assigned !== undefined) label = [`for ${fluidLabel(reservoir.assigned)}`, N.yellow];
			else label = ['free', N.dim];
			p.text(x, y + 5, fit(label[0], 11), label[1]);
			p.text(x, y + 7, reservoirLines(reservoir.name, 11)[1], N.dim);
		});
		if (reservoirs.length === 0) p.text(6, 7, 'No reservoir found.', N.dim);
		else p.text(reservoirs.length > RESERVOIRS_PER_PAGE ? 19 : 6, 45, 'touch a name to reserve it', N.dim);

		if (this.assigning !== undefined) {
			this.paintAssign(p, state, this.assigning);
			return;
		}

		// Totals by fluid, biggest first, in ingots.
		this.bracket(p, 67, 5, 32, 18, N.purple, 'TOTALS');
		const totals: {fluid: string; amount: number}[] = [];
		for (const reservoir of reservoirs) {
			if (reservoir.fluid === undefined) continue;
			const entry = totals.find((candidate) => candidate.fluid === reservoir.fluid);
			if (entry !== undefined) entry.amount += reservoir.amount;
			else totals.push({fluid: reservoir.fluid, amount: reservoir.amount});
		}
		totals.sort((a, b) => b.amount - a.amount);
		const biggest = totals[0]?.amount ?? 1;
		totals.slice(0, 4).forEach((total, index) => {
			const y      = 7 + index * 4;
			const color  = fluidColor(total.fluid);
			const ingots = `${Math.floor(total.amount / INGOT)} ing`;
			p.text(70, y, fit(fluidLabel(total.fluid).toUpperCase(), 25 - ingots.length), color);
			p.text(96 - ingots.length, y, ingots, N.text);
			this.bar(p, 70, y + 1, 26, total.amount / biggest, color);
		});
		if (totals.length > 4) p.text(70, 21, `+ ${totals.length - 4} more`, N.dim);
		if (totals.length === 0) p.text(70, 7, 'Nothing stored.', N.dim);

		// Room left: free reservoirs, and those kept for one fluid.
		this.bracket(p, 67, 24, 32, 10, N.lime, 'ROOM');
		const empty    = reservoirs.filter((reservoir) => reservoir.fluid === undefined);
		const free     = empty.filter((reservoir) => reservoir.assigned === undefined).length;
		const assigned = empty.filter((reservoir) => reservoir.assigned !== undefined);
		let room = `${free} free`;
		if (assigned.length === 1) room += ` ${Glyph.mid} 1 for ${fluidLabel(assigned[0]!.assigned!)}`;
		else if (assigned.length > 1) room += ` ${Glyph.mid} ${assigned.length} reserved`;
		p.text(70, 26, fit(room, 27), N.text);
		p.text(70, 28, `capacity known ${known}/${reservoirs.length}`, N.dim);
		p.text(70, 30, 'touch a name to set it', N.dim);

		// What the stock is waiting for: no room for a fluid (an alert), or the stocks too small to cast.
		const alerts = state.alerts.filter((alert) => alert.startsWith('no reservoir'));
		const small  = state.smallStocks ?? [];
		if (alerts.length > 0) {
			this.bracket(p, 67, 35, 32, 13, N.red, 'NO ROOM');
			const [line] = attentionLines({...state, alerts, waiting: []});
			if (line !== undefined) {
				p.text(70, 37, fit(line.title, 27), N.red);
				p.text(70, 38, fit(line.detail, 27), N.dim);
			}
			if (alerts.length > 1) p.text(70, 40, `+ ${alerts.length - 1} more`, N.dim);
		}
		else if (small.length > 0) {
			this.bracket(p, 67, 35, 32, 13, N.yellow, 'BELOW A CAST');
			small.slice(0, 3).forEach((stock, index) => {
				const y      = 37 + index * 3;
				const holder = reservoirs.find((reservoir) => reservoir.fluid === stock.name);
				p.fill(70, y, 1, 1, fluidColor(stock.name));
				p.text(72, y, fit(`${fluidLabel(stock.name)} ${stock.amount} mB`, 25), N.text);
				p.text(72, y + 1, fit(`${holder !== undefined ? `${placeLabel(holder.name)} ${Glyph.mid} ` : ''}waits for more`, 25), N.dim);
			});
		}
	}

	/** Stock tab, a reservoir touched: what it holds, and the list of fluids to reserve it for. */
	private paintAssign(p: Painter, state: SmelteryState, assigning: Assigning): void {
		const reservoir = state.reservoirs.find((candidate) => candidate.name === assigning.reservoir);
		this.bracket(p, 67, 5, 32, 42, N.yellow, 'ASSIGN RESERVOIR');
		p.text(70, 6, fit(placeLabel(assigning.reservoir), 27), N.text);
		if (reservoir?.fluid !== undefined) p.text(70, 7, fit(`holds ${fluidLabel(reservoir.fluid)} ${reservoir.amount} mB`, 27), N.soft);
		else p.text(70, 7, 'empty', N.dim);
		const now = reservoir?.assigned !== undefined ? `for ${fluidLabel(reservoir.assigned)}` : 'free';
		p.text(70, 8, fit(`now: ${now}`, 27), N.dim);

		p.text(70, 10, 'RESERVE FOR', N.dim);
		if (assigning.fluid !== undefined) {
			p.fill(70, 11, 2, 1, fluidColor(assigning.fluid));
			p.text(73, 11, fit(fluidLabel(assigning.fluid), 24), N.text);
		}
		else {
			p.text(70, 11, 'free (any fluid)', N.soft);
		}

		const holds = reservoir?.fluid;
		if (holds !== undefined && assigning.fluid !== undefined && assigning.fluid !== holds) {
			p.text(70, 35, fit(`Keeps its ${fluidLabel(holds)}, no more;`, 27), N.orange);
			p.text(70, 36, fit(`${fluidLabel(assigning.fluid)} once empty.`, 27), N.dim);
		}
		else {
			p.text(70, 35, 'Reserved: only that fluid.', N.dim);
			p.text(70, 36, 'Free: any, when empty.', N.dim);
		}

		// Capacity: set by hand, or auto (learnt when it refused fluid, or given by its type).
		p.text(70, 38, 'CAPACITY', N.dim);
		const source = reservoir?.capacitySource;
		let value: string;
		if (assigning.capacity !== undefined) {
			p.text(79, 38, 'set by hand', N.text);
			value = `${assigning.capacity} mB`;
		}
		else if (reservoir?.capacity !== undefined && source !== 'set') {
			p.text(79, 38, source === 'learnt' ? 'learnt' : 'from its type', N.dim);
			value = `auto ${reservoir.capacity}`;
		}
		else if (source === 'set') {
			p.text(79, 38, 'type or learnt', N.dim);
			value = 'auto';
		}
		else {
			p.text(79, 38, 'unknown: set it', N.orange);
			value = 'auto ?';
		}
		p.text(75, 39, value.padStart(16), N.text);
	}

	// ------------------------------------------------------------------ log

	private paintLog(p: Painter, state: SmelteryState): void {
		const lines = this.pageLogLines();
		lines.forEach((line, index) => {
			const y     = 8 + index * 2;
			const alert = line.kind === 'alert' || line.kind === 'forced';
			if (alert) p.fill(3, y, 96, 1, N.panel);
			const back = alert ? N.panel : N.bg;
			p.text(3, y, line.time, N.dim, back);
			p.fill(13, y, 1, 1, LOG_COLORS[line.kind]);
			p.text(15, y, line.kind === 'other' ? 'INFO' : line.kind.toUpperCase(), LOG_COLORS[line.kind], back);
			p.text(23, y, fit(line.text, 76), alert ? N.red : N.text, back);
		});
		if (lines.length === 0) p.text(3, 8, state.log.length === 0 ? 'Nothing yet.' : 'Nothing for this filter.', N.dim);
	}

	// ------------------------------------------------------------------ dialog

	private paintConfirm(p: Painter): void {
		const confirm = this.confirm;
		if (confirm === undefined) return;

		const x = 25, y = 18, width = 51, height = 13;
		const color = confirm.step === 2 ? N.red : N.yellow;
		p.fill(x, y, width, height, N.bg);
		this.bracket(p, x, y, width, height, color);

		if (confirm.kind === 'delete') {
			this.paintDelete(p, confirm.option, confirm.step, confirm.deadline, x, y, color);
			return;
		}

		const item = confirm.item;
		const what = item.status === 'alloy'
		             ? `will form ${fluidLabel(item.alloy ?? 'an alloy')}.`
		             : `needs ${item.temperature ?? '?'} K: it may not melt.`;

		p.text(x + 3, y + 2, 'FORCE INSERT', color);
		p.text(x + 16, y + 2, `step ${confirm.step} of 2`, N.dim);
		p.text(x + 3, y + 4, fit(`${item.count} ${placeLabel(item.name)}`, 45), N.text);
		p.text(x + 3, y + 5, fit(what, 45), N.soft);

		if (confirm.step === 1) {
			p.text(x + 3, y + 7, 'Check what will happen before going on.', N.dim);
		}
		else {
			p.text(x + 3, y + 7, item.status === 'alloy' ? 'An alloy cannot be undone.' : 'It stays in the Smeltery until hot enough.', N.dim);
			p.text(x + 21, y + 12, `${Math.max(0, Math.ceil(confirm.deadline - os.clock()))} s`, N.dim);
		}
	}

	/** Inside the confirmation frame: the recipe to delete, and what happens to alloy mode. */
	private paintDelete(p: Painter, option: AlloyOption, step: 1 | 2, deadline: number, x: number, y: number, color: number): void {
		p.text(x + 3, y + 2, 'DELETE RECIPE', color);
		p.text(x + 17, y + 2, `step ${step} of 2`, N.dim);
		const inputs = option.inputs.map((input) => `${input.amount} ${fluidLabel(input.fluid)}`).join(' + ');
		p.text(x + 3, y + 4, fit(inputs, 45), N.text);
		p.text(x + 3, y + 5, fit(`makes ${option.amount} mB ${fluidLabel(option.result)}`, 45), colors.pink);

		// The last recipe of the chosen alloy: alloy mode has nothing left to make.
		const state = this.state;
		const last  = state?.alloy?.result === option.result
		              && !this.alloyOptions().some((other) => other.index !== option.index && other.result === option.result);
		if (last && state?.mode === 'alloy') {
			p.text(x + 3, y + 7, 'It is the alloy being made: alloy mode', N.orange);
			p.text(x + 3, y + 8, 'stops and goes back to the previous mode.', N.orange);
		}
		else if (last) {
			p.text(x + 3, y + 7, 'It is the alloy chosen for alloy mode:', N.orange);
			p.text(x + 3, y + 8, 'none will be chosen any more.', N.orange);
		}
		else {
			p.text(x + 3, y + 7, step === 1 ? 'Check the recipe before going on.' : 'It cannot be undone.', N.dim);
		}

		if (step === 2) p.text(x + 21, y + 12, `${Math.max(0, Math.ceil(deadline - os.clock()))} s`, N.dim);
	}
}
