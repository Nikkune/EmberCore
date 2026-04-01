import {drawBox, type DrawBoxOptions, drawText, type DrawTextOptions, makeToneColorOverride, normalizeInsets, PressableComponent, resolveTextLines, type ResolveTextLinesOptions, type UIDrawSurface} from '@modules/ui';
import type {ButtonStyle, ComponentDependencies, LayoutConstraints, MeasuredSize, RenderContext, ToggleButtonProps, UIContext}                                                                        from '@modules/ui/types';
import {createOptions}                                                                                                                                                                                from '@utils/helpers';

export class ToggleButtonComponent extends PressableComponent<'button', ToggleButtonProps, UIDrawSurface, ButtonStyle> {
	protected _pressed: boolean;

	public constructor(props: ToggleButtonProps, dependencies: ComponentDependencies = {}) {
		super('button', props, dependencies);
		this._pressed = props.pressed ?? false;
	}

	public get pressed(): boolean {
		return this._pressed;
	}

	public setPressed(value: boolean): void {
		if (this._pressed === value) return;

		this._pressed = value;
		this.invalidate(this.createStateInvalidation());
	}

	public toggle(): void {
		this.setPressed(!this._pressed);
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

		const contentWidth  = lines.reduce((max, line) => Math.max(max, line.text.length), 0);
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
		this.toggle();

		this.props.onToggle?.(this._pressed);
		this.props.onPress?.();

		return true;
	}

	protected override getResolvedStyle(context: UIContext | RenderContext<UIDrawSurface>): Partial<ButtonStyle> {
		return this.getStyle(context, (themeStyle) => {
			const colors = themeStyle.colors;

			const foreground = this.disabled ? colors?.disabled : this._pressed ? colors?.pressed ?? colors?.active ?? colors?.selected : this.focused ? colors?.active ?? colors?.selected : colors?.default;

			const background = this.disabled ? colors?.disabled : this._pressed ? colors?.pressed ?? colors?.active ?? colors?.selected : this.focused ? colors?.active ?? colors?.selected : colors?.default;

			const tone = makeToneColorOverride(undefined, context.theme, this.props.foregroundColor ?? foreground, this.props.backgroundColor ?? background);

			return {
				...themeStyle, ...tone,
				padding: themeStyle.padding ?? {
					left:  1,
					right: 1,
				},
				text:    {
					...themeStyle.text,
					alignment: themeStyle.text?.alignment ?? 'center',
					wrap:      themeStyle.text?.wrap ?? 'none',
					ellipsis:  themeStyle.text?.ellipsis ?? true,
				},
			};
		});
	}
}