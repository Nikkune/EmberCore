export function assignIfDefined<T extends object, K extends keyof T>(target: T, key: K, value: T[K] | undefined): void {
	if (value !== undefined) {
		target[key] = value;
	}
}

export function withDefined<T extends object, K extends keyof T>(target: T, key: K, value: T[K] | undefined): T {
	assignIfDefined(target, key, value);
	return target;
}

export function createOptions<T extends object>(base: T) {
	return {
		with<K extends keyof T>(key: K, value: T[K] | undefined) {
			withDefined(base, key, value);
			return this;
		},
		done(): T {
			return base;
		},
	};
}
