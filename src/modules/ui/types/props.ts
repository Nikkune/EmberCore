import type {BaseProps}                                                                                                                                                                                                                   from './component';
import type {Color}                                                                                                                                                                                                                       from './core';
import type {CrossAxisAlignment, Direction, MainAxisAlignment, WrapMode}                                                                                                                                                                 from './layout';
import type {BadgeStyle, BoxStyle, ButtonStyle, CheckboxStyle, ContainerStyle, LabelStyle, ListStyle, LogViewerStyle, PaginationStyle, PanelStyle, ProgressBarStyle, RadioStyle, SeparatorStyle, StackStyle, StatusBarStyle, TableStyle} from './style';

// ============================================================
// Shared item models
// ============================================================

export interface OptionItem<T = string> {
	label: string;
	value: T;
	disabled?: boolean;
	description?: string;
}

export interface ColumnDefinition<T = Record<string, unknown>> {
	key: keyof T | string;
	title: string;
	width?: number;
	minWidth?: number;
	maxWidth?: number;
	alignment?: 'left' | 'center' | 'right';
	render?: (row: T, rowIndex: number) => string;
}

export interface PaginationState {
	page: number;
	pageSize: number;
	totalItems: number;
	totalPages: number;
}

export interface SelectionState<T = string> {
	selectedIndex?: number;
	selectedValue?: T;
}

export interface LogEntry {
	level: 'debug' | 'info' | 'warn' | 'error';
	message: string;
	timestamp?: string;
	meta?: Record<string, unknown>;
}

export interface StatusBarSegment {
	id?: string;
	text: string;
	color?: Color;
	backgroundColor?: Color;
	width?: number;
	alignment?: 'left' | 'center' | 'right';
}

// ============================================================
// Component props
// ============================================================

export interface LabelProps extends BaseProps {
	text: string;
	style?: LabelStyle;
}

export interface ButtonProps extends BaseProps {
	label: string;
	pressed?: boolean;
	style?: ButtonStyle;
	onPress?: () => void;
}

export interface ProgressBarProps extends BaseProps {
	value: number;
	minValue?: number;
	maxValue: number;
	label?: string;
	style?: ProgressBarStyle;
}

export interface CheckboxProps extends BaseProps {
	label: string;
	checked: boolean;
	style?: CheckboxStyle;
	onChange?: (checked: boolean) => void;
}

export interface RadioProps<T = string> extends BaseProps {
	label: string;
	value: T;
	selected?: boolean;
	group?: string;
	style?: RadioStyle;
	onSelect?: (value: T) => void;
}

export interface BadgeProps extends BaseProps {
	label: string;
	style?: BadgeStyle;
}

export interface SeparatorProps extends BaseProps {
	label?: string;
	style?: SeparatorStyle;
}

export interface PanelProps extends BaseProps {
	title?: string;
	style?: PanelStyle;
}

export interface BoxProps extends BaseProps {
	title?: string;
	style?: BoxStyle;
}

export interface ContainerProps extends BaseProps {
	style?: ContainerStyle;
}

export interface StackProps extends BaseProps {
	direction?: Direction;
	spacing?: number;
	alignment?: CrossAxisAlignment;
	justify?: MainAxisAlignment;
	wrap?: WrapMode;
	style?: StackStyle;
}

export interface GridProps extends BaseProps {
	columns?: number;
	columnSpacing?: number;
	rowSpacing?: number;
}

export interface ListProps<T = string> extends BaseProps {
	items: OptionItem<T>[];
	selectedIndex?: number;
	style?: ListStyle;
	onSelect?: (item: OptionItem<T>, index: number) => void;
}

export interface TableProps<T = Record<string, unknown>> extends BaseProps {
	columns: ColumnDefinition<T>[];
	rows: T[];
	rowKey?: (row: T, index: number) => string;
	selectedIndex?: number;
	style?: TableStyle;
	onSelect?: (row: T, index: number) => void;
}

export interface LogViewerProps extends BaseProps {
	entries: LogEntry[];
	scrollOffset?: number;
	style?: LogViewerStyle;
}

export interface PaginationProps extends BaseProps {
	page: number;
	pageSize: number;
	totalItems: number;
	style?: PaginationStyle;
	onPageChange?: (page: number) => void;
}

export interface StatusBarProps extends BaseProps {
	segments: StatusBarSegment[];
	style?: StatusBarStyle;
}

export interface RadioGroupProps<T = string> extends BaseProps {
	items: OptionItem<T>[];
	selectedValue?: T;
	style?: RadioStyle;
	onSelect?: (value: T) => void;
}