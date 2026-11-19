/**
 * npm run dev: compiles the runtime continuously (tstl --watch), serves it with the dev server and,
 * when cloudflared is installed, opens a public tunnel so a computer on any server can reach it.
 *
 * In game: embercore-dev <url> <program> [args...]
 *
 * Environment: DEV_PORT (default: any free port, the tunnel follows it), DEV_TUNNEL=0 to skip the tunnel.
 */
import {type ChildProcess, spawn, spawnSync} from 'node:child_process';
import type {AddressInfo}                     from 'node:net';
import * as path                              from 'node:path';

import {createDevServer, type DevRoot} from './devServer';

const PORT   = Number(process.env['DEV_PORT'] ?? 0);
const CLIENT = path.join('installer', 'embercore-dev.lua');

const ROOTS: DevRoot[] = [
	{dir: 'luas', extension: '.lua', recursive: true},
	{dir: path.join('scripts', 'ingame'), extension: '.lua', recursive: false},
];

const children: ChildProcess[] = [];

function log(message: string): void {
	const time = new Date().toLocaleTimeString();
	console.log(`[dev ${time}] ${message}`);
}

function startCompiler(): void {
	const tstl  = path.join('node_modules', '.bin', 'tstl');
	const child = spawn(tstl, ['-p', 'tsconfig.lua.json', '--watch', '--preserveWatchOutput'], {stdio: ['ignore', 'pipe', 'pipe']});

	const forward = (chunk: Buffer): void => {
		for (const line of chunk.toString().split('\n')) {
			if (line.trim()) console.log(`  tstl: ${line.trim()}`);
		}
	};

	child.stdout?.on('data', forward);
	child.stderr?.on('data', forward);
	children.push(child);
}

/**
 * A new trycloudflare URL answers with errors (530) for a few seconds while it propagates, and
 * wget gives up on the first failure: only announce the URL once it serves the manifest.
 */
async function waitUntilReachable(url: string, timeoutMs = 120_000): Promise<boolean> {
	const deadline = Date.now() + timeoutMs;

	while (Date.now() < deadline) {
		try {
			const response = await fetch(url, {signal: AbortSignal.timeout(10_000)});
			if (response.ok) return true;
		} catch {
			// not resolvable yet
		}

		await new Promise((resolve) => setTimeout(resolve, 1000));
	}

	return false;
}

function startTunnel(port: number): void {
	if (process.env['DEV_TUNNEL'] === '0') return;

	if (spawnSync('cloudflared', ['--version']).error) {
		log('cloudflared not found: no public tunnel (install the "cloudflared" package, or expose the port yourself).');
		log(`Local URL: http://localhost:${port}`);
		return;
	}

	const child = spawn('cloudflared', ['tunnel', '--no-autoupdate', '--url', `http://127.0.0.1:${port}`], {stdio: ['ignore', 'pipe', 'pipe']});
	let announced = false;

	const scan = (chunk: Buffer): void => {
		const match = /https:\/\/[a-z0-9-]+\.trycloudflare\.com/.exec(chunk.toString());

		if (match && !announced) {
			announced = true;
			const url = match[0];
			log(`Tunnel ${url} created, waiting until it answers...`);

			void waitUntilReachable(`${url}/manifest`).then((reachable) => {
				if (!reachable) log('The tunnel still does not answer after 2 minutes; the commands below may fail.');
				log('Tunnel ready. In game:');
				log(`  wget ${url}/client embercore-dev`);
				log(`  embercore-dev ${url} <program> [args...]`);
			});
		}
	};

	child.stdout?.on('data', scan);
	child.stderr?.on('data', scan);
	child.on('exit', (code) => log(`cloudflared stopped (${code})`));
	children.push(child);
}

function stop(code = 0): void {
	for (const child of children) child.kill();
	process.exit(code);
}

function main(): void {
	const dev = createDevServer(ROOTS, CLIENT);

	process.on('SIGINT', () => stop());
	process.on('SIGTERM', () => stop());

	dev.server.on('error', (error: NodeJS.ErrnoException) => {
		if (error.code === 'EADDRINUSE') {
			log(`Port ${PORT} is already used by another program: set another DEV_PORT, or leave it unset to use any free port.`);
		} else {
			log(`Server error: ${error.message}`);
		}
		stop(1);
	});

	// Local only: the computer reaches it through the tunnel. The compiler and the tunnel start
	// once the port is ours, so a failure never leaves them running alone.
	dev.server.listen(PORT, '127.0.0.1', () => {
		const port = (dev.server.address() as AddressInfo).port;
		log(`Serving luas/ and scripts/ingame/ on http://localhost:${port}`);

		startCompiler();
		startTunnel(port);

		setInterval(() => {
			if (dev.refresh()) log(`Revision ${dev.revision()} published`);
		}, 500);
	});
}

main();
