import {drawBox, type DrawBoxOptions, drawText, type DrawTextOptions, normalizeInsets, PressableComponent, resolveTextLines, type ResolveTextLinesOptions, type UIDrawSurface} from '@modules/ui';
import type {ComponentDependencies, LayoutConstraints, MeasuredSize, PaginationProps, PaginationStyle, RenderContext, TextStyle, UIContext, UIEvent}                           from '@modules/ui/types';
import {createOptions}                                                                                                                                                         from '@utils/helpers';

export class PaginationComponent extends PressableComponent<'pagination', PaginationProps, UIDrawSurface, PaginationStyle> {
	public constructor(props: PaginationProps, dependencies: ComponentDependencies = {}) {
		super('pagination', props, dependencies);
	}

	public get totalPages(): number {
		if (this.props.pageSize <= 0) {
			return 1;
		}

		return Math.max(1, Math.ceil(this.props.totalItems / this.props.pageSize));
	}

	public get page(): number {
		return this.clamp(this.props.page, 1, this.totalPages);
	}

	public override measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize {
		const style   = this.getResolvedStyle(context);
		const padding = normalizeInsets(style.padding);
		const border  = style.border?.enabled ? 2 : 0;

		const content = this.getDisplayText(style);
		const width   = this.props.width ?? this.props.minWidth ?? content.length + padding.left + padding.right + border;

		const lines = resolveTextLines(createOptions<ResolveTextLinesOptions>({
			text:  content,
			width: Math.max(0, width - border - padding.left - padding.right),
		})
			.with('style', style.text)
			.done());

		const contentWidth  = lines.reduce((max, line) => Math.max(max, line.text.length), 0);
		const contentHeight = Math.max(1, lines.length);

		return this.createMeasuredSize(this.props.width ?? this.props.minWidth ?? (contentWidth + padding.left + padding.right + border), this.props.height ?? this.props.minHeight ?? (contentHeight + padding.top + padding.bottom + border), constraints);
	}

	public override render(context: RenderContext<UIDrawSurface>): void {
		if (!this.visible) return;
		if (this.width <= 0 || this.height <= 0) return;

		const style = this.getResolvedStyle(context);

		const borderCharacters = style.border?.enabled ? context.theme.borders[style.border.preset ?? 'single'] : undefined;

		const innerRect = drawBox(context.draw, createOptions<DrawBoxOptions>({
			rect: this.rect,
			style,
		})
			.with('borderCharacters', borderCharacters)
			.with('clipRect', context.clipRect)
			.done());

		drawText(context, createOptions<DrawTextOptions>({
			rect:           innerRect,
			text:           this.getDisplayText(style),
			fillBackground: style.text?.backgroundColor !== undefined,
		})
			.with('style', style.text)
			.with('clipRect', context.clipRect)
			.done());
	}

	protected override handleEvent(event: UIEvent, context: UIContext) {
		switch (event.type) {
			case 'mouse_click':
			case 'monitor_touch': {
				if (!('x' in event)) {
					return null;
				}

				this.focus();

				const targetPage = this.resolveTargetPageFromX(event.x);

				if (targetPage === this.page) {
					return null;
				}

				return this.changePage(targetPage, context) ? this.createStateInvalidation() : null;
			}

			default:
				return super.handleEvent(event, context);
		}
	}

	public override press(context: UIContext): boolean {
		const nextPage = Math.min(this.totalPages, this.page + 1);
		return this.changePage(nextPage, context);
	}

	protected override onPress(_context: UIContext): boolean {
		return false;
	}

	protected override getResolvedStyle(context: UIContext | RenderContext<UIDrawSurface>): Partial<PaginationStyle> {
		return this.getStyle(context, (themeStyle) => createOptions<PaginationStyle>(themeStyle)
			.with('padding', themeStyle.padding ?? 0)
			.with('text', createOptions<TextStyle>(themeStyle.text ?? {})
				.with('alignment', themeStyle.text?.alignment ?? 'center')
				.with('wrap', themeStyle.text?.wrap ?? 'none')
				.with('ellipsis', themeStyle.text?.ellipsis ?? true)
				.with('foregroundColor', themeStyle.text?.foregroundColor ?? this.props.foregroundColor ?? context.theme.palette.text)
				.with('backgroundColor', themeStyle.text?.backgroundColor ?? this.props.backgroundColor ?? themeStyle.backgroundColor)
				.done())
			.with('showFirstLast', themeStyle.showFirstLast ?? true)
			.with('showPrevNext', themeStyle.showPrevNext ?? true)
			.done());
	}

	private changePage(page: number, _context: UIContext): boolean {
		const nextPage = this.clamp(page, 1, this.totalPages);

		if (nextPage === this.page) {
			return false;
		}

		this.props.onPageChange?.(nextPage);
		return true;
	}

	private getDisplayText(style: Partial<PaginationStyle>): string {
		const parts: string[] = [];

		if (style.showFirstLast) {
			parts.push('<<');
		}

		if (style.showPrevNext) {
			parts.push('<');
		}

		parts.push(`${this.page}/${this.totalPages}`);

		if (style.showPrevNext) {
			parts.push('>');
		}

		if (style.showFirstLast) {
			parts.push('>>');
		}

		return parts.join(' ');
	}

	private resolveTargetPageFromX(x: number): number {
		const relativeX = x - this.rect.x;
		const width     = Math.max(1, this.rect.width);

		if (relativeX < Math.floor(width * 0.25)) {
			return Math.max(1, this.page - 1);
		}

		if (relativeX >= Math.ceil(width * 0.75)) {
			return Math.min(this.totalPages, this.page + 1);
		}

		return this.page;
	}
}