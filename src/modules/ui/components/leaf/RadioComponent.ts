import {drawBox, type DrawBoxOptions, drawText, type DrawTextOptions, makeToneColorOverride, normalizeInsets, PressableComponent, resolveTextLines, type ResolveTextLinesOptions, type UIDrawSurface} from '@modules/ui';
import type {RadioGroup}                                                                                                                                                                              from '@modules/ui/components/leaf/RadioGroup';
import type {ComponentDependencies, LayoutConstraints, MeasuredSize, RadioProps, RadioStyle, RenderContext, TextStyle, UIContext}                                                                     from '@modules/ui/types';
import {createOptions}                                                                                                                                                                                from '@utils/helpers';

export class RadioComponent<T = string> extends PressableComponent<'radio', RadioProps<T>, UIDrawSurface, RadioStyle> {
	protected _selected: boolean;
	private readonly radioGroup?: RadioGroup<T> | undefined;
	private unsubscribeGroup?: (() => void) | undefined;

	public constructor(props: RadioProps<T>, dependencies: ComponentDependencies = {}, group?: RadioGroup<T>) {
		super('radio', props, dependencies);

		this.radioGroup = group;
		this._selected  = group ? group.isSelected(props.value) : (props.selected ?? false);

		if (this.radioGroup) {
			this.unsubscribeGroup = this.radioGroup.subscribe((value) => {
				const selected = value === this.props.value;

				if (this._selected === selected) {
					return;
				}

				this._selected = selected;
				this.invalidate(this.createStateInvalidation());
			});
		}
	}

	public override destroy(): void {
		this.unsubscribeGroup?.();
		this.unsubscribeGroup = undefined;
		super.destroy();
	}

	public get selected(): boolean {
		return this._selected;
	}

	public setSelected(value: boolean): void {
		if (this.radioGroup) {
			if (value) {
				this.radioGroup.select(this.props.value);
			} else if (this.radioGroup.isSelected(this.props.value)) {
				this.radioGroup.clear();
			}
			return;
		}

		if (this._selected === value) return;

		this._selected = value;
		this.invalidate(this.createStateInvalidation());
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
				.with('wrap', 'none')
				.with('ellipsis', false)
				.with('foregroundColor', style.dotColor ?? style.text?.foregroundColor ?? context.theme.palette.text)
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
		if (this.radioGroup) {
			const changed = this.radioGroup.select(this.props.value);

			if (changed) {
				this.props.onSelect?.(true);
			}

			return changed;
		}

		if (this._selected) {
			return false;
		}

		this._selected = true;
		this.props.onSelect?.(true);
		return true;
	}

	protected override getResolvedStyle(context: UIContext | RenderContext<UIDrawSurface>): Partial<RadioStyle> {
		return this.getStyle(context, (themeStyle) => {
			const foreground = this.props.foregroundColor ?? themeStyle.foregroundColor;
			const background = this.props.backgroundColor ?? themeStyle.backgroundColor;

			const tone = makeToneColorOverride(undefined, context.theme, foreground, background);

			return {
				...themeStyle, ...tone,
				padding: themeStyle.padding ?? {
					left:  1,
					right: 1,
				},
				text:    {
					...themeStyle.text,
					alignment: themeStyle.text?.alignment ?? 'left',
					wrap:      themeStyle.text?.wrap ?? 'none',
					ellipsis:  themeStyle.text?.ellipsis ?? true,
				},
			};
		});
	}

	private getMarker(style: Partial<RadioStyle>): string {
		if (this._selected) {
			return `(${style.selectedCharacter ?? 'o'})`;
		}

		return `(${style.unselectedCharacter ?? ' '})`;
	}
}