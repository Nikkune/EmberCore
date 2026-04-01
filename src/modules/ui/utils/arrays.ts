export function createArray<T>(length: number, factory: (index: number) => T): T[] {
	const result: T[] = [];

	for (let index = 0; index < length; index++) {
		result.push(factory(index));
	}

	return result;
}

export function createFilledArray<T>(length: number, value: T): T[] {
	return createArray(length, () => value);
}