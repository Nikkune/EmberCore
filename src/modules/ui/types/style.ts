import type {Color, PaddingLike, MarginLike} from './core';

// ============================================================
// Generic style primitives
// ============================================================

export type TextWrap = 'none' | 'word' | 'character';
export type BorderPreset = 'ascii' | 'single';
export type TextAlignment = 'left' | 'center' | 'right';
export type Tone = 'default' | 'primary' | 'success' | 'warning' | 'error' | 'info';

export interface TextStyle {
	foregroundColor?: Color;
	backgroundColor?: Color;
	alignment?: TextAlignment;
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

export interface ColorStyle {
	foregroundColor?: Color;
	backgroundColor?: Color;
}

export interface SpacingStyle {
	margin?: MarginLike;
	padding?: PaddingLike;
}

export interface BoxStyle extends ColorStyle, SpacingStyle {
	border?: BorderStyle;
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

export interface BadgeStyle extends BoxStyle {
	text?: TextStyle;
	tone?: Tone;
}

export interface SeparatorStyle extends ColorStyle {
	character?: string;
	labelStyle?: TextStyle;
}

export interface PanelStyle extends BoxStyle {
	titleStyle?: TextStyle;
	gapColor?: Color;
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

export interface TableStyle extends BoxStyle {
	headerStyle?: TextStyle;
	rowStyle?: TextStyle;
	alternateRowBackgroundColor?: Color;
	separatorColor?: Color;
	showHeader?: boolean;
	showBorders?: boolean;
}

export interface StatusBarSegmentStyle {
	id?: string;
	text: string;
	color?: Color;
	backgroundColor?: Color;
	alignment?: TextAlignment;
	width?: number;
}

export interface StatusBarStyle extends BoxStyle {
	text?: TextStyle;
	segments?: StatusBarSegmentStyle[];
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

export interface GridStyle extends BoxStyle {}