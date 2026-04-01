import type {Point, Rect}                                                  from './core';
import type {UIEvent, UIEventBus}                                          from './events';
import type {LayoutConstraints, MeasuredSize}                              from './layout';
import type {BaseProps}                                                    from './props';
import type {InvalidationRequest, RenderContext, UIContext, UIInvalidator} from './runtime';
import type {Theme}                                                        from './theme';

// ============================================================
// Component kinds
// ============================================================

export type LeafComponentKind = 'badge' | 'button' | 'checkbox' | 'label' | 'log_viewer' | 'pagination' | 'progress_bar' | 'radio' | 'separator' | 'status_bar' | 'table';

export type ContainerComponentKind = 'box' | 'container' | 'grid' | 'panel' | 'stack';

export type ComponentKind = LeafComponentKind | ContainerComponentKind;

// ============================================================
// Component tree
// ============================================================

export interface LeafComponentNode<TProps extends BaseProps = BaseProps> {
	kind: LeafComponentKind;
	props: TProps;
}

export interface ContainerComponentNode<TProps extends BaseProps = BaseProps, TChild extends UINode = UINode> {
	kind: ContainerComponentKind;
	readonly props: TProps;
	readonly children: TChild[];
}

export type UINode = LeafComponentNode | ContainerComponentNode;

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

export interface Pressable {
	press(context: UIContext): boolean;
}

export interface Themable {
	applyTheme(theme: Theme): void;
}

export interface Invalidatable {
	invalidate(request?: InvalidationRequest): void;
}

export interface Destroyable {
	destroy(): void;
}

export interface Focusable {
	focus(): void;

	blur(): void;

	readonly focused: boolean;
}

export interface Checkable {
	checked: boolean;

	setChecked(value: boolean): void;

	toggle(): void;
}

export interface ContainerLike<TChild> {
	readonly children: ReadonlyArray<TChild>;

	addChild(child: TChild): void;

	removeChild(childId: string): void;
}

export interface Interactive {
	hitTest(point: Point): boolean;

	dispatch(event: UIEvent, context: UIContext): InvalidationRequest | null;
}

// ============================================================
// Component contracts
// ============================================================

export interface UIComponent<TDraw = unknown> extends Measurable, Layoutable, Renderable<TDraw>, Invalidatable, Destroyable {
	readonly id: string;
	readonly kind: ComponentKind;
	readonly rect: Rect;
	readonly visible: boolean;
	readonly disabled: boolean;
}

export interface UIInteractiveComponent<TDraw = unknown> extends UIComponent<TDraw>, Interactive {}

export interface UIFocusableComponent<TDraw = unknown> extends UIInteractiveComponent<TDraw>, Focusable {}

export interface UIActionableComponent<TDraw = unknown> extends UIFocusableComponent<TDraw> {}

export interface UIPressableComponent<TDraw = unknown> extends UIActionableComponent<TDraw>, Pressable {}

export interface UICheckableComponent<TDraw = unknown> extends UIActionableComponent<TDraw>, Checkable {}

export interface UIThemableComponent<TDraw = unknown> extends UIComponent<TDraw>, Themable {}

export interface UIContainerComponent<TDraw = unknown, TChild extends UIComponent = UIComponent> extends UIComponent<TDraw>, ContainerLike<TChild> {}

// ============================================================
// Dependencies
// ============================================================

export interface ComponentDependencies {
	eventBus?: UIEventBus;
	invalidator?: UIInvalidator;
}