import {Peripheral}                 from '@core/peripheral';

import type {ControllerConfig}      from './config';

export interface Network {
	drain?: string;
	chute?: string;
	casters: string[];
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
	const network: Network   = {casters: [], reservoirs: [], problems};

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

	if (config.casters.length > 0) {
		for (const name of config.casters) {
			if (peripheral.isPresent(name)) network.casters.push(name);
			else problems.push(`caster '${name}' not found on the network`);
		}
	}
	else {
		for (const name of [...namesOfType('tconstruct:table'), ...namesOfType('tconstruct:basin')]) {
			network.casters.push(name);
		}
	}

	if (network.casters.length === 0) problems.push('no casting table nor basin found on the network');

	// Optional: without a fuel tank, the configured fuel is assumed.
	const fuelTank = config.fuelTank !== '' ? (peripheral.isPresent(config.fuelTank) ? config.fuelTank : undefined) : findFuelTank();
	if (config.fuelTank !== '' && fuelTank === undefined) problems.push(`fuel tank '${config.fuelTank}' not found on the network`);
	if (fuelTank !== undefined) network.fuelTank = fuelTank;

	// Reservoirs: the configured ones, otherwise every other fluid storage (not the Smeltery, its casters
	// nor its fuel tank).
	if (config.reservoirs.length > 0) {
		for (const name of config.reservoirs) {
			if (peripheral.isPresent(name)) network.reservoirs.push(name);
			else problems.push(`reservoir '${name}' not found on the network`);
		}
	}
	else {
		for (const name of namesOfType('fluid_storage')) {
			if (name.startsWith('tconstruct:') || name === fuelTank) continue;
			network.reservoirs.push(name);
		}
	}

	return network;
}
