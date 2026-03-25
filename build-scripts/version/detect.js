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
exports.detectTargetFromFile = detectTargetFromFile;
exports.detectTargetsFromFiles = detectTargetsFromFiles;
const fs = __importStar(require("node:fs"));
const path = __importStar(require("node:path"));
function toPosixPath(value) {
    return value.split(path.sep).join("/");
}
function normalizeRelativePath(filePath, cwd = process.cwd()) {
    const absolute = path.isAbsolute(filePath) ? filePath : path.resolve(cwd, filePath);
    return toPosixPath(path.relative(cwd, absolute));
}
function uniqueTargets(targets) {
    const map = new Map();
    for (const target of targets) {
        if (!map.has(target.id)) {
            map.set(target.id, target);
        }
    }
    return [...map.values()].sort((a, b) => a.id.localeCompare(b.id));
}
function fileExists(filePath) {
    return fs.existsSync(filePath) && fs.statSync(filePath).isFile();
}
function detectCoreTarget(srcDir, relativePath) {
    const match = /^src\/core\/([^/]+?)(?:\.manifest\.json|\.ts|\.d\.ts)$/.exec(relativePath);
    if (!match) {
        return undefined;
    }
    const name = match[1];
    const metaPath = path.join(srcDir, "core", `${name}.manifest.json`);
    if (!fileExists(metaPath)) {
        return undefined;
    }
    return {
        id: `core/${name}`,
        metaPath,
        changed: true,
    };
}
function detectModuleTarget(srcDir, relativePath) {
    const match = /^src\/modules\/([^/]+)\/.+$/.exec(relativePath);
    if (!match) {
        return undefined;
    }
    const moduleName = match[1];
    const metaPath = path.join(srcDir, "modules", moduleName, `${moduleName}.manifest.json`);
    if (!fileExists(metaPath)) {
        return undefined;
    }
    return {
        id: `modules/${moduleName}`,
        metaPath,
        changed: true,
    };
}
function detectProjectTarget(srcDir, relativePath) {
    const match = /^src\/projects\/([^/]+)\/.+$/.exec(relativePath);
    if (!match) {
        return undefined;
    }
    const projectName = match[1];
    const metaPath = path.join(srcDir, "projects", projectName, "project.manifest.json");
    if (!fileExists(metaPath)) {
        return undefined;
    }
    return {
        id: `projects/${projectName}`,
        metaPath,
        changed: true,
    };
}
function detectTargetFromFile(filePath, options) {
    const relativePath = normalizeRelativePath(filePath);
    return (detectCoreTarget(options.srcDir, relativePath) ??
        detectModuleTarget(options.srcDir, relativePath) ??
        detectProjectTarget(options.srcDir, relativePath));
}
function detectTargetsFromFiles(filePaths, options) {
    const targets = [];
    for (const filePath of filePaths) {
        const target = detectTargetFromFile(filePath, options);
        if (target) {
            targets.push(target);
        }
    }
    return uniqueTargets(targets);
}
