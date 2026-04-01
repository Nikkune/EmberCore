import {BaseContainerComponent, drawBox, type DrawBoxOptions, drawHorizontalLine, drawText, type DrawTextOptions, getInnerRect, normalizeInsets, type UIDrawSurface} from '@modules/ui';
import type {ComponentDependencies, LayoutConstraints, MeasuredSize, PanelProps, PanelStyle, RenderContext, TextStyle, UIComponent, UIContext}                       from '@modules/ui/types';
import {createOptions}                                                                                                                                               from '@utils/helpers';

export class PanelComponent<TChild extends UIComponent<UIDrawSurface> = UIComponent<UIDrawSurface>> extends BaseContainerComponent<'panel', PanelProps, UIDrawSurface, PanelStyle, TChild> {
	public constructor(props: PanelProps, dependencies: ComponentDependencies = {}, children: TChild[] = []) {
		super('panel', props, dependencies, children);
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

		const titleWidth = this.props.title ? this.props.title.length + (style.border?.enabled ? 4 : 0) : 0;

		const titleExtraHeight = this.props.title ? 2 : 0;

		const measuredWidth = Math.max(childrenWidth + padding.left + padding.right + borderX, titleWidth, this.getRequestedWidth(0));

		const measuredHeight = Math.max(childrenHeight + padding.top + padding.bottom + borderY + titleExtraHeight, this.getRequestedHeight(0));

		return this.createMeasuredSize(measuredWidth, measuredHeight, constraints);
	}

	public override layout(rect: {
		x: number;
		y: number;
		width: number;
		height: number;
	}, context: UIContext): void {
		super.layout(rect, context);

		const style   = this.getResolvedStyle(context);
		let innerRect = getInnerRect(this.rect, style);

		if (this.props.title) {
			innerRect = {
				x:      innerRect.x,
				y:      innerRect.y + 2,
				width:  innerRect.width,
				height: Math.max(0, innerRect.height - 2),
			};
		}

		const entries = this.children.map((child) => ({
			child,
			rect: innerRect,
		}));

		this.layoutChildren(entries, context);
	}

	public override render(context: RenderContext<UIDrawSurface>): void {
		if (!this.visible) return;
		if (this.width <= 0 || this.height <= 0) return;

		const style            = this.getResolvedStyle(context);
		const borderCharacters = style.border?.enabled ? context.theme.borders[style.border.preset ?? 'single'] : undefined;

		drawBox(context.draw, createOptions<DrawBoxOptions>({
			rect: this.rect,
			style,
		})
			.with('borderCharacters', borderCharacters)
			.with('clipRect', context.clipRect)
			.done());

		this.renderTitle(context, style);
		this.renderChildren(context);
	}

	protected override getResolvedStyle(context: UIContext | RenderContext<UIDrawSurface>): Partial<PanelStyle> {
		return this.getStyle(context, (themeStyle) => createOptions<PanelStyle>(themeStyle)
			.with('foregroundColor', this.props.foregroundColor ?? themeStyle.foregroundColor ?? context.theme.palette.text)
			.with('backgroundColor', this.props.backgroundColor ?? themeStyle.backgroundColor ?? context.theme.palette.panel)
			.with('padding', themeStyle.padding ?? 0)
			.with('gapColor', themeStyle.gapColor ?? context.theme.palette.border)
			.with('titleStyle', createOptions<TextStyle>(themeStyle.titleStyle ?? {})
				.with('alignment', themeStyle.titleStyle?.alignment ?? 'left')
				.with('wrap', themeStyle.titleStyle?.wrap ?? 'none')
				.with('ellipsis', themeStyle.titleStyle?.ellipsis ?? true)
				.with('foregroundColor', themeStyle.titleStyle?.foregroundColor ?? this.props.foregroundColor ?? themeStyle.foregroundColor ?? context.theme.palette.text)
				.with('backgroundColor', themeStyle.titleStyle?.backgroundColor ?? this.props.backgroundColor ?? themeStyle.backgroundColor ?? context.theme.palette.panel)
				.done())
			.done());
	}

	private getInnerConstraints(constraints: LayoutConstraints, style: Partial<PanelStyle>): LayoutConstraints {
		const padding          = normalizeInsets(style.padding);
		const borderX          = style.border?.enabled ? 2 : 0;
		const borderY          = style.border?.enabled ? 2 : 0;
		const titleExtraHeight = this.props.title ? 1 : 0;

		const horizontal = padding.left + padding.right + borderX;
		const vertical   = padding.top + padding.bottom + borderY + titleExtraHeight;

		return {
			minWidth:  Math.max(0, constraints.minWidth - horizontal),
			maxWidth:  Math.max(0, constraints.maxWidth - horizontal),
			minHeight: Math.max(0, constraints.minHeight - vertical),
			maxHeight: Math.max(0, constraints.maxHeight - vertical),
		};
	}

	private renderTitle(context: RenderContext<UIDrawSurface>, style: Partial<PanelStyle>): void {
		const title = this.props.title;

		if (!title || this.width <= 0 || this.height <= 0) {
			return;
		}

		const titleY     = style.border?.enabled ? this.y + 1 : this.y;
		const titleX     = style.border?.enabled ? this.x + 1 : this.x;
		const titleWidth = style.border?.enabled ? Math.max(0, this.width - 2) : this.width;

		drawText(context, createOptions<DrawTextOptions>({
			rect:           {
				x:      titleX,
				y:      titleY,
				width:  titleWidth,
				height: 1,
			},
			text:           title,
			fillBackground: style.titleStyle?.backgroundColor !== undefined,
		})
			.with('style', style.titleStyle)
			.with('clipRect', context.clipRect)
			.done());

		if (style.gapColor !== undefined) {
			const gapY = titleY + 1;

			if (gapY < this.y + this.height) {
				drawHorizontalLine(context.draw, {
					x: titleX,
					y: gapY,
				}, titleWidth, '─', style.gapColor, style.backgroundColor, context.clipRect);
			}
		}
	}
}