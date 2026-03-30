import type {BorderCharacters, BoxStyle, ButtonProps, ButtonStyle, Color, ComponentDependencies,  LayoutConstraints, MeasuredSize, RenderContext, TextStyle, UIContext} from '@modules/ui/types';
import {BaseComponent, drawBox, type DrawBoxOptions, drawText, getBorderCharacters, mergeComponentStyle, normalizeInsets, type UIDrawSurface} from '@modules/ui';
import {createOptions}                                                                                                                                                  from '@utils/helpers';

export class ButtonComponent extends BaseComponent<ButtonProps, UIDrawSurface> {
	constructor(props: ButtonProps, dependencies: ComponentDependencies = {}) {
		super('button', props, dependencies.eventBus, dependencies.invalidator);
	}

	public measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize {
		const style = this.getResolvedStyle(context.theme);
		const text  = this.props.label;

		const padding     = normalizeInsets(style?.padding);
		const borderInset = style?.border?.enabled ? 2 : 0;

		const measuredWidth  = text.length + padding.left + padding.right + borderInset;
		const measuredHeight = 1 + padding.top + padding.bottom + borderInset;

		return {
			width:  Math.max(constraints.minWidth, Math.min(this.props.width ?? measuredWidth, constraints.maxWidth)),
			height: Math.max(constraints.minHeight, Math.min(this.props.height ?? measuredHeight, constraints.maxHeight)),
		};
	}

	public render(context: RenderContext<UIDrawSurface>) {
		if (!this.visible || this.rect.width <= 0 || this.rect.height <= 0) return;

		const style            = this.getResolvedStyle(context.theme);
		const boxStyle         = this.resolveBoxStyle(style, context.theme);
		const borderCharacters = this.resolveBorderCharacters(style, context.theme);

		const contentRect = drawBox(context.draw, createOptions<DrawBoxOptions>({
			rect:  this.rect,
			style: boxStyle,
		})
			.with('borderCharacters', borderCharacters)
			.done());

		if (contentRect.width <= 0 || contentRect.height <= 0) return;

		drawText(context, {
			rect:  contentRect,
			text:  this.props.label,
			style: this.resolveTextStyle(style, context.theme),
		});
	}

	public setPressed(pressed: boolean): void {
		if (this.props.pressed === pressed) return;

		this.props.pressed = pressed;
		this.invalidate();
	}

	public press(): void {
		if (this.disabled) return;

		this.setPressed(true);
		this.props.onPress?.();
	}

	public release(): void {
		if (!this.props.pressed) return;

		this.setPressed(false);
	}

	private getResolvedStyle(theme: UIContext['theme']): ButtonStyle | undefined {
		return mergeComponentStyle(theme.components?.button, this.props.style);
	}

	private resolveTextStyle(style: ButtonStyle | undefined, theme: UIContext['theme']): TextStyle {
		const colors = this.resolveStateColors(style, theme);

		return {
			...style?.text,
			foregroundColor: style?.text?.foregroundColor ?? style?.foregroundColor ?? colors.foregroundColor,

			backgroundColor: style?.text?.backgroundColor ?? style?.backgroundColor ?? colors.backgroundColor,

			alignment: style?.text?.alignment ?? 'center',
			ellipsis:  style?.text?.ellipsis ?? true,
			wrap:      style?.text?.wrap ?? 'none',
		};
	}

	private resolveBoxStyle(style: ButtonStyle | undefined, theme: UIContext['theme']): BoxStyle {
		const colors = this.resolveStateColors(style, theme);

		return {
			...style,
			padding:         style?.padding ?? {
				horizontal: 1,
				vertical:   0,
			},
			backgroundColor: style?.backgroundColor ?? colors.backgroundColor,

			foregroundColor: style?.foregroundColor ?? colors.foregroundColor,
		};
	}

	private resolveBorderCharacters(style: ButtonStyle | undefined, theme: UIContext['theme']): BorderCharacters | undefined {
		if (!style?.border?.enabled) {
			return undefined;
		}

		return getBorderCharacters(theme, style.border.preset ?? 'ascii');
	}

	private resolveStateColors(style: ButtonStyle | undefined, theme: UIContext['theme']): {
		foregroundColor: Color;
		backgroundColor: Color;
	} {
		const colors = style?.colors;

		if (this.disabled && colors?.disabled !== undefined) {
			return {
				foregroundColor: theme.palette.text,
				backgroundColor: colors.disabled,
			};
		}

		if (this.props.pressed && colors?.pressed !== undefined) {
			return {
				foregroundColor: theme.palette.text,
				backgroundColor: colors.pressed,
			};
		}

		if (colors?.active !== undefined) {
			return {
				foregroundColor: theme.palette.text,
				backgroundColor: colors.active,
			};
		}

		return {
			foregroundColor: theme.palette.text,
			backgroundColor: theme.palette.surface,
		};
	}
}