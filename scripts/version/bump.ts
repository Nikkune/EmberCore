import * as fs from "node:fs";
import * as path from "node:path";
import {AnyMeta} from "../manifest/types";
import {bumpPatch, hasManualVersionChange} from "./semver";

export interface BumpTarget {
	id: string;
	metaPath: string;
	changed: boolean;
}

export interface PreviousVersionMap {
	[id: string]: string | undefined;
}

export interface BumpResultItem {
	id: string;
	metaPath: string;
	changed: boolean;
	previousVersion?: string;
	currentVersion: string;
	nextVersion: string;
	bumped: boolean;
	manual: boolean;
}

export interface BumpResult {
	updated: BumpResultItem[];
	unchanged: BumpResultItem[];
}

function readJsonFile<T>(filePath: string): T {
	const content = fs.readFileSync(filePath, "utf-8");
	return JSON.parse(content) as T;
}

function writeJsonFile(filePath: string, data: unknown): void {
	fs.writeFileSync(filePath, `${JSON.stringify(data, null, 2)}\n`, "utf-8");
}

export function loadPreviousVersions(filePath: string): PreviousVersionMap {
	if (!fs.existsSync(filePath)) {
		return {};
	}

	return readJsonFile<PreviousVersionMap>(filePath);
}

export function savePreviousVersions(filePath: string, versions: PreviousVersionMap): void {
	const dir = path.dirname(filePath);
	fs.mkdirSync(dir, { recursive: true });
	writeJsonFile(filePath, versions);
}

export function bumpMetaVersions(
	targets: BumpTarget[],
	previousVersions: PreviousVersionMap,
): BumpResult {
	const updated: BumpResultItem[] = [];
	const unchanged: BumpResultItem[] = [];

	for (const target of targets) {
		const meta = readJsonFile<AnyMeta>(target.metaPath);

		if (!meta.version) {
			throw new Error(`Missing version in meta file: ${target.metaPath}`);
		}

		const previousVersion = previousVersions[target.id];
		const currentVersion = meta.version;

		const manual =
			previousVersion !== undefined &&
			hasManualVersionChange(previousVersion, currentVersion);

		let nextVersion = currentVersion;
		let bumped = false;

		if (target.changed && !manual) {
			nextVersion = bumpPatch(currentVersion);

			if (nextVersion !== currentVersion) {
				meta.version = nextVersion;
				writeJsonFile(target.metaPath, meta);
				bumped = true;
			}
		}

		const item: BumpResultItem = {
			id: target.id,
			metaPath: target.metaPath,
			changed: target.changed,
			previousVersion,
			currentVersion,
			nextVersion,
			bumped,
			manual,
		};

		if (bumped) {
			updated.push(item);
		} else {
			unchanged.push(item);
		}
	}

	return {
		updated,
		unchanged,
	};
}

export function collectCurrentVersions(targets: BumpTarget[]): PreviousVersionMap {
	const versions: PreviousVersionMap = {};

	for (const target of targets) {
		const meta = readJsonFile<AnyMeta>(target.metaPath);
		versions[target.id] = meta.version;
	}

	return versions;
}