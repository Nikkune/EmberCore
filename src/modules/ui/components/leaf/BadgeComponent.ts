import {BaseComponent, drawBox, type DrawBoxOptions, drawText, type DrawTextOptions, makeToneColorOverride, normalizeInsets, resolveTextLines, type ResolveTextLinesOptions, type UIDrawSurface} from '@modules/ui';
import type {BadgeProps, BadgeStyle, ComponentDependencies, LayoutConstraints, MeasuredSize, RenderContext, UIContext}                                                                           from '@modules/ui/types';
import {createOptions}                                                                                                                                                                           from '@utils/helpers';

export class BadgeComponent extends BaseComponent<'badge', BadgeProps, UIDrawSurface, BadgeStyle> {
	public constructor(props: BadgeProps, dependencies: ComponentDependencies = {}) {
		super('badge', props, dependencies);
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

		return this.createMeasuredSize(contentWidth + padding.left + padding.right + border, contentHeight + padding.top + padding.bottom + border, constraints);
	}

	public override render(context: RenderContext<UIDrawSurface>) {
		if (!this.visible) return;
		if (this.width <= 0 || this.height <= 0) return;

		const style = this.getResolvedStyle(context);

		const borderCharacters = style.border?.enabled ? context.theme.borders[style.border.preset ?? 'single'] : undefined;

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

	protected override getResolvedStyle(context: UIContext | RenderContext<UIDrawSurface>): Partial<BadgeStyle> {
		return this.getStyle(context, (themeStyle) => {
			const tone = makeToneColorOverride(themeStyle.tone, context.theme, this.props.foregroundColor, this.props.backgroundColor);

			return {
				...themeStyle, ...tone,
				padding: themeStyle.padding ?? {
					left:  1,
					right: 1,
				},
				text:    {
					...themeStyle.text,
					alignment: themeStyle.text?.alignment ?? 'center',
					wrap: themeStyle.text?.wrap ?? 'none',
					ellipsis: themeStyle.text?.ellipsis ?? true,
				},
			};
		});
	}
}