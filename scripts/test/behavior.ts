/**
 * Behaviour regression tests: runs scripts/test/behavior.lua on the compiled Lua (luas/)
 * with a fake CC:Tweaked environment (scripts/test/cc-env.lua).
 *
 * Requires `npm run build` first.
 */
import {spawnSync} from 'node:child_process';
import * as fs     from 'node:fs';
import * as path   from 'node:path';

import {findLua} from './lua';

const DIST_DIR = 'luas';
const TEST_DIR = path.join('scripts', 'test');

function main(): void {
	if (!fs.existsSync(DIST_DIR)) {
		throw new Error(`${DIST_DIR}/ not found: run "npm run build" first.`);
	}

	const lua = findLua();
	console.log(`Using Lua interpreter: ${lua}`);

	const run = spawnSync(lua, [path.join(TEST_DIR, 'behavior.lua'), DIST_DIR, TEST_DIR], {stdio: 'inherit'});

	if (run.error) throw run.error;
	process.exit(run.status ?? 1);
}

try {
	main();
} catch (error) {
	console.error(error instanceof Error ? error.message : String(error));
	process.exit(1);
}
