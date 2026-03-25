import * as fs from "node:fs";
import * as path from "node:path";

import {type AnyManifest, type ComponentManifest, type IndexManifest, MANIFEST_VERSION, type ManifestId, type ProjectManifest,} from "./types";
import {assertValidIndexManifest, assertValidManifestCollection,} from "./validate";

export interface BuildManifestOptions {
	repository: string;
	branch: string;
	outputDir: string;
	generatedAt?: string;
}

export interface BuildManifestResult {
	index: IndexManifest;
	writtenFiles: string[];
}

function ensureDir(dirPath: string): void {
	fs.mkdirSync(dirPath, {recursive: true});
}

function writeJsonFile(filePath: string, data: unknown): void {
	ensureDir(path.dirname(filePath));
	fs.writeFileSync(filePath, `${JSON.stringify(data, null, 2)}\n`, "utf-8");
}

function getManifestRelativePath(manifest: AnyManifest): string {
	const parts = manifest.id.split("/");

	if (parts.length < 2) {
		throw new Error(`Invalid manifest id '${manifest.id}'`);
	}

	const [group, ...rest] = parts;
	return path.posix.join(group, `${rest.join("__")}.json`);
}

function isProjectManifest(manifest: AnyManifest): manifest is ProjectManifest {
	return manifest.type === "project";
}

function isComponentManifest(manifest: AnyManifest): manifest is ComponentManifest {
	return manifest.type === "component";
}

export function buildIndexManifest(
	manifests: AnyManifest[],
	options: Omit<BuildManifestOptions, "outputDir">,
): IndexManifest {
	const index: IndexManifest = {
		manifestVersion: MANIFEST_VERSION,
		repository: options.repository,
		branch: options.branch,
		generatedAt: options.generatedAt ?? new Date().toISOString(),
		components: {},
		projects: {},
	};

	for (const manifest of manifests) {
		const relativePath = path.posix.join(
			"manifests",
			getManifestRelativePath(manifest),
		);

		if (isComponentManifest(manifest)) {
			index.components[manifest.id] = relativePath;
			continue;
		}

		if (isProjectManifest(manifest)) {
			index.projects[manifest.id] = relativePath;
		}
	}

	assertValidIndexManifest(index);

	return index;
}

export function buildManifests(
	manifests: AnyManifest[],
	options: BuildManifestOptions,
): BuildManifestResult {
	assertValidManifestCollection(manifests);

	const writtenFiles: string[] = [];
	const manifestsRoot = path.resolve(options.outputDir);

	ensureDir(manifestsRoot);

	for (const manifest of manifests) {
		const relativePath = getManifestRelativePath(manifest);
		const absolutePath = path.join(manifestsRoot, relativePath);

		writeJsonFile(absolutePath, manifest);
		writtenFiles.push(absolutePath);
	}

	const index = buildIndexManifest(manifests, {
		repository: options.repository,
		branch: options.branch,
		generatedAt: options.generatedAt,
	});

	const indexPath = path.join(manifestsRoot, "index.json");
	writeJsonFile(indexPath, index);
	writtenFiles.push(indexPath);

	return {
		index,
		writtenFiles,
	};
}

export function componentManifest(
	input: Omit<ComponentManifest, "manifestVersion" | "type">,
): ComponentManifest {
	return {
		manifestVersion: MANIFEST_VERSION,
		type: "component",
		...input,
	};
}

export function projectManifest(
	input: Omit<ProjectManifest, "manifestVersion" | "type">,
): ProjectManifest {
	return {
		manifestVersion: MANIFEST_VERSION,
		type: "project",
		...input,
	};
}

export function sortManifests(manifests: AnyManifest[]): AnyManifest[] {
	return [...manifests].sort((a, b) => a.id.localeCompare(b.id));
}

export function getManifestMap(
	manifests: AnyManifest[],
): Map<ManifestId, AnyManifest> {
	const map = new Map<ManifestId, AnyManifest>();

	for (const manifest of manifests) {
		map.set(manifest.id, manifest);
	}

	return map;
}