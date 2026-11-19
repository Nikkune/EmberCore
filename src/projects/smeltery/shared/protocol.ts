import type {ItemSummary}                from '@core/inventory';
import type {FluidStack}                 from '@core/tank';
import type {ReservoirView}              from '@modules/fluids/index';
import type {CasterKind, CasterStatus}   from '@modules/tinkers/index';

/** What the controller and the display say to each other over rednet. */
export const PROTOCOL            = 'smeltery/v1';
export const CONTROLLER_HOSTNAME = 'smeltery-controller';

/**
 * idle:   nothing automatic, the state is kept;
 * auto:   melts the input and casts pure metals, never lets an alloy form;
 * manual: only what the display asks (insert, cast);
 * lock:   no new item goes in, the casts under way finish;
 * drain:  every fluid goes to the reservoirs, then idle;
 * purge:  leftovers and alloys go to the reservoirs, then back to the previous mode.
 */
export type Mode = 'idle' | 'auto' | 'manual' | 'lock' | 'drain' | 'purge';

export const MODES: Mode[] = ['idle', 'auto', 'manual', 'lock', 'drain', 'purge'];

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
	/** Display → controller, request: SetFormatRequest. */
	setFormat: 'setFormat',
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
