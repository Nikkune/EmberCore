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
exports.loadPreviousVersions = loadPreviousVersions;
exports.savePreviousVersions = savePreviousVersions;
exports.bumpMetaVersions = bumpMetaVersions;
exports.collectCurrentVersions = collectCurrentVersions;
const fs = __importStar(require("node:fs"));
const path = __importStar(require("node:path"));
const semver_1 = require("./semver");
function readJsonFile(filePath) {
    const content = fs.readFileSync(filePath, "utf-8");
    return JSON.parse(content);
}
function writeJsonFile(filePath, data) {
    fs.writeFileSync(filePath, `${JSON.stringify(data, null, 2)}\n`, "utf-8");
}
function loadPreviousVersions(filePath) {
    if (!fs.existsSync(filePath)) {
        return {};
    }
    return readJsonFile(filePath);
}
function savePreviousVersions(filePath, versions) {
    const dir = path.dirname(filePath);
    fs.mkdirSync(dir, { recursive: true });
    writeJsonFile(filePath, versions);
}
function bumpMetaVersions(targets, previousVersions) {
    const updated = [];
    const unchanged = [];
    for (const target of targets) {
        const meta = readJsonFile(target.metaPath);
        if (!meta.version) {
            throw new Error(`Missing version in meta file: ${target.metaPath}`);
        }
        const previousVersion = previousVersions[target.id];
        const currentVersion = meta.version;
        const manual = previousVersion !== undefined &&
            (0, semver_1.hasManualVersionChange)(previousVersion, currentVersion);
        let nextVersion = currentVersion;
        let bumped = false;
        if (target.changed && !manual) {
            nextVersion = (0, semver_1.bumpPatch)(currentVersion);
            if (nextVersion !== currentVersion) {
                meta.version = nextVersion;
                writeJsonFile(target.metaPath, meta);
                bumped = true;
            }
        }
        const item = {
            id: target.id,
            metaPath: target.metaPath,
            changed: target.changed,
            previousVersion,
            currentVersion,
            nextVersion,
            bumped,
            manual,
        };
        if (bumped) {
            updated.push(item);
        }
        else {
            unchanged.push(item);
        }
    }
    return {
        updated,
        unchanged,
    };
}
function collectCurrentVersions(targets) {
    const versions = {};
    for (const target of targets) {
        const meta = readJsonFile(target.metaPath);
        versions[target.id] = meta.version;
    }
    return versions;
}
