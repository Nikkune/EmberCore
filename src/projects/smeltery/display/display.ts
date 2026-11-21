import {Peripheral}                                         from '@core/peripheral';
import {Channel}                                            from '@modules/net/index';
import {BasicUIEventBus, ComputerCraftSurfaceAdapter, defaultTheme, UIRuntime} from '@modules/ui/index';
import type {TerminalLike, UIDrawSurface}                  from '@modules/ui/render/surfaceAdapter';
import type {Theme}                                         from '@modules/ui/types';

import {CONTROLLER_HOSTNAME, Messages, PROTOCOL}            from '../shared/protocol';
import type {SmelteryState}                                 from '../shared/protocol';

import {PALETTE, SmelteryScreen}                            from './screen';

/** Buttons drawn flat (no border): the screen gives each one its colors. */
const THEME: Theme = {
	...defaultTheme,
	components: {
		...defaultTheme.components,
		button:     {border: {enabled: false}},
		pagination: {showFirstLast: false},
	},
};

/** @noSelf */
interface MonitorPeripheral {
	setTextScale(scale: number): void;
	setPaletteColour(color: number, rgb: number): void;
}

/** A CC window: drawn to while hidden, then shown in one go. @noSelf */
interface WindowBuffer extends TerminalLike {
	setVisible(visible: boolean): void;
	setPaletteColour(color: number, rgb: number): void;
}

/**
 * The screen computer: shows the controller's state on the monitor (text scale 0.5: 100 x 52) and sends
 * the commands touched on it. The controller is found by name at start, then by the states it broadcasts.
 */
export function runDisplay(this: void): void {
	const monitorName = Peripheral.findNameByType('monitor');
	if (monitorName === undefined) {
		print('No monitor found next to this computer.');
		return;
	}

	const monitor = peripheral.wrap(monitorName) as unknown as MonitorPeripheral & TerminalLike;
	monitor.setTextScale(0.5);
	// A frame is a clear and hundreds of writes: drawn straight on the monitor, the game can show it half
	// done (buttons missing, for one frame). Drawn in a hidden window, then shown at once.
	const [width, height] = monitor.getSize();
	const buffer = window.create(monitor as unknown as Redirect, 1, 1, width, height, false) as unknown as WindowBuffer;
	// The neon palette: the window shows its own palette when it is drawn, the monitor keeps it in between.
	for (const [color, rgb] of PALETTE) {
		monitor.setPaletteColour(color, rgb);
		buffer.setPaletteColour(color, rgb);
	}
	const flush  = (): void => {
		buffer.setVisible(true);
		buffer.setVisible(false);
	};

	const channel = new Channel({protocol: PROTOCOL, timeoutSeconds: 8});
	channel.open();

	let controller: number | undefined;
	// Set once the runtime exists: the callbacks below are created before it.
	const ui: {runtime?: UIRuntime<UIDrawSurface>} = {};

	const redraw = (): void => ui.runtime?.invalidate({reason: 'state', kind: 'full'});

	/** Every fluid of the catalogue, for the fluid lists: asked once, and again after a recipe change. */
	const loadFluids = (): void => {
		if (controller === undefined) return;
		channel.request(controller, Messages.getFluids, undefined, (result) => {
			if (result.ok) screen.setFluids(result.value as string[]);
			redraw();
		});
	};
	let fluidsAsked = false;

	const request = (messageType: string, payload: unknown, done: string, then?: () => void): void => {
		if (controller === undefined) {
			screen.notify('controller not found yet', colors.red);
			redraw();
			return;
		}

		channel.request(controller, messageType, payload, (result) => {
			if (result.ok) {
				screen.setState(result.value as SmelteryState);
				screen.notify(done, colors.lime);
				then?.();
			}
			else {
				screen.notify(result.error, colors.red);
			}
			redraw();
		});
	};

	const screen = new SmelteryScreen({
		setMode: (mode) => request(Messages.setMode, {mode}, `mode ${mode}`),
		insert:  (insert) => request(Messages.insert, insert, insert.force === true ? 'forced insert sent' : 'inserted'),
		queueOrder:  (order, sent) => request(Messages.queueOrder, order, `order sent: ${order.lines.length} shape(s)`, sent),
		cancelOrder: (id) => request(Messages.cancelOrder, {id}, `order #${id} cancelled`),
		insertReady: () => request(Messages.insertReady, undefined, 'inserting what is ready'),
		queueCraft:  (craft, sent) => request(Messages.queueCraft, craft, `craft sent: ${craft.count} casting(s)`, sent),
		trashFluid:  (trash) => request(Messages.trashFluid, trash, `${trash.fluid.substring(trash.fluid.indexOf(':') + 1)} trashed`),
		injectFluid: (inject) => request(Messages.injectFluid, inject, `${inject.fluid.substring(inject.fluid.indexOf(':') + 1)} injected`),

		setFormat: (format) => request(Messages.setFormat, format, `${format.format}: ${format.auto ? 'auto' : 'off'}`),
		setAlloy:  (alloy) => request(Messages.setAlloy, alloy, `alloy ${alloy.result.substring(alloy.result.indexOf(':') + 1)}`),
		setReservoir: (settings) => request(Messages.setReservoir, settings, 'reservoir saved'),
		setSmelteryCapacity: (capacity) => request(Messages.setSmelteryCapacity, capacity, capacity.capacity !== undefined ? `capacity ${capacity.capacity} mB` : 'capacity: auto'),
		saveRecipe:    (recipe, saved) => request(Messages.saveRecipe, recipe, 'recipe saved', () => {
			saved();
			loadFluids();
		}),
		deleteRecipe:  (recipe) => request(Messages.deleteRecipe, recipe, 'recipe deleted', loadFluids),
	});

	channel.on(Messages.state, (payload, from) => {
		controller = from;
		screen.setState(payload as SmelteryState);
		// The controller was not found at start: the fluid lists come with its first broadcast.
		if (!fluidsAsked) {
			fluidsAsked = true;
			loadFluids();
		}
	});

	print('Looking for the Smeltery controller...');
	controller = channel.lookup(CONTROLLER_HOSTNAME);
	print(controller !== undefined ? `Controller: computer #${controller}` : 'Not found yet: waiting for its broadcast');

	const runtime = new UIRuntime<UIDrawSurface>({
		root:        screen.root,
		eventBus:    new BasicUIEventBus(),
		theme:       THEME,
		surface:     ComputerCraftSurfaceAdapter.fromMonitor(buffer),
		surfaceKind: 'monitor',
	});
	ui.runtime = runtime;

	if (controller !== undefined) {
		channel.request(controller, Messages.getState, undefined, (result) => {
			if (result.ok) screen.setState(result.value as SmelteryState);
			redraw();
		});
		fluidsAsked = true;
		loadFluids();
	}

	// Every second: the confirmation countdown and the online dot.
	const everySecond = (): void => {
		screen.tick();
		redraw();
		runtime.schedule(1, everySecond);
	};
	runtime.schedule(1, everySecond);

	runtime.run({
		monitor:     monitorName,
		afterRender: flush,
		onEvent:     (raw) => {
			if (channel.handleEvent(raw)) redraw();
		},
	});
}
