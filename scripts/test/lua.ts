import {spawnSync} from 'node:child_process';

/** Lua interpreter used by the tests: $LUA, otherwise `lua5.1`, `luajit`, `lua5.2`, otherwise `lua`. */
export function findLua(): string {
	const candidates = process.env['LUA'] ? [process.env['LUA']] : ['lua5.1', 'luajit', 'lua5.2', 'lua'];

	for (const candidate of candidates) {
		const probe = spawnSync(candidate, ['-v'], {encoding: 'utf-8'});
		if (!probe.error) return candidate;
	}

	throw new Error(`No Lua interpreter found (tried: ${candidates.join(', ')}). Set $LUA.`);
}
