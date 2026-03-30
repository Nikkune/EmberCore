// ============================================================
// Events
// ============================================================
export type UIEventName = keyof UIEventMap;

export type UIEvent = | MouseClickEvent | MouseScrollEvent | KeyEvent | CharEvent | PasteEvent | TimerEvent | ChangeEvent | ToggleEvent | SelectEvent | PageChangeEvent | SubmitEvent | CustomEvent;

export type UIEventHandler<TEvent extends UIEvent = UIEvent> = (event: TEvent) => void;

export interface BaseUIEvent {
	type: UIEventName;
	targetId?: string;
	cancelled?: boolean;
	propagationStopped?: boolean;
}

export interface PositionalUIEvent extends BaseUIEvent {
	x: number;
	y: number;
}

export interface MouseClickEvent extends PositionalUIEvent {
	type: 'mouse_click' | 'mouse_drag' | 'mouse_up' | 'monitor_touch';
	button?: number;
}

export interface MouseScrollEvent extends PositionalUIEvent {
	type: 'mouse_scroll';
	direction: -1 | 1;
}

export interface KeyEvent extends BaseUIEvent {
	type: 'key' | 'key_up';
	key: number;
	held?: boolean;
}

export interface CharEvent extends BaseUIEvent {
	type: 'char';
	char: string;
}

export interface PasteEvent extends BaseUIEvent {
	type: 'paste';
	text: string;
}

export interface TimerEvent extends BaseUIEvent {
	type: 'timer';
	timerId: number;
}

export interface ChangeEvent<T = unknown> extends BaseUIEvent {
	type: 'change';
	value: T;
}

export interface ToggleEvent extends BaseUIEvent {
	type: 'toggle';
	checked: boolean;
}

export interface SelectEvent<T = string> extends BaseUIEvent {
	type: 'select';
	value: T;
	index?: number;
}

export interface PageChangeEvent extends BaseUIEvent {
	type: 'page_change';
	page: number;
	pageSize: number;
}

export interface SubmitEvent extends BaseUIEvent {
	type: 'submit';
	values: Record<string, unknown>;
}

export interface CustomEvent<T = unknown> extends BaseUIEvent {
	type: 'custom';
	name: string;
	payload?: T;
}

export interface UIEventMap {
	mouse_click?: UIEventHandler<MouseClickEvent>;
	mouse_scroll?: UIEventHandler<MouseScrollEvent>;
	mouse_drag?: UIEventHandler<MouseClickEvent>;
	mouse_up?: UIEventHandler<MouseClickEvent>;
	monitor_touch?: UIEventHandler<MouseClickEvent>;
	key?: UIEventHandler<KeyEvent>;
	key_up?: UIEventHandler<KeyEvent>;
	char?: UIEventHandler<CharEvent>;
	paste?: UIEventHandler<PasteEvent>;
	timer?: UIEventHandler<TimerEvent>;
	change?: UIEventHandler<ChangeEvent>;
	submit?: UIEventHandler<SubmitEvent>;
	toggle?: UIEventHandler<ToggleEvent>;
	select?: UIEventHandler<SelectEvent>;
	page_change?: UIEventHandler<PageChangeEvent>;
	custom?: UIEventHandler<CustomEvent>;
}

export interface EventSubscription<TEvent extends UIEvent = UIEvent> {
	readonly id: string;
	readonly type: TEvent['type'];
	readonly targetId?: string;
	readonly once: boolean;
	readonly active: boolean;

	unsubscribe(): void;
}

export interface EventDispatchResult {
	dispatched: boolean;
	listenerCount: number;
	cancelled: boolean;
	propagationStopped: boolean;
}

export interface EventSubscriptionOptions {
	targetId?: string;
	once?: boolean;
	order?: number;
}

export interface EventDispatcher {
	subscribe<TEvent extends UIEvent>(type: TEvent['type'], handler: UIEventHandler<TEvent>, options?: EventSubscriptionOptions): EventSubscription<TEvent>;

	subscribeOnce<TEvent extends UIEvent>(type: TEvent['type'], handler: UIEventHandler<TEvent>, options?: Omit<EventSubscriptionOptions, 'once'>): EventSubscription<TEvent>;

	unsubscribe(subscriptionId: string): boolean;

	dispatch<TEvent extends UIEvent>(event: TEvent): EventDispatchResult;

	clear(type?: UIEventName): void;

	count(type?: UIEventName): number;
}

export interface UIEventBus extends EventDispatcher {
	emit<TEvent extends UIEvent>(event: TEvent): EventDispatchResult;

	has(type: UIEventName): boolean;

	getSubscriptions(type?: UIEventName): ReadonlyArray<EventSubscription>;
}