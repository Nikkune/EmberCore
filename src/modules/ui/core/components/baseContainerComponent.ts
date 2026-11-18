import {BaseComponent} from '@modules/ui/core/components/coreComponent';
import {shrinkRect} from '@modules/ui/render/renderHelpers';
import type {BaseProps, ComponentDependencies, ComponentKind, LayoutConstraints, MeasuredSize, Rect, RenderContext, UIComponent, UIContainerComponent, UIContext} from '@modules/ui/types';

export abstract class BaseContainerComponent<
	TKind extends ComponentKind,
	TProps extends BaseProps = BaseProps,
	TDraw = unknown,
	TStyle extends object = never,
	TChild extends UIComponent<TDraw> = UIComponent<TDraw>,
> extends BaseComponent<TKind, TProps, TDraw, TStyle> implements UIContainerComponent<TDraw, TChild> {
	protected readonly internalChildren: TChild[] = [];

	protected constructor(kind: TKind, props: TProps, dependencies: ComponentDependencies = {}, children: TChild[] = []) {
		super(kind, props, dependencies);
		this.internalChildren.push(...children);
	}

	public get children(): ReadonlyArray<TChild> {
		return this.internalChildren;
	}

	public addChild(child: TChild): void {
		if (this.internalChildren.includes(child)) return;

		this.internalChildren.push(child);
		this.invalidate({reason: 'layout'});
	}

	public removeChild(childId: string): void {
		const index = this.internalChildren.findIndex((child) => child.id === childId);

		if (index < 0) {
			return;
		}

		const [removed] = this.internalChildren.splice(index, 1);

		removed?.destroy();
		this.invalidate({reason: 'layout'});
	}

	public override destroy(): void {
		for (const child of this.internalChildren) {
			child.destroy();
		}

		this.internalChildren.length = 0;
		super.destroy();
	}

	protected renderChildren(context: RenderContext<TDraw>): void {
		for (const child of this.internalChildren) {
			if (!child.visible) {
				continue;
			}

			child.render(context);
		}
	}

	/**
	 * Measures a child including its margin: the child gets the constraints minus its margin,
	 * and the returned size is the space it takes in the container (size + margin).
	 */
	protected measureChild(child: TChild, constraints: LayoutConstraints, context: UIContext): MeasuredSize {
		const margin     = child.margin;
		const horizontal = margin ? margin.left + margin.right : 0;
		const vertical   = margin ? margin.top + margin.bottom : 0;

		const size = child.measure({
			minWidth:  Math.max(0, constraints.minWidth - horizontal),
			maxWidth:  Math.max(0, constraints.maxWidth - horizontal),
			minHeight: Math.max(0, constraints.minHeight - vertical),
			maxHeight: Math.max(0, constraints.maxHeight - vertical),
		}, context);

		return {
			width:  size.width + horizontal,
			height: size.height + vertical,
		};
	}

	protected measureChildren(constraints: LayoutConstraints, context: UIContext): MeasuredSize[] {
		return this.internalChildren.map((child) => this.measureChild(child, constraints, context));
	}

	/** Lays out each child in its slot, minus the child's margin. */
	protected layoutChildren(entries: ReadonlyArray<{
		child: TChild;
		rect: Rect
	}>, context: UIContext): void {
		for (const entry of entries) {
			const margin = entry.child.margin;
			entry.child.layout(margin ? shrinkRect(entry.rect, margin) : entry.rect, context);
		}
	}

	protected getVisibleChildren(): TChild[] {
		return this.internalChildren.filter((child) => child.visible);
	}

	protected getEnabledChildren(): TChild[] {
		return this.internalChildren.filter((child) => !child.disabled);
	}

	protected abstract override getResolvedStyle(context: UIContext | RenderContext<TDraw>): Partial<TStyle>;

	public abstract override measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize;

	public abstract override render(context: RenderContext<TDraw>): void;
}