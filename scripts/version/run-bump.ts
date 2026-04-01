import * as path from 'node:path';

import {bumpMetaVersions, collectCurrentVersions, loadPreviousVersions, savePreviousVersions} from './bump';
import {detectTargetsFromFiles}                                                               from './detect';
import {getChangedFilesSafe}                                                                  from './git';

const SNAPSHOT_PATH = path.join('.cache', 'versions.json');

function main(): void {
	const changedFiles = getChangedFilesSafe();

	console.log('Changed files:');
	for (const file of changedFiles) {
		console.log(`- ${file}`);
	}

	const targets = detectTargetsFromFiles(changedFiles, {
		srcDir: 'src',
	});

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

	const previousVersions = loadPreviousVersions(SNAPSHOT_PATH);
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

	savePreviousVersions(SNAPSHOT_PATH, collectCurrentVersions(targets));

	console.log('');
	console.log(`Snapshot saved to ${SNAPSHOT_PATH}`);
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
