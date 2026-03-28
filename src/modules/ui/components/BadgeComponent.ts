import type {BadgeProps, BadgeStyle, BorderCharacters, BoxStyle, Color, ComponentDependencies, DrawBoxOptions, LayoutConstraints, MeasuredSize, RenderContext, TextStyle, UIContext, UIDrawSurface} from '@modules/ui';
import {BaseComponent, drawBox, drawText, getBorderCharacters, mergeComponentStyle, normalizeInsets}                                                                                                from '@modules/ui';
import {createOptions}                                                                                                                                                                              from '@utils/helpers';

export class BadgeComponent extends BaseComponent<BadgeProps, UIDrawSurface> {
	constructor(props: BadgeProps, dependencies: ComponentDependencies = {}) {
		super('badge', props, dependencies.eventBus, dependencies.invalidator);
	}

	public measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize {
		const style       = this.getResolvedStyle(context.theme);
		const text        = this.props.label;
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

	private getResolvedStyle(theme: UIContext['theme']): BadgeStyle | undefined {
		return mergeComponentStyle(theme.components?.badge, this.props.style);
	}

	private resolveTextStyle(style: BadgeStyle | undefined, contextTheme: UIContext['theme']): TextStyle {
		const toneColors = this.resolveToneColors(style, contextTheme);

		return {
			...style?.text,
			foregroundColor: style?.text?.foregroundColor ?? style?.foregroundColor ?? toneColors.foregroundColor,
			backgroundColor: style?.text?.backgroundColor ?? style?.backgroundColor ?? toneColors.backgroundColor,
			alignment:       style?.text?.alignment ?? 'center',
			ellipsis:        style?.text?.ellipsis ?? true,
			wrap:            style?.text?.wrap ?? 'none',
		};
	}

	private resolveBoxStyle(style: BadgeStyle | undefined, theme: UIContext['theme']): BoxStyle {
		const toneColors = this.resolveToneColors(style, theme);

		return {
			...style,
			padding:         style?.padding ?? {
				horizontal: 1,
			},
			backgroundColor: style?.backgroundColor ?? toneColors.backgroundColor,
			foregroundColor: style?.foregroundColor ?? toneColors.foregroundColor,
		};
	}

	private resolveBorderCharacters(style: BadgeStyle | undefined, theme: UIContext['theme']): BorderCharacters | undefined {
		if (!style?.border?.enabled) {
			return undefined;
		}

		return getBorderCharacters(theme, style.border.preset ?? 'ascii');
	}

	private resolveToneColors(style: BadgeStyle | undefined, theme: UIContext['theme']): {
		foregroundColor: Color;
		backgroundColor: Color;
	} {
		switch (style?.tone) {
			case 'primary':
				return {
					foregroundColor: theme.palette.text,
					backgroundColor: theme.palette.primary,
				};

			case 'success':
				return {
					foregroundColor: theme.palette.text,
					backgroundColor: theme.palette.success,
				};

			case 'warning':
				return {
					foregroundColor: theme.palette.text,
					backgroundColor: theme.palette.warning,
				};

			case 'error':
				return {
					foregroundColor: theme.palette.text,
					backgroundColor: theme.palette.error,
				};

			case 'info':
				return {
					foregroundColor: theme.palette.text,
					backgroundColor: theme.palette.info,
				};

			case 'default':
			default:
				return {
					foregroundColor: theme.palette.text,
					backgroundColor: theme.palette.surface,
				};
		}
	}
}
