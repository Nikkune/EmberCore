export class TableUtils {
	public static keys<T extends object>(table: T): (keyof T)[] {
		const result: (keyof T)[] = [];

		for (const key in table) {
			result.push(key as keyof T);
		}

		return result;
	}

	public static values<T extends object>(table: T): T[keyof T][] {
		const result: T[keyof T][] = [];

		for (const key in table) {
			result.push(table[key as keyof T]);
		}

		return result;
	}

	public static size<T extends object>(table: T): number {
		let count = 0;

		for (const _key in table) {
			count++;
		}

		return count;
	}

	public static isEmpty<T extends object>(table: T): boolean {
		for (const _key in table) {
			return false;
		}

		return true;
	}

	public static contains<T>(values: T[], value: T): boolean {
		for (const current of values) {
			if (current === value) {
				return true;
			}
		}

		return false;
	}

	public static copyShallow<T extends object>(table: T): T {
		const result: Partial<T> = {};

		for (const key in table) {
			const typedKey   = key as keyof T;
			result[typedKey] = table[typedKey];
		}

		return result as T;
	}

	public static mergeShallow<T extends object>(base: T, override: Partial<T>): T {
		const result = this.copyShallow(base);

		for (const key in override) {
			const typedKey = key as keyof T;
			const value    = override[typedKey];

			if (value !== undefined) {
				result[typedKey] = value;
			}
		}

		return result;
	}

	public static mapValues<T extends object, U>(table: T, mapper: (value: T[keyof T], key: keyof T) => U): Record<string, U> {
		const result: Record<string, U> = {};

		for (const key in table) {
			const typedKey = key as keyof T;
			result[key]    = mapper(table[typedKey], typedKey);
		}

		return result;
	}
}
