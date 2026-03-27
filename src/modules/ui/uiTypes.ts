// ============================================================
// Core primitives
// ============================================================

export type Color = number
export type Maybe<T> = T | undefined

export interface Point {
	x: number;
	y: number;
}

export interface Size {
	width: number;
	height: number;
}

export interface Rect extends Point, Size {
}

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

export type PaddingLike =
	| number
	| Partial<Insets>
	| {
	x?: number;
	y?: number;
	horizontal?: number;
	vertical?: number;
};

export type MarginLike = PaddingLike;

// ============================================================
// Alignment / layout
// ============================================================

export type HorizontalAlignment = 'start' | 'center' | 'end' | 'stretch';
export type VerticalAlignment = 'start' | 'center' | 'end' | 'stretch';
export type CrossAxisAlignment = 'start' | 'center' | 'end' | 'stretch';

export type MainAxisAlignment =
	| 'start'
	| 'center'
	| 'end'
	| 'space-between'
	| 'space-around'
	| 'space-evenly';

export type Direction = 'row' | 'column';
export type WrapMode = 'nowrap' | 'wrap';

export interface LayoutConstraints {
	minWidth: number;
	maxWidth: number;
	minHeight: number;
	maxHeight: number;
}

export interface MeasuredSize {
	width: number;
	height: number;
}

export interface LayoutRect extends Rect {
}

export interface FlexItemOptions {
	grow?: number;
	shrink?: number;
	basis?: number | 'auto';
	order?: number;
	alignmentSelf?: CrossAxisAlignment | 'auto';
}

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

// ============================================================
// Text / border / style
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
	character?: string
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
	list?: Partial<ListStyle>;
	statusBar?: Partial<StatusBarStyle>;
	logViewer?: Partial<LogViewerStyle>;
	pagination?: Partial<PaginationStyle>;
	container?: Partial<ContainerStyle>;
	box?: Partial<BoxStyle>;
}

export interface Theme {
	name: string;
	palette: ThemePalette;
	borders: ThemeBorderSet;
	components?: ThemeComponentStyles;
}

// ============================================================
// Events
// ============================================================

export type UIEventName = keyof UIEventMap;

export type UIEvent =
	| MouseClickEvent
	| MouseScrollEvent
	| KeyEvent
	| CharEvent
	| PasteEvent
	| TimerEvent
	| ChangeEvent
	| ToggleEvent
	| SelectEvent
	| PageChangeEvent
	| SubmitEvent
	| CustomEvent;

export type UIEventHandler<TEvent extends UIEvent = UIEvent> = (event: TEvent) => void;

export interface BaseUIEvent {
	type: UIEventName;
	targetId?: string;
	cancelled?: boolean;
	propagationStopped?: boolean;
}

export interface PositionalUIEvent extends BaseUIEvent {
	x: number;
	y: number;
}

export interface MouseClickEvent extends PositionalUIEvent {
	type: 'mouse_click' | 'mouse_drag' | 'mouse_up' | 'monitor_touch';
	button?: number;
}

export interface MouseScrollEvent extends PositionalUIEvent {
	type: 'mouse_scroll';
	direction: -1 | 1;
}

export interface KeyEvent extends BaseUIEvent {
	type: 'key' | 'key_up';
	key: number;
	held?: boolean;
}

export interface CharEvent extends BaseUIEvent {
	type: 'char';
	char: string;
}

export interface PasteEvent extends BaseUIEvent {
	type: 'paste';
	text: string;
}

export interface TimerEvent extends BaseUIEvent {
	type: 'timer';
	timerId: number;
}

export interface ChangeEvent<T = unknown> extends BaseUIEvent {
	type: 'change';
	value: T;
}

export interface ToggleEvent extends BaseUIEvent {
	type: 'toggle';
	checked: boolean;
}

export interface SelectEvent<T = string> extends BaseUIEvent {
	type: "select";
	value: T;
	index?: number;
}

export interface PageChangeEvent extends BaseUIEvent {
	type: 'page_change';
	page: number;
	pageSize: number;
}

export interface SubmitEvent extends BaseUIEvent {
	type: 'submit';
	values: Record<string, unknown>;
}

export interface CustomEvent<T = unknown> extends BaseUIEvent {
	type: 'custom';
	name: string;
	payload?: T;
}

export interface UIEventMap {
	mouse_click?: UIEventHandler<MouseClickEvent>;
	mouse_scroll?: UIEventHandler<MouseScrollEvent>;
	mouse_drag?: UIEventHandler<MouseClickEvent>;
	mouse_up?: UIEventHandler<MouseClickEvent>;
	monitor_touch?: UIEventHandler<MouseClickEvent>;
	key?: UIEventHandler<KeyEvent>;
	key_up?: UIEventHandler<KeyEvent>;
	char?: UIEventHandler<CharEvent>;
	paste?: UIEventHandler<PasteEvent>;
	timer?: UIEventHandler<TimerEvent>;
	change?: UIEventHandler<ChangeEvent>;
	submit?: UIEventHandler<SubmitEvent>;
	toggle?: UIEventHandler<ToggleEvent>;
	select?: UIEventHandler<SelectEvent>;
	page_change?: UIEventHandler<PageChangeEvent>;
	custom?: UIEventHandler<CustomEvent>;
}

export interface EventSubscription<TEvent extends UIEvent = UIEvent> {
	readonly id: string;
	readonly type: TEvent["type"];
	readonly targetId?: string;
	readonly once: boolean;
	readonly active: boolean;

	unsubscribe(): void;
}

export interface EventDispatchResult {
	dispatched: boolean;
	listenerCount: number;
	cancelled: boolean;
	propagationStopped: boolean;
}

export interface EventSubscriptionOptions {
	targetId?: string;
	once?: boolean;
	order?: number;
}

export interface EventDispatcher {
	subscribe<TEvent extends UIEvent>(
		type: TEvent["type"],
		handler: UIEventHandler<TEvent>,
		options?: EventSubscriptionOptions,
	): EventSubscription<TEvent>;

	subscribeOnce<TEvent extends UIEvent>(
		type: TEvent["type"],
		handler: UIEventHandler<TEvent>,
		options?: Omit<EventSubscriptionOptions, "once">,
	): EventSubscription<TEvent>;

	unsubscribe(subscriptionId: string): boolean;

	dispatch<TEvent extends UIEvent>(event: TEvent): EventDispatchResult;

	clear(type?: UIEventName): void;

	count(type?: UIEventName): number;
}

export interface UIEventBus extends EventDispatcher {
	emit<TEvent extends UIEvent>(event: TEvent): EventDispatchResult;

	has(type: UIEventName): boolean;

	getSubscriptions(type?: UIEventName): ReadonlyArray<EventSubscription>;
}

// ============================================================
// Render / invalidation / runtime
// ============================================================

export type SurfaceKind = 'terminal' | 'monitor';
export type InvalidationReason = 'mount' | 'layout' | 'state' | 'theme' | "event" | "manual";

export interface RenderContext {
	surface: SurfaceKind;
	theme: Theme;
	tick: number;
}

export interface DirtyRegion extends Rect {
}

export interface InvalidationRequest {
	reason: InvalidationReason;
	rect?: DirtyRegion;
}

export interface UIContext {
	theme: Theme
	surface: SurfaceKind;
	activeElement?: string;
}

// ============================================================
// Base component contracts
// ============================================================

export type ComponentKind =
	| "button"
	| "progress_bar"
	| "table"
	| "box"
	| "grid"
	| "checkbox"
	| "radio"
	| "log_viewer"
	| "pagination"
	| "label"
	| "panel"
	| "separator"
	| "badge"
	| "list"
	| "status_bar"
	| "container"
	| "stack"
	| "custom";

export interface BaseProps extends AxisSize {
	id?: string;
	visible?: boolean;
	disabled?: boolean;
	zIndex?: number;

	margin?: MarginLike;
	padding?: PaddingLike;

	rect?: Partial<Rect>;

	backgroundColor?: Color;
	foregroundColor?: Color;
	border?: BorderStyle;

	flex?: FlexItemOptions;

	on?: UIEventMap;
}

export interface ComponentNode<TProps extends BaseProps = BaseProps> {
	kind: ComponentKind;
	props: TProps;
	children?: ComponentNode[];
}

export interface Measurable {
	measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize;
}

export interface Layoutable {
	layout(rect: Rect, context: UIContext): void;
}

export interface Renderable {
	render(context: RenderContext): void;
}

export interface Interactive {
	hitTest(point: Point): boolean;

	dispatch(event: UIEvent, context: UIContext): boolean;
}

export interface UIComponent extends Measurable, Layoutable, Renderable, Interactive {
	readonly id: string;
	readonly kind: ComponentKind;
	readonly rect: Rect;
	readonly visible: boolean;
	readonly disabled: boolean;

	invalidate(request?: InvalidationRequest): void;
}

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

// ============================================================
// Component-specific styles
// ============================================================

export interface LabelStyle extends TextStyle {
}

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
	charFilled?: string;
	charEmpty?: string;
}

export interface CheckboxStyle extends BoxStyle {
	text?: TextStyle;
	checkColor?: Color;
	checkedChar?: string;
	uncheckedChar?: string;
}

export interface RadioStyle extends BoxStyle {
	text?: TextStyle;
	dotColor?: Color;
	selectedChar?: string;
	unselectedChar?: string;
}

export interface BadgeStyle extends BoxStyle {
	text?: TextStyle;
	tone?: "default" | "primary" | "success" | "warning" | "error" | "info";
}

export interface SeparatorStyle {
	foregroundColor?: Color;
	backgroundColor?: Color;
	char?: string;
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

export interface ListStyle extends BoxStyle {
	itemStyle?: TextStyle;
	selectedStyle?: TextStyle;
	bullet?: string;
}

export interface StatusBarStyle extends BoxStyle {
	text?: TextStyle;
	segments?: Array<{
		id?: string;
		text: string;
		color?: Color;
		backgroundColor?: Color;
		alignment?: "left" | "center" | "right";
		width?: number;
	}>;
}

export interface LogViewerStyle extends BoxStyle {
	lineStyle?: TextStyle;
	levelColors?: Partial<Record<"debug" | "info" | "warn" | "error", Color>>;
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

export interface ContainerStyle extends BoxStyle {
}

export interface StackStyle extends BoxStyle {
	layout?: StackLayoutOptions;
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

export interface LogEntry {
	level: "debug" | "info" | "warn" | "error";
	message: string;
	timestamp?: string;
	meta?: Record<string, unknown>;
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

export interface StatusBarSegment {
	id?: string;
	text: string;
	color?: Color;
	backgroundColor?: Color;
	width?: number;
	alignment?: "left" | "center" | "right";
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