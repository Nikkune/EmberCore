import {ISurface} from "./surface";
import {HorizontalAlign, Rect, TextOptions} from "./types";

export class TextRenderer {
	constructor(private readonly surface: ISurface) {
	}

	public static truncate(text: string, maxLength: number, ellipsis = false): string {
		if (maxLength <= 0) {
			return "";
		}

		if (text.length <= maxLength) {
			return text;
		}

		if (!ellipsis || maxLength <= 3) {
			return text.slice(0, maxLength);
		}

		return `${text.slice(0, maxLength - 3)}...`;
	}

	public static alignText(text: string, width: number, align: HorizontalAlign = "left"): string {
		if (width <= 0) {
			return "";
		}

		if (text.length >= width) {
			return text.slice(0, width);
		}

		const remaining = width - text.length;

		switch (align) {
			case "right":
				return `${" ".repeat(remaining)}${text}`;
			case "center":
				const leftPadding = Math.floor(remaining / 2);
				const rightPadding = remaining - leftPadding;
				return `${" ".repeat(leftPadding)}${text}${" ".repeat(rightPadding)}`;
			case "left":
			default:
				return `${text}${" ".repeat(remaining)}`;
		}
	}

	public drawLine(y: number, text: string, options: TextOptions = {}): void {
		const width = options.maxWidth ?? this.surface.getWidth();
		const align = options.align ?? "left";

		const clipped = TextRenderer.truncate(text, width, options.ellipsis ?? false);
		const rendered = TextRenderer.alignText(clipped, width, align);

		this.surface.withColors(
			{
				foreground: options.color,
				background: options.backgroundColor,
			},
			() => {
				this.surface.drawTextLine(y, rendered);
			}
		)
	}

	public drawAt(x: number, y: number, text: string, options: TextOptions = {}): void {
		const maxWidth = options.maxWidth ?? Math.max(0, this.surface.getWidth() - x + 1);
		const clipped = TextRenderer.truncate(text, maxWidth, options.ellipsis ?? false);

		this.surface.withColors(
			{
				foreground: options.color,
				background: options.backgroundColor,
			},
			() => {
				this.surface.writeAt({x, y}, clipped);
			}
		)
	}

	public drawInRect(rect: Rect, text: string, options: TextOptions = {}): void {
		const align = options.align ?? "left";
		const clipped = TextRenderer.truncate(text, rect.width, options.ellipsis ?? false);
		const rendered = TextRenderer.alignText(clipped, rect.width, align);

		this.surface.withColors(
			{
				foreground: options.color,
				background: options.backgroundColor,
			},
			() => {
				this.surface.writeAt({x: rect.x, y: rect.y}, rendered);
			}
		)
	}
}