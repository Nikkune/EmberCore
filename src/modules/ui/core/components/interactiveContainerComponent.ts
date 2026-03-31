import {ContainerComponent}                                                                                                                                                           from '@modules/ui';
import type {BaseProps, ComponentDependencies, ComponentKind, InvalidationRequest, LayoutConstraints, MeasuredSize, Point, RenderContext, UIContext, UIEvent, UIInteractiveComponent} from '@modules/ui/types';

export abstract class InteractiveContainerComponent<TKind extends ComponentKind, TProps extends BaseProps = BaseProps, TDraw = unknown, TChild extends UIInteractiveComponent<TDraw> = UIInteractiveComponent<TDraw>> extends ContainerComponent<TKind, TProps, TDraw, TChild> implements UIInteractiveComponent<TDraw> {
	protected readonly eventBus = this.dependencies.eventBus;

	protected constructor(kind: TKind, props: TProps, dependencies: ComponentDependencies = {}, children: TChild[] = []) {
		super(kind, props, dependencies, children);
	}

	public hitTest(point: Point): boolean {
		if (!this.isVisibleAndEnabled()) return false;

		if (this.isPointInsideRect(point, this.rect)) return true;

		for (let index = this.internalChildren.length - 1; index >= 0; index--) {
			const child = this.internalChildren[index];

			if (child?.hitTest(point)) {
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

				if (!child) continue;

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

			if (!child || !child.visible || child.disabled) {
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

	public abstract override measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize;

	public abstract override render(context: RenderContext<TDraw>): void;
}