import type {AlloyRatio}                     from '@modules/tinkers/index';
import {ButtonComponent, PaginationComponent} from '@modules/ui/components';
import type {Rect}                           from '@modules/ui/types';

import type {AlloyOption, CastRequest, DeleteRecipeRequest, InputItemView, InsertRequest, Mode, SaveRecipeRequest, SetAlloyRequest, SetReservoirRequest, SetFormatRequest, SmelteryState} from '../shared/protocol';
import {MAX_INGREDIENTS, MODES}              from '../shared/protocol';
import {recipeProblem}                       from '../shared/recipes';

import {attentionLines, fluidChoices, fluidColor, fluidLabel, formatLabel, Glyph, groupCasters, itemLabel, knownFluids, parseLogLine, textOn} from './model';
import type {CastGroup, FluidChoice, LogKind} from './model';
import {AbsoluteLayout, PaintComponent}      from './widgets';
import type {Painter}                        from './widgets';

export const SCREEN_WIDTH  = 79;
export const SCREEN_HEIGHT = 38;

type Tab = 'overview' | 'modes' | 'manual' | 'stock' | 'log';

/** What the screen asks the controller; the answers come back through setState(). */
export interface ScreenActions {
	setMode(mode: Mode): void;
	insert(request: InsertRequest): void;
	cast(request: CastRequest): void;
	setFormat(request: SetFormatRequest): void;
	setAlloy(request: SetAlloyRequest): void;
	setReservoir(request: SetReservoirRequest): void;
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

const TABS: [Tab, string][] = [['overview', 'Overview'], ['modes', 'Modes'], ['manual', 'Manual'], ['stock', 'Stock'], ['log', 'Log']];
/** Column of the first tab: the last one ends before the mode badge (column 67). */
const TABS_X = 23;

/** Card texts fit the 17 columns of a card (16 with its margin). */
const MODE_CARDS: Record<Mode, {color: number; lines: string[]}> = {
	idle:   {color: colors.lightGray, lines: ['Full stop.', 'Nothing moves.']},
	auto:   {color: colors.lime, lines: ['Melts the input', 'and casts pure', 'metals.']},
	manual: {color: colors.orange, lines: ['You insert and', 'cast from the', 'Manual tab.']},
	lock:   {color: colors.red, lines: ['Nothing new goes', 'in; the casts', 'under way finish.']},
	drain:  {color: colors.lightBlue, lines: ['Every fluid to', 'the reservoirs,', 'then idle.']},
	purge:  {color: colors.purple, lines: ['Leftovers and', 'alloys to the', 'reservoirs.']},
	// The alloy card names the chosen alloy (alloyLines).
	alloy:  {color: colors.magenta, lines: []},
	melt:   {color: colors.cyan, lines: ['Melts the input', 'into the stock,', 'casts nothing.']},
};

const LOG_COLORS: Record<LogKind, number> = {
	in:     colors.lightBlue,
	cast:   colors.white,
	out:    colors.lime,
	reject: colors.orange,
	forced: colors.red,
	mode:   colors.yellow,
	other:  colors.lightGray,
};

const CASTS_PER_PAGE  = 4;
const ALLOYS_PER_PAGE = 8;
/** mB of an ingot: the amounts of alloy mode are chosen in ingots. */
const INGOT = 90;
const ITEMS_PER_PAGE  = 6;
const RESERVOIRS_PER_PAGE = 8;
/** Rows of the fluid lists (Stock: reserve a reservoir; recipe editor: choose a fluid). */
const CHOICE_ROWS = 14;
/** Steps of the recipe editor's - and + (mB). */
const STEPS = [10, 90, 1000];
/** Smallest amount of a recipe line. */
const MIN_AMOUNT = 10;
/** Capacities ◀ ▶ go through on the Stock tab (the reservoirs of the modpack); before them, auto. */
const CAPACITIES = [16000, 32000, 64000, 256000, 1024000, 4096000];
/** Level of a reservoir whose capacity is not known yet: the biggest known one, or this. */
const DEFAULT_CAPACITY = 16000;
const LOG_LINES       = 13;
const CONFIRM_SECONDS = 10;
const OFFLINE_SECONDS = 12;

/** Mode cards, four per row: the top-left corner of the `index`-th one. */
function cardPlace(this: void, index: number): {x: number; y: number} {
	return {x: 3 + (index % 4) * 19, y: 8 + Math.floor(index / 4) * 12};
}

const FULL_SCREEN: Rect = {x: 1, y: 1, width: SCREEN_WIDTH, height: SCREEN_HEIGHT};

/**
 * The monitor of the Smeltery, drawn to the character (79 x 38 at text scale 0.5): paint components draw,
 * EmberCore buttons and paginations take the touches. All coordinates are 1-based, as on the monitor.
 */
export class SmelteryScreen {
	public readonly root = new AbsoluteLayout(SCREEN_WIDTH, SCREEN_HEIGHT);

	private state?: SmelteryState | undefined;
	private lastState = -Infinity;
	private tab: Tab  = 'overview';
	private castPage  = 1;
	private itemPage  = 1;
	private stockPage = 1;
	/** Modes tab: the alloy picker is open instead of the cards. */
	private picking   = false;
	private alloyPage = 1;
	/** Recipe picked in the list (AlloyOption.index). */
	private picked?: number | undefined;
	private editor?: EditorState | undefined;
	private assigning?: Assigning | undefined;
	private choicePage = 1;
	/** Every fluid of the catalogue (sorted), once the controller sent it. */
	private allFluids?: string[] | undefined;
	private pickIngots = 16;
	private nonstop    = false;
	private logOffset = 0;
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
	private readonly logUp: ButtonComponent;
	private readonly logDown: ButtonComponent;
	private readonly confirmYes: ButtonComponent;
	private readonly confirmNo: ButtonComponent;
	private readonly castPages: PaginationComponent;
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
	private readonly choiceButtons: ButtonComponent[] = [];
	private readonly choicePages: PaginationComponent;
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

		MODES.forEach((mode, index) => {
			const card = cardPlace(index);
			this.modeButtons.set(mode, this.button(' Activate ', {x: card.x + 1, y: card.y + 6, width: 10, height: 1}, () => this.actions.setMode(mode)));
		});

		this.castPages = this.root.place(new PaginationComponent({
			page: 1, pageSize: CASTS_PER_PAGE, totalItems: 0, foregroundColor: colors.lightGray, backgroundColor: colors.black,
			onPageChange: (page) => {
				this.castPage = page;
			},
		}), {x: 59, y: 19, width: 11, height: 1});

		for (let row = 0; row < CASTS_PER_PAGE; row++) {
			const index = row;
			this.autoButtons.push(this.button('', {x: 71, y: 7 + index * 3, width: 6, height: 1}, () => this.toggleAuto(index)));
		}

		this.stockPages = this.root.place(new PaginationComponent({
			page: 1, pageSize: RESERVOIRS_PER_PAGE, totalItems: 0, foregroundColor: colors.lightGray, backgroundColor: colors.black,
			onPageChange: (page) => {
				this.stockPage = page;
			},
		}), {x: 3, y: 35, width: 11, height: 1});

		// TSTL compiles `for (let ...)` to one shared Lua variable: closures must capture a per-iteration const.
		for (let row = 0; row < ITEMS_PER_PAGE; row++) {
			const index = row;
			this.itemButtons.push(this.button('', {x: 37, y: 8 + index * 3, width: 8, height: 1}, () => this.pressItem(index)));
		}

		this.itemPages = this.root.place(new PaginationComponent({
			page: 1, pageSize: ITEMS_PER_PAGE, totalItems: 0, foregroundColor: colors.lightGray, backgroundColor: colors.black,
			onPageChange: (page) => {
				this.itemPage = page;
			},
		}), {x: 3, y: 27, width: 11, height: 1});

		for (let row = 0; row < 5; row++) {
			const index = row;
			this.fluidButtons.push(this.button('', {x: 58, y: 10 + index * 2, width: 20, height: 1}, () => this.pickFluid(index)));
			this.formatButtons.push(this.button('', {x: 53, y: 22 + index * 2, width: 25, height: 1}, () => this.pickFormat(index)));
		}

		this.castButton = this.button('', {x: 53, y: 34, width: 25, height: 1}, () => this.pressCast());
		this.logUp      = this.button(` ${Glyph.up} `, {x: 70, y: 5, width: 3, height: 1}, () => this.scrollLog(1));
		this.logDown    = this.button(` ${Glyph.down} `, {x: 74, y: 5, width: 3, height: 1}, () => this.scrollLog(-1));

		// The alloy card and its picker (Modes tab).
		const alloyCard  = cardPlace(MODES.indexOf('alloy'));
		this.changeAlloy = this.button(' Change alloy ', {x: alloyCard.x + 1, y: alloyCard.y + 9, width: 14, height: 1}, () => this.openPicker());
		for (let row = 0; row < ALLOYS_PER_PAGE; row++) {
			const index = row;
			this.alloyButtons.push(this.button('', {x: 8, y: 7 + index * 3, width: 24, height: 1}, () => this.pickAlloy(index)));
		}
		this.alloyPages = this.root.place(new PaginationComponent({
			page: 1, pageSize: ALLOYS_PER_PAGE, totalItems: 0, foregroundColor: colors.lightGray, backgroundColor: colors.black,
			onPageChange: (page) => {
				this.alloyPage = page;
			},
		}), {x: 3, y: 32, width: 11, height: 1});
		this.lessButton    = this.button(' - ', {x: 53, y: 22, width: 3, height: 1}, () => this.stepIngots(-1));
		this.moreButton    = this.button(' + ', {x: 69, y: 22, width: 3, height: 1}, () => this.stepIngots(1));
		this.nonstopButton = this.button(' Until stopped ', {x: 53, y: 24, width: 15, height: 1}, () => this.toggleNonstop());
		this.selectButton  = this.button('', {x: 53, y: 30, width: 21, height: 1}, () => this.selectAlloy());
		this.closePicker   = this.button(' Cancel ', {x: 53, y: 32, width: 8, height: 1}, () => this.cancelPicker());

		// Stock: the name of each reservoir is its button (touch it to reserve the reservoir).
		for (let slot = 0; slot < RESERVOIRS_PER_PAGE; slot++) {
			const index = slot;
			const place = SmelteryScreen.reservoirPlace(index);
			this.reservoirButtons.push(this.button('', {x: place.x, y: place.y + 10, width: 11, height: 1}, () => this.pressReservoir(index)));
		}

		// The fluid list, on the right: Stock (reserve a reservoir) and the recipe editor.
		for (let row = 0; row < CHOICE_ROWS; row++) {
			const index = row;
			this.choiceButtons.push(this.button('', {x: 59, y: 10 + index, width: 20, height: 1}, () => this.pressChoice(index)));
		}
		this.choicePages = this.root.place(new PaginationComponent({
			page: 1, pageSize: CHOICE_ROWS, totalItems: 0, foregroundColor: colors.lightGray, backgroundColor: colors.black,
			onPageChange: (page) => {
				this.choicePage = page;
			},
		}), {x: 55, y: 25, width: 11, height: 1});
		this.capacityLess = this.button(` ${Glyph.left} `, {x: 55, y: 31, width: 3, height: 1}, () => this.stepCapacity(-1));
		this.capacityMore = this.button(` ${Glyph.right} `, {x: 73, y: 31, width: 3, height: 1}, () => this.stepCapacity(1));
		this.panelSave   = this.button(' Save ', {x: 55, y: 33, width: 6, height: 1}, () => this.savePanel());
		this.panelCancel = this.button(' Cancel ', {x: 63, y: 33, width: 8, height: 1}, () => this.cancelPanel());

		// The alloy picker: edit, add or delete the recipe picked.
		this.editButton   = this.button(' Edit ', {x: 53, y: 34, width: 6, height: 1}, () => this.openEditor(this.pickedOption()));
		this.newButton    = this.button(' New ', {x: 60, y: 34, width: 5, height: 1}, () => this.openEditor(undefined));
		this.deleteButton = this.button(' Delete ', {x: 66, y: 34, width: 8, height: 1}, () => this.askDelete());

		// The recipe editor.
		this.resultButton = this.button('', {x: 6, y: 9, width: 18, height: 1}, () => this.pickSlot('result'));
		this.resultLess   = this.button(' - ', {x: 25, y: 9, width: 3, height: 1}, () => this.stepAmount('result', -1));
		this.resultMore   = this.button(' + ', {x: 38, y: 9, width: 3, height: 1}, () => this.stepAmount('result', 1));
		for (let row = 0; row < MAX_INGREDIENTS; row++) {
			const index = row;
			const y     = 14 + index * 2;
			this.inputButtons.push(this.button('', {x: 6, y, width: 18, height: 1}, () => this.pickSlot(index)));
			this.inputLess.push(this.button(' - ', {x: 25, y, width: 3, height: 1}, () => this.stepAmount(index, -1)));
			this.inputMore.push(this.button(' + ', {x: 38, y, width: 3, height: 1}, () => this.stepAmount(index, 1)));
			this.inputRemove.push(this.button(' x ', {x: 43, y, width: 3, height: 1}, () => this.removeInput(index)));
		}
		this.addInput = this.button(' + ingredient ', {x: 3, y: 22, width: 14, height: 1}, () => this.addIngredient());
		let stepX = 9;
		for (const step of STEPS) {
			const label = ` ${step} `;
			this.stepButtons.push(this.button(label, {x: stepX, y: 25, width: label.length, height: 1}, () => this.setStep(step)));
			stepX += label.length + 1;
		}

		// Added last: drawn and hit above everything else.
		this.root.place(new PaintComponent({paint: (painter) => this.paintConfirm(painter)}), FULL_SCREEN);
		this.confirmYes = this.button('', {x: 18, y: 22, width: 16, height: 1}, () => this.confirmStep());
		this.confirmNo  = this.button(' Cancel ', {x: 47, y: 22, width: 8, height: 1}, () => this.cancelConfirm());

		this.sync();
	}

	public setState(state: SmelteryState): void {
		this.state     = state;
		this.lastState = os.clock();
		this.sync();
	}

	/** A short message in the bottom line (command results, errors). */
	public notify(text: string, color: number = colors.lightGray): void {
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

	// ------------------------------------------------------------------ actions

	private showTab(tab: Tab): void {
		this.tab       = tab;
		this.picking   = false;
		this.editor    = undefined;
		this.assigning = undefined;
		this.sync();
	}

	/** Every fluid of the catalogue, from the controller (asked at start and after a recipe change). */
	public setFluids(fluids: string[]): void {
		this.allFluids = fluids;
		this.sync();
	}

	/** Stock tab: the top-left corner of the frame of the `index`-th reservoir of the page. */
	private static reservoirPlace(index: number): {x: number; y: number} {
		return {x: 3 + (index % 4) * 12, y: 7 + Math.floor(index / 4) * 14};
	}

	private pageReservoirs(): SmelteryState['reservoirs'] {
		const start = (this.stockPage - 1) * RESERVOIRS_PER_PAGE;
		return (this.state?.reservoirs ?? []).slice(start, start + RESERVOIRS_PER_PAGE);
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

	/** Rows of the fluid list shown now: for a reservoir (with "free"), or for the slot of the editor. */
	private choices(): FluidChoice[] {
		const state = this.state;
		if (state === undefined) return [];

		if (this.tab === 'stock' && this.assigning !== undefined) return fluidChoices(knownFluids(state), this.allFluids, true);

		const editor = this.editor;
		if (this.tab === 'modes' && editor !== undefined && editor.slot !== undefined) {
			const extra = [editor.result, ...editor.inputs.map((input) => input.fluid)];
			return fluidChoices(knownFluids(state, extra), this.allFluids, false);
		}
		return [];
	}

	private pageChoices(): FluidChoice[] {
		const start = (this.choicePage - 1) * CHOICE_ROWS;
		return this.choices().slice(start, start + CHOICE_ROWS);
	}

	/** The fluid now chosen for what the list fills (undefined: free, or nothing chosen). */
	private chosenFluid(): string | undefined {
		if (this.assigning !== undefined) return this.assigning.fluid;
		const editor = this.editor;
		if (editor === undefined || editor.slot === undefined) return undefined;
		return editor.slot === 'result' ? editor.result : editor.inputs[editor.slot]?.fluid;
	}

	private pressChoice(row: number): void {
		const choice = this.pageChoices()[row];
		if (choice === undefined || choice.kind === 'header') return;

		const fluid = choice.kind === 'fluid' ? choice.fluid : undefined;
		const editor = this.editor;
		if (this.assigning !== undefined) {
			this.assigning.fluid = fluid;
		}
		else if (editor !== undefined && fluid !== undefined) {
			if (editor.slot === 'result') editor.result = fluid;
			else if (editor.slot !== undefined && editor.inputs[editor.slot] !== undefined) editor.inputs[editor.slot]!.fluid = fluid;
		}
		this.sync();
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
		this.choicePage = 1;
		this.sync();
	}

	private pickSlot(slot: 'result' | number): void {
		if (this.editor === undefined) return;
		this.editor.slot = slot;
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
			this.notify(problem ?? 'cannot save', colors.red);
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

	private alloyOptions(): AlloyOption[] {
		return this.state?.alloyOptions ?? [];
	}

	private openPicker(): void {
		const alloy  = this.state?.alloy;
		const options = this.alloyOptions();
		this.picking = true;
		this.picked  = (options.find((option) => option.result === alloy?.result) ?? options[0])?.index;
		this.nonstop = alloy !== undefined && alloy.target === undefined;
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

	/** Overview, CASTING: the format of that row goes in or out of auto mode. */
	private toggleAuto(row: number): void {
		const group = this.castGroups()[(this.castPage - 1) * CASTS_PER_PAGE + row];
		if (group !== undefined && group.format !== 'no cast') this.actions.setFormat({format: group.format, auto: !group.auto});
	}

	private pressCast(): void {
		if (this.fluid !== undefined && this.format !== undefined) this.actions.cast({fluid: this.fluid, format: this.format});
	}

	private scrollLog(delta: number): void {
		const lines    = this.state?.log.length ?? 0;
		this.logOffset = Math.max(0, Math.min(Math.max(0, lines - LOG_LINES), this.logOffset + delta));
		this.sync();
	}

	// ------------------------------------------------------------- button state

	private button(label: string, rect: Rect, onPress: () => void): ButtonComponent {
		const button = this.root.place(new ButtonComponent({
			label, padding: 0, foregroundColor: colors.white, backgroundColor: colors.black, onPress,
		}), rect);
		this.allButtons.push(button);
		return button;
	}

	private show(button: ButtonComponent, visible: boolean, label?: string, foreground?: number, background?: number): void {
		const patch: {visible: boolean; label?: string; foregroundColor?: number; backgroundColor?: number} = {visible};
		if (label !== undefined) patch.label = label;
		if (foreground !== undefined) patch.foregroundColor = foreground;
		if (background !== undefined) patch.backgroundColor = background;
		button.setProps(patch);
	}

	/** Puts every button and pagination in line with the tab, the state and the dialog. */
	private sync(): void {
		const state = this.state;
		const modal = this.confirm !== undefined;

		for (const [tab, button] of this.tabButtons) this.show(button, true, undefined, tab === this.tab ? colors.white : colors.gray);

		const editing = this.tab === 'modes' && state !== undefined && this.editor !== undefined;
		const cards   = this.tab === 'modes' && state !== undefined && !this.picking && !editing;
		const picker  = this.tab === 'modes' && state !== undefined && this.picking && !editing;
		for (const [mode, button] of this.modeButtons) {
			this.show(button, cards && state.mode !== mode, ' Activate ', colors.black, MODE_CARDS[mode].color);
		}
		this.show(this.changeAlloy, cards, ' Change alloy ', colors.white, colors.gray);

		const options = this.alloyOptions();
		this.alloyPages.setProps({visible: picker && options.length > ALLOYS_PER_PAGE, totalItems: options.length});
		this.alloyPage = Math.min(this.alloyPage, Math.max(1, Math.ceil(options.length / ALLOYS_PER_PAGE)));
		const pageOptions = options.slice((this.alloyPage - 1) * ALLOYS_PER_PAGE, this.alloyPage * ALLOYS_PER_PAGE);
		// The name of each alloy is its button (the line under it is painted).
		this.alloyButtons.forEach((button, row) => {
			const option = pageOptions[row];
			const label  = option !== undefined ? fluidLabel(option.result).substring(0, 24).padEnd(24) : '';
			const color  = option !== undefined && option.index === this.picked ? colors.white : colors.lightGray;
			this.show(button, picker && option !== undefined, label, color, colors.black);
		});
		this.show(this.lessButton, picker, ' - ', colors.white, colors.gray);
		this.show(this.moreButton, picker, ' + ', colors.white, colors.gray);
		this.show(this.nonstopButton, picker, ' Until stopped ', this.nonstop ? colors.black : colors.lightGray, this.nonstop ? colors.magenta : colors.gray);
		const pickedOption = this.pickedOption();
		const pickedLabel  = pickedOption !== undefined ? fluidLabel(pickedOption.result) : '';
		this.show(this.selectButton, picker && pickedOption !== undefined, ` Select ${pickedLabel}`.substring(0, 21).padEnd(21), colors.black, colors.magenta);
		this.show(this.closePicker, picker, ' Cancel ', colors.black, colors.lightGray);
		this.show(this.editButton, picker && pickedOption !== undefined, ' Edit ', colors.white, colors.cyan);
		this.show(this.newButton, picker, ' New ', colors.white, colors.cyan);
		this.show(this.deleteButton, picker && pickedOption !== undefined, ' Delete ', colors.white, colors.red);

		this.syncEditor(editing);
		this.syncChoices(editing);

		const groups = this.castGroups();
		this.castPages.setProps({visible: this.tab === 'overview' && groups.length > CASTS_PER_PAGE, totalItems: groups.length});
		this.castPage = Math.min(this.castPage, Math.max(1, Math.ceil(groups.length / CASTS_PER_PAGE)));

		const pageGroups = groups.slice((this.castPage - 1) * CASTS_PER_PAGE, this.castPage * CASTS_PER_PAGE);
		this.autoButtons.forEach((button, row) => {
			const group = pageGroups[row];
			const shown = this.tab === 'overview' && group !== undefined && group.format !== 'no cast';
			if (group?.auto === true) this.show(button, shown, ' AUTO ', colors.black, colors.lime);
			else this.show(button, shown, ' off  ', colors.lightGray, colors.gray);
		});

		const reservoirCount = state?.reservoirs.length ?? 0;
		this.stockPages.setProps({visible: this.tab === 'stock' && reservoirCount > RESERVOIRS_PER_PAGE, totalItems: reservoirCount});
		this.stockPage = Math.min(this.stockPage, Math.max(1, Math.ceil(reservoirCount / RESERVOIRS_PER_PAGE)));

		// The label of a reservoir: its fluid, what it is reserved for, or free.
		const pageReservoirs = this.pageReservoirs();
		this.reservoirButtons.forEach((button, slot) => {
			const reservoir = pageReservoirs[slot];
			if (this.tab !== 'stock' || reservoir === undefined) {
				this.show(button, false);
				return;
			}
			const fluid = reservoir.fluid;
			const label = fluid !== undefined ? fluidLabel(fluid) : reservoir.assigned !== undefined ? `for ${fluidLabel(reservoir.assigned)}` : 'free';
			const color = reservoir.name === this.assigning?.reservoir ? colors.yellow : fluid !== undefined ? colors.white : colors.gray;
			this.show(button, true, label.substring(0, 11).padEnd(11), color, colors.black);
		});

		const manual = this.tab === 'manual';
		const items  = this.pageItems();
		const itemCount = state?.inputItems.length ?? 0;
		this.itemPages.setProps({visible: manual && itemCount > ITEMS_PER_PAGE, totalItems: itemCount});

		this.itemButtons.forEach((button, row) => {
			const item = items[row];
			if (!manual || item === undefined || item.status === 'unknown') this.show(button, false);
			else if (item.status === 'ok') this.show(button, true, ' Insert ', colors.black, colors.lime);
			else this.show(button, true, ' Force  ', colors.white, colors.red);
		});

		const fluids = this.fluids();
		this.fluidButtons.forEach((button, row) => {
			const fluid = fluids[row];
			const label = fluid === undefined ? '' : fluidLabel(fluid.name);
			const color = fluid?.name === this.fluid ? colors.white : colors.lightGray;
			this.show(button, manual && fluid !== undefined, label.padEnd(20), color);
		});

		this.formatButtons.forEach((button, row) => {
			const group = groups[row];
			const label = group === undefined ? '' : `${formatLabel(group.format).padEnd(16)} x${group.free}`;
			const color = group?.format === this.format ? colors.white : colors.lightGray;
			this.show(button, manual && group !== undefined, label.padEnd(25), color);
		});

		const canCast = this.fluid !== undefined && this.format !== undefined;
		const castLabel = canCast ? ` Cast ${fluidLabel(this.fluid!)} ${formatLabel(this.format!)} ` : ' Pick a fluid and a cast ';
		this.show(this.castButton, manual, castLabel.substring(0, 25), colors.black, canCast ? colors.orange : colors.gray);

		this.show(this.logUp, this.tab === 'log', undefined, colors.lightGray, colors.gray);
		this.show(this.logDown, this.tab === 'log', undefined, colors.lightGray, colors.gray);

		const confirm = this.confirm;
		const yes = confirm?.kind === 'delete' ? (confirm.step === 2 ? ' Delete ' : ' Continue ') : (confirm?.step === 2 ? ' Force insert ' : ' Continue ');
		this.show(this.confirmYes, modal, yes, colors.white, confirm?.step === 2 ? colors.red : colors.orange);
		this.show(this.confirmNo, modal, ' Cancel ', colors.black, colors.lightGray);

		// Under the dialog, nothing else can be pressed.
		for (const button of this.allButtons) {
			if (button !== this.confirmYes && button !== this.confirmNo) button.setProps({disabled: modal});
		}
		this.castPages.setProps({disabled: modal});
		this.itemPages.setProps({disabled: modal});
		this.stockPages.setProps({disabled: modal});
		this.alloyPages.setProps({disabled: modal});
		this.choicePages.setProps({disabled: modal});
	}

	/** The buttons of the recipe editor. */
	private syncEditor(editing: boolean): void {
		const editor = this.editor;
		const shown  = editing && editor !== undefined;
		const slotColor = (slot: 'result' | number): number => (editor?.slot === slot ? colors.yellow : colors.white);

		const result = editor?.result !== undefined ? fluidLabel(editor.result) : 'choose...';
		this.show(this.resultButton, shown, result.substring(0, 18).padEnd(18), editor?.result !== undefined ? slotColor('result') : colors.gray, colors.black);
		this.show(this.resultLess, shown, ' - ', colors.white, colors.gray);
		this.show(this.resultMore, shown, ' + ', colors.white, colors.gray);

		for (let row = 0; row < MAX_INGREDIENTS; row++) {
			const input = editor?.inputs[row];
			const visible = shown && input !== undefined;
			const label = input?.fluid !== undefined ? fluidLabel(input.fluid) : 'choose...';
			const color = input?.fluid !== undefined ? slotColor(row) : colors.gray;
			this.show(this.inputButtons[row]!, visible, label.substring(0, 18).padEnd(18), color, colors.black);
			this.show(this.inputLess[row]!, visible, ' - ', colors.white, colors.gray);
			this.show(this.inputMore[row]!, visible, ' + ', colors.white, colors.gray);
			this.show(this.inputRemove[row]!, visible, ' x ', colors.white, colors.red);
		}
		this.show(this.addInput, shown && (editor?.inputs.length ?? 0) < MAX_INGREDIENTS, ' + ingredient ', colors.white, colors.gray);

		this.stepButtons.forEach((button, index) => {
			const on = editor?.step === STEPS[index];
			this.show(button, shown, undefined, on ? colors.black : colors.white, on ? colors.lime : colors.gray);
		});
	}

	/** The fluid list on the right (Stock or editor), its pages, and Save / Cancel. */
	private syncChoices(editing: boolean): void {
		const assigning = this.tab === 'stock' && this.assigning !== undefined && this.state !== undefined;
		const choices   = this.choices();
		const listed    = assigning || (editing && this.editor?.slot !== undefined);

		this.choicePages.setProps({visible: listed && choices.length > CHOICE_ROWS, totalItems: choices.length});
		this.choicePage = Math.min(this.choicePage, Math.max(1, Math.ceil(choices.length / CHOICE_ROWS)));

		const page   = this.pageChoices();
		const chosen = this.chosenFluid();
		this.choiceButtons.forEach((button, row) => {
			const choice = page[row];
			if (!listed || choice === undefined) {
				this.show(button, false);
			}
			else if (choice.kind === 'header') {
				this.show(button, true, choice.text.padEnd(20), colors.gray, colors.black);
			}
			else if (choice.kind === 'free') {
				this.show(button, true, 'free (no fluid)'.padEnd(20), chosen === undefined ? colors.white : colors.lightGray, colors.black);
			}
			else {
				const color = choice.fluid === chosen ? colors.white : colors.lightGray;
				this.show(button, true, fluidLabel(choice.fluid).substring(0, 20).padEnd(20), color, colors.black);
			}
		});

		this.show(this.capacityLess, assigning, undefined, colors.white, colors.gray);
		this.show(this.capacityMore, assigning, undefined, colors.white, colors.gray);

		const panel = assigning || editing;
		const ready = assigning || this.editedRecipe().recipe !== undefined;
		this.show(this.panelSave, panel, ' Save ', ready ? colors.black : colors.lightGray, ready ? colors.lime : colors.gray);
		this.show(this.panelCancel, panel, ' Cancel ', colors.black, colors.lightGray);
	}

	// ------------------------------------------------------------------ drawing

	private paint(p: Painter): void {
		p.fill(1, 1, SCREEN_WIDTH, SCREEN_HEIGHT, colors.black);
		this.paintHeader(p);

		const state = this.state;
		if (state === undefined) {
			p.text(27, 18, 'Waiting for the controller...', colors.lightGray);
			p.text(22, 20, 'Is the foundry computer running main?', colors.gray);
			return;
		}

		if (this.tab === 'overview') this.paintOverview(p, state);
		else if (this.tab === 'modes') this.paintModes(p, state);
		else if (this.tab === 'manual') this.paintManual(p, state);
		else if (this.tab === 'stock') this.paintStock(p, state);
		else this.paintLog(p, state);

		const message = this.message;
		if (message !== undefined && os.clock() < message.until) p.text(3, 36, message.text.substring(0, 75), message.color);
		else if (this.tab !== 'log') this.paintLastAction(p, state);
	}

	private paintHeader(p: Painter): void {
		p.text(3, 2, Glyph.up, colors.orange);
		p.text(5, 2, 'S M E L T E R Y', colors.white);

		let x = TABS_X;
		for (const [tab, label] of TABS) {
			if (tab === this.tab) p.text(x, 3, Glyph.underline.repeat(label.length), colors.orange);
			x += label.length + 4;
		}

		const mode = this.state?.mode;
		if (mode !== undefined) p.text(67, 2, ` ${mode.toUpperCase()} `, colors.black, MODE_CARDS[mode].color);

		const online = os.clock() - this.lastState < OFFLINE_SECONDS;
		p.text(76, 2, Glyph.dot, online ? colors.lime : colors.red);
	}

	private title(p: Painter, x: number, y: number, text: string, width: number): void {
		p.text(x, y, text, colors.orange);
		p.text(x + text.length + 1, y, Glyph.rule.repeat(Math.max(0, width - text.length - 1)), colors.gray);
	}

	private frame(p: Painter, x: number, y: number, width: number, height: number): void {
		p.fill(x, y, width + 2, 1, colors.gray);
		p.fill(x, y + height + 1, width + 2, 1, colors.gray);
		p.fill(x, y + 1, 1, height, colors.gray);
		p.fill(x + width + 1, y + 1, 1, height, colors.gray);
	}

	private paintOverview(p: Painter, state: SmelteryState): void {
		// Molten: the Smeltery tank, bottom fluid at the bottom, like its own GUI.
		this.title(p, 3, 5, 'MOLTEN', 22);
		const tankX = 3, tankY = 7, tankW = 18, tankH = 25;
		this.frame(p, tankX, tankY, tankW, tankH);

		const total = state.fluids.reduce((sum, fluid) => sum + fluid.amount, 0);
		let bottom  = tankY + tankH;
		for (const fluid of state.fluids) {
			if (bottom <= tankY) break;
			const rows  = Math.min(bottom - tankY, Math.max(1, Math.round(tankH * fluid.amount / Math.max(total, 1))));
			const color = fluidColor(fluid.name);
			p.fill(tankX + 1, bottom - rows + 1, tankW, rows, color);
			p.text(tankX + 2, bottom - Math.floor((rows - 1) / 2), fluidLabel(fluid.name).substring(0, tankW - 2), textOn(color), color);
			bottom -= rows;
		}

		let legendY = 8;
		for (const fluid of [...state.fluids].reverse().slice(0, 8)) {
			p.fill(24, legendY, 1, 1, fluidColor(fluid.name));
			p.text(26, legendY, `${fluid.amount} mB`.padStart(8), colors.white);
			legendY += 2;
		}
		// Two lines: the column ends at 35, before the fuel tank (15300 mB molten would run into it).
		p.text(24, 26, `${total} mB`, colors.white);
		p.text(24, 27, 'molten', colors.gray);
		const melting = state.melting.reduce((sum, item) => sum + item.count, 0);
		p.text(24, 29, 'melting', colors.gray);
		p.text(24, 30, `${melting} item${melting === 1 ? '' : 's'}`, colors.lightGray);

		// Fuel: its tank level (4 buckets is a seared tank) and the heat it gives.
		this.title(p, 37, 5, 'FUEL', 10);
		this.frame(p, 37, tankY, 6, tankH);
		const fuel = state.fuel;
		if (fuel !== undefined) {
			const rows = Math.min(tankH, Math.round(tankH * fuel.amount / 4000));
			for (let row = 0; row < rows; row++) p.fill(38, tankY + tankH - row, 6, 1, row % 5 === 0 ? colors.red : colors.orange);
			p.text(46, 26, fuel.fluid !== undefined ? fluidLabel(fuel.fluid).substring(0, 10) : 'empty', fuel.fluid !== undefined ? colors.orange : colors.red);
			p.text(46, 27, `${fuel.amount} mB`, colors.white);
		}
		else {
			p.text(46, 26, 'no tank', colors.gray);
		}
		p.text(46, 29, state.heat !== undefined ? `${state.heat} K` : '? K', colors.white);
		p.text(46, 30, 'heat', colors.gray);

		// Casting: casters by cast, a block per caster, auto mode's casts first.
		this.title(p, 53, 5, 'CASTING', 25);
		const groups = this.castGroups();
		const start  = (this.castPage - 1) * CASTS_PER_PAGE;
		groups.slice(start, start + CASTS_PER_PAGE).forEach((group, index) => {
			const y = 7 + index * 3;
			// The AUTO / off switch is a button at column 71.
			p.text(53, y, formatLabel(group.format).substring(0, 17), group.auto ? colors.white : colors.lightGray);

			let x = 53;
			const blocks: [number, number][] = [
				[group.free, colors.gray],
				[group.casting, group.auto ? colors.orange : colors.gray],
				[group.ready, group.auto ? colors.yellow : colors.gray],
			];
			for (const [count, color] of blocks) {
				for (let n = 0; n < count && x < 75; n++) {
					p.fill(x, y + 1, 2, 1, color);
					x += 3;
				}
			}
			p.text(x + 1, y + 1, `${group.free + group.casting + group.ready}`, colors.gray);
		});
		if (groups.length === 0) p.text(53, 7, 'no caster found', colors.gray);
		p.fill(53, 21, 1, 1, colors.gray);
		p.text(55, 21, 'free', colors.gray);
		p.fill(61, 21, 1, 1, colors.orange);
		p.text(63, 21, 'casting', colors.gray);
		p.fill(72, 21, 1, 1, colors.yellow);
		p.text(74, 21, 'ready', colors.gray);
		p.text(53, 23, 'Touch AUTO/off: auto casts', colors.gray);
		p.text(53, 24, 'only into the AUTO ones.', colors.gray);

		// Attention: only when something needs a look.
		const lines = attentionLines(state);
		if (lines.length > 0) {
			this.title(p, 53, 25, 'ATTENTION', 25);
			lines.slice(0, 3).forEach((line, index) => {
				const y = 27 + index * 3;
				p.text(53, y, Glyph.up, line.color);
				p.text(55, y, line.title.substring(0, 23), colors.white);
				p.text(55, y + 1, line.detail.substring(0, 23), colors.gray);
			});
			if (lines.length > 3) p.text(55, 36, `+ ${lines.length - 3} more in Log`, colors.gray);
		}
	}

	/** Text of the alloy card: the chosen alloy. */
	private static alloyLines(state: SmelteryState): string[] {
		if (state.alloy === undefined) return ['No alloy chosen:', 'pick one with', 'Change alloy.'];
		const label = fluidLabel(state.alloy.result);
		return [`Only ${label},`.length <= 16 ? `Only ${label},` : label, 'dosed from input', 'and stock.'];
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
			const card   = MODE_CARDS[mode];
			const {x, y} = cardPlace(index);
			const active = state.mode === mode;
			const lines  = mode === 'alloy' ? SmelteryScreen.alloyLines(state) : card.lines;
			p.fill(x, y, 17, 1, card.color);
			p.text(x + 1, y, mode.toUpperCase(), colors.black, card.color);
			lines.forEach((line, row) => p.text(x + 1, y + 2 + row, line.substring(0, 16), active ? colors.white : colors.lightGray));
			if (!active) return;

			const alloy = state.alloy;
			if (mode !== 'alloy' || alloy === undefined) {
				p.text(x + 1, y + 6, `${Glyph.dot} active`, colors.lime);
			}
			else if (alloy.target === undefined) {
				p.text(x + 1, y + 6, `${Glyph.dot} ${Math.floor(alloy.made / INGOT)} ingots made`.substring(0, 16), colors.lime);
			}
			else {
				const target = Math.max(1, Math.round(alloy.target / INGOT));
				p.text(x + 1, y + 6, `${Glyph.dot} ${Math.floor(alloy.made / INGOT)}/${target} ingots`.substring(0, 16), colors.lime);
				p.fill(x + 1, y + 7, 15, 1, colors.gray);
				p.fill(x + 1, y + 7, Math.min(15, Math.floor(15 * alloy.made / alloy.target)), 1, card.color);
			}
		});
		p.text(3, 34, 'Touch Activate to switch; the controller confirms live.', colors.gray);
	}

	/** Modes tab, Change alloy: the alloys (those the stock can make first), the recipe and the amount. */
	private paintPicker(p: Painter, state: SmelteryState): void {
		this.title(p, 3, 5, 'ALLOY', 44);
		const options = this.alloyOptions();
		const start   = (this.alloyPage - 1) * ALLOYS_PER_PAGE;

		options.slice(start, start + ALLOYS_PER_PAGE).forEach((option, index) => {
			const y      = 7 + index * 3;
			const picked = option.index === this.picked;
			if (picked) p.text(3, y, Glyph.right, colors.white);
			p.fill(5, y, 2, 1, fluidColor(option.result));

			if (option.temperature !== undefined) p.text(8, y + 1, `needs ${option.temperature} K`, colors.red);
			else if (option.fromStock > 0) p.text(8, y + 1, `from stock: ${Math.floor(option.fromStock / INGOT)} ing`, colors.lime);
			else p.text(8, y + 1, 'put in the input', colors.gray);
		});
		if (options.length === 0) p.text(3, 7, 'No alloy in the catalogue.', colors.gray);
		if (options.length > ALLOYS_PER_PAGE) p.text(15, 32, 'ready first', colors.gray);

		const option = this.pickedOption();
		if (option === undefined) return;

		const label = fluidLabel(option.result);
		this.title(p, 53, 5, label.toUpperCase().substring(0, 20), 25);
		p.text(53, 7, 'recipe', colors.gray);

		const count = (amount: number): string => (amount % INGOT === 0 ? `${amount / INGOT} ` : '');
		option.inputs.forEach((input, index) => {
			const y = 9 + index;
			p.fill(53, y, 2, 1, fluidColor(input.fluid));
			p.text(56, y, `${count(input.amount)}${fluidLabel(input.fluid)}`.substring(0, 14), colors.white);
			p.text(71, y, `${input.amount} mB`.padStart(6), colors.gray);
		});
		const resultY = 9 + option.inputs.length;
		p.text(56, resultY, `${Glyph.right} ${count(option.amount)}${label}`.substring(0, 14), colors.pink);
		p.text(71, resultY, `${option.amount} mB`.padStart(6), colors.gray);

		const stockY = resultY + 2;
		p.text(53, stockY, 'in stock', colors.gray);
		option.inputs.forEach((input, index) => {
			const stored = state.reservoirs
				.filter((reservoir) => reservoir.fluid === input.fluid)
				.reduce((sum, reservoir) => sum + reservoir.amount, 0);
			p.text(53, stockY + 1 + index, fluidLabel(input.fluid).substring(0, 15), colors.white);
			p.text(69, stockY + 1 + index, `${stored} mB`.padStart(8), colors.lightGray);
		});
		const ingots = Math.floor(option.fromStock / INGOT);
		p.text(53, stockY + 1 + option.inputs.length, `= ${ingots} ingots now`, ingots > 0 ? colors.lime : colors.gray);

		p.text(53, 20, 'amount', colors.gray);
		p.text(58, 22, this.nonstop ? 'nonstop' : `${this.pickIngots} ingots`, this.nonstop ? colors.gray : colors.white);
		const back = SmelteryScreen.endsOnItsOwn(state.mode) ? 'the previous mode' : state.mode.toUpperCase();
		p.text(53, 25, this.nonstop ? 'runs until changed' : `then back to ${back}`.substring(0, 25), colors.gray);
	}

	private static endsOnItsOwn(mode: Mode): boolean {
		return mode === 'drain' || mode === 'purge' || mode === 'alloy';
	}

	private paintManual(p: Painter, state: SmelteryState): void {
		this.title(p, 3, 5, 'INSERT', 44);
		const items = this.pageItems();
		if (state.mode !== 'manual') p.text(3, 7, 'Switch to manual mode to insert and cast.', colors.orange);

		items.forEach((item, row) => {
			const y = 8 + row * 3;
			p.text(3, y, itemLabel(item.name).substring(0, 32), colors.white);
			p.text(3, y + 1, `${item.count} ${Glyph.dot} ${item.fluid !== undefined ? fluidLabel(item.fluid) : 'no fluid'}`.substring(0, 32), colors.gray);

			if (item.status === 'unknown') p.text(37, y, 'unknown', colors.gray);
			else if (item.status === 'alloy') p.text(37, y + 1, fluidLabel(item.alloy ?? 'alloy').substring(0, 12), colors.red);
			else if (item.status === 'heat') p.text(37, y + 1, `${item.temperature ?? '?'} K`, colors.red);
		});
		if (state.inputItems.length === 0) p.text(3, 8, 'The input is empty.', colors.gray);

		this.title(p, 53, 5, 'CAST', 25);
		p.text(53, 8, 'fluid', colors.gray);
		this.fluids().forEach((fluid, row) => {
			const y = 10 + row * 2;
			p.text(53, y, fluid.name === this.fluid ? Glyph.right : ' ', colors.white);
			p.fill(55, y, 2, 1, fluidColor(fluid.name));
		});
		p.text(53, 20, 'into', colors.gray);
		this.castGroups().slice(0, 5).forEach((group, row) => {
			p.text(53, 22 + row * 2, group.format === this.format ? Glyph.right : ' ', colors.white);
		});
	}

	private paintStock(p: Painter, state: SmelteryState): void {
		const reservoirs = state.reservoirs;

		// Reservoirs: a small tank each, filled to its capacity once known (type, set by hand, or learnt).
		this.title(p, 3, 5, 'RESERVOIRS', 48);
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
			const height = 7;
			this.frame(p, x, y, 6, height);
			if (reservoir.name === this.assigning?.reservoir) p.text(x - 1 < 1 ? 1 : x - 1, y + height + 3, Glyph.right, colors.yellow);

			const fluid = reservoir.fluid;
			if (fluid !== undefined) {
				const rows = Math.min(height, Math.max(1, Math.round(height * reservoir.amount / (reservoir.capacity ?? scale))));
				p.fill(x + 1, y + height + 1 - rows, 6, rows, fluidColor(fluid));
			}
			if (reservoir.capacity !== undefined && reservoir.amount >= reservoir.capacity) p.text(x + 1, y + 1, ' FULL ', colors.black, colors.white);

			// The label (line y + height + 3) is the reservoir's button. Reserved for another fluid than the
			// one it holds: it says so, in place of the amount.
			if (fluid !== undefined && reservoir.assigned !== undefined && reservoir.assigned !== fluid) {
				p.text(x, y + height + 4, `for ${fluidLabel(reservoir.assigned)}`.substring(0, 11), colors.orange);
			}
			else if (fluid !== undefined) p.text(x, y + height + 4, `${reservoir.amount} mB`, colors.lightGray);
			else if (reservoir.assigned !== undefined) p.text(x, y + height + 4, 'assigned', colors.gray);
			p.text(x, y + height + 5, itemLabel(reservoir.name).split('_').join(' ').substring(0, 11), colors.gray);
		});
		if (reservoirs.length === 0) p.text(3, 7, 'No reservoir found.', colors.gray);
		else p.text(15, 35, 'touch a name to reserve it', colors.gray);

		if (this.assigning !== undefined) {
			this.paintAssign(p, state, this.assigning);
			return;
		}

		// Totals by fluid, biggest first.
		this.title(p, 55, 5, 'TOTALS', 23);
		const totals: {fluid: string; amount: number}[] = [];
		for (const reservoir of reservoirs) {
			if (reservoir.fluid === undefined) continue;
			const entry = totals.find((candidate) => candidate.fluid === reservoir.fluid);
			if (entry !== undefined) entry.amount += reservoir.amount;
			else totals.push({fluid: reservoir.fluid, amount: reservoir.amount});
		}
		totals.sort((a, b) => b.amount - a.amount);
		totals.slice(0, 5).forEach((total, index) => {
			const y = 7 + index * 3;
			p.fill(55, y, 2, 1, fluidColor(total.fluid));
			p.text(58, y, fluidLabel(total.fluid).substring(0, 20), colors.white);
			p.text(58, y + 1, `${`${total.amount} mB`.padEnd(10)}${Math.floor(total.amount / 90)} ing`, colors.gray);
		});
		if (totals.length > 5) p.text(58, 22, `+ ${totals.length - 5} more`, colors.gray);
		if (totals.length === 0) p.text(55, 7, 'Nothing stored.', colors.gray);

		// Room left: free reservoirs, and those kept for one fluid.
		this.title(p, 55, 23, 'FREE', 23);
		const empty    = reservoirs.filter((reservoir) => reservoir.fluid === undefined);
		const free     = empty.filter((reservoir) => reservoir.assigned === undefined).length;
		const assigned = empty.filter((reservoir) => reservoir.assigned !== undefined);
		p.text(55, 25, `${free} free`, colors.white);
		if (assigned.length === 1) p.text(56 + `${free} free`.length, 25, `+ 1 for ${fluidLabel(assigned[0]!.assigned!)}`.substring(0, 16), colors.gray);
		else if (assigned.length > 1) p.text(56 + `${free} free`.length, 25, `+ ${assigned.length} assigned`, colors.gray);
		p.text(55, 27, `capacity known for ${known}/${reservoirs.length}`, colors.gray);
		p.text(55, 28, '(touch a name to set it)', colors.gray);

		// What the stock is waiting for: no room for a fluid, or a stock too small to cast.
		const alerts = state.alerts.filter((alert) => alert.startsWith('no reservoir') || alert.startsWith('stock of'));
		if (alerts.length > 0) {
			this.title(p, 55, 31, 'ATTENTION', 23);
			const [line] = attentionLines({...state, alerts, waiting: []});
			if (line !== undefined) {
				p.text(55, 33, Glyph.up, colors.orange);
				p.text(57, 33, line.title.substring(0, 21), colors.white);
				p.text(57, 34, line.detail.substring(0, 21), colors.gray);
			}
			if (alerts.length > 1) p.text(57, 35, `+ ${alerts.length - 1} more`, colors.gray);
		}
	}

	/** Stock tab, a reservoir touched: what it holds, and the list of fluids to reserve it for. */
	private paintAssign(p: Painter, state: SmelteryState, assigning: Assigning): void {
		const reservoir = state.reservoirs.find((candidate) => candidate.name === assigning.reservoir);
		this.title(p, 55, 5, 'ASSIGN RESERVOIR', 24);
		p.text(55, 6, itemLabel(assigning.reservoir).split('_').join(' ').substring(0, 24), colors.white);
		if (reservoir?.fluid !== undefined) p.text(55, 7, `holds ${fluidLabel(reservoir.fluid)} ${reservoir.amount} mB`.substring(0, 24), colors.lightGray);
		else p.text(55, 7, 'empty', colors.gray);
		const now = reservoir?.assigned !== undefined ? `for ${fluidLabel(reservoir.assigned)}` : 'free';
		p.text(55, 8, `now: ${now}`.substring(0, 24), colors.gray);

		this.paintChoices(p);

		const holds = reservoir?.fluid;
		if (holds !== undefined && assigning.fluid !== undefined && assigning.fluid !== holds) {
			p.text(55, 27, `Keeps its ${fluidLabel(holds)}, no more;`.substring(0, 24), colors.orange);
			p.text(55, 28, `${fluidLabel(assigning.fluid)} once empty.`.substring(0, 24), colors.gray);
		}
		else {
			p.text(55, 27, 'Reserved: only that fluid.', colors.gray);
			p.text(55, 28, 'Free: any, when empty.', colors.gray);
		}

		// Capacity: set by hand, or auto (learnt when it refused fluid, or given by its type).
		p.text(55, 30, 'CAPACITY', colors.gray);
		const source = reservoir?.capacitySource;
		let value: string;
		if (assigning.capacity !== undefined) {
			p.text(64, 30, 'set by hand', colors.white);
			value = `${assigning.capacity} mB`;
		}
		else if (reservoir?.capacity !== undefined && source !== 'set') {
			p.text(64, 30, source === 'learnt' ? 'learnt' : 'from its type', colors.gray);
			value = `auto ${reservoir.capacity}`;
		}
		else if (source === 'set') {
			p.text(64, 30, 'type or learnt', colors.gray);
			value = 'auto';
		}
		else {
			p.text(64, 30, 'unknown: set it', colors.orange);
			value = 'auto ?';
		}
		p.text(59, 31, value.padStart(13), colors.white);
	}

	/** The fluid list on the right: a mark on the chosen one, the color of each fluid. */
	private paintChoices(p: Painter): void {
		const chosen = this.chosenFluid();
		this.pageChoices().forEach((choice, row) => {
			const y = 10 + row;
			if (choice.kind === 'fluid') {
				p.fill(56, y, 2, 1, fluidColor(choice.fluid));
				if (choice.fluid === chosen) p.text(55, y, Glyph.right, colors.yellow);
			}
			else if (choice.kind === 'free' && chosen === undefined) {
				p.text(55, y, Glyph.right, colors.yellow);
			}
		});
	}

	/** Modes tab, Edit or New: the recipe on the left, the fluid list on the right. */
	private paintEditor(p: Painter, editor: EditorState): void {
		this.title(p, 3, 5, editor.index !== undefined ? 'EDIT RECIPE' : 'NEW RECIPE', 48);

		p.text(3, 7, 'RESULT', colors.gray);
		if (editor.slot === 'result') p.text(1, 9, Glyph.right, colors.yellow);
		if (editor.result !== undefined) p.fill(3, 9, 2, 1, fluidColor(editor.result));
		p.text(29, 9, `${editor.amount} mB`.padStart(8), colors.white);

		p.text(3, 12, 'INGREDIENTS', colors.gray);
		editor.inputs.forEach((input, row) => {
			const y = 14 + row * 2;
			if (editor.slot === row) p.text(1, y, Glyph.right, colors.yellow);
			if (input.fluid !== undefined) p.fill(3, y, 2, 1, fluidColor(input.fluid));
			p.text(29, y, `${input.amount} mB`.padStart(8), colors.white);
		});
		if (editor.inputs.length < MAX_INGREDIENTS) p.text(18, 22, `(up to ${MAX_INGREDIENTS})`, colors.gray);

		p.text(3, 25, 'step', colors.gray);
		p.text(26, 25, 'mB', colors.gray);

		const {recipe, problem} = this.editedRecipe();
		if (recipe !== undefined) {
			const amount = (mB: number, fluid: string): string => `${mB % INGOT === 0 ? `${mB / INGOT} ing` : `${mB} mB`} ${fluidLabel(fluid)}`;
			p.text(3, 28, 'ready to save', colors.lime);
			p.text(3, 30, recipe.inputs.map((input) => amount(input.amount, input.fluid)).join(' + ').substring(0, 48), colors.lightGray);
			p.text(3, 31, `makes ${amount(recipe.amount, recipe.result)}`.substring(0, 48), colors.pink);
		}
		else {
			p.text(3, 28, `cannot save: ${problem ?? '?'}`.substring(0, 48), colors.red);
		}

		this.title(p, 55, 5, 'CHOOSE FLUID', 24);
		const slot = editor.slot;
		if (slot === undefined) {
			p.text(55, 7, 'Touch the result or an', colors.gray);
			p.text(55, 8, 'ingredient to choose it.', colors.gray);
		}
		else {
			p.text(55, 6, slot === 'result' ? 'for: the result' : `for: ingredient ${slot + 1}`, colors.lightGray);
			this.paintChoices(p);
		}
	}

	private paintLog(p: Painter, state: SmelteryState): void {
		this.title(p, 3, 5, 'LOG', 65);
		const lines = state.log;
		const end   = lines.length - this.logOffset;
		const start = Math.max(0, end - LOG_LINES);

		lines.slice(start, end).forEach((raw, index) => {
			const line = parseLogLine(raw);
			const y    = 8 + index * 2;
			p.text(3, y, line.time, colors.gray);
			p.text(13, y, line.kind === 'other' ? '' : line.kind.padEnd(7), LOG_COLORS[line.kind]);
			p.text(21, y, line.text.substring(0, 56), line.kind === 'forced' ? colors.red : colors.white);
		});
		if (lines.length === 0) p.text(3, 8, 'Nothing yet.', colors.gray);
	}

	private paintLastAction(p: Painter, state: SmelteryState): void {
		// The last real action: the caster list printed at start ('  name: format') is not one.
		let last: string | undefined;
		for (let index = state.log.length - 1; index >= 0 && last === undefined; index--) {
			const line = state.log[index];
			if (line !== undefined && line.substring(8, 11) !== '   ') last = line;
		}
		if (last === undefined) return;
		const line = parseLogLine(last);
		p.text(3, 36, line.time, colors.gray);
		p.text(12, 36, `${line.kind === 'other' ? '' : `${line.kind} `}${line.text}`.substring(0, 60), colors.lightGray);
	}

	private paintConfirm(p: Painter): void {
		const confirm = this.confirm;
		if (confirm === undefined) return;

		const x = 15, y = 13, width = 49, height = 11;
		const color = confirm.step === 2 ? colors.red : colors.orange;
		this.frame(p, x, y, width, height);
		p.fill(x, y, width + 2, 1, color);
		p.fill(x, y + height + 1, width + 2, 1, color);
		p.fill(x, y + 1, 1, height, color);
		p.fill(x + width + 1, y + 1, 1, height, color);
		p.fill(x + 1, y + 1, width, height, colors.black);

		if (confirm.kind === 'delete') {
			this.paintDelete(p, confirm.option, confirm.step, confirm.deadline, x, y, color);
			return;
		}

		const item = confirm.item;
		const what = item.status === 'alloy'
		             ? `will form ${fluidLabel(item.alloy ?? 'an alloy')}.`
		             : `needs ${item.temperature ?? '?'} K: it may not melt.`;

		p.text(x + 3, y + 2, 'FORCE INSERT', color);
		p.text(x + 16, y + 2, `step ${confirm.step} of 2`, colors.gray);
		p.text(x + 3, y + 4, `${item.count} ${itemLabel(item.name)}`.substring(0, 45), colors.white);
		p.text(x + 3, y + 5, what.substring(0, 45), colors.lightGray);

		if (confirm.step === 1) {
			p.text(x + 3, y + 7, 'Check what will happen before going on.', colors.gray);
		}
		else {
			p.text(x + 3, y + 7, item.status === 'alloy' ? 'An alloy cannot be undone.' : 'It stays in the Smeltery until hot enough.', colors.gray);
			p.text(x + 21, y + 10, `${Math.max(0, Math.ceil(confirm.deadline - os.clock()))} s`, colors.gray);
		}
	}

	/** Inside the confirmation frame: the recipe to delete, and what happens to alloy mode. */
	private paintDelete(p: Painter, option: AlloyOption, step: 1 | 2, deadline: number, x: number, y: number, color: number): void {
		p.text(x + 3, y + 2, 'DELETE RECIPE', color);
		p.text(x + 17, y + 2, `step ${step} of 2`, colors.gray);
		const inputs = option.inputs.map((input) => `${input.amount} ${fluidLabel(input.fluid)}`).join(' + ');
		p.text(x + 3, y + 4, `${inputs}`.substring(0, 45), colors.white);
		p.text(x + 3, y + 5, `makes ${option.amount} mB ${fluidLabel(option.result)}`.substring(0, 45), colors.pink);

		// The last recipe of the chosen alloy: alloy mode has nothing left to make.
		const state = this.state;
		const last  = state?.alloy?.result === option.result
		              && !this.alloyOptions().some((other) => other.index !== option.index && other.result === option.result);
		if (last && state?.mode === 'alloy') {
			p.text(x + 3, y + 7, 'It is the alloy being made: alloy mode', colors.orange);
			p.text(x + 3, y + 8, 'stops and goes back to the previous mode.', colors.orange);
		}
		else if (last) {
			p.text(x + 3, y + 7, 'It is the alloy chosen for alloy mode:', colors.orange);
			p.text(x + 3, y + 8, 'none will be chosen any more.', colors.orange);
		}
		else {
			p.text(x + 3, y + 7, step === 1 ? 'Check the recipe before going on.' : 'It cannot be undone.', colors.gray);
		}

		if (step === 2) p.text(x + 21, y + 10, `${Math.max(0, Math.ceil(deadline - os.clock()))} s`, colors.gray);
	}
}
