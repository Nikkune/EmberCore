import {execFileSync} from 'node:child_process';

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
	const cwd     = options.cwd ?? process.cwd();
	const baseRef = options.baseRef;
	const headRef = options.headRef;

	let args: string[];

	if (baseRef && headRef) {
		args = ['diff', '--name-only', `${baseRef}..${headRef}`];
	}
	else if (baseRef) {
		args = ['diff', '--name-only', `${baseRef}..HEAD`];
	}
	else {
		args = ['diff', '--name-only', 'HEAD~1..HEAD'];
	}

	const output = execFileSync('git', args, {
		cwd,
		encoding: 'utf-8',
	});

	return normalizeLines(output);
}

export function getStagedFiles(cwd = process.cwd()): string[] {
	const output = execFileSync('git', ['diff', '--cached', '--name-only'], {
		cwd,
		encoding: 'utf-8',
	});

	return normalizeLines(output);
}

export function getUncommittedFiles(cwd = process.cwd()): string[] {
	const output = execFileSync('git', ['diff', '--name-only'], {
		cwd,
		encoding: 'utf-8',
	});

	return normalizeLines(output);
}

export function getTrackedFiles(cwd = process.cwd()): string[] {
	const output = execFileSync('git', ['ls-files'], {
		cwd,
		encoding: 'utf-8',
	});

	return normalizeLines(output);
}

/**
 * Commit the bump compares against: $BUMP_BASE_REF (in CI, the commit before the push, so every
 * pushed commit is covered), or HEAD~1. An all-zero SHA (new branch) or unknown ref falls back to HEAD~1.
 */
export function resolveBaseRef(cwd = process.cwd()): string {
	const candidate = process.env['BUMP_BASE_REF'];

	if (candidate && !/^0+$/.test(candidate)) {
		try {
			execFileSync('git', ['rev-parse', '--verify', '--quiet', `${candidate}^{commit}`], {
				cwd,
				stdio: 'ignore',
			});
			return candidate;
		} catch {
			// unknown ref (e.g. force push): fall back below
		}
	}

	return 'HEAD~1';
}

/** Content of a file at a given ref, or undefined if it did not exist there. */
export function readFileAtRef(ref: string, filePath: string, cwd = process.cwd()): string | undefined {
	try {
		return execFileSync('git', ['show', `${ref}:${filePath.split('\\').join('/')}`], {
			cwd,
			encoding: 'utf-8',
			stdio:    ['ignore', 'pipe', 'ignore'],
		});
	} catch {
		return undefined;
	}
}

export function getChangedFilesSafe(options: GitChangedFilesOptions = {}): string[] {
	try {
		return getChangedFiles(options);
	} catch {
		return getTrackedFiles(options.cwd);
	}
}
