import type {BaseProps, ComponentKind, InvalidationRequest, LayoutConstraints, MeasuredSize, Point, Rect, RenderContext, UIComponent, UIContext, UIEvent, UIEventBus, UIEventHandler, UIEventMap, UIInvalidator,} from "@modules/ui";

let componentIdCounter = 0;

function createComponentId(kind: ComponentKind): string {
	componentIdCounter += 1;
	return `ui_${kind}_${componentIdCounter}`;
}

export abstract class BaseComponent<TProps extends BaseProps = BaseProps, TDraw = unknown> implements UIComponent<TDraw> {
	public readonly id: string;
	public readonly kind: ComponentKind;
	public rect: Rect = {x: 1, y: 1, width: 0, height: 0};

	protected readonly props: TProps;
	protected readonly eventBus?: UIEventBus;
	protected readonly invalidator?: UIInvalidator;

	private readonly subscriptions: Array<{ unsubscribe(): void }> = [];

	protected constructor(
		kind: ComponentKind,
		props: TProps,
		eventBus?: UIEventBus,
		invalidator?: UIInvalidator,
	) {
		this.kind = kind;
		this.props = props;
		if (eventBus !== undefined) {
			this.eventBus = eventBus;
		}
		if (invalidator !== undefined) {
			this.invalidator = invalidator;
		}
		this.id = props.id ?? createComponentId(kind);

		this.bindEventHandlers(props.on);
	}

	public get visible(): boolean {
		return this.props.visible ?? true;
	}

	public get disabled(): boolean {
		return this.props.disabled ?? false;
	}

	public layout(rect: Rect, _context: UIContext): void {
		this.rect = rect;
	}

	public hitTest(point: Point): boolean {
		return (
			this.visible &&
			point.x >= this.rect.x &&
			point.y >= this.rect.y &&
			point.x < this.rect.x + this.rect.width &&
			point.y < this.rect.y + this.rect.height
		);
	}

	public dispatch(event: UIEvent, _context: UIContext): boolean {
		if (this.disabled || !this.visible) {
			return false;
		}

		return !(event.targetId && event.targetId !== this.id);
	}

	public invalidate(request: InvalidationRequest = {reason: "manual"}): void {
		this.invalidator?.invalidate({
			...request,
			rect: request.rect ?? this.rect,
		});
	}

	public destroy(): void {
		for (const subscription of this.subscriptions) {
			subscription.unsubscribe();
		}

		this.subscriptions.length = 0;
	}

	public abstract measure(
		constraints: LayoutConstraints,
		context: UIContext,
	): MeasuredSize;

	public abstract render(context: RenderContext<TDraw>): void;

	private bindEventHandlers(handlers?: UIEventMap): void {
		if (!handlers || !this.eventBus) {
			return;
		}

		for (const key in handlers) {
			const type = key as keyof UIEventMap;
			const handler = handlers[type];

			if (!handler) {
				continue;
			}

			const subscription = this.eventBus.subscribe(
				type,
				handler as UIEventHandler<UIEvent>,
				{targetId: this.id},
			);

			this.subscriptions.push(subscription);
		}
	}
}