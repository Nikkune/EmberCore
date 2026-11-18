import type {BorderCharacters, BorderPreset, Theme, ThemeComponentStyles} from '@modules/ui/types';

const ASCII_BORDER: BorderCharacters = {
	topLeft:     '+',
	topRight:    '+',
	bottomLeft:  '+',
	bottomRight: '+',
	horizontal:  '-',
	vertical:    '|',
};

/**
 * CC:Tweaked drawing character (codes 128-159): a 2x3 pixel cell. Bits: 1 top-left, 2 top-right,
 * 4 middle-left, 8 middle-right, 16 bottom-left. The bottom-right pixel cannot be lit: such
 * shapes use the complementary character with inverted colors (see BorderCharacters.inverted).
 * Built with String.fromCharCode so TypeScriptToLua emits a single byte (a '\x97' literal
 * would be written as two UTF-8 bytes, which CC renders as garbage).
 */
function ccChar(pixels: number): string {
	return String.fromCharCode(0x80 + pixels);
}

// Thin frame drawn on the outer edge of the box (CC drawing characters).
const SINGLE_BORDER: BorderCharacters = {
	topLeft:     ccChar(1 + 2 + 4 + 16),
	topRight:    ccChar(4 + 16),
	bottomLeft:  ccChar(2 + 8),
	bottomRight: ccChar(1 + 4),
	horizontal:  ccChar(1 + 2),
	vertical:    ccChar(1 + 4 + 16),
	top:         ccChar(1 + 2),
	bottom:      ccChar(1 + 2 + 4 + 8),
	left:        ccChar(1 + 4 + 16),
	right:       ccChar(1 + 4 + 16),
	inverted:    ['topRight', 'bottomLeft', 'bottomRight', 'bottom', 'right'],
	rule:        ccChar(4 + 8),
	columnRule:  ccChar(1 + 4 + 16),
};

const DOUBLE_BORDER: BorderCharacters = {
	topLeft:     '#',
	topRight:    '#',
	bottomLeft:  '#',
	bottomRight: '#',
	horizontal:  '=',
	vertical:    'H',
};


const COLORED_BORDER: BorderCharacters = {
	topLeft:     ' ',
	topRight:    ' ',
	bottomLeft:  ' ',
	bottomRight: ' ',
	horizontal:  ' ',
	vertical:    ' ',
};

export const defaultTheme: Theme = {
	name:       'default',
	palette:    {
		backgroundColor: colors.black,
		surface:         colors.black,
		panel:           colors.gray,
		text:            colors.white,
		muted:           colors.lightGray,
		primary:         colors.blue,
		secondary:       colors.cyan,
		accent:          colors.orange,
		error:           colors.red,
		success:         colors.lime,
		warning:         colors.yellow,
		info:            colors.lightBlue,
		border:          colors.lightGray,
		selection:       colors.blue,
	},
	borders:    {
		ascii:  ASCII_BORDER,
		single: SINGLE_BORDER,
		double: DOUBLE_BORDER,
		colored: COLORED_BORDER,
	},
	components: {},
};

/**
 * Same theme with plain ASCII borders and rules (+, -, |) instead of CC drawing characters,
 * e.g. for terminals or screenshots where the drawing characters are not wanted.
 */
export function withAsciiBorders(theme: Theme): Theme {
	return {
		...theme,
		borders: {
			...theme.borders,
			single: ASCII_BORDER,
			double: ASCII_BORDER,
		},
	};
}

/** Character for horizontal rules (separators, table rows, panel titles), from the theme's single preset. */
export function getRuleCharacter(theme: Theme): string {
	return theme.borders.single.rule ?? theme.borders.single.horizontal;
}

/** Character between table columns, from the theme's single preset. */
export function getColumnRuleCharacter(theme: Theme): string {
	return theme.borders.single.columnRule ?? theme.borders.single.vertical;
}

export function getBorderCharacters(theme: Theme, preset: BorderPreset = 'ascii'): BorderCharacters {
	return theme.borders[preset];
}

export function mergeComponentStyle<TStyle>(base: TStyle | undefined, override: Partial<TStyle> | undefined): TStyle | undefined {
	if (!base && !override) {
		return undefined;
	}

	return {
		...(base ?? {}), ...(override ?? {}),
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
		...(base ?? {}), ...(override ?? {}),
	};
}
