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
exports.buildIndexManifest = buildIndexManifest;
exports.buildManifests = buildManifests;
exports.componentManifest = componentManifest;
exports.projectManifest = projectManifest;
exports.sortManifests = sortManifests;
exports.getManifestMap = getManifestMap;
const fs = __importStar(require("node:fs"));
const path = __importStar(require("node:path"));
const types_1 = require("./types");
const validate_1 = require("./validate");
function ensureDir(dirPath) {
    fs.mkdirSync(dirPath, { recursive: true });
}
function writeJsonFile(filePath, data) {
    ensureDir(path.dirname(filePath));
    fs.writeFileSync(filePath, `${JSON.stringify(data, null, 2)}\n`, "utf-8");
}
function getManifestRelativePath(manifest) {
    const parts = manifest.id.split("/");
    if (parts.length < 2) {
        throw new Error(`Invalid manifest id '${manifest.id}'`);
    }
    const [group, ...rest] = parts;
    return path.posix.join(group, `${rest.join("__")}.json`);
}
function isProjectManifest(manifest) {
    return manifest.type === "project";
}
function isComponentManifest(manifest) {
    return manifest.type === "component";
}
function buildIndexManifest(manifests, options) {
    const index = {
        manifestVersion: types_1.MANIFEST_VERSION,
        repository: options.repository,
        branch: options.branch,
        generatedAt: options.generatedAt ?? new Date().toISOString(),
        components: {},
        projects: {},
    };
    for (const manifest of manifests) {
        const relativePath = path.posix.join("manifests", getManifestRelativePath(manifest));
        if (isComponentManifest(manifest)) {
            index.components[manifest.id] = relativePath;
            continue;
        }
        if (isProjectManifest(manifest)) {
            index.projects[manifest.id] = relativePath;
        }
    }
    (0, validate_1.assertValidIndexManifest)(index);
    return index;
}
function buildManifests(manifests, options) {
    (0, validate_1.assertValidManifestCollection)(manifests);
    const writtenFiles = [];
    const manifestsRoot = path.resolve(options.outputDir);
    ensureDir(manifestsRoot);
    for (const manifest of manifests) {
        const relativePath = getManifestRelativePath(manifest);
        const absolutePath = path.join(manifestsRoot, relativePath);
        writeJsonFile(absolutePath, manifest);
        writtenFiles.push(absolutePath);
    }
    const index = buildIndexManifest(manifests, {
        repository: options.repository,
        branch: options.branch,
        generatedAt: options.generatedAt,
    });
    const indexPath = path.join(manifestsRoot, "index.json");
    writeJsonFile(indexPath, index);
    writtenFiles.push(indexPath);
    return {
        index,
        writtenFiles,
    };
}
function componentManifest(input) {
    return {
        manifestVersion: types_1.MANIFEST_VERSION,
        type: "component",
        ...input,
    };
}
function projectManifest(input) {
    return {
        manifestVersion: types_1.MANIFEST_VERSION,
        type: "project",
        ...input,
    };
}
function sortManifests(manifests) {
    return [...manifests].sort((a, b) => a.id.localeCompare(b.id));
}
function getManifestMap(manifests) {
    const map = new Map();
    for (const manifest of manifests) {
        map.set(manifest.id, manifest);
    }
    return map;
}
