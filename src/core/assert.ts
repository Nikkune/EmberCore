export function assert(condition: unknown, message = 'Assertion failed'): asserts condition {
	if (!condition) {
		error(message, 2);
	}
}

export function assertNotNil<T>(value: T | undefined | null, message: string): T {
	if (value === undefined || value === null) {
		error(message, 2);
	}
	return value;
}

export function assertString(value: unknown, name: string): asserts value is string {
	if (type(value) !== 'string') {
		error(`${name} must be a string`, 2);
	}
}

export function assertNumber(value: unknown, name: string): asserts value is number {
	if (type(value) !== 'number') {
		error(`${name} must be a number`, 2);
	}
}

export function assertBoolean(value: unknown, name: string): asserts value is boolean {
	if (type(value) !== 'boolean') {
		error(`${name} must be a boolean`, 2);
	}
}

export function assertTable(value: unknown, name: string): asserts value is Record<string, unknown> {
	if (type(value) !== 'table') {
		error(`${name} must be a table`, 2);
	}
}

export function assertPeripheral(value: unknown, side: string): asserts value {
	if (value === undefined || value === null) {
		error(`No peripheral found on side '${side}'`, 2);
	}
}
