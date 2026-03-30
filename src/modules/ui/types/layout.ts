import type {Rect} from './core';

// ============================================================
// Alignment
// ============================================================

export type HorizontalAlignment = 'start' | 'center' | 'end' | 'stretch';
export type VerticalAlignment = 'start' | 'center' | 'end' | 'stretch';
export type CrossAxisAlignment = 'start' | 'center' | 'end' | 'stretch';

export type MainAxisAlignment = 'start' | 'center' | 'end' | 'space-between' | 'space-around' | 'space-evenly';

// ============================================================
// Layout
// ============================================================

export type Direction = 'row' | 'column';
export type WrapMode = 'nowrap' | 'wrap';

export type Axis = 'x' | 'y';

// ============================================================
// Constraints
// ============================================================

export interface LayoutConstraints {
	minWidth: number;
	maxWidth: number;
	minHeight: number;
	maxHeight: number;
}

// ============================================================
// Measurement
// ============================================================

export interface MeasuredSize {
	width: number;
	height: number;
}

export interface LayoutRect extends Rect {
}

// ============================================================
// Layout options
// ============================================================

export interface StackLayoutOptions {
	direction?: Direction;
	spacing?: number;
	alignment?: CrossAxisAlignment;
	justify?: MainAxisAlignment;
	wrap?: WrapMode;
}

export interface GridLayoutOptions {
	columns?: number;
	columnSpacing?: number;
	rowSpacing?: number;
}

export interface GridItemOptions {
	xs?: number;
	sm?: number;
	md?: number;
	lg?: number;
	xl?: number;
	offset?: number;
}