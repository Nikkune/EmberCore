import {Peripheral} from "./peripheral";
import {TankError} from "./errors";
import {createOptions} from "@utils/helpers";

export interface FluidStack {
	name: string;
	amount: number;
	displayName?: string;
}

export interface FluidTank {
	name?: string;
	amount?: number;
	capacity?: number;
	displayName?: string;
}

function mapToFluidTank(raw: LuaMap<AnyNotNil, any> | undefined): FluidTank | undefined {
	if (!raw) {
		return undefined;
	}

	return createOptions<FluidTank>({})
		.with('name', raw.get("name"))
		.with('amount', raw.get("amount"))
		.with('capacity', raw.get("capacity"))
		.with('displayName', raw.get("displayName"))
		.done();
}

export class Tank {
	public constructor(
		public readonly name: string,
		private readonly peripheralRef: FluidStorage,
	) {
	}

	public static fromName(name: string): Tank {
		const peripheral = Peripheral.require<FluidStorage>(name);
		return new Tank(name, peripheral);
	}

	public list(): (FluidTank | undefined)[] {
		const rawTanks = this.peripheralRef.tanks();
		const result: (FluidTank | undefined)[] = [];

		for (const raw of rawTanks) {
			result.push(mapToFluidTank(raw));
		}

		return result;
	}

	public getTank(slot: number): FluidTank | undefined {
		const tanks = this.list();

		if (slot < 1 || slot > tanks.length) {
			throw new TankError(`Tank slot ${slot} is out of bounds for '${this.name}'`, {
				tank: this.name,
				slot,
				size: tanks.length,
				action: "get_tank",
			});
		}

		return tanks[slot - 1];
	}

	public isEmpty(): boolean {
		for (const tank of this.list()) {
			if (tank && (tank.amount ?? 0) > 0) {
				return false;
			}
		}
		return true;
	}

	public getTotalAmount(): number {
		let total = 0;

		for (const tank of this.list()) {
			if (tank?.amount) {
				total += tank.amount;
			}
		}

		return total;
	}

	public getAmount(fluidName: string): number {
		let total = 0;

		for (const tank of this.list()) {
			if (tank?.name === fluidName && tank.amount) {
				total += tank.amount;
			}
		}

		return total;
	}

	public hasFluid(fluidName: string): boolean {
		return this.getAmount(fluidName) > 0;
	}

	public getFluids(): FluidStack[] {
		const result: FluidStack[] = [];

		for (const tank of this.list()) {
			if (tank?.name && (tank.amount ?? 0) > 0) {
				result.push({
					name: tank.name,
					amount: tank.amount ?? 0,
				});
			}
		}

		return result;
	}

	public pushTo(target: Tank, limit: number, fluidName: string): number {
		if (limit <= 0) {
			throw new TankError("Fluid push limit must be greater than 0", {
				tank: this.name,
				target: target.name,
				fluidName,
				limit,
				action: "push_to",
			});
		}

		return this.peripheralRef.pushFluid(target.name, limit, fluidName);
	}

	public pullFrom(source: Tank, limit: number, fluidName: string): number {
		if (limit <= 0) {
			throw new TankError("Fluid pull limit must be greater than 0", {
				tank: this.name,
				source: source.name,
				fluidName,
				limit,
				action: "pull_from",
			});
		}

		return this.peripheralRef.pullFluid(source.name, limit, fluidName);
	}
}