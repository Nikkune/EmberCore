import {BaseComponent, drawBox, type DrawBoxOptions, drawText, type DrawTextOptions, fillRect, type FillRectOptions, normalizeInsets, type UIDrawSurface} from '@modules/ui';
import type {ComponentDependencies, LayoutConstraints, MeasuredSize, ProgressBarProps, ProgressBarStyle, RenderContext, TextStyle, UIContext}             from '@modules/ui/types';
import {createOptions}                                                                                                                                    from '@utils/helpers';

export class ProgressBarComponent extends BaseComponent<'progress_bar', ProgressBarProps, UIDrawSurface, ProgressBarStyle> {
	public constructor(props: ProgressBarProps, dependencies: ComponentDependencies = {}) {
		super('progress_bar', props, dependencies);
	}

	public get minValue(): number {
		return this.props.minValue ?? 0;
	}

	public get maxValue(): number {
		return Math.max(this.minValue, this.props.maxValue);
	}

	public get value(): number {
		return this.clamp(this.props.value, this.minValue, this.maxValue);
	}

	public get progress(): number {
		const range = this.maxValue - this.minValue;

		if (range <= 0) {
			return 0;
		}

		return (this.value - this.minValue) / range;
	}

	public override measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize {
		const style   = this.getResolvedStyle(context);
		const padding = normalizeInsets(style.padding);
		const border  = style.border?.enabled ? 2 : 0;

		const contentText  = this.getDisplayText(style);
		const contentWidth = Math.max(1, contentText.length);

		const width = this.props.width ?? this.props.minWidth ?? (contentWidth + padding.left + padding.right + border);

		const height = this.props.height ?? this.props.minHeight ?? (1 + padding.top + padding.bottom + border);

		return this.createMeasuredSize(width, height, constraints);
	}

	public override render(context: RenderContext<UIDrawSurface>): void {
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

		if (innerRect.width <= 0 || innerRect.height <= 0) {
			return;
		}

		const filledWidth = this.progress > 0 ? Math.max(1, Math.floor(innerRect.width * this.progress)) : 0;
		const emptyWidth  = Math.max(0, innerRect.width - filledWidth);

		if (filledWidth > 0) {
			fillRect(context.draw, createOptions<FillRectOptions>({
				rect:      {
					x:      innerRect.x,
					y:      innerRect.y,
					width:  filledWidth,
					height: innerRect.height,
				},
				character: style.characterFilled ?? ' ',
			})
				.with('backgroundColor', style.fillColor)
				.with('foregroundColor', style.fillColor)
				.with('clipRect', context.clipRect)
				.done());
		}

		if (emptyWidth > 0 && style.emptyColor !== undefined) {
			fillRect(context.draw, createOptions<FillRectOptions>({
				rect:      {
					x:      innerRect.x + filledWidth,
					y:      innerRect.y,
					width:  emptyWidth,
					height: innerRect.height,
				},
				character: style.characterEmpty ?? ' ',
			})
				.with('backgroundColor', style.emptyColor)
				.with('foregroundColor', style.emptyColor)
				.with('clipRect', context.clipRect)
				.done());
		}

		const text = this.getDisplayText(style);

		if (text.length > 0) {
			drawText(context, createOptions<DrawTextOptions>({
				rect:           innerRect,
				text,
				fillBackground: false,
			})
				.with('style', style.labelStyle)
				.with('clipRect', context.clipRect)
				.done());
		}
	}

	protected override getResolvedStyle(context: UIContext | RenderContext<UIDrawSurface>): Partial<ProgressBarStyle> {
		return this.getStyle(context, (themeStyle) => createOptions<ProgressBarStyle>(themeStyle)
			.with('padding', themeStyle.padding ?? 0)
			.with('fillColor', themeStyle.fillColor ?? context.theme.palette.primary)
			.with('emptyColor', themeStyle.emptyColor ?? context.theme.palette.surface)
			.with('showPercentage', themeStyle.showPercentage ?? true)
			.with('characterFilled', themeStyle.characterFilled ?? ' ')
			.with('characterEmpty', themeStyle.characterEmpty ?? ' ')
			.with('labelStyle', createOptions<TextStyle>(themeStyle.labelStyle ?? {})
				.with('alignment', themeStyle.labelStyle?.alignment ?? 'center')
				.with('wrap', themeStyle.labelStyle?.wrap ?? 'none')
				.with('ellipsis', themeStyle.labelStyle?.ellipsis ?? true)
				.with('foregroundColor', themeStyle.labelStyle?.foregroundColor ?? this.props.foregroundColor ?? context.theme.palette.text)
				.with('backgroundColor', themeStyle.labelStyle?.backgroundColor)
				.done())
			.done());
	}

	private getDisplayText(style: Partial<ProgressBarStyle>): string {
		const parts: string[] = [];

		if (this.props.label) {
			parts.push(this.props.label);
		}

		if (style.showPercentage) {
			parts.push(`${Math.floor(this.progress * 100)}%`);
		}

		return parts.join(' ');
	}
}