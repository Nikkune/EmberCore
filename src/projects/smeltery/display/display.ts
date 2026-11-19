import {Peripheral}                                         from '@core/peripheral';
import {Channel}                                            from '@modules/net/index';
import {BasicUIEventBus, ComputerCraftSurfaceAdapter, defaultTheme, UIRuntime} from '@modules/ui/index';
import type {TerminalLike, UIDrawSurface}                  from '@modules/ui/render/surfaceAdapter';
import type {Theme}                                         from '@modules/ui/types';

import {CONTROLLER_HOSTNAME, Messages, PROTOCOL}            from '../shared/protocol';
import type {SmelteryState}                                 from '../shared/protocol';

import {SmelteryScreen}                                     from './screen';

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
}

/**
 * The screen computer: shows the controller's state on the monitor (text scale 0.5: 79 x 38) and sends
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

	const channel = new Channel({protocol: PROTOCOL, timeoutSeconds: 8});
	channel.open();

	let controller: number | undefined;
	// Set once the runtime exists: the callbacks below are created before it.
	const ui: {runtime?: UIRuntime<UIDrawSurface>} = {};

	const redraw = (): void => ui.runtime?.invalidate({reason: 'state', kind: 'full'});

	const request = (messageType: string, payload: unknown, done: string): void => {
		if (controller === undefined) {
			screen.notify('controller not found yet', colors.red);
			redraw();
			return;
		}

		channel.request(controller, messageType, payload, (result) => {
			if (result.ok) {
				screen.setState(result.value as SmelteryState);
				screen.notify(done, colors.lime);
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
		cast:    (cast) => request(Messages.cast, cast, 'cast'),
		setFormat: (format) => request(Messages.setFormat, format, `${format.format}: ${format.auto ? 'auto' : 'off'}`),
		setAlloy:  (alloy) => request(Messages.setAlloy, alloy, `alloy ${alloy.result.substring(alloy.result.indexOf(':') + 1)}`),
	});

	channel.on(Messages.state, (payload, from) => {
		controller = from;
		screen.setState(payload as SmelteryState);
	});

	print('Looking for the Smeltery controller...');
	controller = channel.lookup(CONTROLLER_HOSTNAME);
	print(controller !== undefined ? `Controller: computer #${controller}` : 'Not found yet: waiting for its broadcast');

	const runtime = new UIRuntime<UIDrawSurface>({
		root:        screen.root,
		eventBus:    new BasicUIEventBus(),
		theme:       THEME,
		surface:     ComputerCraftSurfaceAdapter.fromMonitor(monitor),
		surfaceKind: 'monitor',
	});
	ui.runtime = runtime;

	if (controller !== undefined) {
		channel.request(controller, Messages.getState, undefined, (result) => {
			if (result.ok) screen.setState(result.value as SmelteryState);
			redraw();
		});
	}

	// Every second: the confirmation countdown and the online dot.
	const everySecond = (): void => {
		screen.tick();
		redraw();
		runtime.schedule(1, everySecond);
	};
	runtime.schedule(1, everySecond);

	runtime.run({
		monitor: monitorName,
		onEvent: (raw) => {
			if (channel.handleEvent(raw)) redraw();
		},
	});
}
