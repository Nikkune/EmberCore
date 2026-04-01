import {BaseContainerComponent, drawBox, type DrawBoxOptions, getInnerRect, normalizeInsets, type UIDrawSurface}                            from '@modules/ui';
import type {ComponentDependencies, ContainerProps, ContainerStyle, LayoutConstraints, MeasuredSize, RenderContext, UIComponent, UIContext} from '@modules/ui/types';
import {createOptions}                                                                                                                      from '@utils/helpers';

export class ContainerComponent<TChild extends UIComponent<UIDrawSurface> = UIComponent<UIDrawSurface>> extends BaseContainerComponent<'container', ContainerProps, UIDrawSurface, ContainerStyle, TChild> {
	public constructor(props: ContainerProps, dependencies: ComponentDependencies = {}, children: TChild[] = []) {
		super('container', props, dependencies, children);
	}

	public override measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize {
		const style            = this.getResolvedStyle(context);
		const innerConstraints = this.getInnerConstraints(constraints, style);

		const childrenSizes = this.measureChildren(innerConstraints, context);

		const childrenWidth  = childrenSizes.reduce((max, size) => Math.max(max, size.width), 0);
		const childrenHeight = childrenSizes.reduce((max, size) => Math.max(max, size.height), 0);

		const borderX = style.border?.enabled ? 2 : 0;
		const borderY = style.border?.enabled ? 2 : 0;
		const padding = normalizeInsets(style.padding);

		return this.createMeasuredSize(this.getRequestedWidth(childrenWidth + padding.left + padding.right + borderX), this.getRequestedHeight(childrenHeight + padding.top + padding.bottom + borderY), constraints);
	}

	public override layout(rect: {
		x: number;
		y: number;
		width: number;
		height: number;
	}, context: UIContext): void {
		super.layout(rect, context);

		const style     = this.getResolvedStyle(context);
		const innerRect = getInnerRect(this.rect, style);

		const entries = this.children.map((child) => ({
			child,
			rect: innerRect,
		}));

		this.layoutChildren(entries, context);
	}

	public override render(context: RenderContext<UIDrawSurface>): void {
		if (!this.visible) return;
		if (this.width <= 0 || this.height <= 0) return;

		const style = this.getResolvedStyle(context);

		const borderCharacters = style.border?.enabled ? context.theme.borders[style.border.preset ?? 'single'] : undefined;

		drawBox(context.draw, createOptions<DrawBoxOptions>({
			rect: this.rect,
			style,
		})
			.with('borderCharacters', borderCharacters)
			.with('clipRect', context.clipRect)
			.done());

		this.renderChildren(context);
	}

	protected override getResolvedStyle(context: UIContext | RenderContext<UIDrawSurface>): Partial<ContainerStyle> {
		return this.getStyle(context, (themeStyle) => createOptions<ContainerStyle>(themeStyle)
			.with('foregroundColor', this.props.foregroundColor ?? themeStyle.foregroundColor ?? context.theme.palette.text)
			.with('backgroundColor', this.props.backgroundColor ?? themeStyle.backgroundColor ?? context.theme.palette.surface)
			.with('padding', themeStyle.padding ?? 0)
			.done());
	}

	private getInnerConstraints(constraints: LayoutConstraints, style: Partial<ContainerStyle>): LayoutConstraints {
		const padding = normalizeInsets(style.padding);
		const borderX = style.border?.enabled ? 2 : 0;
		const borderY = style.border?.enabled ? 2 : 0;

		const horizontal = padding.left + padding.right + borderX;
		const vertical   = padding.top + padding.bottom + borderY;

		return {
			minWidth:  Math.max(0, constraints.minWidth - horizontal),
			maxWidth:  Math.max(0, constraints.maxWidth - horizontal),
			minHeight: Math.max(0, constraints.minHeight - vertical),
			maxHeight: Math.max(0, constraints.maxHeight - vertical),
		};
	}
}