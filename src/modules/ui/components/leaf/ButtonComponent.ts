import {drawBox, type DrawBoxOptions, drawText, type DrawTextOptions, makeToneColorOverride, normalizeInsets, PressableComponent, resolveTextLines, type ResolveTextLinesOptions, type UIDrawSurface} from '@modules/ui';
import type {ButtonProps, ButtonStyle, ComponentDependencies, LayoutConstraints, MeasuredSize, RenderContext, UIContext}                                                                              from '@modules/ui/types';
import {createOptions} from '@utils/helpers';

export class ButtonComponent extends PressableComponent<'button', ButtonProps, UIDrawSurface, ButtonStyle> {
	public constructor(props: ButtonProps, dependencies: ComponentDependencies = {}) {
		super('button', props, dependencies);
	}

	public override measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize {
		const style   = this.getResolvedStyle(context);
		const padding = normalizeInsets(style.padding);

		const border = style.border?.enabled ? 2 : 0;

		const width = this.props.width ?? this.props.minWidth ?? constraints.maxWidth;

		const lines = resolveTextLines(createOptions<ResolveTextLinesOptions>({
			text:  this.props.label,
			width: Math.max(0, width - border - padding.left - padding.right),
		})
			.with('style', style.text)
			.done());

		const contentWidth  = lines.reduce((max, l) => Math.max(max, l.text.length), 0);
		const contentHeight = Math.max(1, lines.length);

		return this.createMeasuredSize(
			contentWidth + padding.left + padding.right + border,
			contentHeight + padding.top + padding.bottom + border,
			constraints,
		);
	}

	public override render(context: RenderContext<UIDrawSurface>): void {
		if (!this.visible) return;
		if (this.width <= 0 || this.height <= 0) return;

		const style = this.getResolvedStyle(context);

		const borderCharacters = style.border?.enabled
		                         ? context.theme.borders[style.border.preset ?? 'single']
		                         : undefined;

		const innerRect = drawBox(context.draw, createOptions<DrawBoxOptions>({
			rect: this.rect,
			style,
		})
			.with('borderCharacters', borderCharacters)
			.with('clipRect', context.clipRect)
			.done());

		drawText(context, createOptions<DrawTextOptions>({
			rect:           innerRect,
			text:           this.props.label,
			fillBackground: style.text?.backgroundColor !== undefined,
		})
			.with('style', style.text)
			.with('clipRect', context.clipRect)
			.done());
	}

	protected override onPress(_context: UIContext): boolean {
		this.props.onPress?.();
		return true;
	}

	protected override getResolvedStyle(context: UIContext | RenderContext<UIDrawSurface>): Partial<ButtonStyle> {
		return this.getStyle(context, (themeStyle) => {
			const isDisabled = this.disabled;
			const isFocused  = this.focused;

			const colors = themeStyle.colors;

			const foreground = isDisabled
			                   ? colors?.disabled
			                   : isFocused
			                     ? colors?.active ?? colors?.selected
			                     : colors?.default;

			const background = isDisabled
			                   ? colors?.disabled
			                   : isFocused
			                     ? colors?.active ?? colors?.selected
			                     : colors?.default;

			const tone = makeToneColorOverride(
				undefined,
				context.theme,
				this.props.foregroundColor ?? foreground,
				this.props.backgroundColor ?? background,
			);

			return {
				...themeStyle,
				...tone,

				padding: themeStyle.padding ?? {
					left:  1,
					right: 1,
				},

				text: {
					...themeStyle.text,
					alignment: themeStyle.text?.alignment ?? 'center',
					wrap:      themeStyle.text?.wrap ?? 'none',
					ellipsis:  themeStyle.text?.ellipsis ?? true,
				},
			};
		});
	}
}