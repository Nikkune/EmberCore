import type {ComponentDependencies, DrawTextLineOptions, LayoutConstraints, MeasuredSize, RadioProps, RadioStyle, RenderContext, TextStyle, UIContext, UIDrawSurface} from '@modules/ui';
import {BaseComponent, drawTextLine, mergeComponentStyle}                                                                                                             from '@modules/ui';
import {createOptions}                                                                                                                                                from '@utils/helpers';

export class RadioComponent<T = string> extends BaseComponent<RadioProps<T>, UIDrawSurface> {
	public constructor(props: RadioProps<T>, dependencies: ComponentDependencies = {}) {
		super('radio', props, dependencies.eventBus, dependencies.invalidator);
	}

	public measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize {
		const style = this.getResolvedStyle(context.theme);

		const indicator = this.buildIndicator(this.props.selected ?? false, style);
		const text      = this.props.label.length > 0 ? `${indicator} ${this.props.label}` : indicator;

		const measuredWidth = Math.max(text.length, 1);

		return {
			width:  Math.max(constraints.minWidth, Math.min(this.props.width ?? measuredWidth, constraints.maxWidth)),
			height: Math.max(constraints.minHeight, Math.min(this.props.height ?? 1, constraints.maxHeight)),
		};
	}

	public render(context: RenderContext<UIDrawSurface>): void {
		if (!this.visible || this.rect.width <= 0 || this.rect.height <= 0) return;

		const style      = this.getResolvedStyle(context.theme);
		const indicator  = this.buildIndicator(this.props.selected ?? false, style);
		const labelX     = this.rect.x + indicator.length + 1;
		const labelWidth = Math.max(0, this.rect.width - indicator.length - 1);

		this.renderIndicator(context, indicator, style);

		if (this.props.label.length > 0 && labelWidth > 0) {
			drawTextLine(context.draw, createOptions<DrawTextLineOptions>({
				position: {
					x: labelX,
					y: this.rect.y,
				},
				width:    labelWidth,
				text:     this.props.label,
			})
				.with('style', this.resolveLabelStyle(style))
				.done());
		}
	}

	public setSelected(selected: boolean): void {
		if ((this.props.selected ?? false) === selected) return;

		this.props.selected = selected;
		this.invalidate();

		if (selected) {
			this.props.onSelect?.(this.props.value);
		}
	}

	public select(): void {
		this.setSelected(true);
	}

	private getResolvedStyle(theme: UIContext['theme']): RadioStyle | undefined {
		return mergeComponentStyle(theme.components?.radio, this.props.style);
	}

	private buildIndicator(selected: boolean, style?: RadioStyle): string {
		const character = selected ? this.resolveSelectedCharacter(style) : this.resolveUnselectedCharacter(style);

		return `(${character})`;
	}

	private renderIndicator(context: RenderContext<UIDrawSurface>, indicator: string, style?: RadioStyle): void {
		const left  = '(';
		const right = ')';
		const dot   = indicator.length >= 3 ? indicator[1]! : ' ';

		drawTextLine(context.draw, createOptions<DrawTextLineOptions>({
			position: {
				x: this.rect.x,
				y: this.rect.y,
			},
			width:    1,
			text:     left,
		})
			.with('style', this.resolveBracketStyle(style))
			.done());

		drawTextLine(context.draw, createOptions<DrawTextLineOptions>({
			position: {
				x: this.rect.x + 1,
				y: this.rect.y,
			},
			width:    1,
			text:     dot,
		})
			.with('style', this.resolveDotStyle(style))
			.done());

		drawTextLine(context.draw, createOptions<DrawTextLineOptions>({
			position: {
				x: this.rect.x + 2,
				y: this.rect.y,
			},
			width:    1,
			text:     right,
		})
			.with('style', this.resolveBracketStyle(style))
			.done());
	}

	private resolveSelectedCharacter(style?: RadioStyle): string {
		const value = style?.selectedCharacter;
		if (!value || value.length === 0) return '*';
		return value[0]!;
	}

	private resolveUnselectedCharacter(style?: RadioStyle): string {
		const value = style?.unselectedCharacter;
		if (!value || value.length === 0) return ' ';
		return value[0]!;
	}

	private resolveBracketStyle(style?: RadioStyle): TextStyle {
		return createOptions<TextStyle>({
			alignment: 'left',
			wrap:      'none',
			ellipsis:  false,
		})
			.with('foregroundColor', style?.foregroundColor)
			.with('backgroundColor', style?.backgroundColor)
			.done();
	}

	private resolveDotStyle(style?: RadioStyle): TextStyle {
		return createOptions<TextStyle>({
			alignment: 'left',
			wrap:      'none',
			ellipsis:  false,
		})
			.with('foregroundColor', style?.dotColor ?? style?.foregroundColor)
			.with('backgroundColor', style?.backgroundColor)
			.done();
	}

	private resolveLabelStyle(style?: RadioStyle): TextStyle {
		return createOptions<TextStyle>({
			alignment: style?.text?.alignment ?? 'left',
			wrap:      style?.text?.wrap ?? 'none',
			ellipsis:  style?.text?.ellipsis ?? true,
		})
			.with('foregroundColor', style?.text?.foregroundColor ?? style?.foregroundColor)
			.with('backgroundColor', style?.text?.backgroundColor ?? style?.backgroundColor)
			.done();
	}
}