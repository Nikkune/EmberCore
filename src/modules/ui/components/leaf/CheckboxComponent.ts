import {drawBox, type DrawBoxOptions, drawText, type DrawTextOptions, makeToneColorOverride, normalizeInsets, PressableComponent, resolveTextLines, type ResolveTextLinesOptions, type UIDrawSurface} from '@modules/ui';
import type {CheckboxProps, CheckboxStyle, ComponentDependencies, LayoutConstraints, MeasuredSize, RenderContext, TextStyle, UIContext}                                                               from '@modules/ui/types';
import {createOptions}                                                                                                                                                                                from '@utils/helpers';

export class CheckboxComponent extends PressableComponent<'checkbox', CheckboxProps, UIDrawSurface, CheckboxStyle> {
	protected _checked: boolean;

	public constructor(props: CheckboxProps, dependencies: ComponentDependencies = {}) {
		super('checkbox', props, dependencies);
		this._checked = props.checked;
	}

	public get checked(): boolean {
		return this._checked;
	}

	public setChecked(value: boolean): void {
		if (this._checked === value) return;

		this._checked = value;
		this.invalidate(this.createStateInvalidation());
	}

	public toggle(): void {
		this.setChecked(!this._checked);
	}

	public override measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize {
		const style   = this.getResolvedStyle(context);
		const padding = normalizeInsets(style.padding);

		const border         = style.border?.enabled ? 2 : 0;
		const marker         = this.getMarker(style);
		const contentPrefix  = `${marker} `;
		const availableWidth = Math.max(0, (this.props.width ?? this.props.minWidth ?? constraints.maxWidth) - border - padding.left - padding.right);

		const textWidth = Math.max(0, availableWidth - contentPrefix.length);

		const lines = resolveTextLines(createOptions<ResolveTextLinesOptions>({
			text:  this.props.label,
			width: textWidth,
		})
			.with('style', style.text)
			.done());

		const contentWidth = lines.reduce((max, line) => {
			const lineWidth = contentPrefix.length + line.text.length;
			return Math.max(max, lineWidth);
		}, contentPrefix.length);

		const contentHeight = Math.max(1, lines.length);

		return this.createMeasuredSize(contentWidth + padding.left + padding.right + border, contentHeight + padding.top + padding.bottom + border, constraints);
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

		const marker      = this.getMarker(style);
		const markerText  = `${marker} `;
		const markerWidth = Math.min(markerText.length, innerRect.width);

		drawText(context, createOptions<DrawTextOptions>({
			rect:           {
				x:      innerRect.x,
				y:      innerRect.y,
				width:  markerWidth,
				height: innerRect.height,
			},
			text:           markerText,
			fillBackground: style.text?.backgroundColor !== undefined,
		})
			.with('style', createOptions<TextStyle>({
				...style.text,
			})
				.with('foregroundColor', style.checkColor ?? style.text?.foregroundColor ?? context.theme.palette.text)
				.with('wrap', 'none')
				.with('ellipsis', false)
				.done())
			.with('clipRect', context.clipRect)
			.done());

		const textRectWidth = Math.max(0, innerRect.width - markerText.length);

		if (textRectWidth <= 0) {
			return;
		}

		drawText(context, createOptions<DrawTextOptions>({
			rect:           {
				x:      innerRect.x + markerText.length,
				y:      innerRect.y,
				width:  textRectWidth,
				height: innerRect.height,
			},
			text:           this.props.label,
			fillBackground: style.text?.backgroundColor !== undefined,
		})
			.with('style', style.text)
			.with('clipRect', context.clipRect)
			.done());
	}

	protected override onPress(_context: UIContext): boolean {
		this.toggle();
		this.props.onChange?.(this._checked);
		return true;
	}

	protected override getResolvedStyle(context: UIContext | RenderContext<UIDrawSurface>): Partial<CheckboxStyle> {
		return this.getStyle(context, (themeStyle) => {
			const tone = makeToneColorOverride(undefined, context.theme, this.props.foregroundColor ?? themeStyle.foregroundColor, this.props.backgroundColor ?? themeStyle.backgroundColor);

			return {
				...themeStyle, ...tone,

				padding: themeStyle.padding ?? {
					left:  1,
					right: 1,
				},

				text: {
					...themeStyle.text,
					alignment: themeStyle.text?.alignment ?? 'left',
					wrap:      themeStyle.text?.wrap ?? 'none',
					ellipsis:  themeStyle.text?.ellipsis ?? true,
				},
			};
		});
	}

	private getMarker(style: Partial<CheckboxStyle>): string {
		if (this._checked) {
			return `[${style.checkedCharacter ?? 'x'}]`;
		}

		return `[${style.uncheckedCharacter ?? ' '}]`;
	}
}