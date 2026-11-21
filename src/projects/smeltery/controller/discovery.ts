import {Peripheral}                 from '@core/peripheral';

import type {ControllerConfig}      from './config';

export interface Network {
	drain?: string;
	chute?: string;
	casters: string[];
	/** Tables and basins for casting onto an item (never among `casters`). */
	craftCasters: string[];
	/** The fluid trash can (never among `reservoirs`). */
	trash?: string;
	input?: string;
	output?: string;
	heatOutput?: string;
	unknownOutput?: string;
	fuelTank?: string;
	reservoirs: string[];
	/** What is missing or wrong, for the alerts. */
	problems: string[];
}

function namesOfType(this: void, type: string): string[] {
	const names: string[] = [];

	for (const name of peripheral.getNames()) {
		if (Peripheral.hasType(name, type)) names.push(name);
	}

	names.sort();
	return names;
}

function pick(this: void, configured: string, type: string, label: string, problems: string[]): string | undefined {
	if (configured !== '') {
		if (peripheral.isPresent(configured)) return configured;
		problems.push(`${label} '${configured}' not found on the network`);
		return undefined;
	}

	const [first] = namesOfType(type);
	if (first === undefined) problems.push(`no ${label} found on the network`);
	return first;
}

function pickInventory(this: void, configured: string, label: string, problems: string[]): string | undefined {
	if (configured === '') {
		problems.push(`${label} inventory not set in the controller config`);
		return undefined;
	}

	if (!peripheral.isPresent(configured)) {
		problems.push(`${label} inventory '${configured}' not found on the network`);
		return undefined;
	}

	return configured;
}

/** A TConstruct tank or gauge (any fluid storage of tconstruct that is not a drain, table or basin). */
function findFuelTank(this: void): string | undefined {
	for (const name of namesOfType('fluid_storage')) {
		if (!name.startsWith('tconstruct:')) continue;
		if (name.includes('drain') || name.includes('table') || name.includes('basin')) continue;
		if (name.includes('tank') || name.includes('gauge')) return name;
	}

	return undefined;
}

/** Finds the Smeltery peripherals: configured names first, otherwise the first (or every) one of the right type. */
export function discoverNetwork(this: void, config: ControllerConfig): Network {
	const problems: string[] = [];
	const network: Network   = {casters: [], craftCasters: [], reservoirs: [], problems};

	const drain = pick(config.drain, 'tconstruct:drain', 'Smeltery drain', problems);
	const chute = pick(config.chute, 'tconstruct:chute', 'Smeltery chute', problems);
	const input = pickInventory(config.input, 'input', problems);
	const output = pickInventory(config.output, 'output', problems);

	if (drain !== undefined) network.drain = drain;
	if (chute !== undefined) network.chute = chute;
	if (input !== undefined) network.input = input;
	if (output !== undefined) network.output = output;

	// Optional: unset means the rejected items stay in the input.
	if (config.heatOutput !== '') {
		const heat = pickInventory(config.heatOutput, 'heat output', problems);
		if (heat !== undefined) network.heatOutput = heat;
	}
	if (config.unknownOutput !== '') {
		const unknown = pickInventory(config.unknownOutput, 'unknown output', problems);
		if (unknown !== undefined) network.unknownOutput = unknown;
	}

	for (const name of config.craftCasters) {
		if (peripheral.isPresent(name)) network.craftCasters.push(name);
		else problems.push(`craft caster '${name}' not found on the network`);
	}
	const craft = new Set(config.craftCasters);

	if (config.casters.length > 0) {
		for (const name of config.casters) {
			if (craft.has(name)) continue;
			if (peripheral.isPresent(name)) network.casters.push(name);
			else problems.push(`caster '${name}' not found on the network`);
		}
	}
	else {
		for (const name of [...namesOfType('tconstruct:table'), ...namesOfType('tconstruct:basin')]) {
			if (!craft.has(name)) network.casters.push(name);
		}
	}

	if (network.casters.length === 0) problems.push('no casting table nor basin found on the network');

	// Optional: without a fuel tank, the configured fuel is assumed.
	const fuelTank = config.fuelTank !== '' ? (peripheral.isPresent(config.fuelTank) ? config.fuelTank : undefined) : findFuelTank();
	if (config.fuelTank !== '' && fuelTank === undefined) problems.push(`fuel tank '${config.fuelTank}' not found on the network`);
	if (fuelTank !== undefined) network.fuelTank = fuelTank;

	// Optional: without a trash can, fluids cannot be trashed from the display.
	let trash: string | undefined;
	if (config.fluidTrash !== '') {
		if (peripheral.isPresent(config.fluidTrash)) trash = config.fluidTrash;
		else problems.push(`fluid trash '${config.fluidTrash}' not found on the network`);
	}
	else {
		trash = namesOfType('fluid_storage').find((name) => name.includes('trash'));
	}
	if (trash !== undefined) network.trash = trash;

	// Reservoirs: the configured ones, otherwise every other fluid storage (not the Smeltery, its casters,
	// its fuel tank nor the trash can).
	if (config.reservoirs.length > 0) {
		for (const name of config.reservoirs) {
			if (name === trash) continue;
			if (peripheral.isPresent(name)) network.reservoirs.push(name);
			else problems.push(`reservoir '${name}' not found on the network`);
		}
	}
	else {
		for (const name of namesOfType('fluid_storage')) {
			if (name.startsWith('tconstruct:') || name === fuelTank || name === trash) continue;
			network.reservoirs.push(name);
		}
	}

	return network;
}
