import {BaseComponent, drawHorizontalLine, drawText, type DrawTextOptions, type UIDrawSurface} from '@modules/ui';
import type {ComponentDependencies, LayoutConstraints, MeasuredSize, RenderContext, SeparatorProps, SeparatorStyle, TextStyle, UIContext} from '@modules/ui/types';
import {createOptions} from '@utils/helpers';

export class SeparatorComponent extends BaseComponent<'separator', SeparatorProps, UIDrawSurface, SeparatorStyle> {
	public constructor(props: SeparatorProps, dependencies: ComponentDependencies = {}) {
		super('separator', props, dependencies);
	}

	public override measure(constraints: LayoutConstraints, _context: UIContext): MeasuredSize {
		const label = this.props.label ?? '';
		const width = this.props.width ?? this.props.minWidth ?? Math.max(1, label.length);
		const height = this.props.height ?? this.props.minHeight ?? 1;

		return this.createMeasuredSize(width, height, constraints);
	}

	public override render(context: RenderContext<UIDrawSurface>): void {
		if (!this.visible) return;
		if (this.width <= 0 || this.height <= 0) return;

		const style = this.getResolvedStyle(context);
		const y = this.y + Math.floor((this.height - 1) / 2);
		const character = style.character ?? '─';

		drawHorizontalLine(
			context.draw,
			{x: this.x, y},
			this.width,
			character,
			style.foregroundColor,
			style.backgroundColor,
			context.clipRect,
		);

		const label = this.props.label ?? '';

		if (label.length === 0 || this.width <= 0) {
			return;
		}

		const textWidth = Math.min(this.width, label.length + 2);
		const textX = this.x + Math.max(0, Math.floor((this.width - textWidth) / 2));

		drawText(context, createOptions<DrawTextOptions>({
			rect: {
				x: textX,
				y,
				width: textWidth,
				height: 1,
			},
			text: ` ${label} `,
			fillBackground: style.labelStyle?.backgroundColor !== undefined || style.backgroundColor !== undefined,
		})
			.with('style', style.labelStyle)
			.with('clipRect', context.clipRect)
			.done());
	}

	protected override getResolvedStyle(context: UIContext | RenderContext<UIDrawSurface>): Partial<SeparatorStyle> {
		return this.getStyle(context, (themeStyle) => createOptions<SeparatorStyle>(themeStyle)
			.with('character', themeStyle.character ?? '─')
			.with('foregroundColor', this.props.foregroundColor ?? themeStyle.foregroundColor ?? context.theme.palette.border)
			.with('backgroundColor', this.props.backgroundColor ?? themeStyle.backgroundColor)
			.with('labelStyle', createOptions<TextStyle>(themeStyle.labelStyle ?? {})
				.with('alignment', themeStyle.labelStyle?.alignment ?? 'center')
				.with('wrap', themeStyle.labelStyle?.wrap ?? 'none')
				.with('ellipsis', themeStyle.labelStyle?.ellipsis ?? true)
				.with('foregroundColor', themeStyle.labelStyle?.foregroundColor ?? this.props.foregroundColor ?? themeStyle.foregroundColor ?? context.theme.palette.text)
				.with('backgroundColor', themeStyle.labelStyle?.backgroundColor ?? this.props.backgroundColor ?? themeStyle.backgroundColor)
				.done())
			.done());
	}
}