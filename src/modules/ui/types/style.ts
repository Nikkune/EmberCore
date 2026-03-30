import type {Color, PaddingLike, MarginLike} from './core';

// ============================================================
// Text / border / generic style
// ============================================================

export type TextWrap = 'none' | 'word' | 'character';
export type BorderPreset = 'ascii' | 'single';

export interface TextStyle {
	foregroundColor?: Color;
	backgroundColor?: Color;
	alignment?: 'left' | 'center' | 'right';
	wrap?: TextWrap;
	ellipsis?: boolean;
}

export interface BorderCharacters {
	topLeft: string;
	topRight: string;
	bottomLeft: string;
	bottomRight: string;
	horizontal: string;
	vertical: string;
}

export interface BorderStyle {
	enabled?: boolean;
	foregroundColor?: Color;
	backgroundColor?: Color;
	characters?: Partial<BorderCharacters>;
	preset?: BorderPreset;
}

export interface FillStyle {
	backgroundColor?: Color;
	character?: string;
}

export interface BoxStyle {
	padding?: PaddingLike;
	margin?: MarginLike;
	border?: BorderStyle;
	backgroundColor?: Color;
	foregroundColor?: Color;
}

export interface StateColors {
	default?: Color;
	active?: Color;
	disabled?: Color;
	selected?: Color;
	pressed?: Color;
	error?: Color;
	success?: Color;
	warning?: Color;
	info?: Color;
}

// ============================================================
// Component-specific styles
// ============================================================

export interface LabelStyle extends TextStyle {}

export interface ButtonStyle extends BoxStyle {
	text?: TextStyle;
	colors?: StateColors;
}

export interface PanelStyle extends BoxStyle {
	titleStyle?: TextStyle;
}

export interface ProgressBarStyle extends BoxStyle {
	fillColor?: Color;
	emptyColor?: Color;
	labelStyle?: TextStyle;
	showPercentage?: boolean;
	characterFilled?: string;
	characterEmpty?: string;
}

export interface CheckboxStyle extends BoxStyle {
	text?: TextStyle;
	checkColor?: Color;
	checkedCharacter?: string;
	uncheckedCharacter?: string;
}

export interface RadioStyle extends BoxStyle {
	text?: TextStyle;
	dotColor?: Color;
	selectedCharacter?: string;
	unselectedCharacter?: string;
}

export interface BadgeStyle extends BoxStyle {
	text?: TextStyle;
	tone?: 'default' | 'primary' | 'success' | 'warning' | 'error' | 'info';
}

export interface SeparatorStyle {
	foregroundColor?: Color;
	backgroundColor?: Color;
	character?: string;
	labelStyle?: TextStyle;
}

export interface TableStyle extends BoxStyle {
	headerStyle?: TextStyle;
	rowStyle?: TextStyle;
	alternateRowBackgroundColor?: Color;
	separatorColor?: Color;
	showHeader?: boolean;
	showBorders?: boolean;
}

export interface StatusBarStyle extends BoxStyle {
	text?: TextStyle;
	segments?: Array<{
		id?: string;
		text: string;
		color?: Color;
		backgroundColor?: Color;
		alignment?: 'left' | 'center' | 'right';
		width?: number;
	}>;
}

export interface LogViewerStyle extends BoxStyle {
	lineStyle?: TextStyle;
	levelColors?: Partial<Record<'debug' | 'info' | 'warn' | 'error', Color>>;
	autoScroll?: boolean;
	showTimestamp?: boolean;
}

export interface PaginationStyle extends BoxStyle {
	text?: TextStyle;
	activeColor?: Color;
	inactiveColor?: Color;
	showFirstLast?: boolean;
	showPrevNext?: boolean;
}

export interface ContainerStyle extends BoxStyle {}

export interface StackStyle extends BoxStyle {}