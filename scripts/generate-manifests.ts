import {buildManifests,} from "./manifest/builder";
import type {AnyManifest} from "./manifest/types";
import {discoverManifests} from "./manifest/discover";

const manifests: AnyManifest[] = discoverManifests({
	srcDir: 'src',
	distDir: 'luas',
	version: '1.0.0',
});

try {
	const result = buildManifests(manifests, {
		repository: 'Nikkune/EmberCore',
		branch: 'lua',
		outputDir: 'manifests',
	})

	console.log("Manifests generated successfully.")
	for (const file of result.writtenFiles) {
		console.log(`+ ${file}`)
	}
} catch (error) {
	console.error("Manifest generation failed.");

	if (error instanceof Error) {
		console.error(error.message);
	} else {
		console.error(String(error));
	}

	process.exit(1);
}