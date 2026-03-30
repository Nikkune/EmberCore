import type {ComponentDependencies, LayoutConstraints, LogEntry, LogViewerProps, LogViewerStyle, MeasuredSize, RenderContext, TextStyle, UIContext} from '@modules/ui/types';
import {BaseComponent, clamp, drawTextLine, type DrawTextLineOptions, mergeComponentStyle, type UIDrawSurface} from '@modules/ui';
import {createOptions}                                                                                                                              from '@utils/helpers';

interface VisibleLogLine {
	text: string;
	style: TextStyle;
}

export class LogViewerComponent extends BaseComponent<LogViewerProps, UIDrawSurface> {
	public constructor(props: LogViewerProps, dependencies: ComponentDependencies = {}) {
		super('log_viewer', props, dependencies.eventBus, dependencies.invalidator);
	}

	public measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize {
		const style          = this.getResolvedStyle(context.theme);
		const preferredWidth = this.getPreferredWidth(style);

		return {
			width:  Math.max(constraints.minWidth, Math.min(this.props.width ?? preferredWidth, constraints.maxWidth)),
			height: Math.max(constraints.minHeight, Math.min(this.props.height ?? Math.max(1, this.props.entries.length), constraints.maxHeight)),
		};
	}

	public render(context: RenderContext<UIDrawSurface>): void {
		if (!this.visible || this.rect.width <= 0 || this.rect.height <= 0) return;

		const style = this.getResolvedStyle(context.theme);
		const lines = this.getVisibleLines(style);

		for (let index = 0; index < this.rect.height; index++) {
			const line = lines[index];

			drawTextLine(context.draw, createOptions<DrawTextLineOptions>({
				position: {
					x: this.rect.x,
					y: this.rect.y + index,
				},
				width:    this.rect.width,
				text:     line?.text ?? '',
			})
				.with('style', line?.style ?? this.resolveBaseLineStyle(style))
				.done());
		}
	}

	public setScrollOffset(scrollOffset: number): void {
		const nextOffset = clamp(scrollOffset, 0, this.getMaxScrollOffset());

		if ((this.props.scrollOffset ?? 0) === nextOffset) return;

		this.props.scrollOffset = nextOffset;
		this.invalidate();
	}

	public scrollUp(lines = 1): void {
		this.setScrollOffset((this.props.scrollOffset ?? 0) - Math.max(1, lines));
	}

	public scrollDown(lines = 1): void {
		this.setScrollOffset((this.props.scrollOffset ?? 0) + Math.max(1, lines));
	}

	public scrollToTop(): void {
		this.setScrollOffset(0);
	}

	public scrollToBottom(): void {
		this.setScrollOffset(this.getMaxScrollOffset());
	}

	private getResolvedStyle(theme: UIContext['theme']): LogViewerStyle | undefined {
		return mergeComponentStyle(theme.components?.logViewer, this.props.style);
	}

	private getPreferredWidth(style?: LogViewerStyle): number {
		let width = 1;

		for (const entry of this.props.entries) {
			const text = this.formatEntry(entry, style);
			if (text.length > width) {
				width = text.length;
			}
		}

		return width;
	}

	private getVisibleLines(style?: LogViewerStyle): VisibleLogLine[] {
		const allLines       = this.buildLines(style);
		const height         = Math.max(1, this.rect.height);
		const maxOffset      = Math.max(0, allLines.length - height);
		const resolvedOffset = this.resolveScrollOffset(style, maxOffset);
		const start          = Math.max(0, allLines.length - height - resolvedOffset);
		const end            = start + height;

		return allLines.slice(start, end);
	}

	private buildLines(style?: LogViewerStyle): VisibleLogLine[] {
		const result: VisibleLogLine[] = [];

		for (const entry of this.props.entries) {
			result.push({
				text:  this.formatEntry(entry, style),
				style: this.resolveEntryStyle(entry, style),
			});
		}

		return result;
	}

	private resolveScrollOffset(style?: LogViewerStyle, maxOffset?: number): number {
		const maximum = maxOffset ?? this.getMaxScrollOffset();

		if (style?.autoScroll ?? true) {
			return 0;
		}

		return clamp(this.props.scrollOffset ?? 0, 0, maximum);
	}

	private getMaxScrollOffset(): number {
		const height = Math.max(1, this.rect.height || this.props.height || 1);
		return Math.max(0, this.props.entries.length - height);
	}

	private formatEntry(entry: LogEntry, style?: LogViewerStyle): string {
		const parts: string[] = [];

		if ((style?.showTimestamp ?? true) && entry.timestamp && entry.timestamp.length > 0) {
			parts.push(`[${entry.timestamp}]`);
		}

		parts.push(`[${entry.level.toUpperCase()}]`);
		parts.push(entry.message);

		if (entry.meta) {
			const metaText = this.formatMeta(entry.meta);
			if (metaText.length > 0) {
				parts.push(metaText);
			}
		}

		return parts.join(' ');
	}

	private formatMeta(meta: Record<string, unknown>): string {
		const parts: string[] = [];

		for (const key in meta) {
			const value = meta[key];

			if (value === undefined) continue;

			parts.push(`${key}=${String(value)}`);
		}

		return parts.join(' ');
	}

	private resolveBaseLineStyle(style?: LogViewerStyle): TextStyle {
		return createOptions<TextStyle>({
			alignment: style?.lineStyle?.alignment ?? 'left',
			wrap:      style?.lineStyle?.wrap ?? 'none',
			ellipsis:  style?.lineStyle?.ellipsis ?? true,
		})
			.with('foregroundColor', style?.lineStyle?.foregroundColor ?? style?.foregroundColor)
			.with('backgroundColor', style?.lineStyle?.backgroundColor ?? style?.backgroundColor)
			.done();
	}

	private resolveEntryStyle(entry: LogEntry, style?: LogViewerStyle): TextStyle {
		const levelColor = style?.levelColors?.[entry.level];

		return createOptions<TextStyle>({
			alignment: style?.lineStyle?.alignment ?? 'left',
			wrap:      style?.lineStyle?.wrap ?? 'none',
			ellipsis:  style?.lineStyle?.ellipsis ?? true,
		})
			.with('foregroundColor', levelColor ?? style?.lineStyle?.foregroundColor ?? style?.foregroundColor)
			.with('backgroundColor', style?.lineStyle?.backgroundColor ?? style?.backgroundColor)
			.done();
	}
}