"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const path = __importStar(require("node:path"));
const bump_1 = require("./bump");
const detect_1 = require("./detect");
const git_1 = require("./git");
const SNAPSHOT_PATH = path.join(".cache", "versions.json");
function main() {
    const changedFiles = (0, git_1.getChangedFilesSafe)();
    console.log("Changed files:");
    for (const file of changedFiles) {
        console.log(`- ${file}`);
    }
    const targets = (0, detect_1.detectTargetsFromFiles)(changedFiles, {
        srcDir: "src",
    });
    if (targets.length === 0) {
        console.log("");
        console.log("No versioned components changed.");
        return;
    }
    console.log("");
    console.log("Detected targets:");
    for (const target of targets) {
        console.log(`- ${target.id} (${target.metaPath})`);
    }
    const previousVersions = (0, bump_1.loadPreviousVersions)(SNAPSHOT_PATH);
    const result = (0, bump_1.bumpMetaVersions)(targets, previousVersions);
    console.log("");
    console.log("Bump results:");
    for (const item of result.updated) {
        console.log(`- [BUMP] ${item.id}: ${item.currentVersion} -> ${item.nextVersion}`);
    }
    for (const item of result.unchanged) {
        const reason = item.manual
            ? "manual version change detected"
            : item.changed
                ? "already up to date"
                : "not changed";
        console.log(`- [SKIP] ${item.id}: ${item.currentVersion} (${reason})`);
    }
    (0, bump_1.savePreviousVersions)(SNAPSHOT_PATH, (0, bump_1.collectCurrentVersions)(targets));
    console.log("");
    console.log(`Snapshot saved to ${SNAPSHOT_PATH}`);
}
try {
    main();
}
catch (error) {
    console.error("run-bump failed");
    if (error instanceof Error) {
        console.error(error.message);
    }
    else {
        console.error(String(error));
    }
    process.exit(1);
}
