"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const builder_1 = require("./manifest/builder");
const discover_1 = require("./manifest/discover");
const manifests = (0, discover_1.discoverManifests)({
    srcDir: 'src',
    distDir: 'luas',
    version: '1.0.0',
});
try {
    const result = (0, builder_1.buildManifests)(manifests, {
        repository: 'Nikkune/EmberCore',
        branch: 'lua',
        outputDir: 'manifests',
    });
    console.log("Manifests generated successfully.");
    for (const file of result.writtenFiles) {
        console.log(`+ ${file}`);
    }
}
catch (error) {
    console.error("Manifest generation failed.");
    if (error instanceof Error) {
        console.error(error.message);
    }
    else {
        console.error(String(error));
    }
    process.exit(1);
}
