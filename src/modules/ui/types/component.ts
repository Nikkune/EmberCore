import type {AxisSize, Color, MarginLike, PaddingLike, Point, Rect}        from './core';
import type {UIEvent, UIEventBus, UIEventMap}                              from './events';
import type {FlexItemOptions, LayoutConstraints, MeasuredSize}             from './layout';
import type {InvalidationRequest, RenderContext, UIContext, UIInvalidator} from './runtime';
import type {BorderStyle}                                                  from './style';

// ============================================================
// Component kinds
// ============================================================

export type ComponentKind = | 'button' | 'progress_bar' | 'table' | 'box' | 'grid' | 'checkbox' | 'radio' | 'log_viewer' | 'pagination' | 'label' | 'panel' | 'separator' | 'badge' | 'list' | 'status_bar' | 'container' | 'stack' | 'custom';

// ============================================================
// Base props
// ============================================================

export interface BaseProps extends AxisSize {
	id?: string;
	visible?: boolean;
	disabled?: boolean;
	zIndex?: number;

	margin?: MarginLike;
	padding?: PaddingLike;

	rect?: Partial<Rect>;

	backgroundColor?: Color;
	foregroundColor?: Color;
	border?: BorderStyle;

	flex?: FlexItemOptions;

	on?: UIEventMap;
}

// ============================================================
// Component tree
// ============================================================

export interface ComponentNode<TProps extends BaseProps = BaseProps> {
	kind: ComponentKind;
	props: TProps;
	children?: ComponentNode[];
}

// ============================================================
// Component capabilities
// ============================================================

export interface Measurable {
	measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize;
}

export interface Layoutable {
	layout(rect: Rect, context: UIContext): void;
}

export interface Renderable<TDraw = unknown> {
	render(context: RenderContext<TDraw>): void;
}

export interface Interactive {
	hitTest(point: Point): boolean;

	dispatch(event: UIEvent, context: UIContext): boolean;
}

// ============================================================
// Component contracts
// ============================================================

export interface UIComponent<TDraw = unknown> extends Measurable, Layoutable, Renderable<TDraw>, Interactive {
	readonly id: string;
	readonly kind: ComponentKind;
	readonly rect: Rect;
	readonly visible: boolean;
	readonly disabled: boolean;

	invalidate(request?: InvalidationRequest): void;

	destroy(): void;
}

// ============================================================
// Dependencies
// ============================================================

export interface ComponentDependencies {
	eventBus?: UIEventBus;
	invalidator?: UIInvalidator;
}