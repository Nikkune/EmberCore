import type {BorderCharacters, BoxStyle, Color, Insets, PaddingLike, Point, Rect, RenderContext, TextStyle, TextWrap, UIDrawSurface} from '@modules/ui';
import {makeColorOptions}                                                                                                            from '@modules/ui';
import {createOptions}                                                                                                               from '@utils/helpers';

export interface ClipTextResult {
	text: string;
	startOffset: number;
}

export interface WrappedLine {
	text: string;
	sourceLineIndex: number;
}

export interface DrawTextLineOptions {
	position: Point;
	width: number;
	text: string;
	style?: TextStyle;
	clipRect?: Rect;
}

export interface DrawTextOptions {
	rect: Rect;
	text: string;
	style?: TextStyle;
	clipRect?: Rect;
	fillBackground?: boolean;
}

export interface FillRectOptions {
	rect: Rect;
	character?: string;
	backgroundColor?: Color;
	foregroundColor?: Color;
	clipRect?: Rect;
}

export interface DrawBorderOptions {
	rect: Rect;
	border: BorderCharacters;
	foregroundColor?: Color;
	backgroundColor?: Color;
	clipRect?: Rect;
}

export interface DrawBoxOptions {
	rect: Rect;
	style?: BoxStyle;
	borderCharacters?: BorderCharacters;
	clipRect?: Rect;
}

export interface ResolveTextLinesOptions {
	text: string;
	width: number;
	height?: number;
	style?: TextStyle;
}

export function repeat(value: string, count: number): string {
	if (count <= 0 || value.length === 0) {
		return '';
	}

	let result = '';

	for (let index = 0; index < count; index += 1) {
		result += value;
	}

	return result;
}

export function containsPoint(rect: Rect, point: Point): boolean {
	return point.x >= rect.x && point.y >= rect.y && point.x < rect.x + rect.width && point.y < rect.y + rect.height;
}

export function intersectRects(a: Rect, b: Rect): Rect | undefined {
	const x      = Math.max(a.x, b.x);
	const y      = Math.max(a.y, b.y);
	const right  = Math.min(a.x + a.width - 1, b.x + b.width - 1);
	const bottom = Math.min(a.y + a.height - 1, b.y + b.height - 1);

	const width  = right - x + 1;
	const height = bottom - y + 1;

	if (width <= 0 || height <= 0) {
		return undefined;
	}

	return {
		x,
		y,
		width,
		height,
	};
}

export function rectRight(rect: Rect): number {
	return rect.x + rect.width - 1;
}

export function rectBottom(rect: Rect): number {
	return rect.y + rect.height - 1;
}

export function normalizeInsets(value?: PaddingLike): Insets {
	if (value === undefined) {
		return {
			top:    0,
			right:  0,
			bottom: 0,
			left:   0,
		};
	}

	if (typeof value === 'number') {
		return {
			top:    value,
			right:  value,
			bottom: value,
			left:   value,
		};
	}

	let horizontal = 0;
	let vertical   = 0;

	if ('horizontal' in value) horizontal = value.horizontal ?? 0;
	if ('vertical' in value) vertical = value.vertical ?? 0;
	if ('x' in value) horizontal = value.x ?? 0;
	if ('y' in value) vertical = value.y ?? 0;

	let result = {
		top:    vertical,
		right:  horizontal,
		bottom: vertical,
		left:   horizontal,
	};

	if ('top' in value) result.top = value.top ?? 0;
	if ('right' in value) result.right = value.right ?? 0;
	if ('bottom' in value) result.bottom = value.bottom ?? 0;
	if ('left' in value) result.left = value.left ?? 0;
	return result;
}

export function shrinkRect(rect: Rect, insets: Partial<Insets>): Rect {
	const top    = insets.top ?? 0;
	const right  = insets.right ?? 0;
	const bottom = insets.bottom ?? 0;
	const left   = insets.left ?? 0;

	const width  = Math.max(0, rect.width - left - right);
	const height = Math.max(0, rect.height - top - bottom);

	return {
		x: rect.x + left,
		y: rect.y + top,
		width,
		height,
	};
}

export function expandRect(rect: Rect, insets: Partial<Insets>): Rect {
	const top    = insets.top ?? 0;
	const right  = insets.right ?? 0;
	const bottom = insets.bottom ?? 0;
	const left   = insets.left ?? 0;

	return {
		x:      rect.x - left,
		y:      rect.y - top,
		width:  rect.width + left + right,
		height: rect.height + top + bottom,
	};
}

export function getInnerRect(rect: Rect, style?: BoxStyle): Rect {
	let result = rect;

	if (style?.border?.enabled) {
		result = shrinkRect(result, {
			top:    1,
			right:  1,
			bottom: 1,
			left:   1,
		});
	}

	if (style?.padding !== undefined) {
		result = shrinkRect(result, normalizeInsets(style.padding));
	}

	return result;
}

export function clipText(text: string, maxWidth: number): string {
	if (maxWidth <= 0 || text.length === 0) {
		return '';
	}

	if (text.length <= maxWidth) {
		return text;
	}

	return text.slice(0, maxWidth);
}

export function applyEllipsis(text: string, maxWidth: number): string {
	if (maxWidth <= 0) {
		return '';
	}

	if (text.length <= maxWidth) {
		return text;
	}

	if (maxWidth === 1) {
		return '…';
	}

	return `${text.slice(0, maxWidth - 1)}…`;
}

export function alignText(text: string, width: number, alignment: 'left' | 'center' | 'right' = 'left'): string {
	if (width <= 0) {
		return '';
	}

	const clipped = clipText(text, width);

	if (clipped.length >= width) {
		return clipped;
	}

	const remaining = width - clipped.length;

	if (alignment === 'right') {
		return `${repeat(' ', remaining)}${clipped}`;
	}

	if (alignment === 'center') {
		const left  = Math.floor(remaining / 2);
		const right = remaining - left;
		return `${repeat(' ', left)}${clipped}${repeat(' ', right)}`;
	}

	return `${clipped}${repeat(' ', remaining)}`;
}

export function clipTextToRect(position: Point, text: string, clipRect: Rect): ClipTextResult | undefined {
	if (text.length === 0) {
		return undefined;
	}

	if (position.y < clipRect.y || position.y >= clipRect.y + clipRect.height) {
		return undefined;
	}

	const textStart = position.x;
	const textEnd   = position.x + text.length - 1;
	const clipStart = clipRect.x;
	const clipEnd   = clipRect.x + clipRect.width - 1;

	if (textEnd < clipStart || textStart > clipEnd) {
		return undefined;
	}

	const startOffset  = Math.max(0, clipStart - textStart);
	const visibleStart = textStart + startOffset;
	const visibleWidth = clipEnd - visibleStart + 1;

	if (visibleWidth <= 0) {
		return undefined;
	}

	return {
		text: text.slice(startOffset, startOffset + visibleWidth),
		startOffset,
	};
}

export function drawTextLine(draw: UIDrawSurface, options: DrawTextLineOptions): void {
	if (options.width <= 0 || options.text.length === 0) {
		return;
	}

	const alignment = options.style?.alignment ?? 'left';

	const aligned = alignText(options.text, options.width, alignment);

	const clipRect = options.clipRect;

	const withColorsOptions = makeColorOptions(options.style);

	if (clipRect) {
		const clipped = clipTextToRect(options.position, aligned, clipRect);

		if (!clipped) {
			return;
		}

		draw.withColors(withColorsOptions, () => {
			draw.writeAt({
				x: options.position.x + clipped.startOffset,
				y: options.position.y,
			}, clipped.text);
		});

		return;
	}

	draw.withColors(withColorsOptions, () => {
		draw.writeAt(options.position, aligned);
	});
}

export function splitLines(text: string): string[] {
	return text.split('\n');
}

function pushWrappedLine(lines: WrappedLine[], text: string, sourceLineIndex: number): void {
	lines.push({
		text,
		sourceLineIndex,
	});
}

export function wrapLineByCharacter(text: string, width: number): string[] {
	if (width <= 0) {
		return [];
	}

	if (text.length === 0) {
		return [''];
	}

	const result: string[] = [];
	let index              = 0;

	while (index < text.length) {
		result.push(text.slice(index, index + width));
		index += width;
	}

	return result;
}

export function wrapLineByWord(text: string, width: number): string[] {
	if (width <= 0) {
		return [];
	}

	if (text.length === 0) {
		return [''];
	}

	const result: string[] = [];
	const words            = text.split(/\s+/).filter((word) => word.length > 0);

	if (words.length === 0) {
		return [''];
	}

	let current = '';

	for (const word of words) {
		if (current.length === 0) {
			if (word.length <= width) {
				current = word;
				continue;
			}

			const chunks = wrapLineByCharacter(word, width);
			result.push(...chunks);
			continue;
		}

		const candidate = `${current} ${word}`;

		if (candidate.length <= width) {
			current = candidate;
			continue;
		}

		result.push(current);

		if (word.length <= width) {
			current = word;
			continue;
		}

		const chunks = wrapLineByCharacter(word, width);
		result.push(...chunks.slice(0, Math.max(0, chunks.length - 1)));
		current = chunks[chunks.length - 1] ?? '';
	}

	if (current.length > 0 || result.length === 0) {
		result.push(current);
	}

	return result;
}

export function wrapText(text: string, width: number, wrap: TextWrap = 'none'): WrappedLine[] {
	if (width <= 0) {
		return [];
	}

	const sourceLines           = splitLines(text);
	const result: WrappedLine[] = [];

	for (let sourceLineIndex = 0; sourceLineIndex < sourceLines.length; sourceLineIndex += 1) {
		const sourceLine = sourceLines[sourceLineIndex]!;

		if (wrap === 'none') {
			pushWrappedLine(result, sourceLine, sourceLineIndex);
			continue;
		}

		const wrappedLines = wrap === 'word' ? wrapLineByWord(sourceLine, width) : wrapLineByCharacter(sourceLine, width);

		if (wrappedLines.length === 0) {
			pushWrappedLine(result, '', sourceLineIndex);
			continue;
		}

		for (const line of wrappedLines) {
			pushWrappedLine(result, line, sourceLineIndex);
		}
	}

	return result;
}

export function resolveTextLines(options: ResolveTextLinesOptions): WrappedLine[] {
	const width    = options.width;
	const height   = options.height;
	const style    = options.style;
	const wrap     = style?.wrap ?? 'none';
	const ellipsis = style?.ellipsis ?? false;

	if (width <= 0) {
		return [];
	}

	let lines = wrapText(options.text, width, wrap);

	if (wrap === 'none') {
		lines = lines.map((line) => ({
			...line,
			text: ellipsis ? applyEllipsis(line.text, width) : clipText(line.text, width),
		}));
	}

	if (height !== undefined && height >= 0 && lines.length > height) {
		lines = lines.slice(0, height);

		if (ellipsis && height > 0) {
			const lastIndex = lines.length - 1;
			const lastLine  = lines[lastIndex];

			if (lastLine) {
				lines[lastIndex] = {
					...lastLine,
					text: applyEllipsis(lastLine.text, width),
				};
			}
		}
	}

	return lines;
}

export function drawText(context: RenderContext<UIDrawSurface>, options: DrawTextOptions): void {
	const draw     = context.draw;
	const style    = options.style;
	const clipRect = options.clipRect;

	if (options.rect.width <= 0 || options.rect.height <= 0) {
		return;
	}

	const targetRect = clipRect ? intersectRects(options.rect, clipRect) : options.rect;

	if (!targetRect) {
		return;
	}

	if (options.fillBackground && style?.backgroundColor !== undefined) {
		fillRect(draw, createOptions<FillRectOptions>({
			rect:            options.rect,
			backgroundColor: style.backgroundColor,
		})
			.with('clipRect', clipRect)
			.done());
	}

	const lines = resolveTextLines(createOptions<ResolveTextLinesOptions>({
		text:   options.text,
		width:  options.rect.width,
		height: options.rect.height,
	})
		.with('style', style)
		.done());

	const maxLines = Math.min(lines.length, options.rect.height);

	for (let index = 0; index < maxLines; index += 1) {
		drawTextLine(draw, createOptions<DrawTextLineOptions>({
			position: {
				x: options.rect.x,
				y: options.rect.y + index,
			},
			width:    options.rect.width,
			text:     lines[index]!.text,
		})
			.with('style', style)
			.with('clipRect', clipRect)
			.done());
	}
}

export function fillRect(draw: UIDrawSurface, options: FillRectOptions): void {
	const targetRect = options.clipRect ? intersectRects(options.rect, options.clipRect) : options.rect;

	if (!targetRect || targetRect.width <= 0 || targetRect.height <= 0) {
		return;
	}

	draw.fillRect(targetRect, options.character ?? ' ', options.backgroundColor, options.foregroundColor);
}

export function drawHorizontalLine(draw: UIDrawSurface, position: Point, width: number, character: string, foregroundColor?: Color, backgroundColor?: Color, clipRect?: Rect): void {
	drawTextLine(draw, createOptions<DrawTextLineOptions>({
		position: position,
		width:    width,
		text:     repeat(character, width),
		style:    makeColorOptions({
			foregroundColor,
			backgroundColor,
		}),
	})
		.with('clipRect', clipRect)
		.done());
}

export function drawVerticalLine(draw: UIDrawSurface, position: Point, height: number, character: string, foregroundColor?: Color, backgroundColor?: Color, clipRect?: Rect): void {
	for (let index = 0; index < height; index += 1) {
		drawTextLine(draw, createOptions<DrawTextLineOptions>({
			position: {
				x: position.x,
				y: position.y + index,
			},
			width:    1,
			text:     character,
			style:    makeColorOptions({
				foregroundColor,
				backgroundColor,
			}),
		})
			.with('clipRect', clipRect)
			.done());
	}
}

export function drawBorder(draw: UIDrawSurface, options: DrawBorderOptions): void {
	const {
		      rect,
		      border,
		      foregroundColor,
		      backgroundColor,
		      clipRect,
	      } = options;

	if (rect.width <= 0 || rect.height <= 0) {
		return;
	}

	if (rect.width === 1 && rect.height === 1) {
		drawTextLine(draw, createOptions<DrawTextLineOptions>({
			position: {
				x: rect.x,
				y: rect.y,
			},
			width:    1,
			text:     border.topLeft,
			style:    makeColorOptions({
				foregroundColor,
				backgroundColor,
			}),
		})
			.with('clipRect', clipRect)
			.done());

		return;
	}

	if (rect.height === 1) {
		const middleWidth = Math.max(0, rect.width - 2);
		const top         = rect.width === 1 ? border.topLeft : border.topLeft + repeat(border.horizontal, middleWidth) + border.topRight;

		drawTextLine(draw, createOptions<DrawTextLineOptions>({
			position: {
				x: rect.x,
				y: rect.y,
			},
			width:    rect.width,
			text:     top,
			style:    makeColorOptions({
				foregroundColor,
				backgroundColor,
			}),
		})
			.with('clipRect', clipRect)
			.done());

		return;
	}

	const top = rect.width === 1 ? border.vertical : border.topLeft + repeat(border.horizontal, Math.max(0, rect.width - 2)) + border.topRight;

	const bottom = rect.width === 1 ? border.vertical : border.bottomLeft + repeat(border.horizontal, Math.max(0, rect.width - 2)) + border.bottomRight;

	drawTextLine(draw, createOptions<DrawTextLineOptions>({
		position: {
			x: rect.x,
			y: rect.y,
		},
		width:    rect.width,
		text:     top,
		style:    makeColorOptions({
			foregroundColor,
			backgroundColor,
		}),
	})
		.with('clipRect', clipRect)
		.done());

	drawTextLine(draw, createOptions<DrawTextLineOptions>({
		position: {
			x: rect.x,
			y: rect.y + rect.height - 1,
		},
		width:    rect.width,
		text:     bottom,
		style:    makeColorOptions({
			foregroundColor,
			backgroundColor,
		}),
	})
		.with('clipRect', clipRect)
		.done());

	for (let row = 1; row < rect.height - 1; row += 1) {
		if (rect.width === 1) {
			drawTextLine(draw, createOptions<DrawTextLineOptions>({
				position: {
					x: rect.x,
					y: rect.y + row,
				},
				width:    1,
				text:     border.vertical,
				style:    makeColorOptions({
					foregroundColor,
					backgroundColor,
				}),
			})
				.with('clipRect', clipRect)
				.done());

			continue;
		}

		drawTextLine(draw, createOptions<DrawTextLineOptions>({
			position: {
				x: rect.x,
				y: rect.y + row,
			},
			width:    1,
			text:     border.vertical,
			style:    makeColorOptions({
				foregroundColor,
				backgroundColor,
			}),
		})
			.with('clipRect', clipRect)
			.done());

		drawTextLine(draw, createOptions<DrawTextLineOptions>({
			position: {
				x: rect.x + rect.width - 1,
				y: rect.y + row,
			},
			width:    1,
			text:     border.vertical,
			style:    makeColorOptions({
				foregroundColor,
				backgroundColor,
			}),
		})
			.with('clipRect', clipRect)
			.done());
	}
}

export function drawBox(draw: UIDrawSurface, options: DrawBoxOptions): Rect {
	const style           = options.style;
	const backgroundColor = style?.backgroundColor;
	const foregroundColor = style?.foregroundColor;
	const borderStyle     = style?.border;

	if (backgroundColor !== undefined) {
		fillRect(draw, createOptions<FillRectOptions>({
			rect: options.rect,
			backgroundColor,
		})
			.with('foregroundColor', foregroundColor)
			.with('clipRect', options.clipRect)
			.done());
	}

	if (borderStyle?.enabled && options.borderCharacters) {
		drawBorder(draw, createOptions<DrawBorderOptions>({
			rect:   options.rect,
			border: options.borderCharacters,
		})
			.with('clipRect', options.clipRect)
			.with('backgroundColor', borderStyle.backgroundColor ?? backgroundColor)
			.with('foregroundColor', borderStyle.foregroundColor ?? foregroundColor)
			.done());
	}

	return getInnerRect(options.rect, style);
}

export function resolveVisibleRect(rect: Rect, clipRect?: Rect): Rect | undefined {
	return clipRect ? intersectRects(rect, clipRect) : rect;
}
