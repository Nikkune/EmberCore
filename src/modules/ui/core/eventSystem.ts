import type {EventDispatchResult, EventSubscription, EventSubscriptionOptions, UIEvent, UIEventBus, UIEventHandler, UIEventName,} from "../types/uiTypes";

interface InternalEventSubscription extends EventSubscription<UIEvent> {
	readonly handler: UIEventHandler<UIEvent>;
	readonly order: number;

	setActive(active: boolean): void;
}

let subscriptionIdCounter = 0;

function createSubscriptionId(): string {
	subscriptionIdCounter++;
	return `ui_subscription_${subscriptionIdCounter}`;
}

class BasicEventSubscription<TEvent extends UIEvent = UIEvent> implements InternalEventSubscription {
	public active = true;

	public constructor(
		public readonly id: string,
		public readonly type: TEvent["type"],
		private readonly handlerTyped: UIEventHandler<TEvent>,
		private readonly owner: BasicUIEventBus,
		public readonly once: boolean,
		public readonly targetId: string | undefined,
		public readonly order: number,
	) {
	}

	public unsubscribe(): void {
		if (!this.active) return;

		this.owner.unsubscribe(this.id);
	}

	public setActive(active: boolean): void {
		this.active = active;
	}

	public get handler(): UIEventHandler<UIEvent> {
		return this.handlerTyped as UIEventHandler<UIEvent>;
	}
}

export class BasicUIEventBus implements UIEventBus {
	private readonly subscriptions: Partial<Record<UIEventName, InternalEventSubscription[]>> = {};

	public subscribe<TEvent extends UIEvent>(type: TEvent["type"], handler: UIEventHandler<TEvent>, options: EventSubscriptionOptions = {}): EventSubscription<TEvent> {
		const subscription = new BasicEventSubscription<TEvent>(
			createSubscriptionId(),
			type,
			handler,
			this,
			options.once ?? false,
			options.targetId,
			options.order ?? 0,
		);

		const list = this.getOrCreateSubscriptions(type);
		list.push(subscription);
		list.sort((left, right) => left.order - right.order);

		return subscription;
	}

	public subscribeOnce<TEvent extends UIEvent>(type: TEvent["type"], handler: UIEventHandler<TEvent>, options?: Omit<EventSubscriptionOptions, "once">): EventSubscription<TEvent> {
		return this.subscribe(type, handler, {...options, once: true});
	}

	public unsubscribe(subscriptionId: string): boolean {
		for (const eventType in this.subscriptions) {
			const type = eventType as UIEventName;
			const list = this.subscriptions[type];

			if (!list || list.length === 0) continue;

			for (let i = 0; i < list.length; i++) {
				const subscription = list[i];

				if (subscription.id !== subscriptionId) continue;

				subscription.setActive(false);
				list.splice(i, 1);

				return true;
			}
		}

		return false;
	}

	public dispatch<TEvent extends UIEvent>(event: TEvent): EventDispatchResult {
		const list = this.subscriptions[event.type];

		if (!list || list.length === 0) return {
			dispatched: false,
			listenerCount: 0,
			cancelled: event.cancelled ?? false,
			propagationStopped: event.propagationStopped ?? false,
		}

		let listenerCount = 0;
		const snapshot = [...list];

		for (const subscription of snapshot) {
			if (!subscription.active) continue;
			if (subscription.targetId !== undefined && subscription.targetId !== event.targetId) continue;
			listenerCount++;

			subscription.handler(event);

			if (subscription.once) this.unsubscribe(subscription.id);
			if (event.propagationStopped) break;
		}

		return {
			dispatched: listenerCount > 0,
			listenerCount,
			cancelled: event.cancelled ?? false,
			propagationStopped: event.propagationStopped ?? false,
		};
	}

	public emit<TEvent extends UIEvent>(event: TEvent): EventDispatchResult {
		return this.dispatch(event);
	}

	public clear(type?: UIEventName): void {
		if (type !== undefined) {
			const list = this.subscriptions[type];

			if (!list) return;

			for (const subscription of list) {
				subscription.setActive(false);
			}

			this.subscriptions[type] = [];
			return;
		}

		for (const eventType in this.subscriptions) {
			this.clear(eventType as UIEventName);
		}
	}

	public count(type?: UIEventName): number {
		if (type !== undefined) return this.subscriptions[type]?.length ?? 0;

		let total = 0;

		for (const eventType in this.subscriptions) {
			total += this.subscriptions[eventType as UIEventName]?.length ?? 0;
		}

		return total;
	}

	public has(type: UIEventName): boolean {
		return (this.subscriptions[type]?.length ?? 0) > 0;
	}

	public getSubscriptions(type?: UIEventName): ReadonlyArray<EventSubscription> {
		if (type !== undefined) return [...(this.subscriptions[type] ?? [])]

		const allSubscriptions: EventSubscription[] = [];

		for (const eventType in this.subscriptions) {
			const list = this.subscriptions[eventType as UIEventName];

			if (!list || list.length === 0) continue;

			allSubscriptions.push(...list);
		}

		return allSubscriptions;
	}

	private getOrCreateSubscriptions(type: UIEventName): InternalEventSubscription[] {
		if (!this.subscriptions[type]) {
			this.subscriptions[type] = [];
		}

		return this.subscriptions[type]!;
	}
}

export function stopPropagation(event: UIEvent): void {
	event.propagationStopped = true;
}

export function cancelEvent(event: UIEvent): void {
	event.cancelled = true;
}

export function cancelAndStop(event: UIEvent): void {
	event.cancelled = true;
	event.propagationStopped = true;
}