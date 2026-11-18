import * as fs   from 'node:fs';
import * as path from 'node:path';

import type {BumpTarget} from './bump';

export interface DetectOptions {
	srcDir: string;
}

function toPosixPath(value: string): string {
	return value.split(path.sep).join('/');
}

function normalizeRelativePath(filePath: string, cwd = process.cwd()): string {
	const absolute = path.isAbsolute(filePath) ? filePath : path.resolve(cwd, filePath);
	return toPosixPath(path.relative(cwd, absolute));
}

function uniqueTargets(targets: BumpTarget[]): BumpTarget[] {
	const map = new Map<string, BumpTarget>();

	for (const target of targets) {
		if (!map.has(target.id)) {
			map.set(target.id, target);
		}
	}

	return [...map.values()].sort((a, b) => a.id.localeCompare(b.id));
}

function fileExists(filePath: string): boolean {
	return fs.existsSync(filePath) && fs.statSync(filePath).isFile();
}

/** One component per file, for src/core/<name>.ts and src/utils/<name>.ts. */
function detectFlatTarget(srcDir: string, relativePath: string, group: 'core' | 'utils'): BumpTarget | undefined {
	const match = new RegExp(`^src/${group}/([^/]+?)(?:\\.manifest\\.json|\\.ts|\\.d\\.ts)$`).exec(relativePath);
	if (!match) {
		return undefined;
	}

	const name     = match[1];
	const metaPath = path.join(srcDir, group, `${name}.manifest.json`);

	if (!fileExists(metaPath)) {
		return undefined;
	}

	return {
		id:      `${group}/${name}`,
		metaPath,
		changed: true,
	};
}

function detectModuleTarget(srcDir: string, relativePath: string): BumpTarget | undefined {
	const match = /^src\/modules\/([^/]+)\/.+$/.exec(relativePath);
	if (!match) {
		return undefined;
	}

	const moduleName = match[1];
	if (!moduleName) return undefined;
	const metaPath = path.join(srcDir, 'modules', moduleName, `${moduleName}.manifest.json`);

	if (!fileExists(metaPath)) {
		return undefined;
	}

	return {
		id:      `modules/${moduleName}`,
		metaPath,
		changed: true,
	};
}

function detectProjectTarget(srcDir: string, relativePath: string): BumpTarget | undefined {
	const match = /^src\/projects\/([^/]+)\/.+$/.exec(relativePath);
	if (!match) {
		return undefined;
	}

	const projectName = match[1];
	if (!projectName) return undefined;
	const metaPath = path.join(srcDir, 'projects', projectName, `${projectName}.manifest.json`);

	if (!fileExists(metaPath)) {
		return undefined;
	}

	return {
		id:      `projects/${projectName}`,
		metaPath,
		changed: true,
	};
}

export function detectTargetFromFile(filePath: string, options: DetectOptions): BumpTarget | undefined {
	const relativePath = normalizeRelativePath(filePath);

	return (
		detectFlatTarget(options.srcDir, relativePath, 'core')
		?? detectFlatTarget(options.srcDir, relativePath, 'utils')
		?? detectModuleTarget(options.srcDir, relativePath)
		?? detectProjectTarget(options.srcDir, relativePath)
	);
}

export function detectTargetsFromFiles(filePaths: string[], options: DetectOptions): BumpTarget[] {
	const targets: BumpTarget[] = [];

	for (const filePath of filePaths) {
		const target = detectTargetFromFile(filePath, options);

		if (target) {
			targets.push(target);
		}
	}

	return uniqueTargets(targets);
}

/** Bump target for a manifest id (core/x, utils/x, modules/x, projects/x), if it has a meta file. */
export function targetForId(id: string, options: DetectOptions): BumpTarget | undefined {
	const [group, name] = id.split('/');

	if (!group || !name) return undefined;

	const metaPath = group === 'core' || group === 'utils'
		? path.join(options.srcDir, group, `${name}.manifest.json`)
		: path.join(options.srcDir, group, name, `${name}.manifest.json`);

	if (!fileExists(metaPath)) return undefined;

	return {
		id,
		metaPath,
		changed: true,
	};
}

/**
 * Adds every component that depends (directly or not) on a changed one: its installed copy
 * must be updated too, so it needs a new version. `dependencies` maps id -> dependency ids.
 */
export function addDependentTargets(
	targets: BumpTarget[],
	dependencies: ReadonlyMap<string, readonly string[]>,
	options: DetectOptions,
): BumpTarget[] {
	const changed = new Set(targets.map((target) => target.id));
	let grew      = true;

	while (grew) {
		grew = false;

		for (const [id, deps] of dependencies) {
			if (!changed.has(id) && deps.some((dep) => changed.has(dep))) {
				changed.add(id);
				grew = true;
			}
		}
	}

	const result = [...targets];

	for (const id of changed) {
		if (targets.some((target) => target.id === id)) continue;

		const target = targetForId(id, options);
		if (target) result.push(target);
	}

	return uniqueTargets(result);
}

/**
 * Files that change the compiled Lua of every component (shared type declarations, compiler
 * options such as luaTarget): a change there must bump everything.
 */
const GLOBAL_INPUTS = [/^src\/types\//, /^tsconfig\.json$/, /^tsconfig\.lua\.json$/];

export function hasGlobalChange(filePaths: string[]): boolean {
	return filePaths.some((filePath) => GLOBAL_INPUTS.some((pattern) => pattern.test(normalizeRelativePath(filePath))));
}

/** Every component and project that has a meta file. */
export function allTargets(options: DetectOptions): BumpTarget[] {
	const ids: string[] = [];

	for (const group of ['core', 'utils'] as const) {
		const dir = path.join(options.srcDir, group);
		if (!fs.existsSync(dir)) continue;

		for (const file of fs.readdirSync(dir)) {
			const match = /^(.+)\.manifest\.json$/.exec(file);
			if (match?.[1]) ids.push(`${group}/${match[1]}`);
		}
	}

	for (const group of ['modules', 'projects'] as const) {
		const dir = path.join(options.srcDir, group);
		if (!fs.existsSync(dir)) continue;

		for (const name of fs.readdirSync(dir)) {
			ids.push(`${group}/${name}`);
		}
	}

	return uniqueTargets(ids.flatMap((id) => targetForId(id, options) ?? []));
}
