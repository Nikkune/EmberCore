import {BaseComponent}                                                                                                                                            from '@modules/ui';
import type {BaseProps, ComponentDependencies, ComponentKind, LayoutConstraints, MeasuredSize, Rect, RenderContext, UIComponent, UIContainerComponent, UIContext} from '@modules/ui/types';

export abstract class ContainerComponent<TKind extends ComponentKind, TProps extends BaseProps = BaseProps, TDraw = unknown, TStyle extends object = never, TChild extends UIComponent<TDraw> = UIComponent<TDraw>> extends BaseComponent<TKind, TProps, TDraw, TStyle> implements UIContainerComponent<TDraw, TChild> {
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

	protected measureChildren(constraints: LayoutConstraints, context: UIContext): MeasuredSize[] {
		return this.internalChildren.map((child) => child.measure(constraints, context));
	}

	protected layoutChildren(entries: ReadonlyArray<{
		child: TChild;
		rect: Rect
	}>, context: UIContext): void {
		for (const entry of entries) {
			entry.child.layout(entry.rect, context);
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