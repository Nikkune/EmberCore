import { Peripheral } from "./peripheral";

export interface ItemSummary {
	name: string;
	count: number;
}

export interface ItemDetail extends ItemSummary {
	displayName?: string;
	maxCount?: number;
	damage?: number;
	nbt?: string;
}

export interface InventoryPeripheral {
	size(): number;
	list(): LuaTable<number, ItemSummary>;
	getItemDetail(slot: number): ItemDetail | undefined;

	pushItems(toName: string, fromSlot: number, limit?: number, toSlot?: number): number;
	pullItems(fromName: string, fromSlot: number, limit?: number, toSlot?: number): number;
}

export class Inventory {
	public constructor(
		public readonly name: string,
		private readonly peripheralRef: InventoryPeripheral,
	) {}

	public static fromName(name: string): Inventory {
		const peripheral = Peripheral.require<InventoryPeripheral>(name);
		return new Inventory(name, peripheral);
	}

	public size(): number {
		return this.peripheralRef.size();
	}

	public list(): LuaTable<number, ItemSummary> {
		return this.peripheralRef.list();
	}

	public getItem(slot: number): ItemDetail | undefined {
		return this.peripheralRef.getItemDetail(slot);
	}

	public isEmpty(): boolean {
		const items = this.list();
		return next(items)[0] === undefined;
	}

	public hasItem(itemName: string): boolean {
		return this.findFirstSlotByName(itemName) !== undefined;
	}

	public findFirstSlotByName(itemName: string): number | undefined {
		const items = this.list();

		for (const [slot, item] of pairs(items)) {
			if (item.name === itemName) {
				return slot;
			}
		}

		return undefined;
	}

	public countItem(itemName: string): number {
		let total = 0;
		const items = this.list();

		for (const [, item] of pairs(items)) {
			if (item.name === itemName) {
				total += item.count;
			}
		}

		return total;
	}

	public countAllItems(): number {
		let total = 0;
		const items = this.list();

		for (const [, item] of pairs(items)) {
			total += item.count;
		}

		return total;
	}

	public pushTo(target: Inventory, fromSlot: number, limit?: number, toSlot?: number): number {
		return this.peripheralRef.pushItems(target.name, fromSlot, limit, toSlot);
	}

	public pullFrom(source: Inventory, fromSlot: number, limit?: number, toSlot?: number): number {
		return this.peripheralRef.pullItems(source.name, fromSlot, limit, toSlot);
	}

	public moveFirstItemByName(target: Inventory, itemName: string, limit?: number): number {
		const slot = this.findFirstSlotByName(itemName);

		if (slot === undefined) {
			return 0;
		}

		return this.pushTo(target, slot, limit);
	}

	public moveAllOfItem(target: Inventory, itemName: string): number {
		let moved = 0;

		while (true) {
			const slot = this.findFirstSlotByName(itemName);

			if (slot === undefined) {
				break;
			}

			const amount = this.pushTo(target, slot);

			if (amount <= 0) {
				break;
			}

			moved += amount;
		}

		return moved;
	}

	public getUsedSlots(): number[] {
		const result: number[] = [];
		const items = this.list();

		for (const [slot] of pairs(items)) {
			result.push(slot);
		}

		return result;
	}

	public getFreeSlotCount(): number {
		return this.size() - this.getUsedSlots().length;
	}
}