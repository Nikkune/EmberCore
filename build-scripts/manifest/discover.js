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
exports.discoverManifests = discoverManifests;
const fs = __importStar(require("fs"));
const path = __importStar(require("node:path"));
const builder_1 = require("./builder");
function readJsonIfExists(filePath) {
    if (!fs.existsSync(filePath)) {
        return undefined;
    }
    const content = fs.readFileSync(filePath, "utf-8");
    return JSON.parse(content);
}
function listLuaFilesRecursive(dir) {
    const result = [];
    if (!fs.existsSync(dir)) {
        return result;
    }
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
        const fullPath = path.join(dir, entry.name);
        if (entry.isDirectory()) {
            result.push(...listLuaFilesRecursive(fullPath));
        }
        else if (entry.isFile() && entry.name.endsWith(".lua")) {
            result.push(fullPath);
        }
    }
    return result;
}
function toPosixPath(filePath) {
    return filePath.split(path.sep).join("/");
}
function relativeToDist(distDir, filePath) {
    return toPosixPath(path.relative(distDir, filePath));
}
function capitalize(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
}
function discoverCore(options) {
    const dir = path.join(options.distDir, "core");
    if (!fs.existsSync(dir)) {
        return [];
    }
    const manifests = [];
    for (const file of fs.readdirSync(dir)) {
        if (!file.endsWith(".lua"))
            continue;
        const name = file.replace(".lua", "");
        const id = `core/${name}`;
        const metaPath = path.join(options.srcDir, "core", `${name}.manifest.json`);
        const meta = readJsonIfExists(metaPath);
        const manifest = (0, builder_1.componentManifest)({
            id,
            name: meta?.name ?? capitalize(name),
            version: meta?.version ?? options.version,
            files: [`core/${file}`],
            dependencies: meta?.dependencies ?? [],
        });
        manifests.push(manifest);
    }
    return manifests;
}
function discoverModules(options) {
    const dir = path.join(options.distDir, "modules");
    if (!fs.existsSync(dir)) {
        return [];
    }
    const manifests = [];
    for (const moduleName of fs.readdirSync(dir)) {
        const moduleDistPath = path.join(dir, moduleName);
        if (!fs.statSync(moduleDistPath).isDirectory())
            continue;
        const files = listLuaFilesRecursive(moduleDistPath).map(file => relativeToDist(options.distDir, file));
        const metaPath = path.join(options.srcDir, "modules", moduleName, `${moduleName}.manifest.json`);
        const meta = readJsonIfExists(metaPath);
        const id = `modules/${moduleName}`;
        const manifest = (0, builder_1.componentManifest)({
            id,
            name: meta?.name ?? capitalize(moduleName),
            version: meta?.version ?? options.version,
            files,
            dependencies: meta?.dependencies ?? [],
        });
        manifests.push(manifest);
    }
    return manifests;
}
function discoverProjects(options) {
    const dir = path.join(options.distDir, "projects");
    if (!fs.existsSync(dir)) {
        return [];
    }
    const manifests = [];
    for (const projectName of fs.readdirSync(dir)) {
        const projectDistPath = path.join(dir, projectName);
        if (!fs.statSync(projectDistPath).isDirectory())
            continue;
        const mainPath = path.join(projectDistPath, "main.lua");
        if (!fs.existsSync(mainPath))
            continue;
        const files = listLuaFilesRecursive(projectDistPath).map(file => relativeToDist(options.distDir, file));
        const metaPath = path.join(options.srcDir, "projects", projectName, `${projectName}.manifest.json`);
        const meta = readJsonIfExists(metaPath);
        const id = `projects/${projectName}`;
        const manifest = (0, builder_1.projectManifest)({
            id,
            name: meta?.name ?? capitalize(projectName),
            version: meta?.version ?? options.version,
            entry: relativeToDist(options.distDir, mainPath),
            files,
            dependencies: meta?.dependencies ?? [],
            install: meta?.install,
        });
        manifests.push(manifest);
    }
    return manifests;
}
function discoverManifests(options) {
    const core = discoverCore(options);
    const modules = discoverModules(options);
    const projects = discoverProjects(options);
    return [...core, ...modules, ...projects];
}
