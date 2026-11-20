import {Config}         from '@core/config';
import {Peripheral}     from '@core/peripheral';

type Role = 'controller' | 'display';

const ROLE_PATH = '/smeltery/role.db';

/**
 * Each role is installed on its own (embercore install smeltery-controller / smeltery-display): both
 * would not fit on one computer (1 MB). So main loads the role it runs, never the other one.
 */
const ROLE_MODULES: Record<Role, string> = {
	controller: 'projects.smeltery.controller.controller',
	display:    'projects.smeltery.display.display',
};

/** Lua's require: the role module is loaded only when it is the one that runs. */
declare function require(this: void, module: string): unknown;

interface RoleFile {
	role: string;
}

function isRole(this: void, value: string | undefined): value is Role {
	return value === 'controller' || value === 'display';
}

function isInstalled(this: void, role: Role): boolean {
	return fs.exists(`/${ROLE_MODULES[role].split('.').join('/')}.lua`);
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
 * previous start, otherwise the only one installed, otherwise detected from the peripherals. The
 * startup.lua written by the installer runs main with no argument, so the role is saved once known.
 */
function resolveRole(this: void, argument: string | undefined): Role | undefined {
	const saved     = Config.load<RoleFile>(ROLE_PATH, {role: ''});
	const installed = (['controller', 'display'] as Role[]).filter((role) => isInstalled(role));
	const only      = installed.length === 1 ? installed[0] : undefined;
	const role      = isRole(argument) ? argument : isRole(saved.role) ? saved.role : only ?? detectRole();

	if (role !== undefined && role !== saved.role) Config.save<RoleFile>(ROLE_PATH, {role});
	return role;
}

const [argument] = [...$vararg];

if (argument !== undefined && !isRole(argument)) {
	print('Usage: main [controller|display]');
}
else {
	const role = resolveRole(argument);

	if (role === undefined) {
		print('No Smeltery drain nor monitor found: start with "main controller" or "main display".');
	}
	else if (!isInstalled(role)) {
		print(`The ${role} is not installed on this computer: embercore install smeltery-${role}`);
	}
	else if (role === 'controller') {
		(require(ROLE_MODULES.controller) as {runController: (this: void) => void}).runController();
	}
	else {
		(require(ROLE_MODULES.display) as {runDisplay: (this: void) => void}).runDisplay();
	}
}
