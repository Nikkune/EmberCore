import {PressableComponent} from '@modules/ui/core/components/pressableComponent';
import {drawBox, type DrawBoxOptions, drawText, type DrawTextOptions, normalizeInsets, resolveTextLines, type ResolveTextLinesOptions} from '@modules/ui/render/renderHelpers';
import type {UIDrawSurface} from '@modules/ui/render/surfaceAdapter';
import {inheritTextColors, makeToneColorOverride} from '@modules/ui/theme/tone';
import type {ButtonProps, ButtonStyle, ComponentDependencies, LayoutConstraints, MeasuredSize, RenderContext, UIContext}                                                                              from '@modules/ui/types';
import {createOptions} from '@utils/helpers';

export class ButtonComponent extends PressableComponent<'button', ButtonProps, UIDrawSurface, ButtonStyle> {
	public constructor(props: ButtonProps, dependencies: ComponentDependencies = {}) {
		super('button', props, dependencies);
	}

	public setLabel(label: string): void {
		this.setProps({label} as Partial<ButtonProps>);
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
			const colors = themeStyle.colors;

			// State colors are the button background; the text keeps its own color.
			// A click flashes the active color; focus alone does not color the button.
			const stateBackground = isDisabled
			                        ? colors?.disabled
			                        : this.flashing
			                          ? colors?.active ?? colors?.selected ?? colors?.pressed
			                          : colors?.default;

			const tone = makeToneColorOverride(
				undefined,
				context.theme,
				this.props.foregroundColor ?? themeStyle.foregroundColor,
				this.props.backgroundColor ?? stateBackground ?? themeStyle.backgroundColor,
			);

			return {
				...themeStyle,
				...tone,

				padding: this.props.padding ?? themeStyle.padding ?? {
					left:  1,
					right: 1,
				},

				text: {
					...inheritTextColors(themeStyle.text, tone, this.props),
					alignment: themeStyle.text?.alignment ?? 'center',
					wrap:      themeStyle.text?.wrap ?? 'none',
					ellipsis:  themeStyle.text?.ellipsis ?? true,
				},
			};
		});
	}
}