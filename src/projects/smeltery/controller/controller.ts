import {EmberError}                                     from '@core/errors';
import {Inventory}                                      from '@core/inventory';
import type {FluidStack}                                from '@core/tank';
import {Channel}                                        from '@modules/net/index';
import {Caster, Smeltery}                               from '@modules/tinkers/index';
import type {AlloyGuard, CastAmounts, MaterialMap}      from '@modules/tinkers/index';

import {alloyGuardOf, castAmountsOf, loadCatalogue, materialMapOf, temperatureMap} from '../shared/catalogue';
import type {Catalogue}                                 from '../shared/catalogue';
import {CONTROLLER_HOSTNAME, Messages, MODES, PROTOCOL} from '../shared/protocol';
import type {CasterView, CastRequest, InsertRequest, InventoryView, Mode, SetModeRequest, SmelteryState, WaitingItem} from '../shared/protocol';

import {loadControllerConfig, loadMode, saveMode}       from './config';
import type {ControllerConfig}                          from './config';
import {discoverNetwork}                                from './discovery';
import type {Network}                                   from './discovery';
import {planTick}                                       from './planner';
import type {Action, InputSlot, Plan, PlanContext, Snapshot} from './planner';

/** Fluid of an item by name, or false when it melts into nothing known (cached: tags do not change). */
type FluidCache = Map<string, string | false>;

/**
 * The foundry: reads the Smeltery every tick, plans what the mode allows, does it, and keeps the state
 * the display shows. Peripheral calls that fail (a block broken, a modem off) become alerts, and the
 * network is searched again on the next tick.
 */
export class Controller {
	private mode: Mode;
	private network: Network = {casters: [], problems: []};
	private smeltery?: Smeltery | undefined;
	private casters: Caster[]                    = [];
	private input?: Inventory | undefined;
	private output?: Inventory | undefined;
	private heatOutput?: Inventory | undefined;
	private unknownOutput?: Inventory | undefined;
	private readonly fluidCache: FluidCache      = new Map();
	private readonly logLines: string[]          = [];
	private readonly materials: MaterialMap;
	private readonly guard: AlloyGuard;
	private readonly amounts: CastAmounts;
	private readonly meltingTemperatures: Map<string, number>;
	private readonly fuelTemperature: number | undefined;
	private state: SmelteryState;
	private needsDiscovery                       = true;
	private logFile?: string | undefined;
	private lastAlerts                           = '';

	public constructor(private readonly config: ControllerConfig, catalogue: Catalogue, private readonly modePath?: string) {
		this.materials = materialMapOf(catalogue);
		this.guard     = alloyGuardOf(catalogue);
		this.amounts   = castAmountsOf(catalogue);

		this.meltingTemperatures = temperatureMap(catalogue.meltingTemperatures);
		this.fuelTemperature     = temperatureMap(catalogue.fuels).get(config.fuel);
		this.mode      = loadMode(modePath);
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

	public getState(): SmelteryState {
		return this.state;
	}

	public getMode(): Mode {
		return this.mode;
	}

	public setMode(mode: Mode): void {
		if (mode === this.mode) return;

		this.log(`mode ${this.mode} -> ${mode}`);
		this.mode = mode;
		saveMode(mode, this.modePath);
		this.state.mode = mode;
	}

	/** One reading of the Smeltery, the plan of the mode, and its actions. */
	public tick(): void {
		if (this.needsDiscovery) this.connect();

		const alerts = [...this.network.problems];
		if (this.fuelTemperature === undefined) alerts.push(`unknown fuel '${this.config.fuel}': melting temperatures not checked`);
		let plan: Plan = {actions: [], waiting: [], alerts: []};

		try {
			const snapshot = this.read();

			if (snapshot !== undefined) {
				const context: PlanContext = {
					guard:               this.guard,
					amounts:             this.amounts,
					formatPriority:      this.config.formatPriority,
					meltingTemperature:  (fluid) => this.meltingTemperatures.get(fluid),
				};
				if (this.fuelTemperature !== undefined) context.fuelTemperature = this.fuelTemperature;
				context.reject = {heat: this.heatOutput !== undefined, unknown: this.unknownOutput !== undefined};

				plan = planTick(this.mode, snapshot, context);
				this.execute(plan);
			}
		}
		catch (error) {
			Controller.passTerminate(error);
			alerts.push(`peripheral error: ${Controller.messageOf(error)}`);
			this.needsDiscovery = true;
		}

		this.state = this.buildState([...alerts, ...plan.alerts], plan.waiting);

		const alertText = this.state.alerts.join('; ');
		if (alertText !== this.lastAlerts) {
			this.log(alertText === '' ? 'alerts cleared' : `alerts: ${alertText}`);
			this.lastAlerts = alertText;
		}
	}

	/** Manual mode: sends items of an input slot to the Smeltery, unless they would form an alloy. */
	public insert(request: InsertRequest): number {
		this.requireManual();
		const smeltery = this.smeltery;
		const input    = this.input;
		if (smeltery === undefined || input === undefined) throw new EmberError('Smeltery or input missing', 'SMELTERY_ERROR');

		const detail = input.getItem(request.slot);
		if (detail === undefined) throw new EmberError(`input slot ${request.slot} is empty`, 'SMELTERY_ERROR');

		const fluid = this.fluidOf(detail.name, () => detail);
		if (fluid === undefined) throw new EmberError(`${detail.name} melts into no known fluid`, 'SMELTERY_ERROR');

		const temperature = this.meltingTemperatures.get(fluid);
		if (temperature !== undefined && this.fuelTemperature !== undefined && temperature > this.fuelTemperature) {
			throw new EmberError(`${detail.name} needs ${temperature} K, the fuel gives ${this.fuelTemperature} K`, 'SMELTERY_ERROR');
		}

		const alloy = this.guard.wouldForm(this.presentFluids(smeltery), fluid);
		if (alloy !== undefined) throw new EmberError(`${detail.name} would form ${alloy.result}`, 'SMELTERY_ERROR');

		const moved = smeltery.insert(input, request.slot, request.count);
		this.log(`inserted ${moved} ${detail.name}`);
		return moved;
	}

	/** Manual mode: one casting of a fluid into a caster. */
	public cast(request: CastRequest): number {
		this.requireManual();
		const smeltery = this.smeltery;
		const caster   = this.casters.find((candidate) => candidate.name === request.caster);
		if (smeltery === undefined || caster === undefined) throw new EmberError(`unknown caster ${request.caster}`, 'SMELTERY_ERROR');

		const moved = caster.pour(smeltery, request.fluid);
		if (moved === 0) throw new EmberError(`${caster.name} cannot cast ${request.fluid} now (busy, unknown amount or not enough fluid)`, 'SMELTERY_ERROR');

		this.log(`poured ${moved} mB ${Controller.shortName(request.fluid)} into ${caster.name}`);
		return moved;
	}

	/** Answers the display: state, mode changes, manual commands. Each command replies with the new state. */
	public serve(channel: Channel): void {
		channel.on(Messages.getState, () => this.state);

		channel.on(Messages.setMode, (payload) => {
			const mode = (payload as SetModeRequest | undefined)?.mode;
			if (!MODES.includes(mode as Mode)) throw new EmberError(`unknown mode ${tostring(mode)}`, 'SMELTERY_ERROR');
			this.setMode(mode as Mode);
			return this.state;
		});

		channel.on(Messages.insert, (payload) => {
			this.insert(payload as InsertRequest);
			this.tick();
			return this.state;
		});

		channel.on(Messages.cast, (payload) => {
			this.cast(payload as CastRequest);
			this.tick();
			return this.state;
		});
	}

	private connect(): void {
		this.network        = discoverNetwork(this.config);
		this.needsDiscovery = false;

		const {drain, chute, input, output} = this.network;
		this.smeltery = drain !== undefined && chute !== undefined ? Smeltery.fromNames(drain, chute) : undefined;
		this.input    = input !== undefined ? Inventory.fromName(input) : undefined;
		this.output   = output !== undefined ? Inventory.fromName(output) : undefined;

		const {heatOutput, unknownOutput} = this.network;
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

		const snapshot: Snapshot = {
			fluids:        present.fluids,
			meltingFluids: present.melting,
			casters:       this.casters.map((caster) => ({name: caster.name, state: caster.read()})),
			input:         [],
			outputFree:    this.output?.getFreeSlotCount() ?? 0,
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

		return snapshot;
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
	private readPresent(smeltery: Smeltery): {fluids: FluidStack[]; melting: string[]; uncertain: boolean} {
		const items  = smeltery.chute.list();
		const fluids = smeltery.fluids();

		const melting: string[] = [];
		let uncertain           = false;

		for (const [slot, item] of pairs(items)) {
			const fluid = this.fluidOf(item.name, () => smeltery.chute.getItem(slot));

			if (fluid === undefined && !this.fluidCache.has(item.name)) uncertain = true;
			else if (fluid !== undefined && !melting.includes(fluid)) melting.push(fluid);
		}

		return {fluids, melting, uncertain};
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
		};

		try {
			if (this.smeltery !== undefined) {
				state.fluids  = this.smeltery.fluids();
				state.melting = this.smeltery.melting();
			}

			state.casters = this.casters.map((caster) => Controller.viewOf(caster));

			const input  = Controller.inventoryView(this.input);
			const output = Controller.inventoryView(this.output);
			if (input !== undefined) state.input = input;
			if (output !== undefined) state.output = output;
		}
		catch (error) {
			Controller.passTerminate(error);
			state.alerts.push(`peripheral error: ${Controller.messageOf(error)}`);
			this.needsDiscovery = true;
		}

		return state;
	}

	private emptyState(): SmelteryState {
		return {mode: this.mode, time: 0, fluids: [], melting: [], casters: [], waiting: [], alerts: [], log: []};
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

	private static viewOf(caster: Caster): CasterView {
		const state         = caster.read();
		const view: CasterView = {name: caster.name, kind: caster.kind, status: state.status, amount: state.amount};
		if (state.format !== undefined) view.format = state.format;
		if (state.fluid !== undefined) view.fluid = state.fluid;
		if (state.output !== undefined) view.output = state.output;
		return view;
	}

	private static inventoryView(inventory: Inventory | undefined): InventoryView | undefined {
		if (inventory === undefined) return undefined;
		const size = inventory.size();
		return {name: inventory.name, size, used: size - inventory.getFreeSlotCount()};
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

/** Main loop of the foundry computer: ticks on a timer, answers the display between ticks. */
export function runController(this: void): void {
	const config     = loadControllerConfig();
	const controller = new Controller(config, loadCatalogue());
	controller.setLogFile('/smeltery/controller.log');
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

	let lastSent      = '';
	let lastSentClock = -Infinity;
	let timer         = os.startTimer(0);

	while (true) {
		const event = [...os.pullEvent()];
		if (channel.handleEvent(event)) continue;
		if (event[0] !== 'timer' || event[1] !== timer) continue;

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
}
