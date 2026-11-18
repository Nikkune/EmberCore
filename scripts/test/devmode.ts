/**
 * Dev mode tests: checks the dev server over real HTTP, then runs scripts/test/devmode.lua, where
 * installer/embercore-dev.lua talks to that same server through curl.
 */
import {spawn}    from 'node:child_process';
import * as fs    from 'node:fs';
import type {AddressInfo} from 'node:net';
import * as os    from 'node:os';
import * as path  from 'node:path';

import {createDevServer} from '../dev/devServer';

import {findLua}         from './lua';

let failures = 0;

function check(condition: boolean, message: string): void {
	if (condition) {
		console.log(`  ok   ${message}`);
	} else {
		failures += 1;
		console.log(`  FAIL ${message}`);
	}
}

async function get(base: string, route: string): Promise<{status: number; body: string; ms: number}> {
	const start    = Date.now();
	const response = await fetch(base + route);
	return {status: response.status, body: await response.text(), ms: Date.now() - start};
}

async function main(): Promise<void> {
	const served = fs.mkdtempSync(path.join(os.tmpdir(), 'embercore-dev-'));
	fs.mkdirSync(path.join(served, 'sub'));
	fs.writeFileSync(path.join(served, 'a.lua'), 'return "a1"');
	fs.writeFileSync(path.join(served, 'sub', 'b.lua'), 'return "b1"');
	fs.writeFileSync(path.join(served, 'notes.txt'), 'not served');
	fs.writeFileSync(path.join(os.tmpdir(), 'embercore-dev-secret.lua'), 'secret');

	const client = path.join('installer', 'embercore-dev.lua');
	const dev    = createDevServer([{dir: served, extension: '.lua', recursive: true}], client, 300);
	await new Promise<void>((resolve) => dev.server.listen(0, '127.0.0.1', resolve));
	const base = `http://127.0.0.1:${(dev.server.address() as AddressInfo).port}`;

	console.log('Dev server tests');

	check(!dev.refresh() && dev.refresh() && dev.revision() === 1, 'a revision is published after two identical scans');

	const manifest = JSON.parse((await get(base, '/manifest')).body) as {revision: number; files: Record<string, string>};
	check(manifest.revision === 1 && Object.keys(manifest.files).sort().join(',') === 'a.lua,sub/b.lua', 'manifest lists the .lua files only');

	check((await get(base, '/files/sub%2Fb.lua')).body === 'return "b1"', 'files are served by key');
	check((await get(base, '/files/..%2Fembercore-dev-secret.lua')).status === 404, 'nothing outside the manifest is served');
	check((await get(base, '/files/notes.txt')).status === 404, 'unlisted files are not served');
	check((await get(base, '/client')).body === fs.readFileSync(client, 'utf-8'), '/client serves the dev mode client');

	const timeout = await get(base, '/wait?revision=1');
	check(timeout.ms >= 250 && JSON.parse(timeout.body).revision === 1, '/wait holds the request when nothing changes');
	check((await get(base, '/wait?revision=0')).ms < 200, '/wait answers at once for an old revision');

	const waiting = get(base, '/wait?revision=1');
	fs.writeFileSync(path.join(served, 'a.lua'), 'return "a2"');
	dev.refresh();
	dev.refresh();
	check(JSON.parse((await waiting).body).revision === 2, '/wait wakes up on a new revision');

	// Lua client against the live server, files refreshed as the compiler would.
	const ticker = setInterval(() => dev.refresh(), 50);
	const lua    = findLua();
	console.log(`\nUsing Lua interpreter: ${lua}`);

	const code = await new Promise<number>((resolve) => {
		const child = spawn(lua, [path.join('scripts', 'test', 'devmode.lua'), path.join('installer', 'embercore-dev.lua'), base, served], {stdio: 'inherit'});
		child.on('exit', (status) => resolve(status ?? 1));
	});

	clearInterval(ticker);
	dev.server.close();
	fs.rmSync(served, {recursive: true, force: true});
	fs.rmSync(path.join(os.tmpdir(), 'embercore-dev-secret.lua'), {force: true});

	if (code !== 0) failures += 1;
	process.exit(failures === 0 ? 0 : 1);
}

main().catch((error: unknown) => {
	console.error(error instanceof Error ? error.stack : String(error));
	process.exit(1);
});
