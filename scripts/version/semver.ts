export interface SemVer {
	major: number;
	minor: number;
	patch: number;
}

const SEMVER_REGEX = /^(\d+)\.(\d+)\.(\d+)$/

export function parseSemVer(version: string): SemVer {
	const match = version.match(SEMVER_REGEX);
	if (!match) {
		throw new Error(`Invalid semantic version '${version}'. Expected format: 'major.minor.patch'`);
	}

	const [, major, minor, patch] = match;

	return {
		major: parseInt(major, 10),
		minor: parseInt(minor, 10),
		patch: parseInt(patch, 10),
	};
}

export function formatSemVer(version: SemVer): string {
	return `${version.major}.${version.minor}.${version.patch}`;
}

export function compareSemVer(a: string | SemVer, b: string | SemVer): number {
	const aSemVer = typeof a === 'string' ? parseSemVer(a) : a;
	const bSemVer = typeof b === 'string' ? parseSemVer(b) : b;

	if (aSemVer.major !== bSemVer.major) {
		return aSemVer.major - bSemVer.major;
	}

	if (aSemVer.minor !== bSemVer.minor) {
		return aSemVer.minor - bSemVer.minor;
	}

	return aSemVer.patch - bSemVer.patch;
}

export function isSameSemVer(a: string | SemVer, b: string | SemVer): boolean {
	return compareSemVer(a, b) === 0;
}

export function isSemVerGreater(a: string | SemVer, b: string | SemVer): boolean {
	return compareSemVer(a, b) > 0;
}

export function bumpPatch(version: string | SemVer): string {
	const parsed = typeof version === 'string' ? parseSemVer(version) : version;

	return formatSemVer({
		major: parsed.major,
		minor: parsed.minor,
		patch: parsed.patch + 1,
	});
}

export function bumpMinor(version: string | SemVer): string {
	const parsed = typeof version === 'string' ? parseSemVer(version) : version;
	return formatSemVer({
		major: parsed.major,
		minor: parsed.minor + 1,
		patch: 0,
	});
}

export function bumpMajor(version: string | SemVer): string {
	const parsed = typeof version === 'string' ? parseSemVer(version) : version;
	return formatSemVer({
		major: parsed.major + 1,
		minor: 0,
		patch: 0,
	});
}

export function hasManualVersionChange(previousVersion: string, currentVersion: string): boolean {
	return !isSameSemVer(previousVersion, currentVersion);
}