import {ButtonComponent, PaginationComponent} from '@modules/ui/components';
import type {Rect}                           from '@modules/ui/types';

import type {CastRequest, InputItemView, InsertRequest, Mode, SmelteryState} from '../shared/protocol';
import {MODES}                               from '../shared/protocol';

import {attentionLines, fluidColor, fluidLabel, formatLabel, Glyph, groupCasters, itemLabel, parseLogLine, textOn} from './model';
import type {CastGroup, LogKind}             from './model';
import {AbsoluteLayout, PaintComponent}      from './widgets';
import type {Painter}                        from './widgets';

export const SCREEN_WIDTH  = 79;
export const SCREEN_HEIGHT = 38;

type Tab = 'overview' | 'modes' | 'manual' | 'log';

/** What the screen asks the controller; the answers come back through setState(). */
export interface ScreenActions {
	setMode(mode: Mode): void;
	insert(request: InsertRequest): void;
	cast(request: CastRequest): void;
}

interface Confirm {
	item: InputItemView;
	step: 1 | 2;
	/** os.clock() after which the second step is cancelled. */
	deadline: number;
}

const TABS: [Tab, string][] = [['overview', 'Overview'], ['modes', 'Modes'], ['manual', 'Manual'], ['log', 'Log']];

/** Card texts fit the 17 columns of a card (16 with its margin). */
const MODE_CARDS: Record<Mode, {color: number; lines: string[]}> = {
	idle:   {color: colors.lightGray, lines: ['Full stop.', 'Nothing moves.']},
	auto:   {color: colors.lime, lines: ['Melts the input', 'and casts pure', 'metals.']},
	manual: {color: colors.orange, lines: ['You insert and', 'cast from the', 'Manual tab.']},
	lock:   {color: colors.red, lines: ['Nothing new goes', 'in; the casts', 'under way finish.']},
	drain:  {color: colors.lightBlue, lines: ['Every fluid to', 'the reservoirs,', 'then idle.']},
	purge:  {color: colors.purple, lines: ['Leftovers and', 'alloys to the', 'reservoirs.']},
};

const LOG_COLORS: Record<LogKind, number> = {
	in:     colors.lightBlue,
	cast:   colors.white,
	out:    colors.lime,
	reject: colors.orange,
	forced: colors.red,
	mode:   colors.yellow,
	other:  colors.lightGray,
};

const CASTS_PER_PAGE  = 4;
const ITEMS_PER_PAGE  = 6;
const LOG_LINES       = 13;
const CONFIRM_SECONDS = 10;
const OFFLINE_SECONDS = 12;

/** Mode cards, four per row: the top-left corner of the `index`-th one. */
function cardPlace(this: void, index: number): {x: number; y: number} {
	return {x: 3 + (index % 4) * 19, y: 8 + Math.floor(index / 4) * 12};
}

const FULL_SCREEN: Rect = {x: 1, y: 1, width: SCREEN_WIDTH, height: SCREEN_HEIGHT};

/**
 * The monitor of the Smeltery, drawn to the character (79 x 38 at text scale 0.5): paint components draw,
 * EmberCore buttons and paginations take the touches. All coordinates are 1-based, as on the monitor.
 */
export class SmelteryScreen {
	public readonly root = new AbsoluteLayout(SCREEN_WIDTH, SCREEN_HEIGHT);

	private state?: SmelteryState | undefined;
	private lastState = -Infinity;
	private tab: Tab  = 'overview';
	private castPage  = 1;
	private itemPage  = 1;
	private logOffset = 0;
	private fluid?: string | undefined;
	private format?: string | undefined;
	private confirm?: Confirm | undefined;
	private message?: {text: string; color: number; until: number} | undefined;

	private readonly allButtons: ButtonComponent[] = [];
	private readonly tabButtons                    = new Map<Tab, ButtonComponent>();
	private readonly modeButtons                   = new Map<Mode, ButtonComponent>();
	private readonly itemButtons: ButtonComponent[] = [];
	private readonly fluidButtons: ButtonComponent[] = [];
	private readonly formatButtons: ButtonComponent[] = [];
	private readonly castButton: ButtonComponent;
	private readonly logUp: ButtonComponent;
	private readonly logDown: ButtonComponent;
	private readonly confirmYes: ButtonComponent;
	private readonly confirmNo: ButtonComponent;
	private readonly castPages: PaginationComponent;
	private readonly itemPages: PaginationComponent;

	public constructor(private readonly actions: ScreenActions) {
		this.root.place(new PaintComponent({paint: (painter) => this.paint(painter)}), FULL_SCREEN);

		let tabX = 27;
		for (const [tab, label] of TABS) {
			this.tabButtons.set(tab, this.button(label, {x: tabX, y: 2, width: label.length, height: 1}, () => this.showTab(tab)));
			tabX += label.length + 4;
		}

		MODES.forEach((mode, index) => {
			const card = cardPlace(index);
			this.modeButtons.set(mode, this.button(' Activate ', {x: card.x + 1, y: card.y + 6, width: 10, height: 1}, () => this.actions.setMode(mode)));
		});

		this.castPages = this.root.place(new PaginationComponent({
			page: 1, pageSize: CASTS_PER_PAGE, totalItems: 0, foregroundColor: colors.lightGray, backgroundColor: colors.black,
			onPageChange: (page) => {
				this.castPage = page;
			},
		}), {x: 59, y: 19, width: 11, height: 1});

		// TSTL compiles `for (let ...)` to one shared Lua variable: closures must capture a per-iteration const.
		for (let row = 0; row < ITEMS_PER_PAGE; row++) {
			const index = row;
			this.itemButtons.push(this.button('', {x: 37, y: 8 + index * 3, width: 8, height: 1}, () => this.pressItem(index)));
		}

		this.itemPages = this.root.place(new PaginationComponent({
			page: 1, pageSize: ITEMS_PER_PAGE, totalItems: 0, foregroundColor: colors.lightGray, backgroundColor: colors.black,
			onPageChange: (page) => {
				this.itemPage = page;
			},
		}), {x: 3, y: 27, width: 11, height: 1});

		for (let row = 0; row < 5; row++) {
			const index = row;
			this.fluidButtons.push(this.button('', {x: 58, y: 10 + index * 2, width: 20, height: 1}, () => this.pickFluid(index)));
			this.formatButtons.push(this.button('', {x: 53, y: 22 + index * 2, width: 25, height: 1}, () => this.pickFormat(index)));
		}

		this.castButton = this.button('', {x: 53, y: 34, width: 25, height: 1}, () => this.pressCast());
		this.logUp      = this.button(` ${Glyph.up} `, {x: 70, y: 5, width: 3, height: 1}, () => this.scrollLog(1));
		this.logDown    = this.button(` ${Glyph.down} `, {x: 74, y: 5, width: 3, height: 1}, () => this.scrollLog(-1));

		// Added last: drawn and hit above everything else.
		this.root.place(new PaintComponent({paint: (painter) => this.paintConfirm(painter)}), FULL_SCREEN);
		this.confirmYes = this.button('', {x: 18, y: 22, width: 16, height: 1}, () => this.confirmStep());
		this.confirmNo  = this.button(' Cancel ', {x: 47, y: 22, width: 8, height: 1}, () => this.cancelConfirm());

		this.sync();
	}

	public setState(state: SmelteryState): void {
		this.state     = state;
		this.lastState = os.clock();
		this.sync();
	}

	/** A short message in the bottom line (command results, errors). */
	public notify(text: string, color: number = colors.lightGray): void {
		this.message = {text, color, until: os.clock() + 6};
	}

	/** Called every second: countdowns and the online dot. */
	public tick(): void {
		if (this.confirm !== undefined && this.confirm.step === 2 && os.clock() > this.confirm.deadline) {
			this.confirm = undefined;
			this.notify('force cancelled: not confirmed in time');
		}
		this.sync();
	}

	// ------------------------------------------------------------------ actions

	private showTab(tab: Tab): void {
		this.tab = tab;
		this.sync();
	}

	private pageItems(): InputItemView[] {
		const items = this.state?.inputItems ?? [];
		const start = (this.itemPage - 1) * ITEMS_PER_PAGE;
		return items.slice(start, start + ITEMS_PER_PAGE);
	}

	private pressItem(row: number): void {
		const item = this.pageItems()[row];
		if (item === undefined) return;

		if (item.status === 'ok') this.actions.insert({slot: item.slot});
		else if (item.status === 'alloy' || item.status === 'heat') this.confirm = {item, step: 1, deadline: 0};
		this.sync();
	}

	private confirmStep(): void {
		const confirm = this.confirm;
		if (confirm === undefined) return;

		if (confirm.step === 1) {
			this.confirm = {item: confirm.item, step: 2, deadline: os.clock() + CONFIRM_SECONDS};
		}
		else {
			this.confirm = undefined;
			this.actions.insert({slot: confirm.item.slot, force: true});
		}
		this.sync();
	}

	private cancelConfirm(): void {
		this.confirm = undefined;
		this.sync();
	}

	private fluids(): {name: string; amount: number}[] {
		return (this.state?.fluids ?? []).slice(0, this.fluidButtons.length);
	}

	private castGroups(): CastGroup[] {
		return groupCasters(this.state?.casters ?? [], this.state?.autoFormats ?? []);
	}

	private pickFluid(row: number): void {
		this.fluid = this.fluids()[row]?.name;
		this.sync();
	}

	private pickFormat(row: number): void {
		this.format = this.castGroups()[row]?.format;
		this.sync();
	}

	private pressCast(): void {
		if (this.fluid !== undefined && this.format !== undefined) this.actions.cast({fluid: this.fluid, format: this.format});
	}

	private scrollLog(delta: number): void {
		const lines    = this.state?.log.length ?? 0;
		this.logOffset = Math.max(0, Math.min(Math.max(0, lines - LOG_LINES), this.logOffset + delta));
		this.sync();
	}

	// ------------------------------------------------------------- button state

	private button(label: string, rect: Rect, onPress: () => void): ButtonComponent {
		const button = this.root.place(new ButtonComponent({
			label, padding: 0, foregroundColor: colors.white, backgroundColor: colors.black, onPress,
		}), rect);
		this.allButtons.push(button);
		return button;
	}

	private show(button: ButtonComponent, visible: boolean, label?: string, foreground?: number, background?: number): void {
		const patch: {visible: boolean; label?: string; foregroundColor?: number; backgroundColor?: number} = {visible};
		if (label !== undefined) patch.label = label;
		if (foreground !== undefined) patch.foregroundColor = foreground;
		if (background !== undefined) patch.backgroundColor = background;
		button.setProps(patch);
	}

	/** Puts every button and pagination in line with the tab, the state and the dialog. */
	private sync(): void {
		const state = this.state;
		const modal = this.confirm !== undefined;

		for (const [tab, button] of this.tabButtons) this.show(button, true, undefined, tab === this.tab ? colors.white : colors.gray);

		for (const [mode, button] of this.modeButtons) {
			this.show(button, this.tab === 'modes' && state !== undefined && state.mode !== mode, ' Activate ', colors.black, MODE_CARDS[mode].color);
		}

		const groups = this.castGroups();
		this.castPages.setProps({visible: this.tab === 'overview' && groups.length > CASTS_PER_PAGE, totalItems: groups.length});
		this.castPage = Math.min(this.castPage, Math.max(1, Math.ceil(groups.length / CASTS_PER_PAGE)));

		const manual = this.tab === 'manual';
		const items  = this.pageItems();
		const itemCount = state?.inputItems.length ?? 0;
		this.itemPages.setProps({visible: manual && itemCount > ITEMS_PER_PAGE, totalItems: itemCount});

		this.itemButtons.forEach((button, row) => {
			const item = items[row];
			if (!manual || item === undefined || item.status === 'unknown') this.show(button, false);
			else if (item.status === 'ok') this.show(button, true, ' Insert ', colors.black, colors.lime);
			else this.show(button, true, ' Force  ', colors.white, colors.red);
		});

		const fluids = this.fluids();
		this.fluidButtons.forEach((button, row) => {
			const fluid = fluids[row];
			const label = fluid === undefined ? '' : fluidLabel(fluid.name);
			const color = fluid?.name === this.fluid ? colors.white : colors.lightGray;
			this.show(button, manual && fluid !== undefined, label.padEnd(20), color);
		});

		this.formatButtons.forEach((button, row) => {
			const group = groups[row];
			const label = group === undefined ? '' : `${formatLabel(group.format).padEnd(16)} x${group.free}`;
			const color = group?.format === this.format ? colors.white : colors.lightGray;
			this.show(button, manual && group !== undefined, label.padEnd(25), color);
		});

		const canCast = this.fluid !== undefined && this.format !== undefined;
		const castLabel = canCast ? ` Cast ${fluidLabel(this.fluid!)} ${formatLabel(this.format!)} ` : ' Pick a fluid and a cast ';
		this.show(this.castButton, manual, castLabel.substring(0, 25), colors.black, canCast ? colors.orange : colors.gray);

		this.show(this.logUp, this.tab === 'log', undefined, colors.lightGray, colors.gray);
		this.show(this.logDown, this.tab === 'log', undefined, colors.lightGray, colors.gray);

		const confirm = this.confirm;
		this.show(this.confirmYes, modal, confirm?.step === 2 ? ' Force insert ' : ' Continue ', colors.white, confirm?.step === 2 ? colors.red : colors.orange);
		this.show(this.confirmNo, modal, ' Cancel ', colors.black, colors.lightGray);

		// Under the dialog, nothing else can be pressed.
		for (const button of this.allButtons) {
			if (button !== this.confirmYes && button !== this.confirmNo) button.setProps({disabled: modal});
		}
		this.castPages.setProps({disabled: modal});
		this.itemPages.setProps({disabled: modal});
	}

	// ------------------------------------------------------------------ drawing

	private paint(p: Painter): void {
		p.fill(1, 1, SCREEN_WIDTH, SCREEN_HEIGHT, colors.black);
		this.paintHeader(p);

		const state = this.state;
		if (state === undefined) {
			p.text(27, 18, 'Waiting for the controller...', colors.lightGray);
			p.text(22, 20, 'Is the foundry computer running main?', colors.gray);
			return;
		}

		if (this.tab === 'overview') this.paintOverview(p, state);
		else if (this.tab === 'modes') this.paintModes(p, state);
		else if (this.tab === 'manual') this.paintManual(p, state);
		else this.paintLog(p, state);

		const message = this.message;
		if (message !== undefined && os.clock() < message.until) p.text(3, 36, message.text.substring(0, 75), message.color);
		else if (this.tab !== 'log') this.paintLastAction(p, state);
	}

	private paintHeader(p: Painter): void {
		p.text(3, 2, Glyph.up, colors.orange);
		p.text(5, 2, 'S M E L T E R Y', colors.white);

		let x = 27;
		for (const [tab, label] of TABS) {
			if (tab === this.tab) p.text(x, 3, Glyph.underline.repeat(label.length), colors.orange);
			x += label.length + 4;
		}

		const mode = this.state?.mode;
		if (mode !== undefined) p.text(67, 2, ` ${mode.toUpperCase()} `, colors.black, MODE_CARDS[mode].color);

		const online = os.clock() - this.lastState < OFFLINE_SECONDS;
		p.text(76, 2, Glyph.dot, online ? colors.lime : colors.red);
	}

	private title(p: Painter, x: number, y: number, text: string, width: number): void {
		p.text(x, y, text, colors.orange);
		p.text(x + text.length + 1, y, Glyph.rule.repeat(Math.max(0, width - text.length - 1)), colors.gray);
	}

	private frame(p: Painter, x: number, y: number, width: number, height: number): void {
		p.fill(x, y, width + 2, 1, colors.gray);
		p.fill(x, y + height + 1, width + 2, 1, colors.gray);
		p.fill(x, y + 1, 1, height, colors.gray);
		p.fill(x + width + 1, y + 1, 1, height, colors.gray);
	}

	private paintOverview(p: Painter, state: SmelteryState): void {
		// Molten: the Smeltery tank, bottom fluid at the bottom, like its own GUI.
		this.title(p, 3, 5, 'MOLTEN', 22);
		const tankX = 3, tankY = 7, tankW = 18, tankH = 25;
		this.frame(p, tankX, tankY, tankW, tankH);

		const total = state.fluids.reduce((sum, fluid) => sum + fluid.amount, 0);
		let bottom  = tankY + tankH;
		for (const fluid of state.fluids) {
			if (bottom <= tankY) break;
			const rows  = Math.min(bottom - tankY, Math.max(1, Math.round(tankH * fluid.amount / Math.max(total, 1))));
			const color = fluidColor(fluid.name);
			p.fill(tankX + 1, bottom - rows + 1, tankW, rows, color);
			p.text(tankX + 2, bottom - Math.floor((rows - 1) / 2), fluidLabel(fluid.name).substring(0, tankW - 2), textOn(color), color);
			bottom -= rows;
		}

		let legendY = 8;
		for (const fluid of [...state.fluids].reverse().slice(0, 8)) {
			p.fill(24, legendY, 1, 1, fluidColor(fluid.name));
			p.text(26, legendY, `${fluid.amount} mB`.padStart(8), colors.white);
			legendY += 2;
		}
		p.text(24, 26, `${total}`, colors.white);
		p.text(24 + `${total}`.length + 1, 26, 'mB molten', colors.gray);
		const melting = state.melting.reduce((sum, item) => sum + item.count, 0);
		p.text(24, 29, 'melting', colors.gray);
		p.text(24, 30, `${melting} item${melting === 1 ? '' : 's'}`, colors.lightGray);

		// Fuel: its tank level (4 buckets is a seared tank) and the heat it gives.
		this.title(p, 37, 5, 'FUEL', 10);
		this.frame(p, 37, tankY, 6, tankH);
		const fuel = state.fuel;
		if (fuel !== undefined) {
			const rows = Math.min(tankH, Math.round(tankH * fuel.amount / 4000));
			for (let row = 0; row < rows; row++) p.fill(38, tankY + tankH - row, 6, 1, row % 5 === 0 ? colors.red : colors.orange);
			p.text(46, 26, fuel.fluid !== undefined ? fluidLabel(fuel.fluid).substring(0, 10) : 'empty', fuel.fluid !== undefined ? colors.orange : colors.red);
			p.text(46, 27, `${fuel.amount} mB`, colors.white);
		}
		else {
			p.text(46, 26, 'no tank', colors.gray);
		}
		p.text(46, 29, state.heat !== undefined ? `${state.heat} K` : '? K', colors.white);
		p.text(46, 30, 'heat', colors.gray);

		// Casting: casters by cast, a block per caster, auto mode's casts first.
		this.title(p, 53, 5, 'CASTING', 25);
		const groups = this.castGroups();
		const start  = (this.castPage - 1) * CASTS_PER_PAGE;
		groups.slice(start, start + CASTS_PER_PAGE).forEach((group, index) => {
			const y = 7 + index * 3;
			p.text(53, y, formatLabel(group.format), group.auto ? colors.white : colors.lightGray);
			if (!group.auto) p.text(54 + formatLabel(group.format).length, y, `${Glyph.dot} manual`, colors.gray);

			let x = 53;
			const blocks: [number, number][] = [
				[group.free, colors.gray],
				[group.casting, group.auto ? colors.orange : colors.gray],
				[group.ready, group.auto ? colors.yellow : colors.gray],
			];
			for (const [count, color] of blocks) {
				for (let n = 0; n < count && x < 75; n++) {
					p.fill(x, y + 1, 2, 1, color);
					x += 3;
				}
			}
			p.text(x + 1, y + 1, `${group.free + group.casting + group.ready}`, colors.gray);
		});
		if (groups.length === 0) p.text(53, 7, 'no caster found', colors.gray);
		p.fill(53, 21, 1, 1, colors.gray);
		p.text(55, 21, 'free', colors.gray);
		p.fill(61, 21, 1, 1, colors.orange);
		p.text(63, 21, 'casting', colors.gray);
		p.fill(72, 21, 1, 1, colors.yellow);
		p.text(74, 21, 'ready', colors.gray);

		// Attention: only when something needs a look.
		const lines = attentionLines(state);
		if (lines.length > 0) {
			this.title(p, 53, 25, 'ATTENTION', 25);
			lines.slice(0, 3).forEach((line, index) => {
				const y = 27 + index * 3;
				p.text(53, y, Glyph.up, line.color);
				p.text(55, y, line.title.substring(0, 23), colors.white);
				p.text(55, y + 1, line.detail.substring(0, 23), colors.gray);
			});
			if (lines.length > 3) p.text(55, 36, `+ ${lines.length - 3} more in Log`, colors.gray);
		}
	}

	private paintModes(p: Painter, state: SmelteryState): void {
		MODES.forEach((mode, index) => {
			const card   = MODE_CARDS[mode];
			const {x, y} = cardPlace(index);
			const active = state.mode === mode;
			p.fill(x, y, 17, 1, card.color);
			p.text(x + 1, y, mode.toUpperCase(), colors.black, card.color);
			card.lines.forEach((line, row) => p.text(x + 1, y + 2 + row, line.substring(0, 16), active ? colors.white : colors.lightGray));
			if (active) p.text(x + 1, y + 6, `${Glyph.dot} active`, colors.lime);
		});
		p.text(3, 34, 'Touch Activate to switch; the controller confirms live.', colors.gray);
	}

	private paintManual(p: Painter, state: SmelteryState): void {
		this.title(p, 3, 5, 'INSERT', 44);
		const items = this.pageItems();
		if (state.mode !== 'manual') p.text(3, 7, 'Switch to manual mode to insert and cast.', colors.orange);

		items.forEach((item, row) => {
			const y = 8 + row * 3;
			p.text(3, y, itemLabel(item.name).substring(0, 32), colors.white);
			p.text(3, y + 1, `${item.count} ${Glyph.dot} ${item.fluid !== undefined ? fluidLabel(item.fluid) : 'no fluid'}`.substring(0, 32), colors.gray);

			if (item.status === 'unknown') p.text(37, y, 'unknown', colors.gray);
			else if (item.status === 'alloy') p.text(37, y + 1, fluidLabel(item.alloy ?? 'alloy').substring(0, 12), colors.red);
			else if (item.status === 'heat') p.text(37, y + 1, `${item.temperature ?? '?'} K`, colors.red);
		});
		if (state.inputItems.length === 0) p.text(3, 8, 'The input is empty.', colors.gray);

		this.title(p, 53, 5, 'CAST', 25);
		p.text(53, 8, 'fluid', colors.gray);
		this.fluids().forEach((fluid, row) => {
			const y = 10 + row * 2;
			p.text(53, y, fluid.name === this.fluid ? Glyph.right : ' ', colors.white);
			p.fill(55, y, 2, 1, fluidColor(fluid.name));
		});
		p.text(53, 20, 'into', colors.gray);
		this.castGroups().slice(0, 5).forEach((group, row) => {
			p.text(53, 22 + row * 2, group.format === this.format ? Glyph.right : ' ', colors.white);
		});
	}

	private paintLog(p: Painter, state: SmelteryState): void {
		this.title(p, 3, 5, 'LOG', 65);
		const lines = state.log;
		const end   = lines.length - this.logOffset;
		const start = Math.max(0, end - LOG_LINES);

		lines.slice(start, end).forEach((raw, index) => {
			const line = parseLogLine(raw);
			const y    = 8 + index * 2;
			p.text(3, y, line.time, colors.gray);
			p.text(13, y, line.kind === 'other' ? '' : line.kind.padEnd(7), LOG_COLORS[line.kind]);
			p.text(21, y, line.text.substring(0, 56), line.kind === 'forced' ? colors.red : colors.white);
		});
		if (lines.length === 0) p.text(3, 8, 'Nothing yet.', colors.gray);
	}

	private paintLastAction(p: Painter, state: SmelteryState): void {
		// The last real action: the caster list printed at start ('  name: format') is not one.
		let last: string | undefined;
		for (let index = state.log.length - 1; index >= 0 && last === undefined; index--) {
			const line = state.log[index];
			if (line !== undefined && line.substring(8, 11) !== '   ') last = line;
		}
		if (last === undefined) return;
		const line = parseLogLine(last);
		p.text(3, 36, line.time, colors.gray);
		p.text(12, 36, `${line.kind === 'other' ? '' : `${line.kind} `}${line.text}`.substring(0, 60), colors.lightGray);
	}

	private paintConfirm(p: Painter): void {
		const confirm = this.confirm;
		if (confirm === undefined) return;

		const x = 15, y = 13, width = 49, height = 11;
		const color = confirm.step === 2 ? colors.red : colors.orange;
		this.frame(p, x, y, width, height);
		p.fill(x, y, width + 2, 1, color);
		p.fill(x, y + height + 1, width + 2, 1, color);
		p.fill(x, y + 1, 1, height, color);
		p.fill(x + width + 1, y + 1, 1, height, color);
		p.fill(x + 1, y + 1, width, height, colors.black);

		const item = confirm.item;
		const what = item.status === 'alloy'
		             ? `will form ${fluidLabel(item.alloy ?? 'an alloy')}.`
		             : `needs ${item.temperature ?? '?'} K: it may not melt.`;

		p.text(x + 3, y + 2, 'FORCE INSERT', color);
		p.text(x + 16, y + 2, `step ${confirm.step} of 2`, colors.gray);
		p.text(x + 3, y + 4, `${item.count} ${itemLabel(item.name)}`.substring(0, 45), colors.white);
		p.text(x + 3, y + 5, what.substring(0, 45), colors.lightGray);

		if (confirm.step === 1) {
			p.text(x + 3, y + 7, 'Check what will happen before going on.', colors.gray);
		}
		else {
			p.text(x + 3, y + 7, item.status === 'alloy' ? 'An alloy cannot be undone.' : 'It stays in the Smeltery until hot enough.', colors.gray);
			p.text(x + 21, y + 10, `${Math.max(0, Math.ceil(confirm.deadline - os.clock()))} s`, colors.gray);
		}
	}
}
