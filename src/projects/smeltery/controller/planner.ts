import type {FluidStack}                          from '@core/tank';
import type {AlloyGuard, AlloyRatio, CastAmounts, CasterState} from '@modules/tinkers/index';

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
	/** The craft casters (never poured into but for a craft order), with the tags of the item they hold. */
	craft?: {name: string; state: CasterState; tags: string[]}[];
	input: InputSlot[];
	/** Free slots of the output inventory; results are only cast when there is room for them. */
	outputFree: number;
	/** An item melting could not be identified: nothing goes in this tick, it might alloy. */
	uncertain?: boolean;
	/** Why nothing may go in this tick (the alert is raised by the caller), e.g. an empty fuel tank. */
	pauseInput?: string;
	/** Fluids stored in the reservoirs. */
	stored: {fluid: string; amount: number}[];
	/** Fluids some reservoir can take now. */
	storable: string[];
}

export type StoreReason = 'drain' | 'purge' | 'unblock' | 'melt' | 'alloy' | 'uncastable';

/** Alloy mode: the alloy being made, and how much of it is still wanted. */
export interface AlloyJob {
	result: string;
	/** Every recipe of that alloy (some have several sets of ingredients). */
	ratios: AlloyRatio[];
	/** mB still to make; undefined: until the mode is changed. */
	remaining?: number;
}

export type Action =
	| {kind: 'collect'; caster: string}
	| {kind: 'pour'; caster: string; fluid: string; amount: number; order?: {id: number; format: string}}
	| {kind: 'insert'; slot: number; name: string; count: number; fluid: string; seen: string[]}
	| {kind: 'reject'; slot: number; name: string; count: number; reason: 'heat' | 'unknown'; temperature?: number}
	| {kind: 'store'; fluid: string; amount: number; why: StoreReason}
	| {kind: 'restore'; fluid: string; amount: number; why: 'complete' | 'stock' | 'alloy' | 'order'};

/**
 * Manual mode: an order of the queue, castings of one fluid by format (`done`: already poured). A craft
 * order has one line, of the format 'craft': castings onto the item on `craft.caster`.
 */
export interface OrderJob {
	id: number;
	fluid: string;
	lines: {format: string; count: number; done: number}[];
	craft?: CraftJob;
}

/** A casting onto an item: `input` is an item name or '#tag', `amount` the mB of one casting. */
export interface CraftJob {
	caster: string;
	input: string;
	result: string;
	amount: number;
	consumed: boolean;
}

export const CRAFT_FORMAT = 'craft';

/** Whether an item (its name and tags) is the input of a craft recipe ('minecraft:apple', '#minecraft:planks'). */
export function craftInputMatches(this: void, input: string, item: string | undefined, tags: string[]): boolean {
	if (item === undefined) return false;
	return input.startsWith('#') ? tags.includes(input.substring(1)) : input === item;
}

/** What became of an order this tick (OrderView without its lines). */
export interface OrderStatus {
	id: number;
	status: 'pouring' | 'waiting' | 'queued';
	missing?: number;
	alloy?: string;
	/** A craft order waits for this item on its caster. */
	need?: string;
}

export interface Plan {
	actions: Action[];
	waiting: WaitingItem[];
	alerts: string[];
	/** Stocks too small for any cast auto mode makes: nothing to fix, the Stock tab notes them. */
	smallStocks?: FluidStack[];
	/** A drain or purge has nothing left it can move: the controller ends it. */
	finished?: boolean;
	/** Manual mode: the status of each order, in queue order. */
	orders?: OrderStatus[];
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
	/** Whether a fluid is an alloy of the catalogue (purge sends them to the reservoirs). */
	isAlloy?: (fluid: string) => boolean;
	/** Alloy mode: what to make. */
	alloy?: AlloyJob;
	/** Manual mode: the queue, oldest first. */
	orders?: OrderJob[];
	/** Manual mode: every input slot that is safe goes in this tick (INSERT READY). */
	insertReady?: boolean;
}

/** 'tconstruct:molten_rose_gold' -> 'rose gold', for alerts (the display cuts them at the first ': '). */
function shortFluid(this: void, fluid: string): string {
	return fluid.substring(fluid.indexOf(':') + 1).replace('molten_', '').split('_').join(' ');
}

/** Amount of the smallest cast auto mode can make of `fluid` with the casters there; undefined: none. */
function smallestCast(this: void, fluid: string, snapshot: Snapshot, context: PlanContext): number | undefined {
	let smallest: number | undefined;

	for (const format of context.formatPriority) {
		const amount = context.amounts.get(format, fluid);
		if (amount === undefined || !snapshot.casters.some((caster) => caster.state.format === format)) continue;
		if (smallest === undefined || amount < smallest) smallest = amount;
	}

	return smallest;
}

/** A fluid too small for any cast auto mode can make (a leftover). */
function isLeftover(this: void, fluid: FluidStack, snapshot: Snapshot, context: PlanContext): boolean {
	const smallest = smallestCast(fluid.name, snapshot, context);
	return smallest !== undefined && fluid.amount < smallest;
}

/**
 * Auto: a fluid no caster on the network can cast (no cast of a format it has a recipe for) would only sit
 * in the Smeltery and block the input (an alloy it would form): it goes to the reservoirs at once.
 */
function storeUncastable(this: void, snapshot: Snapshot, context: PlanContext, plan: Plan): void {
	for (const fluid of snapshot.fluids) {
		if (smallestCast(fluid.name, snapshot, context) === undefined) store(fluid, 'uncastable', snapshot, plan);
	}
}

/** Sends a fluid to the reservoirs, or raises an alert when none can take it. */
function store(this: void, fluid: FluidStack, why: StoreReason, snapshot: Snapshot, plan: Plan): boolean {
	if (!snapshot.storable.includes(fluid.name)) {
		plan.alerts.push(`no reservoir for ${shortFluid(fluid.name)}: it stays in the Smeltery`);
		return false;
	}

	plan.actions.push({kind: 'store', fluid: fluid.name, amount: fluid.amount, why});
	return true;
}

/** Drain: every fluid to the reservoirs; finished once nothing can move and nothing is melting. */
function drainAll(this: void, snapshot: Snapshot, plan: Plan): void {
	let moving = false;
	for (const fluid of snapshot.fluids) moving = store(fluid, 'drain', snapshot, plan) || moving;
	if (!moving && snapshot.meltingFluids.length === 0) plan.finished = true;
}

/** Purge: leftovers and alloys to the reservoirs; finished once none of them can move. */
function purgeAll(this: void, snapshot: Snapshot, context: PlanContext, plan: Plan): void {
	let moving = false;

	for (const fluid of snapshot.fluids) {
		if (isLeftover(fluid, snapshot, context) || context.isAlloy?.(fluid.name) === true) {
			moving = store(fluid, 'purge', snapshot, plan) || moving;
		}
	}

	if (!moving) plan.finished = true;
}

/**
 * Gives a stored fluid back when it completes a cast: the same metal is in the Smeltery, below a format it
 * would reach with the stock (a block instead of ingots). Only what is missing comes back. Returns the
 * fluids being completed: they are not cast this tick, the bigger cast comes next.
 */
function restoreAll(this: void, snapshot: Snapshot, context: PlanContext, plan: Plan): Set<string> {
	const completing = new Set<string>();

	for (const fluid of snapshot.fluids) {
		const stock = snapshot.stored.find((entry) => entry.fluid === fluid.name)?.amount ?? 0;
		if (stock <= 0) continue;

		for (const format of context.formatPriority) {
			const amount = context.amounts.get(format, fluid.name);
			if (amount === undefined || !snapshot.casters.some((caster) => caster.state.format === format)) continue;
			if (fluid.amount >= amount) break;

			if (fluid.amount + stock >= amount) {
				plan.actions.push({kind: 'restore', fluid: fluid.name, amount: amount - fluid.amount, why: 'complete'});
				completing.add(fluid.name);
				break;
			}
		}
	}

	return completing;
}

function collectAll(this: void, snapshot: Snapshot, plan: Plan): void {
	for (const caster of [...snapshot.casters, ...snapshot.craft ?? []]) {
		if (caster.state.status === 'blocked') plan.actions.push({kind: 'collect', caster: caster.name});
	}
}

/**
 * Casts each fluid in the biggest format it still fills: while there is enough for a block, only blocks
 * are cast (waiting for a busy basin rather than making ingots); below a block, ingots; below an ingot,
 * nuggets. A format with no caster on the network is skipped. What is left below the smallest stays.
 */
function pourAll(this: void, snapshot: Snapshot, context: PlanContext, plan: Plan, skip: Set<string> = new Set()): void {
	if (snapshot.outputFree <= 0) {
		plan.alerts.push('output full: casting paused');
		return;
	}

	const used = new Set<string>();
	// A caster collected this tick (just before the pours) is free again: it is cast into at once.
	const collected = new Set<string>();
	for (const action of plan.actions) if (action.kind === 'collect') collected.add(action.caster);
	const free = (caster: {name: string; state: CasterState}): boolean =>
		caster.state.status === 'idle' || (caster.state.status === 'blocked' && collected.has(caster.name));

	for (const fluid of snapshot.fluids) {
		if (skip.has(fluid.name)) continue;
		let left = fluid.amount;

		for (const format of context.formatPriority) {
			const amount = context.amounts.get(format, fluid.name);
			const casters = snapshot.casters.filter((caster) => caster.state.format === format);

			if (amount === undefined || casters.length === 0 || left < amount) continue;

			// The biggest format this fluid fills: use its idle casters, never a smaller format meanwhile.
			for (const caster of casters) {
				if (left < amount) break;
				if (used.has(caster.name) || !free(caster)) continue;

				plan.actions.push({kind: 'pour', caster: caster.name, fluid: fluid.name, amount});
				used.add(caster.name);
				left -= amount;
			}

			break;
		}
	}
}

/**
 * Manual mode: the queue. Orders run side by side: each free caster takes the oldest order that still
 * needs its format. A casting pours from the Smeltery; when the Smeltery lacks fluid, what it misses comes
 * back from the reservoirs this tick and the casting is poured on the next one (as auto completes a cast).
 * A fluid that is not in the Smeltery never comes back when it would form an alloy there. An order with
 * more castings left than the Smeltery and the reservoirs can fill waits, the others go on.
 */
function pourOrders(this: void, snapshot: Snapshot, context: PlanContext, plan: Plan): void {
	const orders = context.orders ?? [];
	if (orders.length === 0) return;

	const castingPaused = snapshot.outputFree <= 0;
	if (castingPaused) plan.alerts.push('output full: casting paused');

	const collected = new Set<string>();
	for (const action of plan.actions) if (action.kind === 'collect') collected.add(action.caster);
	const free = (caster: {name: string; state: CasterState}): boolean =>
		!castingPaused && (caster.state.status === 'idle' || (caster.state.status === 'blocked' && collected.has(caster.name)));

	const inside = new Map<string, number>();
	for (const fluid of snapshot.fluids) inside.set(fluid.name, (inside.get(fluid.name) ?? 0) + fluid.amount);
	const stock = new Map<string, number>();
	for (const entry of snapshot.stored) stock.set(entry.fluid, (stock.get(entry.fluid) ?? 0) + entry.amount);
	const present: string[] = [...snapshot.meltingFluids, ...snapshot.fluids.map((fluid) => fluid.name)];

	const used     = new Set<string>();
	const restores = new Map<string, number>();
	const pours: Action[] = [];
	plan.orders = [];

	for (const order of orders) {
		const fluid = order.fluid;
		// Not in the Smeltery: the stock may only come back if it forms no alloy with what is there.
		const alloy = present.includes(fluid) ? undefined : context.guard.wouldForm(present, fluid);
		const craft = order.craft;
		const craftCaster = craft !== undefined ? snapshot.craft?.find((caster) => caster.name === craft.caster) : undefined;
		let pouring = craft !== undefined
		              ? craftCaster?.state.status === 'busy'
		              : snapshot.casters.some((caster) => caster.state.status === 'busy' && caster.state.fluid === fluid
		                  && order.lines.some((line) => line.format === caster.state.format));
		let remaining = 0;
		let need: string | undefined;

		for (const line of order.lines) {
			const amount = craft !== undefined ? craft.amount : context.amounts.get(line.format, fluid);
			if (amount === undefined) continue;
			let left = line.count - line.done;
			// A craft order pours into its own caster only, once it holds the item (the player puts it).
			let candidates = snapshot.casters.filter((caster) => caster.state.format === line.format);
			if (craft !== undefined) {
				candidates = craftCaster !== undefined ? [craftCaster] : [];
				const holds = craftCaster !== undefined && craftInputMatches(craft.input, craftCaster.state.cast, craftCaster.tags);
				// A consumed item is gone once cast: the order waits for the player to put another one.
				if (left > 0 && craftCaster !== undefined && craftCaster.state.status !== 'busy' && !holds) {
					need = craft.input;
					candidates = [];
				}
			}

			for (const caster of candidates) {
				if (left <= 0) break;
				if (used.has(caster.name) || !free(caster)) continue;

				const have = inside.get(fluid) ?? 0;
				if (have >= amount) {
					inside.set(fluid, have - amount);
					pours.push({kind: 'pour', caster: caster.name, fluid, amount, order: {id: order.id, format: line.format}});
				}
				else {
					const stored = stock.get(fluid) ?? 0;
					if (alloy !== undefined || have + stored < amount) break;
					restores.set(fluid, (restores.get(fluid) ?? 0) + amount - have);
					stock.set(fluid, stored - (amount - have));
					inside.set(fluid, 0);
					if (!present.includes(fluid)) present.push(fluid);
				}
				used.add(caster.name);
				left--;
				pouring = true;
			}

			remaining += left * amount;
		}

		const available = (inside.get(fluid) ?? 0) + (alloy !== undefined ? 0 : stock.get(fluid) ?? 0);
		const status: OrderStatus = {id: order.id, status: pouring ? 'pouring' : 'queued'};
		if (remaining > available) {
			status.status  = 'waiting';
			status.missing = remaining - available;
			if (alloy !== undefined) status.alloy = alloy.result;
		}
		if (need !== undefined && !pouring) {
			status.status = 'waiting';
			status.need   = need;
		}
		plan.orders.push(status);
	}

	restores.forEach((amount, fluid) => plan.actions.push({kind: 'restore', fluid, amount, why: 'order'}));
	for (const pour of pours) plan.actions.push(pour);
}

/**
 * Manual mode, INSERT READY: every input slot that is safe goes in (checked against the Smeltery, what is
 * melting and what this same plan sends); the others stay, nothing is rejected or stored.
 */
function insertReady(this: void, snapshot: Snapshot, context: PlanContext, plan: Plan): void {
	if (snapshot.pauseInput !== undefined) return;
	if (snapshot.uncertain === true) {
		plan.alerts.push('an item melting cannot be identified: input paused for this tick');
		return;
	}

	const present: string[] = [...snapshot.meltingFluids, ...snapshot.fluids.map((fluid) => fluid.name)];
	for (const item of snapshot.input) {
		if (assessItem(item, present, context).status !== 'ok') continue;
		plan.actions.push({kind: 'insert', slot: item.slot, name: item.name, count: item.count, fluid: item.fluid!, seen: [...present]});
		present.push(item.fluid!);
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
	/** Ingredients of that alloy. */
	ingredients?: string[];
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
	if (alloy !== undefined) return {status: 'alloy', alloy: alloy.result, ingredients: alloy.ingredients};

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
	const unblocking = new Set<string>();

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
				unblock(item, assessment, snapshot, context, plan, unblocking);
				break;
			default:
				plan.actions.push({kind: 'insert', slot: item.slot, name: item.name, count: item.count, fluid: item.fluid!, seen: [...present]});
				present.push(item.fluid!);
		}
	}
}

/**
 * An item waits for an alloy: the other ingredients that are only leftovers in the Smeltery (molten, below
 * the smallest cast) go to the reservoirs, and the item goes in on a later tick. Bigger amounts stay: they
 * will be cast anyway; ingredients still melting cannot be moved.
 */
function unblock(
	this: void, item: InputSlot, assessment: Assessment, snapshot: Snapshot, context: PlanContext, plan: Plan, done: Set<string>,
): void {
	for (const ingredient of assessment.ingredients ?? []) {
		if (ingredient === item.fluid || done.has(ingredient)) continue;

		const fluid = snapshot.fluids.find((candidate) => candidate.name === ingredient);
		if (fluid === undefined || !isLeftover(fluid, snapshot, context)) continue;

		done.add(ingredient);
		store(fluid, 'unblock', snapshot, plan);
	}
}

/** Melt: what is molten goes to the reservoirs; the input goes in as in auto, unless a fluid found no room. */
function meltAll(this: void, snapshot: Snapshot, context: PlanContext, plan: Plan): void {
	let full = false;
	for (const fluid of snapshot.fluids) full = !store(fluid, 'melt', snapshot, plan) || full;

	if (full || snapshot.pauseInput !== undefined) return;
	if (snapshot.uncertain === true) {
		plan.alerts.push('an item melting cannot be identified: input paused for this tick');
		return;
	}
	insertAll(snapshot, context, plan);
}

/** Recipe batches dosed in at once (8 x 180 mB of rose gold: 16 ingots). */
const ALLOY_BATCHES = 8;
/** No more ingredients while this much of the alloy waits for the casters. */
const ALLOY_BUFFER = 810;

function amountIn(this: void, snapshot: Snapshot, fluid: string): number {
	return snapshot.fluids.find((candidate) => candidate.name === fluid)?.amount ?? 0;
}

/** The recipe of the job whose every input can be found (Smeltery, stock or input); the first one otherwise. */
function pickRatio(this: void, job: AlloyJob, snapshot: Snapshot): AlloyRatio | undefined {
	const found = (fluid: string): boolean => amountIn(snapshot, fluid) > 0
		|| snapshot.stored.some((entry) => entry.fluid === fluid && entry.amount > 0)
		|| snapshot.input.some((item) => item.fluid === fluid);
	return job.ratios.find((ratio) => ratio.inputs.every((input) => found(input.fluid))) ?? job.ratios[0];
}

/**
 * Alloy: only the chosen alloy is cast. Its ingredients are dosed in batches of the recipe, the stock
 * first (exact amounts), then input items of the ingredient that lacks most. Nothing that would form
 * another alloy goes in (the fluids in its way go to the reservoirs). Once the wanted amount is made, the
 * alloy and ingredients left go to the reservoirs, and the mode is finished.
 */
function alloyTick(this: void, snapshot: Snapshot, context: PlanContext, plan: Plan): void {
	const job   = context.alloy;
	const ratio = job !== undefined ? pickRatio(job, snapshot) : undefined;
	if (job === undefined || ratio === undefined) {
		plan.alerts.push('alloy mode: no alloy chosen');
		return;
	}
	const ingredients = ratio.inputs.map((input) => input.fluid);

	if (job.remaining !== undefined && job.remaining <= 0) {
		let moving = false;
		for (const fluid of snapshot.fluids) {
			if (fluid.name === job.result || ingredients.includes(fluid.name)) moving = store(fluid, 'alloy', snapshot, plan) || moving;
		}
		if (!moving) plan.finished = true;
		return;
	}

	// Never more than still wanted is cast (450 mB wanted: 5 ingots, not the 540 mB three batches gave).
	const others  = new Set(snapshot.fluids.map((fluid) => fluid.name).filter((name) => name !== job.result));
	const wanted  = job.remaining;
	const capOf   = (fluid: FluidStack): FluidStack => (fluid.name === job.result && wanted !== undefined
	                                                    ? {name: fluid.name, amount: Math.min(fluid.amount, wanted)}
	                                                    : fluid);
	const capped  = {...snapshot, fluids: snapshot.fluids.map(capOf)};
	pourAll(capped, context, plan, others);

	const made = amountIn(snapshot, job.result);
	if (made >= ALLOY_BUFFER) return;

	let batches = ALLOY_BATCHES;
	if (job.remaining !== undefined) batches = Math.min(batches, Math.ceil((job.remaining - made) / ratio.amount));
	if (batches <= 0) return;

	// Batches of the recipe each ingredient is worth; the one that lacks most sets the goal.
	const units = ratio.inputs.map((input) => amountIn(snapshot, input.fluid) / input.amount);
	const goal  = Math.min(...units) + batches;

	const present: string[] = [...snapshot.meltingFluids, ...snapshot.fluids.map((fluid) => fluid.name)];
	const missing: string[] = [];
	const inputOpen = snapshot.pauseInput === undefined && snapshot.uncertain !== true;

	ratio.inputs.forEach((input, index) => {
		const need = Math.ceil((goal - units[index]!) * input.amount);
		if (need <= 0) return;

		const blocking = context.guard.wouldForm(present, input.fluid, job.result);
		if (blocking !== undefined) {
			// Another alloy would form: the fluids in its way that are not ours go to the reservoirs first.
			for (const name of blocking.ingredients) {
				const fluid = snapshot.fluids.find((candidate) => candidate.name === name);
				if (fluid !== undefined && name !== job.result && !ingredients.includes(name)) store(fluid, 'unblock', snapshot, plan);
			}
			return;
		}

		const stock = snapshot.stored.find((entry) => entry.fluid === input.fluid)?.amount ?? 0;
		if (stock > 0) plan.actions.push({kind: 'restore', fluid: input.fluid, amount: Math.min(need, stock), why: 'alloy'});
		if (stock >= need) return;

		const item = snapshot.input.find((candidate) => candidate.fluid === input.fluid);
		if (item === undefined) {
			if (stock <= 0) missing.push(shortFluid(input.fluid));
			return;
		}
		if (!inputOpen || snapshot.meltingFluids.includes(input.fluid)) return;

		const temperature = context.meltingTemperature(input.fluid);
		if (temperature !== undefined && context.fuelTemperature !== undefined && temperature > context.fuelTemperature) {
			wait(plan, item, 'heat', {temperature});
			return;
		}
		plan.actions.push({kind: 'insert', slot: item.slot, name: item.name, count: item.count, fluid: input.fluid, seen: [...present]});
		present.push(input.fluid);
	});

	if (missing.length > 0) plan.alerts.push(`${shortFluid(job.result)}: missing ${missing.join(', ')}`);
}

/**
 * Empties the reservoirs once the input has nothing left to melt: one stored fluid at a time comes back
 * whole (the biggest stock first) and is cast on the next ticks like any other. Only when nothing in the
 * Smeltery can still be cast (what is there are leftovers) and nothing is melting. A fluid that would form
 * an alloy with what is there does not come back: the leftovers it would alloy with go to the reservoirs
 * first. A stock too small for any cast stays where it is (noted for the Stock tab, not an alert).
 */
function takeStock(this: void, snapshot: Snapshot, context: PlanContext, plan: Plan): void {
	if (snapshot.meltingFluids.length > 0 || snapshot.stored.length === 0) return;
	if (plan.actions.some((action) => action.kind !== 'collect' && action.kind !== 'reject')) return;
	if (plan.waiting.some((item) => item.reason === 'alloy')) return;

	for (const fluid of snapshot.fluids) {
		const smallest = smallestCast(fluid.name, snapshot, context);
		if (smallest !== undefined && fluid.amount >= smallest) return;
	}

	const present = snapshot.fluids.map((fluid) => fluid.name);
	const stocks  = [...snapshot.stored].sort((a, b) => b.amount - a.amount);

	for (const stock of stocks) {
		const smallest = smallestCast(stock.fluid, snapshot, context);
		if (smallest === undefined || stock.amount <= 0) continue;

		const inside = snapshot.fluids.find((fluid) => fluid.name === stock.fluid)?.amount ?? 0;
		if (stock.amount + inside < smallest) {
			plan.smallStocks ??= [];
			plan.smallStocks.push({name: stock.fluid, amount: stock.amount});
			continue;
		}

		const alloy = context.guard.wouldForm(present, stock.fluid);
		if (alloy === undefined) {
			plan.actions.push({kind: 'restore', fluid: stock.fluid, amount: stock.amount, why: 'stock'});
			return;
		}

		let unblocking = false;
		for (const ingredient of alloy.ingredients) {
			const fluid = snapshot.fluids.find((candidate) => candidate.name === ingredient);
			if (ingredient === stock.fluid || fluid === undefined || !isLeftover(fluid, snapshot, context)) continue;
			unblocking = store(fluid, 'unblock', snapshot, plan) || unblocking;
		}
		if (unblocking) return;
	}
}

/**
 * What to do this tick. Collecting comes first (a blocked caster is freed), then casting, then the input:
 * idle:   nothing;
 * manual: collect, the orders of the queue, INSERT READY; the rest comes from the display;
 * lock:   collect and cast, nothing new goes in;
 * drain:  collect, every fluid to the reservoirs;
 * purge:  collect, leftovers and alloys to the reservoirs;
 * melt:   collect, every fluid to the reservoirs, and the input melted like in auto (nothing is cast);
 * alloy:  collect, the chosen alloy only: its ingredients dosed in, from the stock first, and cast;
 * auto:   collect, complete a cast from the stock, cast, store what no caster can cast, and melt the input
 *         that is safe (a leftover that blocks an input goes to the reservoirs); once the input has nothing
 *         left to melt, the stock.
 */
export function planTick(this: void, mode: Mode, snapshot: Snapshot, context: PlanContext): Plan {
	const plan: Plan = {actions: [], waiting: [], alerts: []};

	if (mode === 'idle') return plan;

	collectAll(snapshot, plan);
	if (mode === 'manual') {
		pourOrders(snapshot, context, plan);
		if (context.insertReady === true) insertReady(snapshot, context, plan);
		return plan;
	}

	if (mode === 'drain') {
		drainAll(snapshot, plan);
		return plan;
	}
	if (mode === 'purge') {
		purgeAll(snapshot, context, plan);
		return plan;
	}
	if (mode === 'melt') {
		meltAll(snapshot, context, plan);
		return plan;
	}
	if (mode === 'alloy') {
		alloyTick(snapshot, context, plan);
		return plan;
	}

	const completing = mode === 'auto' ? restoreAll(snapshot, context, plan) : new Set<string>();
	pourAll(snapshot, context, plan, completing);
	if (mode === 'lock') return plan;
	storeUncastable(snapshot, context, plan);

	if (snapshot.pauseInput !== undefined) return plan;

	if (snapshot.uncertain === true) {
		plan.alerts.push('an item melting cannot be identified: input paused for this tick');
		return plan;
	}

	insertAll(snapshot, context, plan);
	if (mode === 'auto') takeStock(snapshot, context, plan);
	return plan;
}
