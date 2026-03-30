import type {CheckboxProps, CheckboxStyle, ComponentDependencies,  LayoutConstraints, MeasuredSize, RenderContext, TextStyle, UIContext} from '@modules/ui/types';
import {BaseComponent, drawTextLine, type DrawTextLineOptions, mergeComponentStyle, type UIDrawSurface} from '@modules/ui';
import {createOptions}                                                                                                                   from '@utils/helpers';

export class CheckboxComponent extends BaseComponent<CheckboxProps, UIDrawSurface> {
	public constructor(props: CheckboxProps, dependencies: ComponentDependencies = {}) {
		super('checkbox', props, dependencies.eventBus, dependencies.invalidator);
	}

	public measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize {
		const style = this.getResolvedStyle(context.theme);

		const indicator = this.buildIndicator(this.props.checked, style);
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
		const indicator  = this.buildIndicator(this.props.checked, style);
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

	public setChecked(checked: boolean): void {
		if (this.props.checked === checked) return;

		this.props.checked = checked;
		this.invalidate();

		this.props.onChange?.(checked);
	}

	public toggle(): void {
		this.setChecked(!this.props.checked);
	}

	private renderIndicator(context: RenderContext<UIDrawSurface>, indicator: string, style?: CheckboxStyle): void {
		const leftBracket  = '[';
		const rightBracket = ']';
		const mark         = indicator.length >= 3 ? indicator[1]! : ' ';

		drawTextLine(context.draw, createOptions<DrawTextLineOptions>({
			position: {
				x: this.rect.x,
				y: this.rect.y,
			},
			width:    1,
			text:     leftBracket,
		})
			.with('style', this.resolveBracketStyle(style))
			.done());

		drawTextLine(context.draw, createOptions<DrawTextLineOptions>({
			position: {
				x: this.rect.x + 1,
				y: this.rect.y,
			},
			width:    1,
			text:     mark,
		})
			.with('style', this.resolveCheckStyle(style))
			.done());

		drawTextLine(context.draw, createOptions<DrawTextLineOptions>({
			position: {
				x: this.rect.x + 2,
				y: this.rect.y,
			},
			width:    1,
			text:     rightBracket,
		})
			.with('style', this.resolveBracketStyle(style))
			.done());
	}

	private getResolvedStyle(theme: UIContext['theme']): CheckboxStyle | undefined {
		return mergeComponentStyle(theme.components?.checkbox, this.props.style);
	}

	private buildIndicator(checked: boolean, style?: CheckboxStyle): string {
		const character = checked ? this.resolveCheckedCharacter(style) : this.resolveUncheckedCharacter(style);

		return `[${character}]`;
	}

	private resolveCheckedCharacter(style?: CheckboxStyle): string {
		const value = style?.checkedCharacter;
		if (!value || value.length === 0) return 'x';
		return value[0]!;
	}

	private resolveUncheckedCharacter(style?: CheckboxStyle): string {
		const value = style?.uncheckedCharacter;
		if (!value || value.length === 0) return ' ';
		return value[0]!;
	}

	private resolveBracketStyle(style?: CheckboxStyle): TextStyle {
		return createOptions<TextStyle>({
			alignment: 'left',
			wrap:      'none',
			ellipsis:  false,
		})
			.with('foregroundColor', style?.foregroundColor)
			.with('backgroundColor', style?.backgroundColor)
			.done();
	}

	private resolveCheckStyle(style?: CheckboxStyle): TextStyle {
		return createOptions<TextStyle>({
			alignment: 'left',
			wrap:      'none',
			ellipsis:  false,
		})
			.with('foregroundColor', style?.checkColor ?? style?.foregroundColor)
			.with('backgroundColor', style?.backgroundColor)
			.done();
	}

	private resolveLabelStyle(style?: CheckboxStyle): TextStyle {
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