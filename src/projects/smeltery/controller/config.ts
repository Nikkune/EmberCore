import {Config}        from '@core/config';

import {MODES}         from '../shared/protocol';
import type {AlloyView, Mode} from '../shared/protocol';

export const CONFIG_PATH = '/smeltery/controller.db';
export const MODE_PATH   = '/smeltery/mode.db';
export const RESERVOIRS_PATH = '/smeltery/reservoirs.db';

/**
 * Peripheral names are what the wired modems show ('sophisticatedstorage:barrel_1'). An empty name or
 * list means "find it on the network"; input and output cannot be told apart, so they must be set.
 */
export interface ControllerConfig {
	input: string;
	output: string;
	/** Where auto mode sends input items too hot for the fuel; empty: they stay in the input. */
	heatOutput: string;
	/** Where auto mode sends input items that melt into nothing known; empty: they stay in the input. */
	unknownOutput: string;
	/** A drain of the Smeltery (any one: they all see the same Smeltery). */
	drain: string;
	chute: string;
	/** Casting tables and basins; empty: every one on the network. */
	casters: string[];
	/**
	 * A fuel tank of the Smeltery (a seared tank or gauge with a wired modem); empty: the first one found.
	 * Its fluid gives the heat items are checked against.
	 */
	fuelTank: string;
	/** Fuel assumed when no fuel tank is on the network: items too hot for it wait. */
	fuel: string;
	/** Fluid reservoirs (drums, tanks) for leftovers, drain and purge; empty: every other fluid storage found. */
	reservoirs: string[];
	/** Manual assignments, kept first: such a reservoir only ever takes its fluid. */
	assignments: {reservoir: string; fluid: string}[];
	/** Capacities set by hand (from the display), used when none was learnt; before the type ones. */
	capacities: {reservoir: string; capacity: number}[];
	/**
	 * Capacity of the Smeltery in mB (it does not tell it), for the display's gauge; 0: unknown. Learnt
	 * when the Smeltery refuses part of a stock coming back, or set from the display.
	 */
	smelteryCapacity: number;
	/** Where smelteryCapacity comes from: 'learnt', 'set' (from the display), '' (unknown). */
	smelteryCapacitySource: string;
	/**
	 * Formats auto mode casts, biggest first; casters with another cast are left to the other modes.
	 * Also set from the display (Overview, CASTING: AUTO / off).
	 */
	formatPriority: string[];
	/**
	 * Auto, alloy and melt: after this many seconds with nothing happening (nothing goes in, melts, is
	 * cast or collected), the Smeltery is drained into the reservoirs and goes idle. 0: never.
	 */
	idleSeconds: number;
	/** Seconds between two readings of the Smeltery. */
	tickSeconds: number;
	/** Seconds to the next reading after a tick that moved something (cast, collect, insert...). */
	activeTickSeconds: number;
	/** The state is broadcast on every change, and at least this often. */
	heartbeatSeconds: number;
	/** Log lines kept and sent to the display (pages of 20 in the Log tab). */
	logSize: number;
}

export function defaultControllerConfig(this: void): ControllerConfig {
	return {
		input:            '',
		output:           '',
		heatOutput:       '',
		unknownOutput:    '',
		drain:            '',
		chute:            '',
		casters:          [],
		fuelTank:         '',
		fuel:             'minecraft:lava',
		reservoirs:       [],
		assignments:      [],
		capacities:       [],
		smelteryCapacity: 0,
		smelteryCapacitySource: '',
		formatPriority:   ['block', 'ingot', 'nugget'],
		idleSeconds:      30,
		tickSeconds:      1,
		activeTickSeconds: 0.25,
		heartbeatSeconds: 5,
		logSize:          100,
	};
}

/** logSize of the first versions, written into every saved configuration: one page of the Log tab. */
const OLD_LOG_SIZE = 20;

export function loadControllerConfig(this: void, path = CONFIG_PATH): ControllerConfig {
	const config = Config.load(path, defaultControllerConfig());
	// Saved with the old default, it would keep the Log tab to one page: the new default replaces it.
	if (config.logSize === OLD_LOG_SIZE) config.logSize = defaultControllerConfig().logSize;
	return config;
}

/** Written back when the display changes a setting (the auto formats). */
export function saveControllerConfig(this: void, config: ControllerConfig, path = CONFIG_PATH): void {
	Config.save(path, config);
}

interface ModeFile {
	mode: string;
	/** Mode a purge goes back to. */
	previous: string;
}

function toMode(this: void, value: string, fallback: Mode): Mode {
	for (const mode of MODES) {
		if (mode === value) return mode;
	}
	return fallback;
}

/** The mode (and the one a purge goes back to) survive a restart; 'idle' when none was saved. */
export function loadMode(this: void, path = MODE_PATH): {mode: Mode; previous: Mode} {
	const saved = Config.load<ModeFile>(path, {mode: 'idle', previous: 'idle'});
	return {mode: toMode(saved.mode, 'idle'), previous: toMode(saved.previous, 'idle')};
}

export function saveMode(this: void, mode: Mode, previous: Mode, path = MODE_PATH): void {
	Config.save<ModeFile>(path, {mode, previous});
}

export const ALLOY_PATH = '/smeltery/alloy.db';

interface AlloyFile {
	result: string;
	/** mB wanted; 0: until the mode is changed. */
	target: number;
	made: number;
}

/** The alloy chosen for alloy mode and its progress survive a restart; undefined when none was chosen. */
export function loadAlloy(this: void, path = ALLOY_PATH): AlloyView | undefined {
	const saved = Config.load<AlloyFile>(path, {result: '', target: 0, made: 0});
	if (saved.result === '') return undefined;
	const alloy: AlloyView = {result: saved.result, made: saved.made};
	if (saved.target > 0) alloy.target = saved.target;
	return alloy;
}

export function saveAlloy(this: void, alloy: AlloyView, path = ALLOY_PATH): void {
	Config.save<AlloyFile>(path, {result: alloy.result, target: alloy.target ?? 0, made: alloy.made});
}

/** No alloy chosen any more (its last recipe was deleted). */
export function clearAlloy(this: void, path = ALLOY_PATH): void {
	Config.save<AlloyFile>(path, {result: '', target: 0, made: 0});
}

interface ReservoirsFile {
	capacities: {reservoir: string; capacity: number}[];
}

/** Reservoir capacities learnt during earlier runs. */
export function loadCapacities(this: void, path = RESERVOIRS_PATH): Record<string, number> {
	const result: Record<string, number> = {};
	for (const entry of Config.load<ReservoirsFile>(path, {capacities: []}).capacities) result[entry.reservoir] = entry.capacity;
	return result;
}

export function saveCapacities(this: void, capacities: Record<string, number>, path = RESERVOIRS_PATH): void {
	const entries: {reservoir: string; capacity: number}[] = [];
	for (const reservoir in capacities) entries.push({reservoir, capacity: capacities[reservoir]!});
	Config.save<ReservoirsFile>(path, {capacities: entries});
}
