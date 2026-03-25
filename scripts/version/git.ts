import { execFileSync } from "node:child_process";

function normalizeLines(output: string): string[] {
	return output
		.split(/\r?\n/)
		.map((line) => line.trim())
		.filter((line) => line.length > 0);
}

export interface GitChangedFilesOptions {
	baseRef?: string;
	headRef?: string;
	cwd?: string;
}

export function getChangedFiles(options: GitChangedFilesOptions = {}): string[] {
	const cwd = options.cwd ?? process.cwd();
	const baseRef = options.baseRef;
	const headRef = options.headRef;

	let args: string[];

	if (baseRef && headRef) {
		args = ["diff", "--name-only", `${baseRef}..${headRef}`];
	} else if (baseRef) {
		args = ["diff", "--name-only", `${baseRef}..HEAD`];
	} else {
		args = ["diff", "--name-only", "HEAD~1..HEAD"];
	}

	const output = execFileSync("git", args, {
		cwd,
		encoding: "utf-8",
	});

	return normalizeLines(output);
}

export function getStagedFiles(cwd = process.cwd()): string[] {
	const output = execFileSync("git", ["diff", "--cached", "--name-only"], {
		cwd,
		encoding: "utf-8",
	});

	return normalizeLines(output);
}

export function getUncommittedFiles(cwd = process.cwd()): string[] {
	const output = execFileSync("git", ["diff", "--name-only"], {
		cwd,
		encoding: "utf-8",
	});

	return normalizeLines(output);
}

export function getTrackedFiles(cwd = process.cwd()): string[] {
	const output = execFileSync("git", ["ls-files"], {
		cwd,
		encoding: "utf-8",
	});

	return normalizeLines(output);
}

export function getChangedFilesSafe(options: GitChangedFilesOptions = {}): string[] {
	try {
		return getChangedFiles(options);
	} catch {
		return getTrackedFiles(options.cwd);
	}
}