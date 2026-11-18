import {BaseComponent} from '@modules/ui/core/components/coreComponent';
import {drawText, type DrawTextOptions} from '@modules/ui/render/renderHelpers';
import type {UIDrawSurface} from '@modules/ui/render/surfaceAdapter';
import type {ComponentDependencies, LayoutConstraints, MeasuredSize, RenderContext, StatusBarProps, StatusBarSegment, StatusBarStyle, TextStyle, UIContext} from '@modules/ui/types';
import {createOptions}                                                                                                                                      from '@utils/helpers';

interface ResolvedSegment {
	text: string;
	x: number;
	width: number;
	style: Partial<TextStyle>;
}

export class StatusBarComponent extends BaseComponent<'status_bar', StatusBarProps, UIDrawSurface, StatusBarStyle> {
	public constructor(props: StatusBarProps, dependencies: ComponentDependencies = {}) {
		super('status_bar', props, dependencies);
	}

	public setSegments(segments: StatusBarSegment[]): void {
		this.setProps({segments} as Partial<StatusBarProps>);
	}

	public override measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize {
		const style        = this.getResolvedStyle(context);
		const contentWidth = this.getContentWidth(style);
		// A status bar spans the available width (at least its content).
		const width        = this.props.width ?? this.props.minWidth ?? Math.max(contentWidth, constraints.maxWidth);
		const height       = this.props.height ?? this.props.minHeight ?? 1;

		return this.createMeasuredSize(width, height, constraints);
	}

	public override render(context: RenderContext<UIDrawSurface>): void {
		if (!this.visible) return;
		if (this.width <= 0 || this.height <= 0) return;

		const style    = this.getResolvedStyle(context);
		const segments = this.resolveSegments(style, context);

		if (style.backgroundColor !== undefined) {
			context.draw.fillRect(this.rect, ' ', style.backgroundColor, style.foregroundColor);
		}

		for (let index = 0; index < this.height; index += 1) {
			for (const segment of segments) {
				drawText(context, createOptions<DrawTextOptions>({
					rect:           {
						x:      segment.x,
						y:      this.y + index,
						width:  segment.width,
						height: 1,
					},
					text:           segment.text,
					style:          segment.style,
					fillBackground: segment.style.backgroundColor !== undefined,
				})
					.with('clipRect', context.clipRect)
					.done());
			}
		}
	}

	protected override getResolvedStyle(context: UIContext | RenderContext<UIDrawSurface>): Partial<StatusBarStyle> {
		return this.getStyle(context, (themeStyle) => createOptions<StatusBarStyle>({...themeStyle})
			.with('foregroundColor', this.props.foregroundColor ?? themeStyle.foregroundColor ?? context.theme.palette.text)
			.with('backgroundColor', this.props.backgroundColor ?? themeStyle.backgroundColor ?? context.theme.palette.surface)
			.with('text', createOptions<TextStyle>({...(themeStyle.text ?? {})})
				.with('alignment', themeStyle.text?.alignment ?? 'left')
				.with('wrap', themeStyle.text?.wrap ?? 'none')
				.with('ellipsis', themeStyle.text?.ellipsis ?? true)
				.with('foregroundColor', this.props.foregroundColor ?? themeStyle.text?.foregroundColor ?? themeStyle.foregroundColor ?? context.theme.palette.text)
				.with('backgroundColor', this.props.backgroundColor ?? themeStyle.text?.backgroundColor ?? themeStyle.backgroundColor ?? context.theme.palette.surface)
				.done())
			.done());
	}

	private getContentWidth(_style: Partial<StatusBarStyle>): number {
		const segments = this.props.segments;

		if (segments.length === 0) {
			return 1;
		}

		let total = 0;

		for (const segment of segments) {
			total += segment.width ?? segment.text.length;
		}

		return Math.max(1, total);
	}

	private resolveSegments(style: Partial<StatusBarStyle>, context: UIContext | RenderContext<UIDrawSurface>): ResolvedSegment[] {
		const segments = this.props.segments;

		if (segments.length === 0) {
			return [];
		}

		// Segments without a fixed width take their text length; the space left goes to the last
		// of them, and when space is missing the last ones shrink first (with an ellipsis).
		const fixedWidth = segments.reduce((sum, segment) => sum + (segment.width ?? 0), 0);
		const widths     = segments.map((segment) => segment.width ?? segment.text.length);
		const flexible   = segments.flatMap((segment, index) => (segment.width === undefined ? [index] : []));
		let remaining    = Math.max(0, this.width - fixedWidth) - flexible.reduce((sum, index) => sum + (widths[index] ?? 0), 0);

		if (remaining > 0 && flexible.length > 0) {
			const last   = flexible[flexible.length - 1]!;
			widths[last] = (widths[last] ?? 0) + remaining;
		}

		for (let i = flexible.length - 1; i >= 0 && remaining < 0; i -= 1) {
			const index    = flexible[i]!;
			const shrink   = Math.min(widths[index] ?? 0, -remaining);
			widths[index]  = (widths[index] ?? 0) - shrink;
			remaining     += shrink;
		}

		let currentX                      = this.x;
		const resolved: ResolvedSegment[] = [];

		segments.forEach((segment, index) => {
			const width = Math.max(0, widths[index] ?? 0);

			const segmentStyle = this.getSegmentStyle(segment, style, context);

			resolved.push({
				text:  segment.text,
				x:     currentX,
				width,
				style: segmentStyle,
			});

			currentX += width;
		});

		return resolved.filter((segment) => segment.width > 0);
	}

	private getSegmentStyle(
		segment: StatusBarSegment,
		style: Partial<StatusBarStyle>,
		context: UIContext | RenderContext<UIDrawSurface>,
	): Partial<TextStyle> {
		const alignment = segment.alignment === 'center' ? 'center' : segment.alignment === 'right' ? 'right' : 'left';

		// A copy per segment: sharing style.text made every segment take the last segment's colors.
		return createOptions<TextStyle>({...(style.text ?? {})})
			.with('alignment', alignment)
			.with('foregroundColor', segment.color ?? style.text?.foregroundColor ?? style.foregroundColor ?? context.theme.palette.text)
			.with('backgroundColor', segment.backgroundColor ?? style.text?.backgroundColor ?? style.backgroundColor ?? context.theme.palette.surface)
			.done();
	}
}