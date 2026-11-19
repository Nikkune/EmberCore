import {EmberError}                                     from '@core/errors';
import {Inventory}                                      from '@core/inventory';
import type {ItemSummary}                               from '@core/inventory';
import {Parallel}                                       from '@core/parallel';
import {Tank}                                           from '@core/tank';
import type {FluidStack}                                from '@core/tank';
import {ReservoirPool}                                  from '@modules/fluids/index';
import {Channel}                                        from '@modules/net/index';
import {Caster, Smeltery}                               from '@modules/tinkers/index';
import type {AlloyGuard, AlloyRatio, CastAmounts, CasterState, MaterialMap} from '@modules/tinkers/index';

import {alloyGuardOf, castAmountsOf, loadCatalogue, materialMapOf, temperatureMap} from '../shared/catalogue';
import type {Catalogue}                                 from '../shared/catalogue';
import {CONTROLLER_HOSTNAME, Messages, MODES, PROTOCOL} from '../shared/protocol';
import type {AlloyOption, AlloyView, CasterView, CastRequest, FuelView, InputItemView, InsertRequest, InventoryView, Mode, SetAlloyRequest, SetFormatRequest, SetModeRequest, SmelteryState, WaitingItem} from '../shared/protocol';

import {CONFIG_PATH, loadAlloy, loadCapacities, loadControllerConfig, loadMode, saveAlloy, saveCapacities, saveControllerConfig, saveMode} from './config';
import type {ControllerConfig}                          from './config';
import {discoverNetwork}                                from './discovery';
import type {Network}                                   from './discovery';
import {assessInput, assessItem, planTick}              from './planner';
import type {Action, InputSlot, Plan, PlanContext, Snapshot} from './planner';

/** Fluid of an item by name, or false when it melts into nothing known (cached: tags do not change). */
type FluidCache = Map<string, string | false>;

/** What one reading of the network saw, kept to build the state. */
interface Reading {
	fluids: FluidStack[];
	melting: ItemSummary[];
	casters: CasterView[];
	input?: InventoryView;
	output?: InventoryView;
}

/**
 * The foundry: reads the Smeltery every tick, plans what the mode allows, does it, and keeps the state
 * the display shows. Peripheral calls that fail (a block broken, a modem off) become alerts, and the
 * network is searched again on the next tick.
 */
export class Controller {
	private mode: Mode;
	private network: Network = {casters: [], reservoirs: [], problems: []};
	private pool?: ReservoirPool | undefined;
	/** Mode a purge goes back to. */
	private previousMode: Mode;
	private readonly alloyResults: Set<string>;
	private readonly alloyRatios: AlloyRatio[];
	/** The alloy of alloy mode, and how much of it was cast. */
	private alloy?: AlloyView | undefined;
	private smeltery?: Smeltery | undefined;
	private casters: Caster[]                    = [];
	private input?: Inventory | undefined;
	private output?: Inventory | undefined;
	private heatOutput?: Inventory | undefined;
	private unknownOutput?: Inventory | undefined;
	private fuelTank?: Tank | undefined;
	private readonly fluidCache: FluidCache      = new Map();
	private readonly logLines: string[]          = [];
	private readonly materials: MaterialMap;
	private readonly guard: AlloyGuard;
	private readonly amounts: CastAmounts;
	private readonly meltingTemperatures: Map<string, number>;
	private readonly fuelTemperatures: Map<string, number>;
	/** Heat of the configured fuel, used when no fuel tank is on the network. */
	private readonly fallbackHeat: number | undefined;
	private fuel?: FuelView | undefined;
	private heat?: number | undefined;
	private inputItems: InputItemView[]          = [];
	/** What the last reading saw, for the state: building it reads no peripheral again. */
	private lastRead?: Reading | undefined;
	/** Sizes do not change: read once per inventory. */
	private readonly sizes = new Map<string, number>();
	private tickWanted = false;
	private state: SmelteryState;
	private needsDiscovery                       = true;
	private logFile?: string | undefined;
	/** Where settings changed from the display are saved; unset: they only last until a restart. */
	private configPath?: string | undefined;
	private lastAlerts                           = '';
	/** os.clock() of the last activity in auto, alloy or melt (see idleSeconds). */
	private quietSince?: number | undefined;

	public constructor(private readonly config: ControllerConfig, catalogue: Catalogue, private readonly modePath?: string) {
		this.materials = materialMapOf(catalogue);
		this.guard     = alloyGuardOf(catalogue);
		this.amounts   = castAmountsOf(catalogue);

		this.meltingTemperatures = temperatureMap(catalogue.meltingTemperatures);
		this.fuelTemperatures    = temperatureMap(catalogue.fuels);
		this.fallbackHeat        = this.fuelTemperatures.get(config.fuel);
		const saved       = loadMode(modePath);
		this.mode         = saved.mode;
		this.previousMode = saved.previous;
		this.alloyResults = new Set(catalogue.alloys.map((alloy) => alloy.result));
		this.alloyRatios  = catalogue.alloyRatios;
		this.alloy        = loadAlloy();
		this.state     = this.emptyState();
	}

	/** Also appends every log line to this file (the previous run's file is kept as <path>.old). */
	public setLogFile(path: string): void {
		if (fs.exists(path)) {
			if (fs.exists(`${path}.old`)) fs.delete(`${path}.old`);
			fs.move(path, `${path}.old`);
		}
		this.logFile = path;
	}

	/** Settings changed from the display (the auto formats) are written back to this file. */
	public setConfigPath(path: string): void {
		this.configPath = path;
	}

	/**
	 * Lets auto mode cast into `format`, or not. The list stays biggest first: a format comes back before
	 * the first one smaller than it, the others keep their order.
	 */
	public setFormat(request: SetFormatRequest): void {
		const format = request.format;
		if (typeof format !== 'string' || format === '' || format === 'no cast') {
			throw new EmberError(`unknown format ${tostring(format)}`, 'SMELTERY_ERROR');
		}

		const formats = this.config.formatPriority.filter((candidate) => candidate !== format);
		if (request.auto) {
			const size  = (name: string): number => this.amounts.get(name) ?? 0;
			const index = formats.findIndex((candidate) => size(candidate) < size(format));
			if (index < 0) formats.push(format);
			else formats.splice(index, 0, format);
		}

		if (formats.join(',') === this.config.formatPriority.join(',')) return;

		this.config.formatPriority = formats;
		this.state.autoFormats     = formats;
		if (this.configPath !== undefined) saveControllerConfig(this.config, this.configPath);
		this.log(`auto formats: ${formats.length > 0 ? formats.join(', ') : 'none'}`);
	}

	/** Chooses the alloy of alloy mode (an amount in mB, or none: until the mode changes). */
	public setAlloy(request: SetAlloyRequest): void {
		const result = request.result;
		if (!this.alloyRatios.some((ratio) => ratio.result === result)) throw new EmberError(`unknown alloy ${tostring(result)}`, 'SMELTERY_ERROR');
		if (request.target !== undefined && !(request.target > 0)) throw new EmberError('the amount must be positive', 'SMELTERY_ERROR');

		const alloy: AlloyView = {result, made: 0};
		if (request.target !== undefined) alloy.target = request.target;
		this.alloy = alloy;
		saveAlloy(alloy);
		this.log(`alloy: ${Controller.shortName(result)}, ${alloy.target !== undefined ? `${alloy.target} mB` : 'until stopped'}`);
		this.state.alloy = {...alloy};

		if (request.activate === true) this.setMode('alloy');
	}

	public getState(): SmelteryState {
		return this.state;
	}

	public getMode(): Mode {
		return this.mode;
	}

	public setMode(mode: Mode): void {
		if (mode === this.mode) return;
		if (mode === 'alloy' && this.alloy === undefined) throw new EmberError('choose an alloy first (Change alloy)', 'SMELTERY_ERROR');

		// A purge or an alloy goes back to the mode it interrupted (never to a drain, purge or alloy).
		if ((mode === 'purge' || mode === 'alloy') && !Controller.ends(this.mode)) this.previousMode = this.mode;

		// Each run of alloy mode counts from zero.
		if (mode === 'alloy' && this.alloy !== undefined) {
			this.alloy.made = 0;
			saveAlloy(this.alloy);
		}

		this.log(`mode ${this.mode} -> ${mode}`);
		this.quietSince = undefined;
		this.mode = mode;
		saveMode(mode, this.previousMode, this.modePath);
		this.state.mode = mode;
	}

	/** One reading of the Smeltery, the plan of the mode, and its actions. */
	public tick(): void {
		if (this.needsDiscovery) this.connect();

		const alerts = [...this.network.problems];
		let plan: Plan = {actions: [], waiting: [], alerts: []};

		try {
			const pauseInput = this.readFuel(alerts);
			const snapshot   = this.read();

			if (snapshot !== undefined) {
				if (pauseInput !== undefined) snapshot.pauseInput = pauseInput;

				const context = this.planContext();
				this.inputItems = assessInput(snapshot, context);
				plan            = planTick(this.mode, snapshot, context);
				this.execute(plan);
				if (plan.actions.length > 0) this.refreshReading();
				if (plan.finished === true) this.finish();
				else this.checkIdle(plan, snapshot);
			}
		}
		catch (error) {
			Controller.passTerminate(error);
			alerts.push(`peripheral error: ${Controller.messageOf(error)}`);
			this.needsDiscovery = true;
		}

		this.tickWanted = false;
		this.state      = this.buildState([...alerts, ...plan.alerts], plan.waiting);

		const alertText = this.state.alerts.join('; ');
		if (alertText !== this.lastAlerts) {
			this.log(alertText === '' ? 'alerts cleared' : `alerts: ${alertText}`);
			this.lastAlerts = alertText;
		}
	}

	/**
	 * Manual mode: sends the items of an input slot to the Smeltery. Refused when they would form an alloy
	 * or need more heat, unless `force` (the display asks twice first); never for an item with no fluid.
	 */
	public insert(request: InsertRequest): number {
		this.requireManual();
		const smeltery = this.smeltery;
		const input    = this.input;
		if (smeltery === undefined || input === undefined) throw new EmberError('Smeltery or input missing', 'SMELTERY_ERROR');

		const detail = input.getItem(request.slot);
		if (detail === undefined) throw new EmberError(`input slot ${request.slot} is empty`, 'SMELTERY_ERROR');

		const item: InputSlot = {slot: request.slot, name: detail.name, count: detail.count};
		const fluid           = this.fluidOf(detail.name, () => detail);
		if (fluid !== undefined) item.fluid = fluid;

		const assessment = assessItem(item, this.presentFluids(smeltery), this.planContext());
		const forced     = request.force === true;

		if (assessment.status === 'unknown') throw new EmberError(`${detail.name} melts into no known fluid`, 'SMELTERY_ERROR');
		if (assessment.status === 'heat' && !forced) {
			throw new EmberError(`${detail.name} needs ${assessment.temperature ?? '?'} K, the fuel gives ${this.heat ?? '?'} K`, 'SMELTERY_ERROR');
		}
		if (assessment.status === 'alloy' && !forced) throw new EmberError(`${detail.name} would form ${assessment.alloy ?? 'an alloy'}`, 'SMELTERY_ERROR');

		const moved = smeltery.insert(input, request.slot, request.count);
		if (forced && assessment.status !== 'ok') {
			const why = assessment.status === 'alloy' ? Controller.shortName(assessment.alloy ?? 'an alloy') : `needs ${assessment.temperature ?? '?'} K`;
			this.log(`FORCED insert ${moved} ${detail.name} (${why})`);
		}
		else {
			this.log(`inserted ${moved} ${detail.name}`);
		}
		return moved;
	}

	/** Manual mode: one casting of a fluid, into the named caster or into any idle caster of a format. */
	public cast(request: CastRequest): number {
		this.requireManual();
		const smeltery = this.smeltery;
		if (smeltery === undefined) throw new EmberError('Smeltery missing', 'SMELTERY_ERROR');

		const candidates = this.casters.filter((caster) => request.caster !== undefined
			? caster.name === request.caster
			: request.format !== undefined && caster.read().format === request.format);
		if (candidates.length === 0) throw new EmberError(`no caster ${request.caster ?? request.format ?? ''}`, 'SMELTERY_ERROR');

		for (const caster of candidates) {
			const moved = caster.pour(smeltery, request.fluid);

			if (moved > 0) {
				this.log(`poured ${moved} mB ${Controller.shortName(request.fluid)} into ${caster.name}`);
				return moved;
			}
		}

		throw new EmberError(`cannot cast ${Controller.shortName(request.fluid)} now (casters busy, or not enough fluid)`, 'SMELTERY_ERROR');
	}

	/** Answers the display: state, mode changes, manual commands. Each command replies with the new state. */
	public serve(channel: Channel): void {
		channel.on(Messages.getState, () => this.state);

		// Each command answers at once with the state as it is, and asks for a tick right after: the
		// display gets its reply in a fraction of a second, then the broadcast of the new state.
		channel.on(Messages.setMode, (payload) => {
			const mode = (payload as SetModeRequest | undefined)?.mode;
			if (!MODES.includes(mode as Mode)) throw new EmberError(`unknown mode ${tostring(mode)}`, 'SMELTERY_ERROR');
			this.setMode(mode as Mode);
			this.tickWanted = true;
			return this.state;
		});

		channel.on(Messages.insert, (payload) => {
			this.insert(payload as InsertRequest);
			this.tickWanted = true;
			return this.state;
		});

		channel.on(Messages.cast, (payload) => {
			this.cast(payload as CastRequest);
			this.tickWanted = true;
			return this.state;
		});

		channel.on(Messages.setAlloy, (payload) => {
			this.setAlloy(payload as SetAlloyRequest);
			this.tickWanted = true;
			return this.state;
		});

		channel.on(Messages.setFormat, (payload) => {
			this.setFormat(payload as SetFormatRequest);
			this.tickWanted = true;
			return this.state;
		});
	}

	/** A command changed something: the main loop should tick now rather than wait for its timer. */
	public wantsTick(): boolean {
		return this.tickWanted;
	}

	private connect(): void {
		this.network        = discoverNetwork(this.config);
		this.needsDiscovery = false;

		const {drain, chute, input, output} = this.network;
		this.smeltery = drain !== undefined && chute !== undefined ? Smeltery.fromNames(drain, chute) : undefined;
		this.input    = input !== undefined ? Inventory.fromName(input) : undefined;
		this.output   = output !== undefined ? Inventory.fromName(output) : undefined;

		const assignments: Record<string, string> = {};
		for (const entry of this.config.assignments) assignments[entry.reservoir] = entry.fluid;
		this.pool = new ReservoirPool(this.network.reservoirs, {capacities: loadCapacities(), assignments});

		const {heatOutput, unknownOutput, fuelTank} = this.network;
		this.fuelTank      = fuelTank !== undefined ? Tank.fromName(fuelTank) : undefined;
		this.heatOutput    = heatOutput !== undefined ? Inventory.fromName(heatOutput) : undefined;
		this.unknownOutput = unknownOutput !== undefined ? Inventory.fromName(unknownOutput) : undefined;
		this.casters  = this.network.casters.map((name) => Caster.fromName(name, this.amounts));

		this.log(`network: ${this.casters.length} caster(s)${this.network.problems.length > 0 ? `, ${this.network.problems.length} problem(s)` : ''}`);

		for (const caster of this.casters) {
			try {
				const state = caster.read();
				this.log(`  ${caster.name}: ${state.format ?? (state.cast !== undefined ? `unknown cast ${state.cast}` : 'no cast')}`);
			}
			catch (error) {
				Controller.passTerminate(error);
				this.log(`  ${caster.name}: unreadable (${Controller.messageOf(error)})`);
			}
		}
	}

	private read(): Snapshot | undefined {
		const smeltery = this.smeltery;
		if (smeltery === undefined) return undefined;

		const present = this.readPresent(smeltery);

		// Each peripheral call waits a game tick: the casters are read all at once, not one by one.
		const states: CasterState[] = [];
		if (this.casters.length > 0) {
			Parallel.all(...this.casters.map((caster, index) => () => {
				states[index] = caster.read();
			}));
		}

		const outputUsed = this.output !== undefined ? Controller.usedSlots(this.output) : 0;
		const outputSize = this.output !== undefined ? this.sizeOf(this.output) : 0;

		const pool = this.pool;
		pool?.refresh();

		const snapshot: Snapshot = {
			stored:        Controller.storedFluids(pool),
			storable:      present.fluids.filter((fluid) => pool?.canStore(fluid.name) === true).map((fluid) => fluid.name),
			fluids:        present.fluids,
			meltingFluids: present.melting,
			casters:       this.casters.map((caster, index) => ({name: caster.name, state: states[index]!})),
			input:         [],
			outputFree:    outputSize - outputUsed,
		};
		if (present.uncertain) snapshot.uncertain = true;

		const input = this.input;
		if (input !== undefined) {
			for (const [slot, item] of pairs(input.list())) {
				const entry: InputSlot = {slot, name: item.name, count: item.count};
				const fluid            = this.fluidOf(item.name, () => input.getItem(slot));
				if (fluid !== undefined) entry.fluid = fluid;
				snapshot.input.push(entry);
			}
			snapshot.input.sort((a, b) => a.slot - b.slot);
		}

		const reading: Reading = {
			fluids:  present.fluids,
			melting: present.items,
			casters: this.casters.map((caster, index) => Controller.viewOf(caster, states[index]!)),
		};
		if (input !== undefined) reading.input = {name: input.name, size: this.sizeOf(input), used: snapshot.input.length};
		if (this.output !== undefined) reading.output = {name: this.output.name, size: outputSize, used: outputUsed};
		this.lastRead = reading;

		return snapshot;
	}

	/**
	 * After a tick that acted (poured, collected, inserted), reads again what the state shows, all at once:
	 * the display sees this tick's result, not the reading taken before it.
	 */
	/**
	 * Auto, alloy and melt drain the Smeltery and go idle once nothing happened for idleSeconds: nothing
	 * done this tick, nothing melting, no caster at work.
	 */
	private checkIdle(plan: Plan, snapshot: Snapshot): void {
		if (this.mode !== 'auto' && this.mode !== 'alloy' && this.mode !== 'melt') {
			this.quietSince = undefined;
			return;
		}

		const busy = plan.actions.length > 0
			|| snapshot.meltingFluids.length > 0
			|| snapshot.casters.some((caster) => caster.state.status === 'busy');
		if (busy || this.quietSince === undefined) {
			this.quietSince = os.clock();
			return;
		}

		const seconds = this.config.idleSeconds;
		if (seconds > 0 && os.clock() - this.quietSince >= seconds) {
			this.log(`nothing to do for ${seconds} s: drain, then idle`);
			this.setMode('drain');
		}
	}

	/** Modes that end on their own: one of them never becomes the mode to go back to. */
	private static ends(mode: Mode): boolean {
		return mode === 'drain' || mode === 'purge' || mode === 'alloy';
	}

	/**
	 * A drain or purge has nothing left it can move, or alloy mode made its amount: drain stops, purge and
	 * alloy go back to the previous mode.
	 */
	private finish(): void {
		if (this.mode === 'drain') {
			this.log('drain finished');
			this.setMode('idle');
		}
		else if (this.mode === 'purge' || this.mode === 'alloy') {
			this.log(this.mode === 'purge' ? 'purge finished' : `alloy finished: ${this.alloy?.made ?? 0} mB cast`);
			this.setMode(Controller.ends(this.previousMode) ? 'idle' : this.previousMode);
		}
	}

	private static storedFluids(pool: ReservoirPool | undefined): {fluid: string; amount: number}[] {
		const stored: {fluid: string; amount: number}[] = [];
		for (const view of pool?.views() ?? []) {
			if (view.fluid === undefined) continue;
			const entry = stored.find((candidate) => candidate.fluid === view.fluid);
			if (entry !== undefined) entry.amount += view.amount;
			else stored.push({fluid: view.fluid, amount: view.amount});
		}
		return stored;
	}

	private refreshReading(): void {
		const reading  = this.lastRead;
		const smeltery = this.smeltery;
		if (reading === undefined || smeltery === undefined) return;

		const states: CasterState[] = [];
		const tasks: (() => void)[] = this.casters.map((caster, index) => () => {
			states[index] = caster.read();
		});
		tasks.push(() => {
			reading.fluids = smeltery.fluids();
		});
		tasks.push(() => {
			reading.melting = smeltery.melting();
		});
		if (this.input !== undefined && reading.input !== undefined) {
			const input = this.input, view = reading.input;
			tasks.push(() => {
				view.used = Controller.usedSlots(input);
			});
		}
		if (this.output !== undefined && reading.output !== undefined) {
			const output = this.output, view = reading.output;
			tasks.push(() => {
				view.used = Controller.usedSlots(output);
			});
		}

		Parallel.all(...tasks);
		reading.casters = this.casters.map((caster, index) => Controller.viewOf(caster, states[index]!));
	}

	private execute(plan: Plan): void {
		let smelteryFull = false;

		for (const action of plan.actions) {
			if (action.kind === 'insert' && smelteryFull) {
				Controller.addWaiting(plan.waiting, action.name, action.count);
				continue;
			}

			const left = this.apply(action);

			if (action.kind === 'insert' && left > 0) {
				smelteryFull = true;
				Controller.addWaiting(plan.waiting, action.name, left);
			}

			if (action.kind === 'reject' && left > 0) {
				plan.alerts.push(`${action.reason} output full: ${left} ${action.name} left in the input`);
			}
		}
	}

	/** Does one action; for an insert or a reject, returns how many items did not move. */
	private apply(action: Action): number {
		const smeltery = this.smeltery!;

		switch (action.kind) {
			case 'collect': {
				const caster = this.casters.find((candidate) => candidate.name === action.caster);
				const output = this.output;
				if (caster === undefined || output === undefined) return 0;

				const moved = caster.collect(output);
				if (moved > 0) this.log(`collected ${moved} from ${caster.name}`);
				return 0;
			}
			case 'pour': {
				const caster = this.casters.find((candidate) => candidate.name === action.caster);
				if (caster === undefined) return 0;

				const moved = caster.pour(smeltery, action.fluid);
				if (moved > 0) this.log(`poured ${moved} mB ${Controller.shortName(action.fluid)} into ${caster.name}`);

				const alloy = this.alloy;
				if (moved > 0 && this.mode === 'alloy' && alloy !== undefined && alloy.result === action.fluid) {
					alloy.made += moved;
					saveAlloy(alloy);
				}
				return 0;
			}
			case 'reject': {
				const target = action.reason === 'heat' ? this.heatOutput : this.unknownOutput;
				if (target === undefined) return action.count;

				const moved = this.input!.pushTo(target, action.slot, action.count);
				if (moved > 0) {
					const why = action.reason === 'heat' ? `needs ${action.temperature ?? '?'} K` : 'melts into nothing known';
					this.log(`moved ${moved} ${action.name} to ${target.name} (${why})`);
				}
				return action.count - moved;
			}
			case 'store': {
				const pool = this.pool;
				if (pool === undefined) return 0;

				// Never more than the Smeltery holds now: a reservoir taking less is then known to be full.
				const amount = Math.min(action.amount, smeltery.amountOf(action.fluid));
				if (amount <= 0) return 0;

				const before = textutils.serialise(pool.capacities());
				const stored = pool.store(smeltery.drain, action.fluid, amount);
				if (stored > 0) this.log(`stored ${stored} mB ${Controller.shortName(action.fluid)} (${action.why})`);
				if (stored < amount) this.log(`no room left for ${amount - stored} mB ${Controller.shortName(action.fluid)}`);
				if (textutils.serialise(pool.capacities()) !== before) saveCapacities(pool.capacities());
				return 0;
			}
			case 'restore': {
				const taken = this.pool?.take(smeltery.drain, action.fluid, action.amount) ?? 0;
				const why   = action.why === 'stock'
				              ? 'from the stock'
				              : action.why === 'alloy' ? `for ${Controller.shortName(this.alloy?.result ?? 'the alloy')}` : 'to complete a cast';
				if (taken > 0) this.log(`restored ${taken} mB ${Controller.shortName(action.fluid)} ${why}`);
				return 0;
			}
			default: {
				const moved = smeltery.insert(this.input!, action.slot, action.count);
				if (moved > 0) {
					const seen = action.seen.map((fluid) => Controller.shortName(fluid)).join(', ');
					this.log(`inserted ${moved} ${action.name} (seen: ${seen === '' ? 'nothing' : seen})`);
				}
				return action.count - moved;
			}
		}
	}

	/**
	 * Fluid of an item, its tags read once per name. An item whose detail cannot be read (it left its slot,
	 * melted) is not remembered as "melts into nothing": undefined, and asked again next time.
	 */
	private fluidOf(name: string, detail: () => {name: string; tags?: LuaMap<string, boolean>} | undefined): string | undefined {
		let fluid = this.fluidCache.get(name);

		if (fluid === undefined) {
			const item = detail();
			if (item === undefined || item.name !== name) return undefined;

			fluid = this.materials.fluidOf(item) ?? false;
			this.fluidCache.set(name, fluid);
		}

		return fluid === false ? undefined : fluid;
	}

	/**
	 * What is in the Smeltery: items melting, then fluids, read one right after the other in THIS order.
	 * An item can only go from the chute to the fluids, so one finishing to melt between the two readings
	 * is seen at least once (read the other way round, it could be seen in neither: copper missed, gold let
	 * in, rose gold). The tags of new items are read afterwards; one that melted meanwhile cannot be
	 * identified, and the reading is then `uncertain`.
	 */
	private planContext(): PlanContext {
		const context: PlanContext = {
			guard:              this.guard,
			amounts:            this.amounts,
			formatPriority:     this.config.formatPriority,
			meltingTemperature: (fluid) => this.meltingTemperatures.get(fluid),
			reject:             {heat: this.heatOutput !== undefined, unknown: this.unknownOutput !== undefined},
			isAlloy:            (fluid) => this.alloyResults.has(fluid),
		};
		if (this.heat !== undefined) context.fuelTemperature = this.heat;

		const alloy = this.alloy;
		if (alloy !== undefined) {
			context.alloy = {result: alloy.result, ratios: this.alloyRatios.filter((ratio) => ratio.result === alloy.result)};
			if (alloy.target !== undefined) context.alloy.remaining = alloy.target - alloy.made;
		}
		return context;
	}

	/**
	 * Reads the fuel tank and sets the heat items are checked against: the fuel's, otherwise the configured
	 * fuel's. Returns why the input must pause (an empty tank: nothing would melt), or undefined.
	 */
	private readFuel(alerts: string[]): string | undefined {
		this.fuel = undefined;
		this.heat = this.fallbackHeat;

		if (this.fuelTank === undefined) {
			if (this.fallbackHeat === undefined) alerts.push(`unknown fuel '${this.config.fuel}': melting temperatures not checked`);
			return undefined;
		}

		const [fluid] = this.fuelTank.getFluids();
		this.fuel     = {amount: fluid?.amount ?? 0};

		if (fluid === undefined) {
			alerts.push('fuel tank empty: input paused');
			return 'fuel tank empty: input paused';
		}

		this.fuel.fluid  = fluid.name;
		const temperature = this.fuelTemperatures.get(fluid.name);

		if (temperature === undefined) {
			alerts.push(`unknown fuel '${fluid.name}': assuming ${this.config.fuel}`);
			return undefined;
		}

		this.fuel.temperature = temperature;
		this.heat             = temperature;
		return undefined;
	}

	private readPresent(smeltery: Smeltery): {fluids: FluidStack[]; melting: string[]; items: ItemSummary[]; uncertain: boolean} {
		const items  = smeltery.chute.list();
		const fluids = smeltery.fluids();

		const melting: string[]       = [];
		const summaries: ItemSummary[] = [];
		let uncertain                 = false;

		for (const [slot, item] of pairs(items)) {
			summaries.push({name: item.name, count: item.count});
			const fluid = this.fluidOf(item.name, () => smeltery.chute.getItem(slot));

			if (fluid === undefined && !this.fluidCache.has(item.name)) uncertain = true;
			else if (fluid !== undefined && !melting.includes(fluid)) melting.push(fluid);
		}

		return {fluids, melting, items: summaries, uncertain};
	}

	private presentFluids(smeltery: Smeltery): string[] {
		const present = this.readPresent(smeltery);
		if (present.uncertain) throw new EmberError('the Smeltery content cannot be told right now, try again', 'SMELTERY_ERROR');
		return [...present.melting, ...present.fluids.map((fluid) => fluid.name)];
	}

	private requireManual(): void {
		if (this.mode !== 'manual') throw new EmberError(`manual commands need manual mode (now ${this.mode})`, 'SMELTERY_ERROR');
	}

	private buildState(alerts: string[], waiting: WaitingItem[]): SmelteryState {
		const state: SmelteryState = {
			mode:    this.mode,
			time:    os.epoch('utc'),
			fluids:  [],
			melting: [],
			casters: [],
			waiting,
			alerts,
			log:     [...this.logLines],

			inputItems:   this.inputItems,
			autoFormats:  this.config.formatPriority,
			reservoirs:   this.pool?.views() ?? [],
			alloyOptions: this.alloyOptions(),
		};
		if (this.alloy !== undefined) state.alloy = {...this.alloy};
		if (this.fuel !== undefined) state.fuel = this.fuel;
		if (this.heat !== undefined) state.heat = this.heat;

		// From the reading of this tick (taken before its actions): no peripheral is read again.
		const reading = this.lastRead;
		if (reading !== undefined) {
			state.fluids  = reading.fluids;
			state.melting = reading.melting;
			state.casters = reading.casters;
			if (reading.input !== undefined) state.input = reading.input;
			if (reading.output !== undefined) state.output = reading.output;
		}

		return state;
	}

	/**
	 * Every alloy of the catalogue for the picker, with what the stock alone can make of it (the recipe
	 * the stock suits best when there are several), those that can be made first.
	 */
	private alloyOptions(): AlloyOption[] {
		const stored  = Controller.storedFluids(this.pool);
		const stockOf = (fluid: string): number => stored.find((entry) => entry.fluid === fluid)?.amount ?? 0;
		const options: AlloyOption[] = [];

		for (const ratio of this.alloyRatios) {
			const batches   = Math.min(...ratio.inputs.map((input) => Math.floor(stockOf(input.fluid) / input.amount)));
			const fromStock = Math.max(0, batches) * ratio.amount;
			const existing  = options.find((option) => option.result === ratio.result);
			if (existing !== undefined && existing.fromStock >= fromStock) continue;

			const option: AlloyOption = {result: ratio.result, amount: ratio.amount, inputs: ratio.inputs, fromStock};
			const temperature = this.meltingTemperatures.get(ratio.result);
			const heat        = this.heat ?? this.fallbackHeat;
			if (temperature !== undefined && heat !== undefined && temperature > heat) option.temperature = temperature;

			if (existing !== undefined) options[options.indexOf(existing)] = option;
			else options.push(option);
		}

		return options.sort((a, b) => {
			if (a.fromStock !== b.fromStock) return b.fromStock - a.fromStock;
			return a.result < b.result ? -1 : a.result > b.result ? 1 : 0;
		});
	}

	private emptyState(): SmelteryState {
		return {
			mode:        this.mode,
			time:        0,
			fluids:      [],
			melting:     [],
			casters:     [],
			inputItems:  [],
			autoFormats: this.config.formatPriority,
			reservoirs:  [],
			// The picker has its list before the first tick.
			alloyOptions: this.alloyOptions(),
			waiting:     [],
			alerts:      [],
			log:         [],
		};
	}

	private log(line: string): void {
		const stamped = `${os.date('%H:%M:%S')} ${line}`;
		print(stamped);
		this.logLines.push(stamped);

		if (this.logFile !== undefined) {
			const file = fs.open(this.logFile, 'a') as WriteHandle | undefined;
			if (file !== undefined) {
				file.writeLine(stamped);
				file.close();
			}
		}

		while (this.logLines.length > this.config.logSize) this.logLines.shift();
	}

	private static viewOf(caster: Caster, state: CasterState): CasterView {
		const view: CasterView = {name: caster.name, kind: caster.kind, status: state.status, amount: state.amount};
		if (state.format !== undefined) view.format = state.format;
		if (state.fluid !== undefined) view.fluid = state.fluid;
		if (state.output !== undefined) view.output = state.output;
		return view;
	}

	private sizeOf(inventory: Inventory): number {
		let size = this.sizes.get(inventory.name);
		if (size === undefined) {
			size = inventory.size();
			this.sizes.set(inventory.name, size);
		}
		return size;
	}

	private static usedSlots(inventory: Inventory): number {
		let used = 0;
		for (const [_slot] of pairs(inventory.list())) used++;
		return used;
	}

	private static addWaiting(waiting: WaitingItem[], name: string, count: number): void {
		for (const item of waiting) {
			if (item.name === name && item.reason === 'full') {
				item.count += count;
				return;
			}
		}
		waiting.push({name, count, reason: 'full'});
	}

	private static shortName(fluid: string): string {
		const colon = fluid.indexOf(':');
		return colon >= 0 ? fluid.substring(colon + 1) : fluid;
	}

	/** Ctrl+T raises "Terminated" inside whatever call is running: it must stop the program, not become an alert. */
	private static passTerminate(error: unknown): void {
		if (error === 'Terminated') throw error;
	}

	private static messageOf(error: unknown): string {
		return error instanceof Error ? error.message : tostring(error);
	}
}

/** Event queued by the listener to wake the main loop when a message arrived. */
const WAKE_EVENT = 'smeltery_message';

/**
 * Main loop of the foundry computer, in two coroutines:
 * - the listener only receives the display's messages and queues them. It must be separate: every
 *   peripheral call waits for its own event and CC drops all the others meanwhile, so a loop busy reading
 *   the Smeltery missed nearly every command (0 of 20 messages in the in-game probe, 20 of 20 here);
 * - the main loop ticks on its timer, and between two ticks handles the queued messages one by one, so
 *   a command never runs in the middle of a tick.
 */
export function runController(this: void): void {
	const config     = loadControllerConfig();
	const controller = new Controller(config, loadCatalogue());
	controller.setLogFile('/smeltery/controller.log');
	controller.setConfigPath(CONFIG_PATH);
	const channel    = new Channel({protocol: PROTOCOL});

	let online = false;
	try {
		channel.open();
		channel.host(CONTROLLER_HOSTNAME);
		online = true;
	}
	catch (error) {
		print(`No rednet (${error instanceof Error ? error.message : tostring(error)}): running without the display`);
	}

	controller.serve(channel);

	const inbox: unknown[][] = [];

	const listen = (): void => {
		while (true) {
			const event = [...os.pullEvent('rednet_message')];
			if (event[3] !== PROTOCOL) continue;
			inbox.push(event);
			os.queueEvent(WAKE_EVENT);
		}
	};

	const loop = (): void => {
		let lastSent      = '';
		let lastSentClock = -Infinity;
		let timer         = os.startTimer(0);

		while (true) {
			const event = [...os.pullEvent()];

			// Messages come through the inbox only (this coroutine may have missed some of them).
			while (inbox.length > 0) channel.handleEvent(inbox.shift()!);

			const timerDue = event[0] === 'timer' && event[1] === timer;
			if (!timerDue && !controller.wantsTick()) continue;

			if (!timerDue) os.cancelTimer(timer);
			controller.tick();
			timer = os.startTimer(config.tickSeconds);

			if (!online) continue;

			// Broadcast on change (the time does not count as a change), and as a heartbeat.
			const state = controller.getState();
			const text  = textutils.serialise({...state, time: 0});
			if (text !== lastSent || os.clock() - lastSentClock >= config.heartbeatSeconds) {
				channel.broadcast(Messages.state, state);
				lastSent      = text;
				lastSentClock = os.clock();
			}
		}
	};

	Parallel.any(loop, listen);
}
