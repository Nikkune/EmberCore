import type {BaseProps, ComponentDependencies, ComponentKind, InvalidationRequest, LayoutConstraints, MeasuredSize, Point, Rect, RenderContext, UIComponent, UIContext, UIInvalidator} from '@modules/ui/types';

let componentIdCounter = 0;

function createComponentId(kind: ComponentKind): string {
	componentIdCounter += 1;
	return `ui_${kind}_${componentIdCounter}`;
}

export abstract class BaseComponent<TKind extends ComponentKind, TProps extends BaseProps = BaseProps, TDraw = unknown> implements UIComponent<TDraw> {
	public readonly id: string;
	public readonly kind: TKind;

	public rect: Rect = {
		x:      1,
		y:      1,
		width:  0,
		height: 0,
	};

	protected readonly props: TProps;
	protected readonly dependencies: ComponentDependencies;
	protected readonly invalidator?: UIInvalidator | undefined;

	protected constructor(kind: TKind, props: TProps, dependencies: ComponentDependencies = {}) {
		this.kind         = kind;
		this.props        = props;
		this.id           = props.id ?? createComponentId(kind);
		this.dependencies = dependencies;
		this.invalidator  = dependencies.invalidator;
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

	public invalidate(request: InvalidationRequest = {reason: 'manual'}): void {
		this.invalidator?.invalidate({
			...request,
			rect: request.rect ?? this.rect,
		});
	}

	public destroy(): void {
		// no-op by default
	}

	protected get width(): number {
		return this.rect.width;
	}

	protected get height(): number {
		return this.rect.height;
	}

	protected get x(): number {
		return this.rect.x;
	}

	protected get y(): number {
		return this.rect.y;
	}

	protected createMeasuredSize(width: number, height: number, constraints?: LayoutConstraints): MeasuredSize {
		if (!constraints) {
			return {
				width:  Math.max(0, width),
				height: Math.max(0, height),
			};
		}

		return {
			width:  this.clamp(width, constraints.minWidth, constraints.maxWidth),
			height: this.clamp(height, constraints.minHeight, constraints.maxHeight),
		};
	}

	protected isVisibleAndEnabled(): boolean {
		return this.visible && !this.disabled;
	}

	protected getRequestedWidth(fallback: number): number {
		return this.props.width ?? this.props.minWidth ?? fallback;
	}

	protected getRequestedHeight(fallback: number): number {
		return this.props.height ?? this.props.minHeight ?? fallback;
	}

	protected clamp(value: number, min: number, max: number): number {
		return Math.max(min, Math.min(max, value));
	}

	protected isPointInsideRect(point: Point, rect: Rect): boolean {
		return (point.x >= rect.x && point.y >= rect.y && point.x < rect.x + rect.width && point.y < rect.y + rect.height);
	}

	public abstract measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize;

	public abstract render(context: RenderContext<TDraw>): void;
}