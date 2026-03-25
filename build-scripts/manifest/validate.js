"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.validateManifest = validateManifest;
exports.validateIndexManifest = validateIndexManifest;
exports.validateManifestCollection = validateManifestCollection;
exports.detectDependencyCycles = detectDependencyCycles;
exports.assertValidManifestCollection = assertValidManifestCollection;
exports.assertValidIndexManifest = assertValidIndexManifest;
const types_1 = require("./types");
function issue(message, manifestId, field) {
    return { message, manifestId, field };
}
function isNonEmptyString(value) {
    return typeof value === "string" && value.trim().length > 0;
}
function isStringArray(value) {
    return Array.isArray(value) && value.every((entry) => typeof entry === "string");
}
function validateBaseManifest(manifest) {
    const issues = [];
    if (manifest.manifestVersion !== types_1.MANIFEST_VERSION) {
        issues.push(issue(`Unsupported manifestVersion ${manifest.manifestVersion}, expected '${types_1.MANIFEST_VERSION}'`, manifest.id, "manifestVersion"));
    }
    if (!isNonEmptyString(manifest.id)) {
        issues.push(issue("Manifest id must be a non-empty string", manifest.id, "id"));
    }
    if (!isNonEmptyString(manifest.version)) {
        issues.push(issue("Manifest version must be a non-empty string", manifest.id, "version"));
    }
    if (!Array.isArray(manifest.files) || manifest.files.length === 0) {
        issues.push(issue("Manifest files must be a non-empty array", manifest.id, "files"));
    }
    else {
        for (const file of manifest.files) {
            if (!isNonEmptyString(file)) {
                issues.push(issue("Manifest file must contain only non-empty strings", manifest.id, "files"));
                break;
            }
        }
    }
    if (!Array.isArray(manifest.dependencies)) {
        issues.push(issue("Manifest dependencies must be an array", manifest.id, "dependencies"));
    }
    else {
        for (const dependency of manifest.dependencies) {
            if (!isNonEmptyString(dependency)) {
                issues.push(issue("Manifest dependencies must contain only non-empty strings", manifest.id, "dependencies"));
                break;
            }
        }
    }
    if (manifest.name !== undefined && !isNonEmptyString(manifest.name)) {
        issues.push(issue("Manifest name must be a non-empty string when provided", manifest.id, "name"));
    }
    return issues;
}
function validateComponentManifest(manifest) {
    const issues = validateBaseManifest(manifest);
    if (manifest.type !== "component") {
        issues.push(issue("Component manifests must have type 'component'", manifest.id, "type"));
    }
    return issues;
}
function validateProjectManifest(manifest) {
    const issues = validateBaseManifest(manifest);
    if (manifest.type !== "project") {
        issues.push(issue("Project manifests must have type 'project'", manifest.id, "type"));
    }
    if (!isNonEmptyString(manifest.entry)) {
        issues.push(issue("Project manifests must have an entry file", manifest.id, "entry"));
    }
    if (manifest.install) {
        if (manifest.install.root !== undefined && !isNonEmptyString(manifest.install.root)) {
            issues.push(issue("Project install root must be a non-empty string when provided", manifest.id, "install.root"));
        }
        if (manifest.install.startup !== undefined && typeof manifest.install.startup !== "boolean") {
            issues.push(issue("Project install startup must be a boolean string when provided", manifest.id, "install.startup"));
        }
        if (manifest.install.preserve !== undefined && !isStringArray(manifest.install.preserve)) {
            issues.push(issue("Project install preserve must be a string array when provided", manifest.id, "install.preserve"));
        }
    }
    return issues;
}
function validateManifest(manifest) {
    const issues = manifest.type === "component" ? validateComponentManifest(manifest) : validateProjectManifest(manifest);
    return {
        ok: issues.length === 0,
        issues,
    };
}
function validateIndexManifest(index) {
    const issues = [];
    if (index.manifestVersion !== types_1.MANIFEST_VERSION) {
        issues.push(issue(`Unsupported manifest version ${index.manifestVersion}, expected ${types_1.MANIFEST_VERSION}`, undefined, "manifestVersion"));
    }
    if (!isNonEmptyString(index.repository)) {
        issues.push(issue("Index manifest repository must be a non-empty string", undefined, "repository"));
    }
    if (!isNonEmptyString(index.branch)) {
        issues.push(issue("Index manifest branch must be a non-empty string", undefined, "branch"));
    }
    if (!isNonEmptyString(index.generatedAt)) {
        issues.push(issue("Index manifest generatedAt must be a non-empty string", undefined, "generatedAt"));
    }
    if (typeof index.components !== "object" || index.components === null) {
        issues.push(issue("Index manifest components must be an object", undefined, "components"));
    }
    else {
        for (const id in index.components) {
            const path = index.components[id];
            if (!isNonEmptyString(id) || !isNonEmptyString(path)) {
                issues.push(issue("Index manifest components must map non-empty ids to non-empty paths", undefined, "components"));
            }
        }
    }
    if (typeof index.projects !== "object" || index.components === null) {
        issues.push(issue("Index manifest projects must be an object", undefined, "projects"));
    }
    else {
        for (const id in index.projects) {
            const path = index.projects[id];
            if (!isNonEmptyString(id) || !isNonEmptyString(path)) {
                issues.push(issue("Index manifest projects must map non-empty ids to non-empty paths", undefined, "projects"));
            }
        }
    }
    return {
        ok: issues.length === 0,
        issues,
    };
}
function validateManifestCollection(manifests) {
    const issues = [];
    const ids = new Set();
    for (const manifest of manifests) {
        const result = validateManifest(manifest);
        issues.push(...result.issues);
        if (ids.has(manifest.id)) {
            issues.push(issue(`Duplicate manifest id '${manifest.id}'`, manifest.id, "id"));
        }
        else {
            ids.add(manifest.id);
        }
    }
    const knownIds = new Set(manifests.map((manifest) => manifest.id));
    for (const manifest of manifests) {
        for (const dependency of manifest.dependencies) {
            if (!knownIds.has(dependency)) {
                issues.push(issue(`Unknown dependency '${dependency}'`, manifest.id, "dependencies"));
            }
        }
    }
    issues.push(...detectDependencyCycles(manifests));
    return {
        ok: issues.length === 0,
        issues,
    };
}
function detectDependencyCycles(manifests) {
    const issues = [];
    const manifestMap = new Map();
    for (const manifest of manifests) {
        manifestMap.set(manifest.id, manifest);
    }
    const visiting = new Set();
    const visited = new Set();
    function visit(id, trail) {
        if (visited.has(id)) {
            return;
        }
        if (visiting.has(id)) {
            const cycleStart = trail.indexOf(id);
            const cycle = [...trail.slice(cycleStart), id];
            issues.push(issue(`Dependency cycle detected: ${cycle.join(" -> ")}`, id, "dependencies"));
            return;
        }
        const manifest = manifestMap.get(id);
        if (!manifest) {
            return;
        }
        visiting.add(id);
        for (const dependency of manifest.dependencies) {
            visit(dependency, [...trail, dependency]);
        }
        visiting.delete(id);
        visited.add(id);
    }
    for (const manifest of manifests) {
        visit(manifest.id, [manifest.id]);
    }
    return issues;
}
function assertValidManifestCollection(manifests) {
    const result = validateManifestCollection(manifests);
    if (!result.ok) {
        const lines = result.issues.map((entry) => {
            const prefix = entry.manifestId ? `[${entry.manifestId}] ` : "";
            const field = entry.field ? ` (${entry.field})` : "";
            return `- ${prefix}${entry.message}${field}`;
        });
        throw new Error(`Manifest validation failed:\n${lines.join("\n")}`);
    }
}
function assertValidIndexManifest(index) {
    const result = validateIndexManifest(index);
    if (!result.ok) {
        const lines = result.issues.map((entry) => {
            const prefix = entry.manifestId ? `[${entry.manifestId}] ` : "";
            const field = entry.field ? ` (${entry.field})` : "";
            return `- ${prefix}${entry.message}${field}`;
        });
        throw new Error(`Index manifest validation failed:\n${lines.join("\n")}`);
    }
}
