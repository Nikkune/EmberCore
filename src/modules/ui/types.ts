// =========================
// Geometry
// =========================

export interface Point {
	x: number,
	y: number
}

export interface Size {
	width: number,
	height: number
}

export interface Rect extends Point, Size {
}

export interface Padding {
	top: number;
	right: number;
	bottom: number;
	left: number;
}

export type PaddingLike = number | Partial<Padding>;

// =========================
// Alignment
// =========================

export type HorizontalAlign = "left" | "center" | "right";
export type VerticalAlign = "top" | "middle" | "bottom";

export interface Align {
	horizontal: HorizontalAlign;
	vertical: VerticalAlign;
}

// =========================
// Colors
// =========================

export type Color = number;

export interface ColorPair {
	foreground: Color;
	background: Color;
}

// =========================
// Text
// =========================

export interface TextOptions {
	align?: HorizontalAlign;
	color?: Color;
	backgroundColor?: Color;
	maxWidth?: number;
	ellipsis?: boolean;
}

export interface TextBlock {
	text: string;
	align?: HorizontalAlign;
}

// =========================
// Surface / Drawing
// =========================

export interface WriteOptions {
	color?: Color;
	backgroundColor?: Color;
}

export interface DrawOptions {
	fill?: boolean;
	color?: Color;
	backgroundColor?: Color;
}

// =========================
// Box / Panel
// =========================

export interface BoxOptions {
	border?: boolean;
	title?: string;
	padding?: PaddingLike;
	color?: Color;
	backgroundColor?: Color;
	borderColor?: Color;
	titleBackgroundColor?: Color;
}

// =========================
// Progress Bar
// =========================

export interface ProgressBarOptions {
	value: number;
	maxValue: number;

	width: number;

	label?: string;
	showPercentage?: boolean;

	color?: Color;
	backgroundColor?: Color;
	emptyColor?: Color;
}

// =========================
// Layout (future-proof)
// =========================

export type Direction = "horizontal" | "vertical";

export interface LayoutOptions {
	direction?: Direction;
	spacing?: number;
}

// =========================
// UI State / Components (future)
// =========================

export interface UIComponent {
	draw(): void;
}

export interface PositionedComponent extends UIComponent {
	rect: Rect;
}