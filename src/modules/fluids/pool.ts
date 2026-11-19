import {Parallel} from '@core/parallel';
import {Tank}     from '@core/tank';

/** A reservoir as seen at the last reading. */
export interface ReservoirView {
	name: string;
	/** Undefined when empty. */
	fluid?: string;
	amount: number;
	/** Learnt the first time it refused fluid; undefined until then. */
	capacity?: number;
	/** Fluid it is reserved for by the configuration, even when empty. */
	assigned?: string;
}

export interface ReservoirPoolOptions {
	/** Capacities already known (learnt during an earlier run), by reservoir name. */
	capacities?: Record<string, number>;
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

	public constructor(names: string[], options: ReservoirPoolOptions = {}) {
		this.assignments = options.assignments ?? {};
		this.reservoirs  = names.map((name) => {
			const view: ReservoirView = {name, amount: 0};
			const capacity            = options.capacities?.[name];
			const assigned            = this.assignments[name];
			if (capacity !== undefined) view.capacity = capacity;
			if (assigned !== undefined) view.assigned = assigned;
			return {tank: Tank.fromName(name), view};
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

	/** Capacities learnt so far, to keep them for the next run. */
	public capacities(): Record<string, number> {
		const result: Record<string, number> = {};
		for (const {view} of this.reservoirs) {
			if (view.capacity !== undefined) result[view.name] = view.capacity;
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
			if (moved < wanted && reservoir.view.fluid === fluid) reservoir.view.capacity = reservoir.view.amount;
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
