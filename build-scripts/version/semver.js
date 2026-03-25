"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseSemVer = parseSemVer;
exports.formatSemVer = formatSemVer;
exports.compareSemVer = compareSemVer;
exports.isSameSemVer = isSameSemVer;
exports.isSemVerGreater = isSemVerGreater;
exports.bumpPatch = bumpPatch;
exports.bumpMinor = bumpMinor;
exports.bumpMajor = bumpMajor;
exports.hasManualVersionChange = hasManualVersionChange;
const SEMVER_REGEX = /^(\d+)\.(\d+)\.(\d+)$/;
function parseSemVer(version) {
    const match = version.match(SEMVER_REGEX);
    if (!match) {
        throw new Error(`Invalid semantic version '${version}'. Expected format: 'major.minor.patch'`);
    }
    const [, major, minor, patch] = match;
    return {
        major: parseInt(major, 10),
        minor: parseInt(minor, 10),
        patch: parseInt(patch, 10),
    };
}
function formatSemVer(version) {
    return `${version.major}.${version.minor}.${version.patch}`;
}
function compareSemVer(a, b) {
    const aSemVer = typeof a === 'string' ? parseSemVer(a) : a;
    const bSemVer = typeof b === 'string' ? parseSemVer(b) : b;
    if (aSemVer.major !== bSemVer.major) {
        return aSemVer.major - bSemVer.major;
    }
    if (aSemVer.minor !== bSemVer.minor) {
        return aSemVer.minor - bSemVer.minor;
    }
    return aSemVer.patch - bSemVer.patch;
}
function isSameSemVer(a, b) {
    return compareSemVer(a, b) === 0;
}
function isSemVerGreater(a, b) {
    return compareSemVer(a, b) > 0;
}
function bumpPatch(version) {
    const parsed = typeof version === 'string' ? parseSemVer(version) : version;
    return formatSemVer({
        major: parsed.major,
        minor: parsed.minor,
        patch: parsed.patch + 1,
    });
}
function bumpMinor(version) {
    const parsed = typeof version === 'string' ? parseSemVer(version) : version;
    return formatSemVer({
        major: parsed.major,
        minor: parsed.minor + 1,
        patch: 0,
    });
}
function bumpMajor(version) {
    const parsed = typeof version === 'string' ? parseSemVer(version) : version;
    return formatSemVer({
        major: parsed.major + 1,
        minor: 0,
        patch: 0,
    });
}
function hasManualVersionChange(previousVersion, currentVersion) {
    return !isSameSemVer(previousVersion, currentVersion);
}
