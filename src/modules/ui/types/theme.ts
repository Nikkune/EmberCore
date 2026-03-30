import type {Color}                                                                                                                                                                                                                             from './core';
import type {BadgeStyle, BorderCharacters, BoxStyle, ButtonStyle, CheckboxStyle, ContainerStyle, LabelStyle, LogViewerStyle, PaginationStyle, PanelStyle, ProgressBarStyle, RadioStyle, SeparatorStyle, StackStyle, StatusBarStyle, TableStyle} from './style';

// ============================================================
// Theme
// ============================================================

export interface ThemePalette {
	backgroundColor: Color;
	surface: Color;
	panel: Color;
	text: Color;
	muted: Color;
	primary: Color;
	secondary: Color;
	accent: Color;
	error: Color;
	success: Color;
	warning: Color;
	info: Color;
	border: Color;
	selection: Color;
}

export interface ThemeBorderSet {
	ascii: BorderCharacters;
	single: BorderCharacters;
}

export interface ThemeComponentStyles {
	button?: Partial<ButtonStyle>;
	label?: Partial<LabelStyle>;
	panel?: Partial<PanelStyle>;
	progressBar?: Partial<ProgressBarStyle>;
	checkbox?: Partial<CheckboxStyle>;
	radio?: Partial<RadioStyle>;
	badge?: Partial<BadgeStyle>;
	separator?: Partial<SeparatorStyle>;
	table?: Partial<TableStyle>;
	statusBar?: Partial<StatusBarStyle>;
	logViewer?: Partial<LogViewerStyle>;
	pagination?: Partial<PaginationStyle>;
	container?: Partial<ContainerStyle>;
	box?: Partial<BoxStyle>;
	stack?: Partial<StackStyle>;
}

export interface Theme {
	name: string;
	palette: ThemePalette;
	borders: ThemeBorderSet;
	components?: ThemeComponentStyles;
}