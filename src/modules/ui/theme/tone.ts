import type {Color, ColorStyle, Theme, Tone} from '@modules/ui/types';
import {createOptions}                       from '@utils/helpers';

export function resolveToneColors(theme: Theme, tone?: Tone): ColorStyle {
	switch (tone) {
		case 'primary':
			return {
				backgroundColor: theme.palette.primary,
				foregroundColor: theme.palette.text,
			};
		case 'success':
			return {
				backgroundColor: theme.palette.success,
				foregroundColor: theme.palette.text,
			};
		case 'warning':
			return {
				backgroundColor: theme.palette.warning,
				foregroundColor: theme.palette.text,
			};
		case 'info':
			return {
				backgroundColor: theme.palette.info,
				foregroundColor: theme.palette.text,
			};
		case 'error':
			return {
				backgroundColor: theme.palette.error,
				foregroundColor: theme.palette.text,
			};
		case 'default':
		default:
			return {
				backgroundColor: theme.palette.surface,
				foregroundColor: theme.palette.text,
			};
	}
}

export function makeToneColorOverride(tone: Tone | undefined, theme: Theme, foregroundColor?: Color, backgroundColor?: Color): Partial<ColorStyle> {
	const toneColors = resolveToneColors(theme, tone);

	return createOptions<ColorStyle>({})
		.with('foregroundColor', foregroundColor ?? toneColors.foregroundColor)
		.with('backgroundColor', backgroundColor ?? toneColors.backgroundColor)
		.done();
}

export function applyTone(style: Partial<ColorStyle>, theme: Theme, tone?: Tone): Partial<ColorStyle> {
	const toneColors = resolveToneColors(theme, tone);

	return {
		...toneColors, ...style,
	};
}