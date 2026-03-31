import {BaseComponent, drawText, type DrawTextOptions, type UIDrawSurface}                                                                                  from '@modules/ui';
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

	public override measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize {
		const style        = this.getResolvedStyle(context);
		const contentWidth = this.getContentWidth(style);
		const width        = this.props.width ?? this.props.minWidth ?? contentWidth;
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
		return this.getStyle(context, (themeStyle) => createOptions<StatusBarStyle>(themeStyle)
			.with('foregroundColor', this.props.foregroundColor ?? themeStyle.foregroundColor ?? context.theme.palette.text)
			.with('backgroundColor', this.props.backgroundColor ?? themeStyle.backgroundColor ?? context.theme.palette.surface)
			.with('text', createOptions<TextStyle>(themeStyle.text ?? {})
				.with('alignment', themeStyle.text?.alignment ?? 'left')
				.with('wrap', themeStyle.text?.wrap ?? 'none')
				.with('ellipsis', themeStyle.text?.ellipsis ?? true)
				.with('foregroundColor', themeStyle.text?.foregroundColor ?? this.props.foregroundColor ?? themeStyle.foregroundColor ?? context.theme.palette.text)
				.with('backgroundColor', themeStyle.text?.backgroundColor ?? this.props.backgroundColor ?? themeStyle.backgroundColor ?? context.theme.palette.surface)
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

		const fixedWidth       = segments.reduce((sum, segment) => sum + (segment.width ?? 0), 0);
		const flexibleSegments = segments.filter((segment) => segment.width === undefined);
		const remainingWidth   = Math.max(0, this.width - fixedWidth);

		const baseFlexibleWidth = flexibleSegments.length > 0 ? Math.floor(remainingWidth / flexibleSegments.length) : 0;

		let extraWidth = flexibleSegments.length > 0 ? remainingWidth % flexibleSegments.length : 0;

		let currentX                      = this.x;
		const resolved: ResolvedSegment[] = [];

		for (const segment of segments) {
			let width = segment.width ?? baseFlexibleWidth;

			if (segment.width === undefined && extraWidth > 0) {
				width += 1;
				extraWidth -= 1;
			}

			width = Math.max(0, width);

			const segmentStyle = this.getSegmentStyle(segment, style, context);

			resolved.push({
				text:  segment.text,
				x:     currentX,
				width,
				style: segmentStyle,
			});

			currentX += width;
		}

		return resolved.filter((segment) => segment.width > 0);
	}

	private getSegmentStyle(segment: StatusBarSegment, style: Partial<StatusBarStyle>, context: UIContext | RenderContext<UIDrawSurface>): Partial<TextStyle> {
		const alignment = segment.alignment === 'center' ? 'center' : segment.alignment === 'right' ? 'right' : 'left';

		return createOptions<TextStyle>(style.text ?? {})
			.with('alignment', alignment)
			.with('foregroundColor', segment.color ?? style.text?.foregroundColor ?? style.foregroundColor ?? context.theme.palette.text)
			.with('backgroundColor', segment.backgroundColor ?? style.text?.backgroundColor ?? style.backgroundColor ?? context.theme.palette.surface)
			.done();
	}
}