/**
 * Installer tests: runs scripts/test/installer.lua, which drives installer/embercore.lua in a fake
 * CC:Tweaked environment against the compiled runtime (luas/) and manifests (manifests/).
 *
 * Requires `npm run build:all` first.
 */
import {spawnSync} from 'node:child_process';
import * as fs     from 'node:fs';
import * as path   from 'node:path';

import {findLua} from './lua';

const INSTALLER     = path.join('installer', 'embercore.lua');
const DIST_DIR      = 'luas';
const MANIFESTS_DIR = 'manifests';

function main(): void {
	for (const dir of [DIST_DIR, MANIFESTS_DIR]) {
		if (!fs.existsSync(dir)) {
			throw new Error(`${dir}/ not found: run "npm run build:all" first.`);
		}
	}

	const lua = findLua();
	console.log(`Using Lua interpreter: ${lua}`);

	const run = spawnSync(lua, [path.join('scripts', 'test', 'installer.lua'), INSTALLER, DIST_DIR, MANIFESTS_DIR], {stdio: 'inherit'});

	if (run.error) throw run.error;
	process.exit(run.status ?? 1);
}

try {
	main();
} catch (error) {
	console.error(error instanceof Error ? error.message : String(error));
	process.exit(1);
}
