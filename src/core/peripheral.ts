import { assertNotNil } from './assert';
import { PeripheralError } from './errors';
import { Logger } from './logger';

const log = new Logger('Peripheral', 'info');

export type Side = 'back' | 'bottom' | 'front' | 'left' | 'right' | 'top';
export type PeripheralName = Side | string;

const SIDES: Side[] = ['back', 'bottom', 'front', 'left', 'right', 'top'];

export function isSide(value: string): value is Side {
	return SIDES.includes(value as Side);
}

export function getSides(): Side[] {
	return [...SIDES];
}

export class Peripheral {
	public static list(): string[] {
		return peripheral.getNames();
	}

	public static listSides(): Side[] {
		return getSides();
	}

	public static has(name: PeripheralName): boolean {
		return peripheral.isPresent(name);
	}

	public static getType(name: PeripheralName): string | undefined {
		const value = peripheral.getType(name);

		if (value === undefined || value === null) {
			return undefined;
		}

		if (type(value) === 'table') {
			return (value as unknown as string[])[0];
		}

		return value as unknown as string;
	}

	public static wrap<T>(name: PeripheralName): T | undefined {
		const wrapped = peripheral.wrap(name);

		if (wrapped === undefined || wrapped === null) {
			log.debug('Peripheral wrap failed', {
				name,
				action: 'wrap',
				status: 'missing',
			});
			return undefined;
		}

		log.debug('Peripheral wrapped', {
			name,
			action: 'wrap',
			status: 'ok',
		});

		return wrapped as T;
	}

	public static require<T>(name: PeripheralName): T {
		const wrapped = Peripheral.wrap<T>(name);

		if (wrapped === undefined) {
			const message = `Peripheral not found on side '${name}'`;
			log.error(message, {
				name,
				action: 'require',
				status: 'failed',
			});
			throw new PeripheralError(message, {
				name,
				action: 'require',
			});
		}

		return wrapped;
	}

	public static wrapType<T>(name: PeripheralName, expectedType: string): T | undefined {
		const actualType = this.getType(name);

		if (actualType !== expectedType) {
			log.debug('Peripheral type mismatch', {
				name,
				action: 'wrapType',
				status: 'failed',
				expected: expectedType,
				actual: actualType ?? 'nil',
			});
			return undefined;
		}

		return this.wrap<T>(name);
	}

	public static requireType<T>(name: PeripheralName, expectedType: string): T {
		const actualType = this.getType(name);

		if (actualType !== expectedType) {
			const message = `Peripheral on side '${name}' has type '${actualType ?? 'nil'}', expected '${expectedType}'`;
			log.error(message, {
				name,
				action: 'require_type',
				status: 'failed',
				expectedType,
				actualType: actualType ?? 'nil',
			});
			throw new PeripheralError(message, {
				name,
				action: 'require_type',
				expectedType,
				actualType: actualType ?? 'nil',
			});
		}

		const wrapped = this.wrap<T>(name);
		assertNotNil(wrapped, `Peripheral on side '${name}' could not be wrapped`);

		log.debug('Peripheral type validated', {
			name,
			action: 'require_type',
			status: 'ok',
			expected: expectedType,
		});

		return wrapped!;
	}

	public static findByType<T>(expectedType: string): T | undefined {
		const wrapped = peripheral.find(expectedType);

		if (wrapped === undefined || wrapped === null) {
			log.debug('No peripheral found by type', {
				type: expectedType,
				action: 'find_by_type',
				status: 'missing',
			});
			return undefined;
		}

		log.debug('Peripheral found by type', {
			type: expectedType,
			action: 'find_by_type',
			status: 'ok',
		});

		return wrapped as T;
	}

	public static requireByType<T>(expectedType: string): T {
		const wrapped = this.findByType<T>(expectedType);

		if (wrapped === undefined) {
			const message = `No peripheral found with type '${expectedType}'`;
			log.error(message, {
				expectedType,
				action: 'require_by_type',
				status: 'failed',
			});
			throw new PeripheralError(message, {
				expectedType,
				action: 'require_by_type',
			});
		}

		return wrapped;
	}

	public static findNameByType(expectedType: string): string | undefined {
		for (const side of peripheral.getNames()) {
			const type = this.getType(side);
			if (type === expectedType) {
				return side;
			}
		}

		return undefined;
	}

	public static requireNameByType(expectedType: string): string {
		const side = this.findNameByType(expectedType);

		if (!side) {
			const message = `No peripheral name found with type '${expectedType}'`;
			log.error(message, {
				expectedType,
				action: 'require_name_by_type',
				status: 'failed',
			});
			throw new PeripheralError(message, {
				expectedType,
				action: 'require_name_by_type',
			});
		}

		return side;
	}
}
