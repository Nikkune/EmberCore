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

/**
 * Files of the project a role loads: its module and what it requires inside the project, followed file
 * by file. main.lua is not followed: it requires each role only when it runs it.
 */
function roleFiles(distDir: string, projectName: string, roleModule: string): string[] {
	const prefix  = `projects.${projectName}.`;
	const pattern = /\brequire\(\s*["']([^"']+)["']\s*\)/g;
	const seen    = new Set<string>();
	const pending = [`${prefix}${roleModule.split('/').join('.')}`];

	while (pending.length > 0) {
		const moduleName = pending.pop()!;
		if (seen.has(moduleName)) continue;

		const file = `${moduleName.split('.').join('/')}.lua`;
		if (!fs.existsSync(path.join(distDir, file))) {
			throw new Error(`Role module '${moduleName}' of project '${projectName}' not found (${file})`);
		}
		seen.add(moduleName);

		for (const match of fs.readFileSync(path.join(distDir, file), 'utf-8').matchAll(pattern)) {
			if (match[1]?.startsWith(prefix)) pending.push(match[1]);
		}
	}

	return [...seen].map((moduleName) => `${moduleName.split('.').join('/')}.lua`).sort();
}

function roleManifests(options: DiscoverOptions, projectName: string, meta: ProjectMeta, roles: Record<string, string>): ProjectManifest[] {
	const entry = `projects/${projectName}/main.lua`;

	return Object.keys(roles).sort().map((role) => {
		const files = [entry, ...roleFiles(options.distDir, projectName, roles[role]!)];
		const input: Omit<ProjectManifest, 'manifestVersion' | 'type'> = {
			id:           `projects/${projectName}-${role}`,
			name:         `${meta.name ?? capitalize(projectName)} (${role})`,
			version:      meta.version ?? options.version,
			entry,
			files,
			// Requires inside the project are files of this role, not a dependency on the whole project.
			dependencies: mergeDependencies(meta.dependencies, collectLuaDependencies(options.distDir, files, `projects/${projectName}`)),
		};

		if (meta.install) input.install = meta.install;

		return projectManifest(input);
	});
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

		if (meta?.roles) {
			manifests.push(...roleManifests(options, projectName, meta, meta.roles));
			continue;
		}

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
