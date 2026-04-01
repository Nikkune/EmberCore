import {BaseComponent}                                                                                                                                                                      from '@modules/ui/core/components/coreComponent';
import type {BaseProps, ComponentDependencies, ComponentKind, InvalidationRequest, LayoutConstraints, MeasuredSize, Point, Rect, RenderContext, UIContext, UIEvent, UIInteractiveComponent} from '@modules/ui/types';

export abstract class InteractiveComponent<TKind extends ComponentKind, TProps extends BaseProps = BaseProps, TDraw = unknown, TStyle extends object = never> extends BaseComponent<TKind, TProps, TDraw, TStyle> implements UIInteractiveComponent<TDraw> {
	protected readonly eventBus = this.dependencies.eventBus;

	protected constructor(kind: TKind, props: TProps, dependencies: ComponentDependencies = {}) {
		super(kind, props, dependencies);
	}

	public hitTest(point: Point): boolean {
		if (!this.isVisibleAndEnabled()) return false;

		return this.isPointInsideRect(point, this.rect);
	}

	public dispatch(event: UIEvent, context: UIContext): InvalidationRequest | null {
		if (!this.isVisibleAndEnabled()) return null;

		if (event.targetId && event.targetId !== this.id) return null;

		if (!this.isEventInside(event)) return null;

		return this.handleEvent(event, context);
	}

	protected handleEvent(_event: UIEvent, _context: UIContext): InvalidationRequest | null {
		return null;
	}

	protected createEventInvalidation(rect?: Rect): InvalidationRequest {
		return {
			reason: 'event',
			kind:   'region',
			rect:   rect ?? this.rect,
		};
	}

	protected createStateInvalidation(rect?: Rect): InvalidationRequest {
		return {
			reason: 'state',
			kind:   'region',
			rect:   rect ?? this.rect,
		};
	}

	protected isEventInside(event: UIEvent): boolean {
		if (!('x' in event && 'y' in event)) {
			return true;
		}

		return this.hitTest({
			x: event.x,
			y: event.y,
		});
	}

	protected abstract override getResolvedStyle(context: UIContext | RenderContext<TDraw>): Partial<TStyle>;

	public abstract override measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize;

	public abstract override render(context: RenderContext<TDraw>): void;
}