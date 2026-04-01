import type {AxisSize, Color, MarginLike, PaddingLike, Rect}             from './core';
import type {UIEventMap}                                                 from './events';
import type {CrossAxisAlignment, Direction, MainAxisAlignment, WrapMode} from './layout';
import type {BorderStyle, TextAlignment}                                 from './style';

// ============================================================
// Base props
// ============================================================

export interface IdentityProps {
	id?: string;
}

export interface VisibilityProps {
	visible?: boolean;
	disabled?: boolean;
	zIndex?: number;
}

export interface MarginProps {
	margin?: MarginLike;
}

export interface PaddingProps {
	padding?: PaddingLike;
}

export interface GeometryProps extends AxisSize {
	rect?: Partial<Rect>;
}

export interface ColorProps {
	backgroundColor?: Color;
	foregroundColor?: Color;
}

export interface BorderProps {
	border?: BorderStyle;
}

export interface AppearanceProps extends ColorProps, BorderProps {}

export interface EventProps {
	on?: UIEventMap;
}

export interface BaseProps extends IdentityProps, VisibilityProps, GeometryProps {}

export interface StyledProps extends BaseProps, AppearanceProps {}

export interface BoxPropsBase extends BaseProps, MarginProps, PaddingProps, AppearanceProps {}

export interface InteractivePropsBase extends BaseProps, EventProps {}

export interface InteractiveBoxPropsBase extends BaseProps, MarginProps, PaddingProps, AppearanceProps, EventProps {}

// ============================================================
// Item models
// ============================================================

export interface StatusBarSegment {
	id?: string;
	text: string;
	color?: Color;
	backgroundColor?: Color;
	width?: number;
	alignment?: 'left' | 'center' | 'right';
}

export interface LogEntry {
	level: 'debug' | 'info' | 'warn' | 'error';
	message: string;
	timestamp?: string;
	meta?: Record<string, unknown>;
}

export interface ColumnDefinition<T = Record<string, unknown>> {
	key: keyof T | string;
	title: string;
	width?: number;
	minWidth?: number;
	maxWidth?: number;
	alignment?: TextAlignment;
	render?: (row: T, rowIndex: number) => string;
}

// ============================================================
// Component props
// ============================================================
// --------------------------- Leaf ---------------------------

export interface BadgeProps extends BoxPropsBase {
	label: string;
}

export interface ButtonProps extends InteractiveBoxPropsBase {
	label: string;
	pressed?: boolean;
	onPress?: () => void;
}

export interface ToggleButtonProps extends ButtonProps {
	onToggle?: (pressed: boolean) => void;
}

export interface CheckboxProps extends InteractiveBoxPropsBase {
	label: string;
	checked: boolean;
	onChange?: (checked: boolean) => void;
}

export interface LabelProps extends BaseProps, MarginProps, ColorProps {
	text: string;
}

export interface PaginationProps extends InteractiveBoxPropsBase {
	page: number;
	pageSize: number;
	totalItems: number;
	onPageChange?: (page: number) => void;
}

export interface ProgressBarProps extends BoxPropsBase {
	value: number;
	maxValue: number;
	minValue?: number;
	label?: string;
}

export interface RadioProps<T = string> extends InteractiveBoxPropsBase {
	label: string;
	value: T;
	selected?: boolean;
	group?: string;
	onSelect?: (checked: boolean) => void;
}

export interface SeparatorProps extends BaseProps, MarginProps, ColorProps {
	label?: string;
}

export interface StatusBarProps extends BaseProps, ColorProps {
	segments: StatusBarSegment[];
}

export interface LogViewerProps extends BoxPropsBase {
	entries: LogEntry[];
	scrollOffset?: number;
}

// ------------------------ Container -------------------------

export interface BoxProps extends BoxPropsBase {
	title?: string;
}

export interface ContainerProps extends BoxPropsBase {}

export interface GridProps extends BoxPropsBase {
	columns?: number;
	rowSpacing?: number;
	columnSpacing?: number;
}

export interface PanelProps extends BoxPropsBase {
	title?: string;
}

export interface StackProps extends BoxPropsBase {
	direction?: Direction;
	spacing?: number;
	alignment?: CrossAxisAlignment;
	justify?: MainAxisAlignment;
	wrap?: WrapMode;
}

export interface TableProps<T = Record<string, unknown>> extends BoxPropsBase {
	columns: ColumnDefinition<T>[];
	rows: T[];
}