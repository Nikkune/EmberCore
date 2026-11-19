import type {ItemSummary}                from '@core/inventory';
import type {FluidStack}                 from '@core/tank';
import type {CasterKind, CasterStatus}   from '@modules/tinkers/index';

/** What the controller and the display say to each other over rednet. */
export const PROTOCOL            = 'smeltery/v1';
export const CONTROLLER_HOSTNAME = 'smeltery-controller';

/**
 * idle:   nothing automatic, the state is kept;
 * auto:   melts the input and casts pure metals, never lets an alloy form;
 * manual: only what the display asks (insert, cast);
 * lock:   no new item goes in, the casts under way finish.
 */
export type Mode = 'idle' | 'auto' | 'manual' | 'lock';

export const MODES: Mode[] = ['idle', 'auto', 'manual', 'lock'];

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
	waiting: WaitingItem[];
	/** Problems the player must fix (missing peripheral, output full, ...). */
	alerts: string[];
	/** Latest events, newest last. */
	log: string[];
}

export interface SetModeRequest {
	mode: Mode;
}

export interface InsertRequest {
	/** Slot of the input inventory. */
	slot: number;
	count?: number;
}

export interface CastRequest {
	caster: string;
	fluid: string;
}
