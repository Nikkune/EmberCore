import {Logger} from "./logger";
import {assertNotNil} from "./assert";

const log = new Logger('Peripheral', 'info');

export class PeripheralError extends Error {
	public constructor(message: string) {
		super(message);
		this.name = 'PeripheralError';
	}
}

export class Peripheral {
	public static list(): string[] {
		return peripheral.getNames();
	}

	public static has(side: string): boolean {
		return peripheral.isPresent(side);
	}

	public static getType(side: string): string | undefined {
		const value = peripheral.getType(side);

		if (value === undefined || value === null) {
			return undefined;
		}

		if (type(value) === 'table') {
			return (value as unknown as string[])[0];
		}

		return value as unknown as string;
	}

	public static wrap<T>(side: string): T | undefined {
		const wrapped = peripheral.wrap(side);

		if (wrapped === undefined || wrapped === null) {
			log.debug('Peripheral wrap failed', {
				side,
				action: 'wrap',
				status: 'missing'
			});
			return undefined;
		}

		log.debug('Peripheral wrapped', {
			side,
			action: 'wrap',
			status: 'ok'
		})

		return wrapped as T;
	}

	public static require<T>(side: string): T {
		const wrapped = Peripheral.wrap<T>(side);

		if (wrapped === undefined) {
			const message = `Peripheral not found on side '${side}'`;
			log.error(message, {
				side,
				action: 'require',
				status: 'failed'
			});
			throw new PeripheralError(message);
		}

		return wrapped;
	}

	public static wrapType<T>(side: string, expectedType: string): T | undefined {
		const actualType = this.getType(side);

		if (actualType !== expectedType) {
			log.debug('Peripheral type mismatch', {
				side,
				action: 'wrapType',
				status: 'failed',
				expected: expectedType,
				actual: actualType ?? 'nil'
			});
			return undefined;
		}

		return this.wrap<T>(side);
	}

	public static requireType<T>(side: string, expectedType: string): T {
		const actualType = this.getType(side);

		if (actualType !== expectedType) {
			const message = `Peripheral on side '${side}' has type '${actualType ?? 'nil'}', expected '${expectedType}'`;
			log.error(message, {
				side,
				action: 'require_type',
				status: 'failed',
				expected: expectedType,
				actual: actualType ?? 'nil',
			});
			throw new PeripheralError(message);
		}

		const wrapped = this.wrap<T>(side);
		assertNotNil(wrapped, `Peripheral on side '${side}' could not be wrapped`);

		log.debug('Peripheral type validated', {
			side,
			action: 'require_type',
			status: 'ok',
			expected: expectedType
		})

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
				type: expectedType,
				action: 'require_by_type',
				status: 'failed',
			});
			throw new PeripheralError(message);
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
				type: expectedType,
				action: 'require_name_by_type',
				status: 'failed',
			});
			throw new PeripheralError(message);
		}

		return side;
	}
}