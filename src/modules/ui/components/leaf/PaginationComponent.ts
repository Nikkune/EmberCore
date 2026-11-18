import {PressableComponent} from '@modules/ui/core/components/pressableComponent';
import {drawBox, type DrawBoxOptions, drawText, type DrawTextOptions, getInnerRect, normalizeInsets, resolveTextLines, type ResolveTextLinesOptions} from '@modules/ui/render/renderHelpers';
import type {UIDrawSurface} from '@modules/ui/render/surfaceAdapter';
import type {ComponentDependencies, LayoutConstraints, MeasuredSize, PaginationProps, PaginationStyle, RenderContext, TextStyle, UIContext, UIEvent}                           from '@modules/ui/types';
import {createOptions}                                                                                                                                                         from '@utils/helpers';

export class PaginationComponent extends PressableComponent<'pagination', PaginationProps, UIDrawSurface, PaginationStyle> {
	/** Displayed page: starts at props.page, then follows clicks and setPage(). */
	private currentPage: number;

	public constructor(props: PaginationProps, dependencies: ComponentDependencies = {}) {
		super('pagination', props, dependencies);
		this.currentPage = props.page;
	}

	protected override onPropsChanged(patch: Partial<PaginationProps>): void {
		if (patch.page !== undefined) this.currentPage = patch.page;
	}

	public get totalPages(): number {
		if (this.props.pageSize <= 0) {
			return 1;
		}

		return Math.max(1, Math.ceil(this.props.totalItems / this.props.pageSize));
	}

	public get page(): number {
		return this.clamp(this.currentPage, 1, this.totalPages);
	}

	/** Sets the displayed page without calling onPageChange (e.g. when the data source changes). */
	public setPage(page: number): void {
		const nextPage = this.clamp(page, 1, this.totalPages);

		if (nextPage === this.page) return;

		this.currentPage = nextPage;
		this.invalidate(this.createStateInvalidation());
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

		return this.createMeasuredSize(
			this.props.width ?? this.props.minWidth ?? (contentWidth + padding.left + padding.right + border),
			this.props.height ?? this.props.minHeight ?? (contentHeight + padding.top + padding.bottom + border),
			constraints,
		);
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

				const targetPage = this.resolveTargetPageFromX(event.x, context);

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
		return this.getStyle(context, (themeStyle) => createOptions<PaginationStyle>({...themeStyle})
			.with('padding', this.props.padding ?? themeStyle.padding ?? 0)
			.with('text', createOptions<TextStyle>({...(themeStyle.text ?? {})})
				.with('alignment', themeStyle.text?.alignment ?? 'center')
				.with('wrap', themeStyle.text?.wrap ?? 'none')
				.with('ellipsis', themeStyle.text?.ellipsis ?? true)
				.with('foregroundColor', this.props.foregroundColor ?? themeStyle.text?.foregroundColor ?? context.theme.palette.text)
				.with('backgroundColor', this.props.backgroundColor ?? themeStyle.text?.backgroundColor ?? themeStyle.backgroundColor)
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

		this.currentPage = nextPage;
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

	/** Maps a click to the page of the control under the pointer: <<, <, > or >>. */
	private resolveTargetPageFromX(x: number, context: UIContext): number {
		const style     = this.getResolvedStyle(context);
		const innerRect = getInnerRect(this.rect, style);
		const text      = this.getDisplayText(style);
		const alignment = style.text?.alignment ?? 'center';

		const free   = Math.max(0, innerRect.width - text.length);
		const offset = alignment === 'right' ? free : alignment === 'center' ? Math.floor(free / 2) : 0;
		const index  = x - innerRect.x - offset;

		let position = 0;

		for (const token of text.split(' ')) {
			if (index >= position && index < position + token.length) {
				switch (token) {
					case '<<':
						return 1;
					case '<':
						return this.page - 1;
					case '>':
						return this.page + 1;
					case '>>':
						return this.totalPages;
					default:
						return this.page;
				}
			}

			position += token.length + 1;
		}

		return this.page;
	}
}