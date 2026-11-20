export type ManifestId = string;

export const MANIFEST_VERSION = 1 as const;

export interface BaseManifest {
	id: ManifestId;
	manifestVersion: number;
	name?: string;
	type: 'component' | 'project';
	version: string;
	dependencies: ManifestId[];
	files: string[];
}

export interface ComponentManifest extends BaseManifest {
	type: 'component';
}

export interface ProjectInstallConfig {
	preserve?: string[];
	root?: string;
	startup?: boolean;
}

export interface ProjectManifest extends BaseManifest {
	type: 'project';
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

export type ComponentMeta = Pick<ComponentManifest, 'name' | 'version' | 'dependencies'>;

export type ProjectMeta = Pick<ProjectManifest, 'name' | 'version' | 'dependencies' | 'install'> & {
	/**
	 * A project whose computers each run one role (e.g. {"controller": "controller/controller"}): one
	 * project `projects/<name>-<role>` per role, with main.lua and only what the role module loads, instead
	 * of the whole project. The role module path is relative to the project, without .lua.
	 */
	roles?: Record<string, string>;
};

export type AnyMeta = ComponentMeta | ProjectMeta;
