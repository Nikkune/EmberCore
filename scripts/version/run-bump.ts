import * as fs from 'node:fs';

import {discoverManifests} from '../manifest/discover';
import type {AnyMeta} from '../manifest/manifestTypes';

import {bumpMetaVersions}                                    from './bump';
import type {BumpTarget, PreviousVersionMap}                 from './bump';
import {addDependentTargets, allTargets, detectTargetsFromFiles, hasGlobalChange} from './detect';
import {getChangedFilesSafe, readFileAtRef, resolveBaseRef} from './git';

/**
 * Versions of the targets at the base ref, read from git. A version that differs from the
 * current one was changed by hand in the pushed commits, so it must not be bumped again.
 * (A local snapshot file cannot do this in CI: it never exists on a fresh checkout.)
 */
function readPreviousVersions(targets: BumpTarget[], baseRef: string): PreviousVersionMap {
	const versions: PreviousVersionMap = {};

	for (const target of targets) {
		const content = readFileAtRef(baseRef, target.metaPath);

		if (content === undefined) continue;

		try {
			versions[target.id] = (JSON.parse(content) as AnyMeta).version;
		} catch {
			// unreadable manifest at the base ref: treat as new
		}
	}

	return versions;
}

/**
 * Adds the components that depend on the changed ones, using the dependencies of the compiled
 * Lua (luas/ must be built, as in prepare:release). Without luas/, only direct targets are bumped.
 */
function withDependents(targets: BumpTarget[]): BumpTarget[] {
	if (targets.length === 0) return targets;

	if (!fs.existsSync('luas')) {
		console.warn('luas/ not built: dependents of changed components are not bumped.');
		return targets;
	}

	const dependencies = new Map<string, string[]>();

	for (const manifest of discoverManifests({srcDir: 'src', distDir: 'luas', version: '1.0.0'})) {
		dependencies.set(manifest.id, manifest.dependencies);
	}

	return addDependentTargets(targets, dependencies, {srcDir: 'src'});
}

function main(): void {
	const baseRef      = resolveBaseRef();
	const changedFiles = getChangedFilesSafe({baseRef});

	console.log(`Base ref: ${baseRef}`);
	console.log('Changed files:');
	for (const file of changedFiles) {
		console.log(`- ${file}`);
	}

	// Shared types or compiler options change every component's Lua: bump them all.
	const directTargets = hasGlobalChange(changedFiles)
	                      ? allTargets({srcDir: 'src'})
	                      : detectTargetsFromFiles(changedFiles, {srcDir: 'src'});
	const targets       = withDependents(directTargets);

	if (targets.length === 0) {
		console.log('');
		console.log('No versioned components changed.');
		return;
	}

	console.log('');
	console.log('Detected targets:');
	for (const target of targets) {
		console.log(`- ${target.id} (${target.metaPath})`);
	}

	const previousVersions = readPreviousVersions(targets, baseRef);
	const result           = bumpMetaVersions(targets, previousVersions);

	console.log('');
	console.log('Bump results:');

	for (const item of result.updated) {
		console.log(`- [BUMP] ${item.id}: ${item.currentVersion} -> ${item.nextVersion}`);
	}

	for (const item of result.unchanged) {
		const reason = item.manual ? 'manual version change detected' : item.changed ? 'already up to date' : 'not changed';

		console.log(`- [SKIP] ${item.id}: ${item.currentVersion} (${reason})`);
	}
}

try {
	main();
} catch (error) {
	console.error('run-bump failed');

	if (error instanceof Error) {
		console.error(error.message);
	}
	else {
		console.error(String(error));
	}

	process.exit(1);
}
