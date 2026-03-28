import type { BorderCharacters, BorderPreset, Theme, ThemeComponentStyles } from '@modules/ui';

const ASCII_BORDER: BorderCharacters = {
	topLeft: '+',
	topRight: '+',
	bottomLeft: '+',
	bottomRight: '+',
	horizontal: '-',
	vertical: '|',
};

const SINGLE_BORDER: BorderCharacters = {
	topLeft: '┌',
	topRight: '┐',
	bottomLeft: '└',
	bottomRight: '┘',
	horizontal: '─',
	vertical: '│',
};

export const defaultTheme: Theme = {
	name: 'default',
	palette: {
		backgroundColor: colors.black,
		surface: colors.black,
		panel: colors.gray,
		text: colors.white,
		muted: colors.lightGray,
		primary: colors.blue,
		secondary: colors.cyan,
		accent: colors.orange,
		error: colors.red,
		success: colors.lime,
		warning: colors.yellow,
		info: colors.lightBlue,
		border: colors.lightGray,
		selection: colors.blue,
	},
	borders: {
		ascii: ASCII_BORDER,
		single: SINGLE_BORDER,
	},
	components: {},
};

export function getBorderCharacters(theme: Theme, preset: BorderPreset = 'ascii'): BorderCharacters {
	return theme.borders[preset];
}

export function mergeComponentStyle<TStyle>(base: TStyle | undefined, override: Partial<TStyle> | undefined): TStyle | undefined {
	if (!base && !override) {
		return undefined;
	}

	return {
		...(base ?? {}),
		...(override ?? {}),
	} as TStyle;
}

export function mergeThemeComponentStyles(
	base: ThemeComponentStyles | undefined,
	override: ThemeComponentStyles | undefined,
): ThemeComponentStyles | undefined {
	if (!base && !override) {
		return undefined;
	}

	return {
		...(base ?? {}),
		...(override ?? {}),
	};
}
