import type {FluidStack}                          from '@core/tank';
import type {AlloyGuard, CastAmounts, CasterState} from '@modules/tinkers/index';

import type {InputItemView, Mode, WaitingItem}     from '../shared/protocol';

export interface InputSlot {
	slot: number;
	name: string;
	count: number;
	/** Fluid it melts into; undefined when the catalogue cannot tell. */
	fluid?: string;
}

/** Everything the planner needs, read once per tick. */
export interface Snapshot {
	/** Bottom first. */
	fluids: FluidStack[];
	/** Fluids of the items still melting (they count for the alloy guard). */
	meltingFluids: string[];
	casters: {name: string; state: CasterState}[];
	input: InputSlot[];
	/** Free slots of the output inventory; results are only cast when there is room for them. */
	outputFree: number;
	/** An item melting could not be identified: nothing goes in this tick, it might alloy. */
	uncertain?: boolean;
	/** Why nothing may go in this tick (the alert is raised by the caller), e.g. an empty fuel tank. */
	pauseInput?: string;
}

export type Action =
	| {kind: 'collect'; caster: string}
	| {kind: 'pour'; caster: string; fluid: string; amount: number}
	| {kind: 'insert'; slot: number; name: string; count: number; fluid: string; seen: string[]}
	| {kind: 'reject'; slot: number; name: string; count: number; reason: 'heat' | 'unknown'; temperature?: number};

export interface Plan {
	actions: Action[];
	waiting: WaitingItem[];
	alerts: string[];
}

export interface PlanContext {
	guard: AlloyGuard;
	amounts: CastAmounts;
	/** Formats auto mode casts, biggest first. */
	formatPriority: string[];
	/** Temperature the Smeltery needs to melt into a fluid; undefined: not checked. */
	meltingTemperature: (fluid: string) => number | undefined;
	/** Temperature of the fuel; undefined when unknown (nothing is then checked). */
	fuelTemperature?: number;
	/** Rejected items (too hot, unknown) leave the input when an inventory is set for them. */
	reject?: {heat: boolean; unknown: boolean};
}

function collectAll(this: void, snapshot: Snapshot, plan: Plan): void {
	for (const caster of snapshot.casters) {
		if (caster.state.status === 'blocked') plan.actions.push({kind: 'collect', caster: caster.name});
	}
}

/**
 * Casts each fluid in the biggest format it still fills: while there is enough for a block, only blocks
 * are cast (waiting for a busy basin rather than making ingots); below a block, ingots; below an ingot,
 * nuggets. A format with no caster on the network is skipped. What is left below the smallest stays.
 */
function pourAll(this: void, snapshot: Snapshot, context: PlanContext, plan: Plan): void {
	if (snapshot.outputFree <= 0) {
		plan.alerts.push('output full: casting paused');
		return;
	}

	const used = new Set<string>();

	for (const fluid of snapshot.fluids) {
		let left = fluid.amount;

		for (const format of context.formatPriority) {
			const amount = context.amounts.get(format, fluid.name);
			const casters = snapshot.casters.filter((caster) => caster.state.format === format);

			if (amount === undefined || casters.length === 0 || left < amount) continue;

			// The biggest format this fluid fills: use its idle casters, never a smaller format meanwhile.
			for (const caster of casters) {
				if (left < amount) break;
				if (used.has(caster.name) || caster.state.status !== 'idle') continue;

				plan.actions.push({kind: 'pour', caster: caster.name, fluid: fluid.name, amount});
				used.add(caster.name);
				left -= amount;
			}

			break;
		}
	}
}

function wait(this: void, plan: Plan, item: InputSlot, reason: WaitingItem['reason'], detail: {alloy?: string; temperature?: number} = {}): void {
	for (const waiting of plan.waiting) {
		if (waiting.name === item.name && waiting.reason === reason) {
			waiting.count += item.count;
			return;
		}
	}

	const waiting: WaitingItem = {name: item.name, count: item.count, reason};
	if (detail.alloy !== undefined) waiting.alloy = detail.alloy;
	if (detail.temperature !== undefined) waiting.temperature = detail.temperature;
	plan.waiting.push(waiting);
}

export interface Assessment {
	status: InputItemView['status'];
	alloy?: string;
	temperature?: number;
}

/** What would happen if `item` went into a Smeltery holding `present`: the checks in their order. */
export function assessItem(this: void, item: InputSlot, present: string[], context: PlanContext): Assessment {
	if (item.fluid === undefined) return {status: 'unknown'};

	const temperature = context.meltingTemperature(item.fluid);
	if (temperature !== undefined && context.fuelTemperature !== undefined && temperature > context.fuelTemperature) {
		return {status: 'heat', temperature};
	}

	const alloy = context.guard.wouldForm(present, item.fluid);
	if (alloy !== undefined) return {status: 'alloy', alloy: alloy.result};

	return {status: 'ok'};
}

/** Every input slot judged on its own against the Smeltery as it is (what the Manual tab shows). */
export function assessInput(this: void, snapshot: Snapshot, context: PlanContext): InputItemView[] {
	const present: string[] = [...snapshot.meltingFluids];
	for (const fluid of snapshot.fluids) present.push(fluid.name);

	return snapshot.input.map((item) => {
		const assessment = assessItem(item, present, context);
		const view: InputItemView = {slot: item.slot, name: item.name, count: item.count, status: assessment.status};
		if (item.fluid !== undefined) view.fluid = item.fluid;
		if (assessment.alloy !== undefined) view.alloy = assessment.alloy;
		if (assessment.temperature !== undefined) view.temperature = assessment.temperature;
		return view;
	});
}

/**
 * Sends the input to the Smeltery, item by item, unless its fluid is unknown, it needs more heat than the
 * fuel gives (it would sit in the Smeltery unmelted), or it would form an alloy with what is there, still
 * melting, or already sent in this same plan.
 */
function insertAll(this: void, snapshot: Snapshot, context: PlanContext, plan: Plan): void {
	const present: string[] = [...snapshot.meltingFluids];
	for (const fluid of snapshot.fluids) present.push(fluid.name);

	for (const item of snapshot.input) {
		const assessment = assessItem(item, present, context);

		switch (assessment.status) {
			case 'unknown':
				if (context.reject?.unknown === true) plan.actions.push({kind: 'reject', slot: item.slot, name: item.name, count: item.count, reason: 'unknown'});
				else wait(plan, item, 'unknown');
				break;
			case 'heat':
				if (context.reject?.heat === true) {
					const reject: Action = {kind: 'reject', slot: item.slot, name: item.name, count: item.count, reason: 'heat'};
					if (assessment.temperature !== undefined) reject.temperature = assessment.temperature;
					plan.actions.push(reject);
				}
				else {
					wait(plan, item, 'heat', assessment.temperature !== undefined ? {temperature: assessment.temperature} : {});
				}
				break;
			case 'alloy':
				wait(plan, item, 'alloy', assessment.alloy !== undefined ? {alloy: assessment.alloy} : {});
				break;
			default:
				plan.actions.push({kind: 'insert', slot: item.slot, name: item.name, count: item.count, fluid: item.fluid!, seen: [...present]});
				present.push(item.fluid!);
		}
	}
}

/**
 * What to do this tick. Collecting comes first (a blocked caster is freed), then casting, then the input:
 * idle:   nothing;
 * manual: collect only, the rest comes from the display;
 * lock:   collect and cast, nothing new goes in;
 * auto:   collect, cast, and melt the input that is safe.
 */
export function planTick(this: void, mode: Mode, snapshot: Snapshot, context: PlanContext): Plan {
	const plan: Plan = {actions: [], waiting: [], alerts: []};

	if (mode === 'idle') return plan;

	collectAll(snapshot, plan);
	if (mode === 'manual') return plan;

	pourAll(snapshot, context, plan);
	if (mode === 'lock') return plan;

	if (snapshot.pauseInput !== undefined) return plan;

	if (snapshot.uncertain === true) {
		plan.alerts.push('an item melting cannot be identified: input paused for this tick');
		return plan;
	}

	insertAll(snapshot, context, plan);
	return plan;
}
