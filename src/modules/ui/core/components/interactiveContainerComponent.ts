import {BaseContainerComponent} from '@modules/ui/core/components/baseContainerComponent';
import type {BaseProps, ComponentDependencies, ComponentKind, InvalidationRequest, LayoutConstraints, MeasuredSize, Point, RenderContext, UIComponent, UIContext, UIEvent, UIInteractiveComponent} from '@modules/ui/types';

/** True when the component can receive events (it implements hitTest and dispatch). */
export function isInteractiveComponent<TDraw>(component: UIComponent<TDraw>): component is UIInteractiveComponent<TDraw> {
	const candidate = component as Partial<UIInteractiveComponent<TDraw>>;
	return typeof candidate.hitTest === 'function' && typeof candidate.dispatch === 'function';
}

/**
 * A container that forwards events to its children. Children may be any component:
 * only the interactive ones (buttons, checkboxes, nested containers...) receive events.
 */
export abstract class InteractiveContainerComponent<
	TKind extends ComponentKind,
	TProps extends BaseProps = BaseProps,
	TDraw = unknown,
	TStyle extends object = never,
	TChild extends UIComponent<TDraw> = UIComponent<TDraw>,
> extends BaseContainerComponent<TKind, TProps, TDraw, TStyle, TChild> implements UIInteractiveComponent<TDraw> {
	protected readonly eventBus = this.dependencies.eventBus;

	protected constructor(kind: TKind, props: TProps, dependencies: ComponentDependencies = {}, children: TChild[] = []) {
		super(kind, props, dependencies, children);
	}

	public hitTest(point: Point): boolean {
		if (!this.isVisibleAndEnabled()) return false;

		if (this.isPointInsideRect(point, this.rect)) return true;

		for (let index = this.internalChildren.length - 1; index >= 0; index--) {
			const child = this.internalChildren[index];

			if (child && isInteractiveComponent(child) && child.hitTest(point)) {
				return true;
			}
		}

		return false;
	}

	public dispatch(event: UIEvent, context: UIContext): InvalidationRequest | null {
		if (!this.isVisibleAndEnabled()) return null;

		if (event.targetId && event.targetId !== this.id) {
			for (let index = this.internalChildren.length - 1; index >= 0; index--) {
				const child = this.internalChildren[index];

				if (!child || !isInteractiveComponent(child)) continue;

				const childResult = child.dispatch(event, context);

				if (childResult) {
					return childResult;
				}
			}

			return null;
		}

		const childResult = this.dispatchToChildren(event, context);

		if (childResult) return childResult;

		return this.handleEvent(event, context);
	}

	protected dispatchToChildren(event: UIEvent, context: UIContext): InvalidationRequest | null {
		for (let index = this.internalChildren.length - 1; index >= 0; index--) {
			const child = this.internalChildren[index];

			if (!child || !child.visible || child.disabled || !isInteractiveComponent(child)) {
				continue;
			}

			if ('x' in event && 'y' in event && !child.hitTest({
				x: event.x,
				y: event.y,
			})) {
				continue;
			}

			const result = child.dispatch(event, context);

			if (result) {
				return result;
			}
		}

		return null;
	}

	protected handleEvent(_event: UIEvent, _context: UIContext): InvalidationRequest | null {
		return null;
	}

	protected createEventInvalidation(reason: InvalidationRequest['reason'] = 'event'): InvalidationRequest {
		return {
			reason,
			kind: 'region',
			rect: this.rect,
		};
	}

	protected createStateInvalidation(): InvalidationRequest {
		return {
			reason: 'state',
			kind:   'region',
			rect:   this.rect,
		};
	}

	protected abstract override getResolvedStyle(context: UIContext | RenderContext<TDraw>): Partial<TStyle>;

	public abstract override measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize;

	public abstract override render(context: RenderContext<TDraw>): void;
}
