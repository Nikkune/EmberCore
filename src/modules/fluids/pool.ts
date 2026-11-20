import {Parallel} from '@core/parallel';
import {Tank}     from '@core/tank';

/** A reservoir as seen at the last reading. */
export interface ReservoirView {
	name: string;
	/** Undefined when empty. */
	fluid?: string;
	amount: number;
	/** Undefined while unknown: then learnt the first time the reservoir refuses fluid. */
	capacity?: number;
	/** Where `capacity` comes from: learnt (it refused fluid), set by hand, or given by its type. */
	capacitySource?: CapacitySource;
	/** Fluid it is reserved for by the configuration, even when empty. */
	assigned?: string;
}

export type CapacitySource = 'learnt' | 'set' | 'type';

export interface ReservoirPoolOptions {
	/** Capacities already known (learnt during an earlier run), by reservoir name. */
	capacities?: Record<string, number>;
	/** Capacities set by hand, by reservoir name: used when none was learnt. */
	setCapacities?: Record<string, number>;
	/** Capacities given by the type of the reservoir, by reservoir name: the last resort. */
	typeCapacities?: Record<string, number>;
	/** Manual assignments, by reservoir name: such a reservoir only ever takes that fluid. */
	assignments?: Record<string, string>;
}

interface Reservoir {
	tank: Tank;
	view: ReservoirView;
}

/**
 * A pool of external fluid reservoirs (drums, tanks) used without mixing:
 * - a reservoir holding a fluid only takes more of the same fluid;
 * - an empty reservoir is free for any fluid (dynamic pool), unless the configuration assigns it one;
 * - every transfer checks the target again right before moving, and names the fluid it moves.
 * Reservoirs report no capacity: it is learnt the first time one takes less than it was offered.
 */
export class ReservoirPool {
	private readonly reservoirs: Reservoir[];
	private readonly assignments: Record<string, string>;
	private readonly learnt: Record<string, number>;
	private readonly setCapacities: Record<string, number>;
	private readonly typeCapacities: Record<string, number>;

	public constructor(names: string[], options: ReservoirPoolOptions = {}) {
		this.assignments    = options.assignments ?? {};
		this.learnt         = {...options.capacities};
		this.setCapacities  = {...options.setCapacities};
		this.typeCapacities = {...options.typeCapacities};
		this.reservoirs     = names.map((name) => {
			const view: ReservoirView = {name, amount: 0};
			const assigned            = this.assignments[name];
			if (assigned !== undefined) view.assigned = assigned;
			const reservoir = {tank: Tank.fromName(name), view};
			this.resolveCapacity(reservoir);
			return reservoir;
		});
	}

	/** Reads every reservoir at once (each peripheral call waits a game tick). */
	public refresh(): void {
		if (this.reservoirs.length === 0) return;
		Parallel.all(...this.reservoirs.map((reservoir) => () => this.read(reservoir)));
	}

	public views(): ReservoirView[] {
		return this.reservoirs.map((reservoir) => ({...reservoir.view}));
	}

	/** True when `name` is one of the reservoirs of the pool. */
	public has(name: string): boolean {
		return this.reservoirs.some((reservoir) => reservoir.view.name === name);
	}

	/**
	 * Reserves a reservoir for `fluid` from now on (undefined: frees it). A reservoir that holds another
	 * fluid keeps it and can still give it back, but takes no more of it: it changes fluid once emptied.
	 */
	public assign(name: string, fluid: string | undefined): void {
		const reservoir = this.reservoirs.find((candidate) => candidate.view.name === name);
		if (reservoir === undefined) return;

		if (fluid === undefined) {
			delete this.assignments[name];
			delete reservoir.view.assigned;
		}
		else {
			this.assignments[name] = fluid;
			reservoir.view.assigned = fluid;
		}
	}

	/**
	 * Sets the capacity of a reservoir by hand (undefined: back to the learnt or type one). What was
	 * learnt for it is forgotten: the hand-set value is newer; a reservoir refusing fluid teaches it again.
	 */
	public setCapacity(name: string, capacity: number | undefined): void {
		const reservoir = this.reservoirs.find((candidate) => candidate.view.name === name);
		if (reservoir === undefined) return;

		delete this.learnt[name];
		if (capacity === undefined) delete this.setCapacities[name];
		else this.setCapacities[name] = capacity;
		this.resolveCapacity(reservoir);
	}

	/** Capacities learnt so far (not the set or type ones), to keep them for the next run. */
	public capacities(): Record<string, number> {
		const result: Record<string, number> = {};
		for (const {view} of this.reservoirs) {
			const learnt = this.learnt[view.name];
			if (learnt !== undefined) result[view.name] = learnt;
		}
		return result;
	}

	/** Amount of `fluid` stored, over every reservoir (as last read). */
	public stored(fluid: string): number {
		let total = 0;
		for (const {view} of this.reservoirs) {
			if (view.fluid === fluid) total += view.amount;
		}
		return total;
	}

	/** True when some reservoir may take `fluid` (one holding it and not known full, or a free one). */
	public canStore(fluid: string): boolean {
		return this.candidates(fluid).length > 0;
	}

	/**
	 * Moves up to `amount` mB of `fluid` from `source` into the pool: reservoirs that already hold it first,
	 * then empty ones. Returns the mB stored (less when the pool is full for that fluid).
	 * `amount` must not exceed what the source holds: a reservoir taking less than it was offered is then
	 * known to be full, and its capacity is learnt.
	 */
	public store(source: Tank, fluid: string, amount: number): number {
		let stored = 0;

		for (const reservoir of this.candidates(fluid)) {
			if (stored >= amount) break;

			// The target is read again right before: it may have changed since the last refresh.
			this.read(reservoir);
			if (!this.accepts(reservoir, fluid)) continue;

			const wanted = amount - stored;
			const moved  = source.pushTo(reservoir.tank, wanted, fluid);
			this.read(reservoir);
			stored += moved;

			// Took less than offered (the source had it all): the reservoir is full, its capacity is known.
			if (moved < wanted && reservoir.view.fluid === fluid) {
				this.learnt[reservoir.view.name] = reservoir.view.amount;
				this.resolveCapacity(reservoir);
			}
		}

		return stored;
	}

	/** Moves up to `amount` mB of `fluid` from the pool into `target`, smallest stocks first. Returns the mB moved. */
	public take(target: Tank, fluid: string, amount: number): number {
		let taken = 0;

		const holders = this.reservoirs
			.filter((reservoir) => reservoir.view.fluid === fluid)
			.sort((a, b) => a.view.amount - b.view.amount);

		for (const reservoir of holders) {
			if (taken >= amount) break;
			taken += target.pullFrom(reservoir.tank, amount - taken, fluid);
			this.read(reservoir);
		}

		return taken;
	}

	/** Capacity of the view: learnt first (what the reservoir really did), then set by hand, then by type. */
	private resolveCapacity(reservoir: Reservoir): void {
		const name = reservoir.view.name;
		const view = reservoir.view;
		const found: [number | undefined, CapacitySource][] = [
			[this.learnt[name], 'learnt'], [this.setCapacities[name], 'set'], [this.typeCapacities[name], 'type'],
		];

		delete view.capacity;
		delete view.capacitySource;
		for (const [capacity, source] of found) {
			if (capacity === undefined) continue;
			view.capacity       = capacity;
			view.capacitySource = source;
			return;
		}
	}

	private read(reservoir: Reservoir): void {
		const [fluid] = reservoir.tank.getFluids();
		const view    = reservoir.view;

		view.amount = fluid?.amount ?? 0;
		if (fluid !== undefined) view.fluid = fluid.name;
		else delete view.fluid;
	}

	private accepts(reservoir: Reservoir, fluid: string): boolean {
		const view = reservoir.view;
		if (view.assigned !== undefined && view.assigned !== fluid) return false;
		if (view.fluid !== undefined && view.fluid !== fluid) return false;
		return view.capacity === undefined || view.amount < view.capacity;
	}

	/** Reservoirs that may take `fluid`: those holding it first, then the empty ones (assigned ones first). */
	private candidates(fluid: string): Reservoir[] {
		const holding = this.reservoirs.filter((reservoir) => reservoir.view.fluid === fluid && this.accepts(reservoir, fluid));
		const empty   = this.reservoirs.filter((reservoir) => reservoir.view.fluid === undefined && this.accepts(reservoir, fluid));
		empty.sort((a, b) => (a.view.assigned === fluid ? 0 : 1) - (b.view.assigned === fluid ? 0 : 1));
		return [...holding, ...empty];
	}
}
