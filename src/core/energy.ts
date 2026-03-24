import { Peripheral } from "./peripheral";

export class Energy {
	public constructor(
		public readonly name: string,
		private readonly peripheralRef: EnergyStorage,
	) {}

	public static fromName(name: string): Energy {
		const peripheral = Peripheral.require<EnergyStorage>(name);
		return new Energy(name, peripheral);
	}

	public getStored(): number {
		return this.peripheralRef.getEnergy();
	}

	public getCapacity(): number {
		return this.peripheralRef.getEnergyCapacity();
	}

	public getFreeSpace(): number {
		return this.getCapacity() - this.getStored();
	}

	public getPercent(): number {
		const capacity = this.getCapacity();

		if (capacity <= 0) {
			return 0;
		}

		return (this.getStored() / capacity) * 100;
	}

	public isEmpty(): boolean {
		return this.getStored() <= 0;
	}

	public isFull(): boolean {
		return this.getStored() >= this.getCapacity();
	}
}