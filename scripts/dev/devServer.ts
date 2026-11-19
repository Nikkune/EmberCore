/**
 * Dev mode server: serves the compiled runtime to a CC:Tweaked computer running
 * installer/embercore-dev.lua, which downloads the files that changed and restarts its program.
 *
 *   GET /manifest            {"revision": n, "files": {"core/config.lua": "<hash>", ...}}
 *   GET /wait?revision=n     answers as soon as the revision is not n (or after WAIT_MS): {"revision": m}
 *   GET /files/<path>        content of a file listed in the manifest
 *   GET /client              the dev mode client itself (wget <url>/client embercore-dev)
 */
import * as crypto from 'node:crypto';
import * as fs     from 'node:fs';
import * as http   from 'node:http';
import * as path   from 'node:path';

export interface DevRoot {
	/** Folder on this machine. */
	dir: string;
	/** Only files with this extension are served. */
	extension: string;
	/** Recurse into sub-folders. */
	recursive: boolean;
}

export type FileHashes = Record<string, string>;

const WAIT_MS = 20_000;

function listFiles(root: DevRoot, dir: string, out: string[]): void {
	if (!fs.existsSync(dir)) return;

	for (const entry of fs.readdirSync(dir, {withFileTypes: true})) {
		const full = path.join(dir, entry.name);

		if (entry.isDirectory()) {
			if (root.recursive) listFiles(root, full, out);
		} else if (entry.name.endsWith(root.extension)) {
			out.push(full);
		}
	}
}

/** Hashes every served file, keyed by its path on the computer (relative to its root, '/' separators). */
export function scanFiles(roots: DevRoot[]): {hashes: FileHashes; sources: Record<string, string>} {
	const hashes: FileHashes             = {};
	const sources: Record<string, string> = {};

	for (const root of roots) {
		const files: string[] = [];
		listFiles(root, root.dir, files);

		for (const file of files) {
			const key = path.relative(root.dir, file).split(path.sep).join('/');
			hashes[key]  = crypto.createHash('sha1').update(fs.readFileSync(file)).digest('hex').slice(0, 16);
			sources[key] = file;
		}
	}

	return {hashes, sources};
}

function sameHashes(a: FileHashes, b: FileHashes): boolean {
	const keys = Object.keys(a);
	return keys.length === Object.keys(b).length && keys.every((key) => a[key] === b[key]);
}

export interface DevServer {
	server: http.Server;
	/** Rescans the files; returns true when the served revision changed. */
	refresh(): boolean;
	revision(): number;
}

/**
 * A revision is published only once two consecutive scans agree, so a computer never downloads a
 * file the compiler is still writing.
 */
export function createDevServer(roots: DevRoot[], clientPath?: string, waitMs = WAIT_MS): DevServer {
	let revision                          = 0;
	let published: FileHashes             = {};
	let sources: Record<string, string>   = {};
	let pending: FileHashes | undefined;
	const waiters: (() => void)[]         = [];

	function refresh(): boolean {
		const scan = scanFiles(roots);

		if (sameHashes(scan.hashes, published)) {
			pending = undefined;
			return false;
		}

		if (!pending || !sameHashes(scan.hashes, pending)) {
			pending = scan.hashes;
			return false;
		}

		published = scan.hashes;
		sources   = scan.sources;
		pending   = undefined;
		revision += 1;

		for (const wake of waiters.splice(0)) wake();
		return true;
	}

	function sendJson(response: http.ServerResponse, body: unknown): void {
		response.writeHead(200, {'Content-Type': 'application/json', 'Cache-Control': 'no-store'});
		response.end(JSON.stringify(body));
	}

	const server = http.createServer((request, response) => {
		const url = new URL(request.url ?? '/', 'http://localhost');

		if (request.method !== 'GET') {
			response.writeHead(405).end();
			return;
		}

		if (url.pathname === '/manifest') {
			sendJson(response, {revision, files: published});
			return;
		}

		if (url.pathname === '/wait') {
			const known = Number(url.searchParams.get('revision'));

			if (known !== revision) {
				sendJson(response, {revision});
				return;
			}

			let done = false;
			const answer = (): void => {
				if (done) return;
				done = true;
				clearTimeout(timer);
				sendJson(response, {revision});
			};
			const timer = setTimeout(answer, waitMs);
			waiters.push(answer);
			request.on('close', () => {
				done = true;
				clearTimeout(timer);
			});
			return;
		}

		if (url.pathname === '/client' && clientPath && fs.existsSync(clientPath)) {
			response.writeHead(200, {'Content-Type': 'text/plain', 'Cache-Control': 'no-store'});
			response.end(fs.readFileSync(clientPath));
			return;
		}

		if (url.pathname.startsWith('/files/')) {
			// textutils.urlEncode writes spaces as '+'.
			const key    = decodeURIComponent(url.pathname.slice('/files/'.length).replace(/\+/g, ' '));
			const source = Object.prototype.hasOwnProperty.call(sources, key) ? sources[key] : undefined;

			if (!source || !fs.existsSync(source)) {
				response.writeHead(404).end();
				return;
			}

			response.writeHead(200, {'Content-Type': 'application/octet-stream', 'Cache-Control': 'no-store'});
			response.end(fs.readFileSync(source));
			return;
		}

		response.writeHead(404).end();
	});

	return {server, refresh, revision: () => revision};
}
