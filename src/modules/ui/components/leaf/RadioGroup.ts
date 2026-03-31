export class RadioGroup<T = string> {
	private selectedValue?: T | undefined;
	private readonly listeners = new Set<(value: T | undefined) => void>();

	public constructor(initialValue?: T) {
		this.selectedValue = initialValue;
	}

	public get value(): T | undefined {
		return this.selectedValue;
	}

	public isSelected(value: T): boolean {
		return this.selectedValue === value;
	}

	public select(value: T): boolean {
		if (this.selectedValue === value) {
			return false;
		}

		this.selectedValue = value;
		this.emit();
		return true;
	}

	public clear(): boolean {
		if (this.selectedValue === undefined) {
			return false;
		}

		this.selectedValue = undefined;
		this.emit();
		return true;
	}

	public subscribe(listener: (value: T | undefined) => void): () => void {
		this.listeners.add(listener);

		return () => {
			this.listeners.delete(listener);
		};
	}

	private emit(): void {
		for (const listener of this.listeners) {
			listener(this.selectedValue);
		}
	}
}