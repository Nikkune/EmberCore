/**
 * Smoke test: simulates an in-game install of every component/project from the generated manifests
 * (only the listed files of the component and its transitive dependencies), then loads each Lua module
 * with stubbed CC:Tweaked APIs. Catches missing files in manifests and circular requires.
 *
 * Requires `npm run build` and `npm run generate:manifests` first.
 * Lua interpreter: $LUA, otherwise `lua5.2`, otherwise `lua`.
 */
import {spawnSync} from 'node:child_process';
import * as fs     from 'node:fs';
import * as os     from 'node:os';
import * as path   from 'node:path';

import type {AnyManifest, IndexManifest} from '../manifest/manifestTypes';

const DIST_DIR      = 'luas';
const MANIFESTS_DIR = '.';
const LOADER        = path.join('scripts', 'test', 'cc-loader.lua');

function readJson<T>(filePath: string): T {
	return JSON.parse(fs.readFileSync(filePath, 'utf-8')) as T;
}

function findLua(): string {
	const candidates = process.env['LUA'] ? [process.env['LUA']] : ['lua5.2', 'lua'];

	for (const candidate of candidates) {
		const probe = spawnSync(candidate, ['-v'], {encoding: 'utf-8'});
		if (!probe.error) return candidate;
	}

	throw new Error(`No Lua interpreter found (tried: ${candidates.join(', ')}). Set $LUA.`);
}

function loadManifests(): Map<string, AnyManifest> {
	const indexPath = path.join(MANIFESTS_DIR, 'manifests', 'index.json');

	if (!fs.existsSync(indexPath)) {
		throw new Error(`${indexPath} not found: run "npm run build:all" first.`);
	}

	const index     = readJson<IndexManifest>(indexPath);
	const manifests = new Map<string, AnyManifest>();

	for (const relativePath of [...Object.values(index.components), ...Object.values(index.projects)]) {
		const manifest = readJson<AnyManifest>(path.join(MANIFESTS_DIR, relativePath));
		manifests.set(manifest.id, manifest);
	}

	return manifests;
}

function collectClosure(id: string, manifests: Map<string, AnyManifest>, seen = new Set<string>()): Set<string> {
	if (seen.has(id)) return seen;
	seen.add(id);

	const manifest = manifests.get(id);
	if (!manifest) throw new Error(`Unknown manifest '${id}'`);

	for (const dependency of manifest.dependencies) {
		collectClosure(dependency, manifests, seen);
	}

	return seen;
}

function toModuleName(file: string): string {
	return file.replace(/\.lua$/, '').split('/').join('.');
}

function main(): void {
	const lua       = findLua();
	const manifests = loadManifests();
	let failures    = 0;

	console.log(`Using Lua interpreter: ${lua}`);

	for (const manifest of [...manifests.values()].sort((a, b) => a.id.localeCompare(b.id))) {
		const installDir = fs.mkdtempSync(path.join(os.tmpdir(), 'embercore-smoke-'));

		try {
			for (const id of collectClosure(manifest.id, manifests)) {
				for (const file of manifests.get(id)!.files) {
					const target = path.join(installDir, file);
					fs.mkdirSync(path.dirname(target), {recursive: true});
					fs.copyFileSync(path.join(DIST_DIR, file), target);
				}
			}

			// Project entrypoints run the program on load: only compile them.
			const entry   = manifest.type === 'project' ? manifest.entry : undefined;
			const modules = manifest.files.map((file) => (file === entry ? '@' : '') + toModuleName(file));

			const run = spawnSync(lua, [LOADER, installDir, ...modules], {encoding: 'utf-8'});

			if (run.status === 0) {
				console.log(`ok   ${manifest.id} (${modules.length} module(s))`);
			}
			else {
				failures++;
				console.log(`FAIL ${manifest.id}`);
				const details = (run.stdout + run.stderr).trimEnd() || `exit status ${run.status ?? 'unknown'}`;
				console.log(details.replace(/^/gm, '     '));
			}
		} finally {
			fs.rmSync(installDir, {recursive: true, force: true});
		}
	}

	if (failures > 0) {
		console.error(`\n${failures} component(s) failed to load.`);
		process.exit(1);
	}

	console.log(`\nAll ${manifests.size} component(s) load correctly.`);
}

try {
	main();
} catch (error) {
	console.error(error instanceof Error ? error.message : String(error));
	process.exit(1);
}
