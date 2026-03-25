import * as fs from "node:fs";
import * as path from "node:path";

import type { BumpTarget } from "./bump";

export interface DetectOptions {
	srcDir: string;
}

function toPosixPath(value: string): string {
	return value.split(path.sep).join("/");
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

function detectCoreTarget(srcDir: string, relativePath: string): BumpTarget | undefined {
	const match = /^src\/core\/([^/]+?)(?:\.manifest\.json|\.ts|\.d\.ts)$/.exec(relativePath);
	if (!match) {
		return undefined;
	}

	const name = match[1];
	const metaPath = path.join(srcDir, "core", `${name}.manifest.json`);

	if (!fileExists(metaPath)) {
		return undefined;
	}

	return {
		id: `core/${name}`,
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
	const metaPath = path.join(srcDir, "modules", moduleName, `${moduleName}.manifest.json`);

	if (!fileExists(metaPath)) {
		return undefined;
	}

	return {
		id: `modules/${moduleName}`,
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
	const metaPath = path.join(srcDir, "projects", projectName, "project.manifest.json");

	if (!fileExists(metaPath)) {
		return undefined;
	}

	return {
		id: `projects/${projectName}`,
		metaPath,
		changed: true,
	};
}

export function detectTargetFromFile(
	filePath: string,
	options: DetectOptions,
): BumpTarget | undefined {
	const relativePath = normalizeRelativePath(filePath);

	return (
		detectCoreTarget(options.srcDir, relativePath) ??
		detectModuleTarget(options.srcDir, relativePath) ??
		detectProjectTarget(options.srcDir, relativePath)
	);
}

export function detectTargetsFromFiles(
	filePaths: string[],
	options: DetectOptions,
): BumpTarget[] {
	const targets: BumpTarget[] = [];

	for (const filePath of filePaths) {
		const target = detectTargetFromFile(filePath, options);

		if (target) {
			targets.push(target);
		}
	}

	return uniqueTargets(targets);
}