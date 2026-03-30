import type {ComponentDependencies, DrawTextLineOptions, LayoutConstraints, MeasuredSize, RenderContext, StatusBarProps, StatusBarStyle, TextStyle, UIContext, UIDrawSurface} from '@modules/ui';
import {BaseComponent, drawTextLine, mergeComponentStyle}                                                                                                                     from '@modules/ui';
import {createOptions}                                                                                                                                                        from '@utils/helpers';

interface ResolvedStatusBarSegment {
	id?: string;
	text: string;
	foregroundColor?: number;
	backgroundColor?: number;
	alignment?: 'left' | 'center' | 'right';
	width?: number;
}

export class StatusBarComponent extends BaseComponent<StatusBarProps, UIDrawSurface> {
	public constructor(props: StatusBarProps, dependencies: ComponentDependencies = {}) {
		super('status_bar', props, dependencies.eventBus, dependencies.invalidator);
	}

	public measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize {
		const style         = this.getResolvedStyle(context.theme);
		const segments      = this.getResolvedSegments(style);
		const measuredWidth = Math.max(this.getPreferredWidth(segments), 1);

		return {
			width:  Math.max(constraints.minWidth, Math.min(this.props.width ?? measuredWidth, constraints.maxWidth)),
			height: Math.max(constraints.minHeight, Math.min(this.props.height ?? 1, constraints.maxHeight)),
		};
	}

	public render(context: RenderContext<UIDrawSurface>): void {
		if (!this.visible || this.rect.width <= 0 || this.rect.height <= 0) return;

		const style    = this.getResolvedStyle(context.theme);
		const segments = this.getResolvedSegments(style);

		this.renderBackground(context, style);

		if (segments.length <= 0) return;

		const widths = this.resolveSegmentWidths(segments, this.rect.width);
		let cursorX  = this.rect.x;

		for (let index = 0; index < segments.length; index++) {
			const segment = segments[index]!;
			const width   = widths[index]!;

			if (width <= 0) continue;

			drawTextLine(context.draw, createOptions<DrawTextLineOptions>({
				position: {
					x: cursorX,
					y: this.rect.y,
				},
				width,
				text:     segment.text,
			})
				.with('style', this.resolveSegmentTextStyle(style, segment))
				.done());

			cursorX += width;
			if (cursorX > this.rect.x + this.rect.width - 1) {
				break;
			}
		}
	}

	private renderBackground(context: RenderContext<UIDrawSurface>, style?: StatusBarStyle): void {
		drawTextLine(context.draw, createOptions<DrawTextLineOptions>({
			position: {
				x: this.rect.x,
				y: this.rect.y,
			},
			width:    this.rect.width,
			text:     '',
		})
			.with('style', this.resolveBaseTextStyle(style))
			.done());
	}

	private getResolvedStyle(theme: UIContext['theme']): StatusBarStyle | undefined {
		return mergeComponentStyle(theme.components?.statusBar, this.props.style);
	}

	private getResolvedSegments(style?: StatusBarStyle): ResolvedStatusBarSegment[] {
		const source = this.props.segments.length > 0 ? this.props.segments : (style?.segments ?? []);

		const result: ResolvedStatusBarSegment[] = [];

		for (const segment of source) {
			result.push(createOptions<ResolvedStatusBarSegment>({
				text: segment.text,
			})
				.with('id', segment.id)
				.with('foregroundColor', segment.color)
				.with('backgroundColor', segment.backgroundColor)
				.with('alignment', segment.alignment)
				.with('width', segment.width)
				.done());
		}

		return result;
	}

	private getPreferredWidth(segments: ResolvedStatusBarSegment[]): number {
		let total = 0;

		for (const segment of segments) {
			total += Math.max(1, segment.width ?? segment.text.length);
		}

		return total;
	}

	private resolveSegmentWidths(segments: ResolvedStatusBarSegment[], totalWidth: number): number[] {
		if (segments.length <= 0 || totalWidth <= 0) {
			return [];
		}

		const widths = new Array<number>(segments.length).fill(0);

		let fixedWidth              = 0;
		const autoIndexes: number[] = [];

		for (let index = 0; index < segments.length; index++) {
			const segment = segments[index]!;

			if (segment.width !== undefined) {
				const width   = Math.max(1, segment.width);
				widths[index] = width;
				fixedWidth += width;
			}
			else {
				autoIndexes.push(index);
			}
		}

		let remainingWidth = totalWidth - fixedWidth;

		if (autoIndexes.length <= 0) {
			return this.fitWidthsToTotal(widths, totalWidth);
		}

		if (remainingWidth <= 0) {
			for (const index of autoIndexes) {
				widths[index] = 1;
			}

			return this.fitWidthsToTotal(widths, totalWidth);
		}

		let preferredAutoWidth = 0;

		for (const index of autoIndexes) {
			preferredAutoWidth += Math.max(1, segments[index]!.text.length);
		}

		if (preferredAutoWidth <= remainingWidth) {
			for (const index of autoIndexes) {
				widths[index] = Math.max(1, segments[index]!.text.length);
			}

			let extra  = totalWidth - this.sum(widths);
			let cursor = 0;

			while (extra > 0 && autoIndexes.length > 0) {
				const index = autoIndexes[cursor % autoIndexes.length]!;
				widths[index]! += 1;
				extra--;
				cursor++;
			}

			return widths;
		}

		let assigned = 0;

		for (let i = 0; i < autoIndexes.length; i++) {
			const index     = autoIndexes[i]!;
			const preferred = Math.max(1, segments[index]!.text.length);

			const width = i === autoIndexes.length - 1 ? Math.max(1, remainingWidth - assigned) : Math.max(1, Math.floor((preferred / preferredAutoWidth) * remainingWidth));

			widths[index] = width;
			assigned += width;
		}

		return this.fitWidthsToTotal(widths, totalWidth);
	}

	private fitWidthsToTotal(widths: number[], totalWidth: number): number[] {
		const result = [...widths];
		let current  = this.sum(result);

		while (current > totalWidth) {
			let changed = false;

			for (let index = result.length - 1; index >= 0 && current > totalWidth; index--) {
				if (result[index]! > 1) {
					result[index]!--;
					current--;
					changed = true;
				}
			}

			if (!changed) {
				break;
			}
		}

		while (current < totalWidth && result.length > 0) {
			result[result.length - 1]!++;
			current++;
		}

		return result;
	}

	private sum(values: number[]): number {
		let total = 0;

		for (const value of values) {
			total += value;
		}

		return total;
	}

	private resolveBaseTextStyle(style?: StatusBarStyle): TextStyle {
		return createOptions<TextStyle>({
			alignment: style?.text?.alignment ?? 'left',
			wrap:      style?.text?.wrap ?? 'none',
			ellipsis:  false,
		})
			.with('foregroundColor', style?.text?.foregroundColor ?? style?.foregroundColor)
			.with('backgroundColor', style?.text?.backgroundColor ?? style?.backgroundColor)
			.done();
	}

	private resolveSegmentTextStyle(style: StatusBarStyle | undefined, segment: ResolvedStatusBarSegment): TextStyle {
		return createOptions<TextStyle>({
			alignment: segment.alignment ?? style?.text?.alignment ?? 'left',
			wrap:      style?.text?.wrap ?? 'none',
			ellipsis:  true,
		})
			.with('foregroundColor', segment.foregroundColor ?? style?.text?.foregroundColor ?? style?.foregroundColor)
			.with('backgroundColor', segment.backgroundColor ?? style?.text?.backgroundColor ?? style?.backgroundColor)
			.done();
	}
}