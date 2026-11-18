import * as fs                                                                            from 'node:fs';
import * as path                                                                          from 'node:path';

import {componentManifest, projectManifest}                                               from './builder';
import type {AnyManifest, ComponentManifest, ComponentMeta, ProjectManifest, ProjectMeta} from './manifestTypes';

export interface DiscoverOptions {
	srcDir: string;
	distDir: string;
	version: string;
}

function readJsonIfExists<T>(filePath: string): T | undefined {
	if (!fs.existsSync(filePath)) {
		return undefined;
	}

	const content = fs.readFileSync(filePath, 'utf-8');
	return JSON.parse(content) as T;
}

function listLuaFilesRecursive(dir: string): string[] {
	const result: string[] = [];

	if (!fs.existsSync(dir)) {
		return result;
	}

	for (const entry of fs.readdirSync(dir, {withFileTypes: true})) {
		const fullPath = path.join(dir, entry.name);

		if (entry.isDirectory()) {
			result.push(...listLuaFilesRecursive(fullPath));
		}
		else if (entry.isFile() && entry.name.endsWith('.lua')) {
			result.push(fullPath);
		}
	}

	return result;
}

function toPosixPath(filePath: string): string {
	return filePath.split(path.sep).join('/');
}

function relativeToDist(distDir: string, filePath: string): string {
	return toPosixPath(path.relative(distDir, filePath));
}

function capitalize(str: string): string {
	return str.charAt(0).toUpperCase() + str.slice(1);
}

/**
 * Maps a Lua module name produced by TSTL (e.g. `core.errors`, `modules.ui.theme.tone`)
 * to the manifest id that ships it. Returns undefined for modules outside EmberCore.
 */
function requireToManifestId(moduleName: string): string | undefined {
	const parts = moduleName.split('.');
	const [group, name] = parts;

	if (!group || !name) return undefined;

	if (group === 'core' || group === 'utils') {
		return parts.length === 2 ? `${group}/${name}` : undefined;
	}

	if (group === 'modules' || group === 'projects') {
		return `${group}/${name}`;
	}

	return undefined;
}

/**
 * Collects the manifest ids required by the given Lua files (paths relative to distDir),
 * so manifests can never miss a dependency the compiled code actually loads.
 */
function collectLuaDependencies(distDir: string, files: string[], selfId: string): string[] {
	const dependencies = new Set<string>();
	const requirePattern = /\brequire\(\s*["']([^"']+)["']\s*\)/g;

	for (const file of files) {
		const content = fs.readFileSync(path.join(distDir, file), 'utf-8');

		for (const match of content.matchAll(requirePattern)) {
			const id = match[1] ? requireToManifestId(match[1]) : undefined;

			if (id && id !== selfId) {
				dependencies.add(id);
			}
		}
	}

	return [...dependencies];
}

function mergeDependencies(declared: string[] | undefined, detected: string[]): string[] {
	return [...new Set([...(declared ?? []), ...detected])].sort();
}

function discoverFlatGroup(options: DiscoverOptions, group: 'core' | 'utils'): ComponentManifest[] {
	const dir = path.join(options.distDir, group);

	if (!fs.existsSync(dir)) {
		return [];
	}

	const manifests: ComponentManifest[] = [];

	for (const file of fs.readdirSync(dir)) {
		if (!file.endsWith('.lua')) continue;

		const name  = file.replace('.lua', '');
		const id    = `${group}/${name}`;
		const files = [`${group}/${file}`];

		const metaPath = path.join(options.srcDir, group, `${name}.manifest.json`);
		const meta     = readJsonIfExists<ComponentMeta>(metaPath);

		const manifest = componentManifest({
			id,
			name:         meta?.name ?? capitalize(name),
			version:      meta?.version ?? options.version,
			files,
			dependencies: mergeDependencies(meta?.dependencies, collectLuaDependencies(options.distDir, files, id)),
		});

		manifests.push(manifest);
	}

	return manifests;
}

function discoverModules(options: DiscoverOptions): ComponentManifest[] {
	const dir = path.join(options.distDir, 'modules');

	if (!fs.existsSync(dir)) {
		return [];
	}

	const manifests: ComponentManifest[] = [];

	for (const moduleName of fs.readdirSync(dir)) {
		const moduleDistPath = path.join(dir, moduleName);
		if (!fs.statSync(moduleDistPath).isDirectory()) continue;

		const files = listLuaFilesRecursive(moduleDistPath).map((file) => relativeToDist(options.distDir, file));

		const metaPath = path.join(options.srcDir, 'modules', moduleName, `${moduleName}.manifest.json`);
		const meta     = readJsonIfExists<ComponentMeta>(metaPath);

		const id = `modules/${moduleName}`;

		const manifest = componentManifest({
			id,
			name:         meta?.name ?? capitalize(moduleName),
			version:      meta?.version ?? options.version,
			files,
			dependencies: mergeDependencies(meta?.dependencies, collectLuaDependencies(options.distDir, files, id)),
		});

		manifests.push(manifest);
	}

	return manifests;
}

function discoverProjects(options: DiscoverOptions): ProjectManifest[] {
	const dir = path.join(options.distDir, 'projects');

	if (!fs.existsSync(dir)) {
		return [];
	}

	const manifests: ProjectManifest[] = [];

	for (const projectName of fs.readdirSync(dir)) {
		const projectDistPath = path.join(dir, projectName);
		if (!fs.statSync(projectDistPath).isDirectory()) continue;

		const mainPath = path.join(projectDistPath, 'main.lua');

		if (!fs.existsSync(mainPath)) continue;

		const files = listLuaFilesRecursive(projectDistPath).map((file) => relativeToDist(options.distDir, file));

		const metaPath = path.join(options.srcDir, 'projects', projectName, `${projectName}.manifest.json`);
		const meta     = readJsonIfExists<ProjectMeta>(metaPath);

		const id = `projects/${projectName}`;

		const input: Omit<ProjectManifest, 'manifestVersion' | 'type'> = {
			id,
			name:         meta?.name ?? capitalize(projectName),
			version:      meta?.version ?? options.version,
			entry:        relativeToDist(options.distDir, mainPath),
			files,
			dependencies: mergeDependencies(meta?.dependencies, collectLuaDependencies(options.distDir, files, id)),
		};

		if (meta?.install) input.install = meta.install;

		const manifest = projectManifest(input);

		manifests.push(manifest);
	}

	return manifests;
}

export function discoverManifests(options: DiscoverOptions): AnyManifest[] {
	const core     = discoverFlatGroup(options, 'core');
	const utils    = discoverFlatGroup(options, 'utils');
	const modules  = discoverModules(options);
	const projects = discoverProjects(options);

	return [...core, ...utils, ...modules, ...projects];
}
