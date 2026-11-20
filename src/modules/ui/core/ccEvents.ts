import type {UIEvent} from '@modules/ui/types';

export interface UIEventSourceOptions {
	/**
	 * Side or network name of the monitor the UI is drawn on. When set, only that monitor's
	 * monitor_touch events are used (terminal mouse events are ignored); when not set, the UI is on
	 * the terminal and monitor touches are ignored.
	 */
	monitor?: string;
}

export interface UIRunOptions extends UIEventSourceOptions {
	/** Called with every raw CC event ({name, ...args}) before the UI handles it; may call stop(). */
	onEvent?: (raw: unknown[]) => void;
	/** Called after each frame drawn, e.g. to show a hidden window buffer in one go. */
	afterRender?: () => void;
}

/**
 * Translates a raw CC:Tweaked event, as returned by {os.pullEvent()}, into a UI event.
 * Returns undefined for events the UI does not use or that belong to another screen.
 */
export function toUIEvent(raw: unknown[], options: UIEventSourceOptions = {}): UIEvent | undefined {
	const name    = raw[0];
	const onMonitor = options.monitor !== undefined;

	switch (name) {
		case 'mouse_click':
		case 'mouse_drag':
		case 'mouse_up':
			if (onMonitor) return undefined;

			return {
				type:   name,
				button: raw[1] as number,
				x:      raw[2] as number,
				y:      raw[3] as number,
			};

		case 'monitor_touch':
			if (!onMonitor || raw[1] !== options.monitor) return undefined;

			return {
				type: 'monitor_touch',
				x:    raw[2] as number,
				y:    raw[3] as number,
			};

		case 'mouse_scroll':
			if (onMonitor) return undefined;

			return {
				type:      'mouse_scroll',
				direction: (raw[1] as number) < 0 ? -1 : 1,
				x:         raw[2] as number,
				y:         raw[3] as number,
			};

		case 'key':
			return {
				type: 'key',
				key:  raw[1] as number,
				held: raw[2] === true,
			};

		case 'key_up':
			return {
				type: 'key_up',
				key:  raw[1] as number,
			};

		case 'char':
			return {
				type: 'char',
				char: raw[1] as string,
			};

		case 'paste':
			return {
				type: 'paste',
				text: raw[1] as string,
			};

		case 'timer':
			return {
				type:    'timer',
				timerId: raw[1] as number,
			};

		default:
			return undefined;
	}
}
