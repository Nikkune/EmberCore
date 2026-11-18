import {execFileSync} from 'node:child_process';

import {buildManifests}    from './manifest/builder';
import {discoverManifests} from './manifest/discover';
import type {AnyManifest}  from './manifest/manifestTypes';

const manifests: AnyManifest[] = discoverManifests({
	srcDir:  'src',
	distDir: 'luas',
	version: '1.0.0',
});

/**
 * Date of the last commit that changed src/: stable across runs, so publishing the same sources
 * again produces identical manifests (and no new commit on the lua branch).
 */
function sourcesCommitDate(): string | undefined {
	try {
		const date = execFileSync('git', ['log', '-1', '--format=%cI', '--', 'src'], {encoding: 'utf-8'}).trim();
		return date.length > 0 ? new Date(date).toISOString() : undefined;
	} catch {
		return undefined;
	}
}

try {
	const generatedAt = sourcesCommitDate();
	const result      = buildManifests(manifests, {
		repository: 'Nikkune/EmberCore',
		branch:     'lua',
		outputDir:  'manifests',
		...(generatedAt ? {generatedAt} : {}),
	});

	console.log('Manifests generated successfully.');
	for (const file of result.writtenFiles) {
		console.log(`+ ${file}`);
	}
} catch (error) {
	console.error('Manifest generation failed.');

	if (error instanceof Error) {
		console.error(error.message);
	}
	else {
		console.error(String(error));
	}

	process.exit(1);
}
