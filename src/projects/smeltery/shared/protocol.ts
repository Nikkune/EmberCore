import type {ItemSummary}                from '@core/inventory';
import type {FluidStack}                 from '@core/tank';
import type {ReservoirView}              from '@modules/fluids/index';
import type {AlloyRatio, CasterKind, CasterStatus} from '@modules/tinkers/index';

/** What the controller and the display say to each other over rednet. */
export const PROTOCOL            = 'smeltery/v1';
export const CONTROLLER_HOSTNAME = 'smeltery-controller';

/**
 * idle:   nothing automatic, the state is kept;
 * auto:   melts the input and casts pure metals, never lets an alloy form;
 * manual: only what the display asks (insert, cast);
 * lock:   no new item goes in, the casts under way finish;
 * drain:  every fluid goes to the reservoirs, then idle;
 * purge:  leftovers and alloys go to the reservoirs, then back to the previous mode;
 * alloy:  makes the chosen alloy only, dosing its ingredients (stock first); with an amount, then back
 *         to the previous mode;
 * melt:   melts the input into the reservoirs, casts nothing.
 */
export type Mode = 'idle' | 'auto' | 'manual' | 'lock' | 'drain' | 'purge' | 'alloy' | 'melt';

export const MODES: Mode[] = ['idle', 'auto', 'manual', 'lock', 'drain', 'purge', 'alloy', 'melt'];

export const Messages = {
	/** Controller → everyone, on every change and at least every few seconds: SmelteryState. */
	state:    'state',
	/** Display → controller, request: answered with SmelteryState. */
	getState: 'getState',
	/** Display → controller, request: SetModeRequest. */
	setMode:  'setMode',
	/** Display → controller, request (manual mode): InsertRequest. */
	insert:   'insert',
	/** Display → controller, request (manual mode): CastRequest. */
	cast:     'cast',
	/** Display → controller, request: SetAlloyRequest. */
	setAlloy: 'setAlloy',
	/** Display → controller, request: SetFormatRequest. */
	setFormat: 'setFormat',
	/** Display → controller, request: SetReservoirRequest. */
	setReservoir: 'setReservoir',
	/** Display → controller, request: SaveRecipeRequest (answered with the state, like the others). */
	saveRecipe:    'saveRecipe',
	/** Display → controller, request: DeleteRecipeRequest. */
	deleteRecipe:  'deleteRecipe',
	/**
	 * Display → controller, request: answered with every fluid the catalogue knows (string[], sorted).
	 * Too long for the state broadcast: the display asks for it once, and again after a recipe change.
	 */
	getFluids:     'getFluids',
} as const;

export interface CasterView {
	name: string;
	kind: CasterKind;
	status: CasterStatus;
	format?: string;
	fluid?: string;
	amount: number;
	output?: ItemSummary;
}

export interface InventoryView {
	name: string;
	used: number;
	size: number;
}

/**
 * An input item auto mode leaves where it is, and why:
 * unknown: no known molten fluid for it; alloy: it would form `alloy` with what is already there;
 * heat: it melts at `temperature`, hotter than the fuel; full: the Smeltery took nothing more.
 */
export interface WaitingItem {
	name: string;
	count: number;
	reason: 'unknown' | 'alloy' | 'heat' | 'full';
	alloy?: string;
	temperature?: number;
}

/** Fuel of the Smeltery, read from a fuel tank on the network. */
export interface FuelView {
	/** Undefined when the tank is empty. */
	fluid?: string;
	amount: number;
	/** Heat the fuel gives, from the catalogue; undefined for an unknown fluid. */
	temperature?: number;
}

/** An input slot as the Manual tab shows it: what would happen if it went in now. */
export interface InputItemView {
	slot: number;
	name: string;
	count: number;
	fluid?: string;
	/** ok: safe to insert; alloy / heat: refused, can be forced; unknown: no fluid, never inserted. */
	status: 'ok' | 'alloy' | 'heat' | 'unknown';
	alloy?: string;
	temperature?: number;
}

/** A recipe of the catalogue, as the alloy picker shows it (a result may have several recipes). */
export interface AlloyOption {
	/** Position of the recipe in the catalogue: what Edit and Delete name. */
	index: number;
	result: string;
	/** mB of `result` the recipe makes from `inputs`. */
	amount: number;
	inputs: {fluid: string; amount: number}[];
	/** mB of the alloy the stock alone can make now with this recipe. */
	fromStock: number;
	/** Set when the fuel is not hot enough to melt into it. */
	temperature?: number;
}

/** The alloy chosen for alloy mode, and its progress. */
export interface AlloyView {
	result: string;
	/** mB wanted; undefined: until the mode is changed. */
	target?: number;
	/** mB cast since it was chosen. */
	made: number;
}

export interface SmelteryState {
	mode: Mode;
	/** os.epoch('utc') of the reading, in ms. */
	time: number;
	/** Bottom first. */
	fluids: FluidStack[];
	melting: ItemSummary[];
	casters: CasterView[];
	input?: InventoryView;
	output?: InventoryView;
	/** Content of the input, judged against what is in the Smeltery now. */
	inputItems: InputItemView[];
	/** Formats auto mode casts, biggest first. */
	autoFormats: string[];
	fuel?: FuelView;
	/** Heat used for the checks: the fuel's, otherwise the configured fallback. */
	heat?: number;
	/** External reservoirs, as last read. */
	reservoirs: ReservoirView[];
	alloy?: AlloyView;
	/** Every recipe of the catalogue, those the stock can make first. */
	alloyOptions: AlloyOption[];
	waiting: WaitingItem[];
	/** Problems the player must fix (missing peripheral, output full, ...). */
	alerts: string[];
	/** Latest events, newest last. */
	log: string[];
}

export interface SetModeRequest {
	mode: Mode;
}

/** Lets auto mode cast into a format, or not (the other modes cast into every format). */
export interface SetFormatRequest {
	format: string;
	auto: boolean;
}

/** Chooses the alloy of alloy mode (and switches to it with `activate`). */
export interface SetAlloyRequest {
	result: string;
	/** mB to make; undefined: until the mode is changed. */
	target?: number;
	activate?: boolean;
}

/**
 * The settings of one reservoir, all at once. fluid: what it is reserved for (none: free). capacity:
 * set by hand in mB (none: the learnt or type one).
 */
export interface SetReservoirRequest {
	reservoir: string;
	fluid?: string;
	capacity?: number;
}

/**
 * Adds a recipe (no index) or replaces the one at `index`. `expected` is the result the display saw at
 * that index: the controller refuses when the catalogue changed meanwhile.
 */
export interface SaveRecipeRequest {
	index?: number;
	expected?: string;
	recipe: AlloyRatio;
}

export interface DeleteRecipeRequest {
	index: number;
	expected: string;
}

/** Most ingredients a recipe may have (the editor shows four rows). */
export const MAX_INGREDIENTS = 4;

export interface InsertRequest {
	/** Slot of the input inventory. */
	slot: number;
	count?: number;
	/** Skips the alloy and heat checks (the display asks twice first). Unknown items are never inserted. */
	force?: boolean;
}

/** One casting of `fluid`: into `caster`, or into any idle caster of `format`. */
export interface CastRequest {
	fluid: string;
	caster?: string;
	format?: string;
}
