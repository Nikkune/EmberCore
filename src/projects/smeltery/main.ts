import {Config}         from '@core/config';
import {Peripheral}     from '@core/peripheral';

import {runController}  from './controller/controller';
import {runDisplay}     from './display/display';

type Role = 'controller' | 'display';

const ROLE_PATH = '/smeltery/role.db';

interface RoleFile {
	role: string;
}

function isRole(this: void, value: string | undefined): value is Role {
	return value === 'controller' || value === 'display';
}

/** A computer next to a Smeltery drain is the controller; one with a monitor is the display. */
function detectRole(this: void): Role | undefined {
	for (const name of peripheral.getNames()) {
		if (Peripheral.hasType(name, 'tconstruct:drain')) return 'controller';
	}

	return Peripheral.findNameByType('monitor') !== undefined ? 'display' : undefined;
}

/**
 * Role of this computer: the argument (`main controller` / `main display`), otherwise the one saved by a
 * previous start, otherwise detected from the peripherals. The startup.lua written by the installer runs
 * main with no argument, so the role is saved once known.
 */
function resolveRole(this: void, argument: string | undefined): Role | undefined {
	const saved = Config.load<RoleFile>(ROLE_PATH, {role: ''});
	const role  = isRole(argument) ? argument : isRole(saved.role) ? saved.role : detectRole();

	if (role !== undefined && role !== saved.role) Config.save<RoleFile>(ROLE_PATH, {role});
	return role;
}

const [argument] = [...$vararg];

if (argument !== undefined && !isRole(argument)) {
	print('Usage: main [controller|display]');
}
else {
	const role = resolveRole(argument);

	if (role === 'controller') runController();
	else if (role === 'display') runDisplay();
	else print('No Smeltery drain nor monitor found: start with "main controller" or "main display".');
}
