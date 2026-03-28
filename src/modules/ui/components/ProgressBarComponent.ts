import type {ComponentDependencies, DrawTextLineOptions, LayoutConstraints, MeasuredSize, ProgressBarProps, ProgressBarStyle, RenderContext, TextStyle, UIContext, UIDrawSurface} from '@modules/ui';
import {BaseComponent, clamp, drawHorizontalLine, drawTextLine, mergeComponentStyle}                                                                                              from '@modules/ui';
import {createOptions}                                                                                                                                                            from '@utils/helpers';

export class ProgressBarComponent extends BaseComponent<ProgressBarProps, UIDrawSurface> {
	public constructor(props: ProgressBarProps, dependencies: ComponentDependencies = {}) {
		super('progress_bar', props, dependencies.eventBus, dependencies.invalidator);
	}

	public measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize {
		const style = this.getResolvedStyle(context.theme);

		const minValue = this.props.minValue ?? 0;
		const maxValue = this.props.maxValue;
		const value    = clamp(this.props.value, minValue, maxValue);

		const label         = this.resolveLabel(value, minValue, maxValue, style);
		const measuredWidth = Math.max(label.length, 1);

		return {
			width:  Math.max(constraints.minWidth, Math.min(this.props.width ?? measuredWidth, constraints.maxWidth)),
			height: Math.max(constraints.minHeight, Math.min(this.props.height ?? 1, constraints.maxHeight)),
		};
	}

	public render(context: RenderContext<UIDrawSurface>) {
		if (!this.visible || this.rect.width <= 0 || this.rect.height <= 0) return;

		const style = this.getResolvedStyle(context.theme);

		const minValue = this.props.minValue ?? 0;
		const maxValue = this.props.maxValue;
		const value    = clamp(this.props.value, minValue, maxValue);

		const ratio       = this.resolveRatio(value, minValue, maxValue);
		const filledWidth = Math.max(0, Math.min(this.rect.width, Math.floor(this.rect.width * ratio)));

		const filledCharacter = this.resolveFilledCharacter(style);
		const emptyCharacter  = this.resolveEmptyCharacter(style);
		const y               = this.rect.y;

		if (filledWidth > 0) {
			drawHorizontalLine(context.draw, {
				x: this.rect.x,
				y,
			}, filledWidth, filledCharacter, style?.fillColor ?? style?.foregroundColor, style?.backgroundColor);
		}

		if (filledWidth < this.rect.width) {
			drawHorizontalLine(context.draw, {
				x: this.rect.x + filledWidth,
				y,
			}, this.rect.width - filledWidth, emptyCharacter, style?.emptyColor ?? style?.foregroundColor, style?.backgroundColor);
		}

		const label = this.resolveLabel(value, minValue, maxValue, style);

		if (label.length <= 0) return;

		drawTextLine(context.draw, createOptions<DrawTextLineOptions>({
			position: {
				x: this.rect.x,
				y,
			},
			width:    this.rect.width,
			text:     label,
		})
			.with('style', this.resolveLabelStyle(style))
			.done());
	}

	private getResolvedStyle(theme: UIContext['theme']): ProgressBarStyle | undefined {
		return mergeComponentStyle(theme.components?.progressBar, this.props.style);
	}

	private resolveRatio(value: number, minValue: number, maxValue: number): number {
		const range = maxValue - minValue;

		if (range <= 0) {
			return 0;
		}

		return (value - minValue) / range;
	}

	private resolveLabel(value: number, minValue: number, maxValue: number, style?: ProgressBarStyle): string {
		if (this.props.label && this.props.label.length > 0) {
			return this.props.label;
		}

		if (style?.showPercentage === false) {
			return `${value}/${maxValue}`;
		}

		const ratio = this.resolveRatio(value, minValue, maxValue);
		return `${Math.floor(ratio * 100)}%`;
	}

	private resolveFilledCharacter(style?: ProgressBarStyle): string {
		const value = style?.characterFilled;
		if (!value || value.length === 0) return '#';
		return value[0]!;
	}

	private resolveEmptyCharacter(style?: ProgressBarStyle): string {
		const value = style?.characterEmpty;
		if (!value || value.length === 0) return '-';
		return value[0]!;
	}

	private resolveLabelStyle(style?: ProgressBarStyle): TextStyle {
		return createOptions<TextStyle>({
			alignment: style?.labelStyle?.alignment ?? 'center',
			wrap:      style?.labelStyle?.wrap ?? 'none',
			ellipsis:  style?.labelStyle?.ellipsis ?? true,
		})
			.with('foregroundColor', style?.labelStyle?.foregroundColor ?? style?.foregroundColor)
			.with('backgroundColor', style?.labelStyle?.backgroundColor ?? style?.backgroundColor)
			.done();
	}
}