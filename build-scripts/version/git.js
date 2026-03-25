"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getChangedFiles = getChangedFiles;
exports.getStagedFiles = getStagedFiles;
exports.getUncommittedFiles = getUncommittedFiles;
exports.getTrackedFiles = getTrackedFiles;
exports.getChangedFilesSafe = getChangedFilesSafe;
const node_child_process_1 = require("node:child_process");
function normalizeLines(output) {
    return output
        .split(/\r?\n/)
        .map((line) => line.trim())
        .filter((line) => line.length > 0);
}
function getChangedFiles(options = {}) {
    const cwd = options.cwd ?? process.cwd();
    const baseRef = options.baseRef;
    const headRef = options.headRef;
    let args;
    if (baseRef && headRef) {
        args = ["diff", "--name-only", `${baseRef}..${headRef}`];
    }
    else if (baseRef) {
        args = ["diff", "--name-only", `${baseRef}..HEAD`];
    }
    else {
        args = ["diff", "--name-only", "HEAD~1..HEAD"];
    }
    const output = (0, node_child_process_1.execFileSync)("git", args, {
        cwd,
        encoding: "utf-8",
    });
    return normalizeLines(output);
}
function getStagedFiles(cwd = process.cwd()) {
    const output = (0, node_child_process_1.execFileSync)("git", ["diff", "--cached", "--name-only"], {
        cwd,
        encoding: "utf-8",
    });
    return normalizeLines(output);
}
function getUncommittedFiles(cwd = process.cwd()) {
    const output = (0, node_child_process_1.execFileSync)("git", ["diff", "--name-only"], {
        cwd,
        encoding: "utf-8",
    });
    return normalizeLines(output);
}
function getTrackedFiles(cwd = process.cwd()) {
    const output = (0, node_child_process_1.execFileSync)("git", ["ls-files"], {
        cwd,
        encoding: "utf-8",
    });
    return normalizeLines(output);
}
function getChangedFilesSafe(options = {}) {
    try {
        return getChangedFiles(options);
    }
    catch {
        return getTrackedFiles(options.cwd);
    }
}
