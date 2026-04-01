// ============================================================
// Core primitives
// ============================================================

export type Color = number;
export type Maybe<T> = T | undefined;
export type MaybeProps<T> = { [K in keyof T]?: T[K] | undefined}

// ============================================================
// Geometry
// ============================================================

export interface Point {
	x: number;
	y: number;
}

export interface Size {
	width: number;
	height: number;
}

export interface Rect extends Point, Size {}

export interface RectCorner {
	topLeft: Point;
	topRight: Point;
	bottomLeft: Point;
	bottomRight: Point;
}

// ============================================================
// Spacing
// ============================================================

export interface Insets {
	top: number;
	right: number;
	bottom: number;
	left: number;
}

export interface AxisSize {
	width?: number;
	height?: number;
	minWidth?: number;
	minHeight?: number;
	maxWidth?: number;
	maxHeight?: number;
}

export interface AxisInsets {
	x: number;
	y: number;
}

export interface DirectionalInsets {
	horizontal: number;
	vertical: number;
}


export type PaddingLike =
	| number
	| Partial<Insets>
	| Partial<AxisInsets>
	| Partial<DirectionalInsets>

export type MarginLike = PaddingLike;