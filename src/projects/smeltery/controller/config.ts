import {Config}        from '@core/config';

import {MODES}         from '../shared/protocol';
import type {Mode}     from '../shared/protocol';

export const CONFIG_PATH = '/smeltery/controller.db';
export const MODE_PATH   = '/smeltery/mode.db';

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
	/** Fluid burning in the Smeltery (its tanks are not on the network): items too hot for it wait. */
	fuel: string;
	/** Formats auto mode casts, first preferred; casters with another cast are left to the other modes. */
	formatPriority: string[];
	/** Seconds between two readings of the Smeltery. */
	tickSeconds: number;
	/** The state is broadcast on every change, and at least this often. */
	heartbeatSeconds: number;
	/** Log lines kept and sent to the display. */
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
		fuel:             'minecraft:lava',
		formatPriority:   ['block', 'ingot', 'nugget'],
		tickSeconds:      1,
		heartbeatSeconds: 5,
		logSize:          20,
	};
}

export function loadControllerConfig(this: void, path = CONFIG_PATH): ControllerConfig {
	return Config.load(path, defaultControllerConfig());
}

interface ModeFile {
	mode: string;
}

/** The mode survives a restart; 'idle' when none was saved. */
export function loadMode(this: void, path = MODE_PATH): Mode {
	const saved = Config.load<ModeFile>(path, {mode: 'idle'}).mode;

	for (const mode of MODES) {
		if (mode === saved) return mode;
	}

	return 'idle';
}

export function saveMode(this: void, mode: Mode, path = MODE_PATH): void {
	Config.save<ModeFile>(path, {mode});
}
