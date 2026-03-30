import type {ComponentDependencies, DrawTextLineOptions, LayoutConstraints, MeasuredSize, PaginationProps, PaginationStyle, RenderContext, TextStyle, UIContext, UIDrawSurface} from '@modules/ui';
import {BaseComponent, clamp, drawTextLine, mergeComponentStyle}                                                                                                                from '@modules/ui';

import {createOptions} from '@utils/helpers';

interface PaginationSegment {
	text: string;
	width: number;
	foregroundColor?: number;
	backgroundColor?: number;
}

export class PaginationComponent extends BaseComponent<PaginationProps, UIDrawSurface> {
	public constructor(props: PaginationProps, dependencies: ComponentDependencies = {}) {
		super('pagination', props, dependencies.eventBus, dependencies.invalidator);
	}

	public measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize {
		const style         = this.getResolvedStyle(context.theme);
		const text          = this.buildPlainText(style);
		const measuredWidth = Math.max(text.length, 1);

		return {
			width:  Math.max(constraints.minWidth, Math.min(this.props.width ?? measuredWidth, constraints.maxWidth)),
			height: Math.max(constraints.minHeight, Math.min(this.props.height ?? 1, constraints.maxHeight)),
		};
	}

	public render(context: RenderContext<UIDrawSurface>): void {
		if (!this.visible || this.rect.width <= 0 || this.rect.height <= 0) return;

		const style    = this.getResolvedStyle(context.theme);
		const segments = this.buildSegments(style);

		let cursorX = this.rect.x;
		const right = this.rect.x + this.rect.width - 1;

		for (const segment of segments) {
			if (cursorX > right) break;

			const availableWidth = right - cursorX + 1;
			if (availableWidth <= 0) break;

			drawTextLine(context.draw, createOptions<DrawTextLineOptions>({
				position: {
					x: cursorX,
					y: this.rect.y,
				},
				width:    Math.min(segment.width, availableWidth),
				text:     segment.text,
			})
				.with('style', this.resolveSegmentStyle(segment))
				.done());

			cursorX += segment.width;
		}
	}

	public setPage(page: number): void {
		const totalPages = this.getTotalPages();
		const nextPage   = clamp(page, 1, totalPages);

		if (this.props.page === nextPage) return;

		this.props.page = nextPage;
		this.invalidate();
		this.props.onPageChange?.(nextPage);
	}

	public nextPage(): void {
		this.setPage(this.props.page + 1);
	}

	public previousPage(): void {
		this.setPage(this.props.page - 1);
	}

	public firstPage(): void {
		this.setPage(1);
	}

	public lastPage(): void {
		this.setPage(this.getTotalPages());
	}

	private getResolvedStyle(theme: UIContext['theme']): PaginationStyle | undefined {
		return mergeComponentStyle(theme.components?.pagination, this.props.style);
	}

	private getTotalPages(): number {
		if (this.props.pageSize <= 0) {
			return 1;
		}

		return Math.max(1, Math.ceil(this.props.totalItems / this.props.pageSize));
	}

	private getCurrentPage(): number {
		return clamp(this.props.page, 1, this.getTotalPages());
	}

	private buildPlainText(style?: PaginationStyle): string {
		return this.buildSegments(style)
			.map((segment) => segment.text)
			.join('');
	}

	private buildSegments(style?: PaginationStyle): PaginationSegment[] {
		const page       = this.getCurrentPage();
		const totalPages = this.getTotalPages();

		const activeColor     = style?.activeColor ?? style?.text?.foregroundColor ?? style?.foregroundColor;
		const inactiveColor   = style?.inactiveColor ?? style?.text?.foregroundColor ?? style?.foregroundColor;
		const backgroundColor = style?.text?.backgroundColor ?? style?.backgroundColor;

		const segments: PaginationSegment[] = [];

		if (style?.showFirstLast ?? true) {
			segments.push(this.createSegment(page > 1 ? '<<' : '  ', page > 1 ? activeColor : inactiveColor, backgroundColor));
			segments.push(this.createSegment(' ', activeColor, backgroundColor));
		}

		if (style?.showPrevNext ?? true) {
			segments.push(this.createSegment(page > 1 ? '<' : ' ', page > 1 ? activeColor : inactiveColor, backgroundColor));
			segments.push(this.createSegment(' ', activeColor, backgroundColor));
		}

		segments.push(this.createSegment(`${page}/${totalPages}`, activeColor, backgroundColor));

		if (style?.showPrevNext ?? true) {
			segments.push(this.createSegment(' ', activeColor, backgroundColor));
			segments.push(this.createSegment(page < totalPages ? '>' : ' ', page < totalPages ? activeColor : inactiveColor, backgroundColor));
		}

		if (style?.showFirstLast ?? true) {
			segments.push(this.createSegment(' ', activeColor, backgroundColor));
			segments.push(this.createSegment(page < totalPages ? '>>' : '  ', page < totalPages ? activeColor : inactiveColor, backgroundColor));
		}

		return segments;
	}

	private createSegment(text: string, foregroundColor?: number, backgroundColor?: number): PaginationSegment {
		return createOptions<PaginationSegment>({
			text,
			width: text.length,
		})
			.with('foregroundColor', foregroundColor)
			.with('backgroundColor', backgroundColor)
			.done();
	}

	private resolveSegmentStyle(segment: PaginationSegment): TextStyle {
		return createOptions<TextStyle>({
			alignment: 'left',
			wrap:      'none',
			ellipsis:  false,
		})
			.with('foregroundColor', segment.foregroundColor)
			.with('backgroundColor', segment.backgroundColor)
			.done();
	}
}