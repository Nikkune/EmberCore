import {AnyManifest, ComponentManifest, ComponentMeta, ProjectManifest, ProjectMeta} from "./manifestTypes";
import * as fs from "fs";
import * as path from "node:path";
import {componentManifest, projectManifest} from "./builder";

export interface DiscoverOptions {
	srcDir: string;
	distDir: string;
	version: string;
}

function readJsonIfExists<T>(filePath: string): T | undefined {
	if (!fs.existsSync(filePath)) {
		return undefined;
	}

	const content = fs.readFileSync(filePath, "utf-8");
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
		} else if (entry.isFile() && entry.name.endsWith(".lua")) {
			result.push(fullPath);
		}
	}

	return result;
}

function toPosixPath(filePath: string): string {
	return filePath.split(path.sep).join("/");
}

function relativeToDist(distDir: string, filePath: string): string {
	return toPosixPath(path.relative(distDir, filePath));
}

function capitalize(str: string): string {
	return str.charAt(0).toUpperCase() + str.slice(1);
}

function discoverCore(options: DiscoverOptions): ComponentManifest[] {
	const dir = path.join(options.distDir, "core");

	if (!fs.existsSync(dir)) {
		return [];
	}

	const manifests: ComponentManifest[] = [];

	for (const file of fs.readdirSync(dir)) {
		if (!file.endsWith(".lua")) continue;

		const name = file.replace(".lua", "");
		const id = `core/${name}`;

		const metaPath = path.join(options.srcDir, "core", `${name}.manifest.json`);
		const meta = readJsonIfExists<ComponentMeta>(metaPath);

		const manifest = componentManifest({
			id,
			name: meta?.name ?? capitalize(name),
			version: meta?.version ?? options.version,
			files: [`core/${file}`],
			dependencies: meta?.dependencies ?? [],
		});

		manifests.push(manifest);
	}

	return manifests;
}

function discoverModules(options: DiscoverOptions): ComponentManifest[] {
	const dir = path.join(options.distDir, "modules");

	if (!fs.existsSync(dir)) {
		return [];
	}

	const manifests: ComponentManifest[] = [];

	for (const moduleName of fs.readdirSync(dir)) {
		const moduleDistPath = path.join(dir, moduleName);
		if (!fs.statSync(moduleDistPath).isDirectory()) continue;

		const files = listLuaFilesRecursive(moduleDistPath).map(file => relativeToDist(options.distDir, file));

		const metaPath = path.join(options.srcDir, "modules", moduleName, `${moduleName}.manifest.json`);
		const meta = readJsonIfExists<ComponentMeta>(metaPath);

		const id = `modules/${moduleName}`;

		const manifest = componentManifest({
			id,
			name: meta?.name ?? capitalize(moduleName),
			version: meta?.version ?? options.version,
			files,
			dependencies: meta?.dependencies ?? [],
		});

		manifests.push(manifest);
	}

	return manifests;
}

function discoverProjects(options: DiscoverOptions): ProjectManifest[] {
	const dir = path.join(options.distDir, "projects");

	if (!fs.existsSync(dir)) {
		return [];
	}

	const manifests: ProjectManifest[] = [];

	for (const projectName of fs.readdirSync(dir)) {
		const projectDistPath = path.join(dir, projectName);
		if (!fs.statSync(projectDistPath).isDirectory()) continue;

		const mainPath = path.join(projectDistPath, "main.lua");

		if (!fs.existsSync(mainPath)) continue;

		const files = listLuaFilesRecursive(projectDistPath).map(file => relativeToDist(options.distDir, file));

		const metaPath = path.join(options.srcDir, "projects", projectName, `${projectName}.manifest.json`);
		const meta = readJsonIfExists<ProjectMeta>(metaPath);

		const id = `projects/${projectName}`;

		const manifest = projectManifest({
			id,
			name: meta?.name ?? capitalize(projectName),
			version: meta?.version ?? options.version,
			entry: relativeToDist(options.distDir, mainPath),
			files,
			dependencies: meta?.dependencies ?? [],
			install: meta?.install,
		})

		manifests.push(manifest);
	}

	return manifests;
}

export function discoverManifests(options: DiscoverOptions): AnyManifest[] {
	const core = discoverCore(options);
	const modules = discoverModules(options);
	const projects = discoverProjects(options);

	return [...core, ...modules, ...projects];
}