export type ManifestId = string;

export const MANIFEST_VERSION = 1 as const;

export interface BaseManifest {
	id: ManifestId;
	manifestVersion: number;
	name?: string;
	type: "component" | "project";
	version: string;
	dependencies: ManifestId[];
	files: string[];
}

export interface ComponentManifest extends BaseManifest {
	type: "component";
}

export interface ProjectInstallConfig {
	preserve?: string[];
	root?: string;
	startup?: boolean;
}

export interface ProjectManifest extends BaseManifest {
	type: "project";
	entry: string;
	install?: ProjectInstallConfig;
}

export interface IndexManifest {
	repository: string;
	branch: string;
	generatedAt: string;
	manifestVersion: number;
	components: Record<ManifestId, string>;
	projects: Record<ManifestId, string>;
}

export type AnyManifest = ComponentManifest | ProjectManifest;