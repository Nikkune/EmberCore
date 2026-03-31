import {BaseComponent, drawBox, type DrawBoxOptions, drawText, type DrawTextOptions, type UIDrawSurface}                                            from '@modules/ui';
import type {ComponentDependencies, LayoutConstraints, LogEntry, LogViewerProps, LogViewerStyle, MeasuredSize, RenderContext, TextStyle, UIContext} from '@modules/ui/types';
import {createOptions}                                                                                                                              from '@utils/helpers';

export class LogViewerComponent extends BaseComponent<'log_viewer', LogViewerProps, UIDrawSurface, LogViewerStyle> {
	public constructor(props: LogViewerProps, dependencies: ComponentDependencies = {}) {
		super('log_viewer', props, dependencies);
	}

	public override measure(constraints: LayoutConstraints, _context: UIContext): MeasuredSize {
		const width  = this.props.width ?? this.props.minWidth ?? constraints.maxWidth;
		const height = this.props.height ?? this.props.minHeight ?? Math.min(Math.max(1, this.props.entries.length), constraints.maxHeight);

		return this.createMeasuredSize(width, height, constraints);
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

		if (innerRect.width <= 0 || innerRect.height <= 0) {
			return;
		}

		const visibleEntries = this.getVisibleEntries(innerRect.height, style);

		for (let index = 0; index < visibleEntries.length; index += 1) {
			const entry     = visibleEntries[index]!;
			const lineStyle = this.getEntryTextStyle(style, entry, context);

			drawText(context, createOptions<DrawTextOptions>({
				rect:           {
					x:      innerRect.x,
					y:      innerRect.y + index,
					width:  innerRect.width,
					height: 1,
				},
				text:           this.formatEntry(entry, style),
				fillBackground: lineStyle.backgroundColor !== undefined,
			})
				.with('style', lineStyle)
				.with('clipRect', context.clipRect)
				.done());
		}
	}

	protected override getResolvedStyle(context: UIContext | RenderContext<UIDrawSurface>): Partial<LogViewerStyle> {
		return this.getStyle(context, (themeStyle) => createOptions<LogViewerStyle>(themeStyle)
			.with('padding', themeStyle.padding ?? 0)
			.with('lineStyle', createOptions<TextStyle>(themeStyle.lineStyle ?? {})
				.with('alignment', themeStyle.lineStyle?.alignment ?? 'left')
				.with('wrap', themeStyle.lineStyle?.wrap ?? 'none')
				.with('ellipsis', themeStyle.lineStyle?.ellipsis ?? true)
				.with('foregroundColor', themeStyle.lineStyle?.foregroundColor ?? this.props.foregroundColor ?? context.theme.palette.text)
				.with('backgroundColor', themeStyle.lineStyle?.backgroundColor ?? this.props.backgroundColor ?? themeStyle.backgroundColor)
				.done())
			.with('showTimestamp', themeStyle.showTimestamp ?? true)
			.with('autoScroll', themeStyle.autoScroll ?? true)
			.done());
	}

	private getVisibleEntries(maxLines: number, style: Partial<LogViewerStyle>): LogEntry[] {
		if (maxLines <= 0) {
			return [];
		}

		const entries      = this.props.entries;
		const scrollOffset = Math.max(0, this.props.scrollOffset ?? 0);

		let startIndex = 0;

		if (style.autoScroll) {
			startIndex = Math.max(0, entries.length - maxLines - scrollOffset);
		}
		else {
			startIndex = Math.min(scrollOffset, Math.max(0, entries.length - 1));
		}

		return entries.slice(startIndex, startIndex + maxLines);
	}

	private formatEntry(entry: LogEntry, style: Partial<LogViewerStyle>): string {
		const parts: string[] = [];

		if (style.showTimestamp && entry.timestamp) {
			parts.push(`[${entry.timestamp}]`);
		}

		parts.push(entry.level.toUpperCase());
		parts.push(entry.message);

		return parts.join(' ');
	}

	private getEntryTextStyle(style: Partial<LogViewerStyle>, entry: LogEntry, context: UIContext | RenderContext<UIDrawSurface>): Partial<TextStyle> {
		const levelForeground = style.levelColors?.[entry.level];

		return {
			...style.lineStyle,
			foregroundColor: levelForeground ?? style.lineStyle?.foregroundColor ?? context.theme.palette.text,
		};
	}
}