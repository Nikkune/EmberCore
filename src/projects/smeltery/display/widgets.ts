import {ContainerComponent}                                                         from '@modules/ui/components';
import {BaseComponent}                                                              from '@modules/ui/core/components/coreComponent';
import type {UIDrawSurface}                                                         from '@modules/ui/render/surfaceAdapter';
import type {BaseProps, LabelStyle, LayoutConstraints, MeasuredSize, Rect, RenderContext, UIComponent, UIContext} from '@modules/ui/types';

/**
 * Draws on the monitor with absolute coordinates (1-based, as CC), each call with its own colors. With a
 * `clip` (a partial redraw), only what falls inside it is drawn: the components outside are not redrawn,
 * so painting over them would erase them.
 */
export class Painter {
	public constructor(private readonly draw: UIDrawSurface, private readonly clip?: Rect) {
	}

	public text(x: number, y: number, text: string, foreground: number, background: number = colors.black): void {
		let start = x;
		let shown = text;
		const clip = this.clip;
		if (clip !== undefined) {
			if (y < clip.y || y >= clip.y + clip.height) return;
			const from = Math.max(x, clip.x);
			const to   = Math.min(x + text.length, clip.x + clip.width);
			if (to <= from) return;
			shown = text.substring(from - x, to - x);
			start = from;
		}
		if (shown.length === 0) return;
		this.draw.withColors({foregroundColor: foreground, backgroundColor: background}, () => this.draw.writeAt({x: start, y}, shown));
	}

	public fill(x: number, y: number, width: number, height: number, background: number): void {
		let rect: Rect = {x, y, width, height};
		const clip = this.clip;
		if (clip !== undefined) {
			const left = Math.max(x, clip.x), top = Math.max(y, clip.y);
			const right = Math.min(x + width, clip.x + clip.width), bottom = Math.min(y + height, clip.y + clip.height);
			rect = {x: left, y: top, width: right - left, height: bottom - top};
		}
		if (rect.width <= 0 || rect.height <= 0) return;
		this.draw.fillRect(rect, ' ', background);
	}

	/**
	 * One cell drawn as 2 x 3 pixels (CC's drawing characters, 128-159): `mask` adds 1 top-left, 2 top-right,
	 * 4 middle-left, 8 middle-right, 16 bottom-left, 32 bottom-right for the pixels in `color`; the others
	 * are `background`. The characters have no bottom-right pixel: when it is on, the colors swap.
	 */
	public pixel(x: number, y: number, mask: number, color: number, background: number = colors.black): void {
		const low = mask % 32;
		if (mask >= 32) this.text(x, y, String.fromCharCode(128 + 31 - low), background, color);
		else this.text(x, y, String.fromCharCode(128 + low), color, background);
	}
}

/** Weights of the 6 pixels of a cell, in the order top-left, top-right, middle-left, ... (see Painter.pixel). */
const PIXEL_WEIGHTS = [1, 2, 4, 8, 16, 32];

/**
 * A drawing in pixels (2 per cell across, 3 down) over `width` x `height` cells from (x, y): set pixels,
 * then paint. A cell takes at most two colors: the most used one and the next (or the background).
 * Cells with nothing set are left as they are.
 */
export class Pixels {
	private readonly colorAt = new Map<number, number>();

	public constructor(
		private readonly x: number,
		private readonly y: number,
		private readonly width: number,
		private readonly height: number,
	) {
	}

	/** Pixel (px, py), 0-based from the top-left pixel; outside the area: ignored. */
	public set(px: number, py: number, color: number): void {
		if (px < 0 || py < 0 || px >= this.width * 2 || py >= this.height * 3) return;
		this.colorAt.set(py * 4096 + px, color);
	}

	public line(x0: number, y0: number, x1: number, y1: number, color: number): void {
		const steps = Math.max(Math.abs(x1 - x0), Math.abs(y1 - y0), 1);
		for (let step = 0; step <= steps; step++) {
			this.set(Math.round(x0 + (x1 - x0) * step / steps), Math.round(y0 + (y1 - y0) * step / steps), color);
		}
	}

	public rect(px: number, py: number, width: number, height: number, color: number): void {
		for (let row = 0; row < height; row++) {
			for (let column = 0; column < width; column++) this.set(px + column, py + row, color);
		}
	}

	public paint(p: Painter, background: number = colors.black): void {
		for (let cy = 0; cy < this.height; cy++) {
			for (let cx = 0; cx < this.width; cx++) {
				// No undefined in the array: in Lua it would leave no hole, and the pixels after it would shift.
				const cell: number[] = [];
				let any = false;
				for (let index = 0; index < 6; index++) {
					const color = this.colorAt.get((cy * 3 + Math.floor(index / 2)) * 4096 + cx * 2 + (index % 2));
					cell.push(color ?? background);
					if (color !== undefined) any = true;
				}
				if (!any) continue;

				// The most used color is drawn; the next one (or the background) fills the rest.
				const counts = new Map<number, number>();
				for (const color of cell) counts.set(color, (counts.get(color) ?? 0) + 1);
				const ranked: [number, number][] = [];
				for (const [color, count] of counts) ranked.push([color, count]);
				ranked.sort((a, b) => b[1] - a[1]);
				const first = ranked.find(([color]) => color !== background);
				if (first === undefined) continue;
				const on  = first[0];
				const off = ranked.find(([color]) => color !== on)?.[0] ?? background;

				let mask = 0;
				cell.forEach((color, index) => {
					if (color === on) mask += PIXEL_WEIGHTS[index]!;
				});
				p.pixel(this.x + cx, this.y + cy, mask, on, off);
			}
		}
	}
}

export interface PaintProps extends BaseProps {
	paint: (painter: Painter) => void;
}

/** A leaf that draws whatever its paint function draws (tanks, gauges, texts), over the whole area it gets. */
export class PaintComponent extends BaseComponent<'label', PaintProps, UIDrawSurface, LabelStyle> {
	public constructor(props: PaintProps) {
		super('label', props);
	}

	public override measure(constraints: LayoutConstraints, _context: UIContext): MeasuredSize {
		return this.createMeasuredSize(constraints.maxWidth, constraints.maxHeight, constraints);
	}

	public override render(context: RenderContext<UIDrawSurface>): void {
		if (!this.visible) return;
		this.props.paint(new Painter(context.draw, context.clipRect));
	}

	protected override getResolvedStyle(context: UIContext | RenderContext<UIDrawSurface>): Partial<LabelStyle> {
		return this.getStyle(context, {});
	}
}

type Child = UIComponent<UIDrawSurface>;

/**
 * A container that puts each child at a fixed place (1-based monitor coordinates), for screens drawn to the
 * character. Children are drawn and hit in their order: the last one is on top.
 */
export class AbsoluteLayout extends ContainerComponent<Child> {
	private readonly places = new Map<Child, Rect>();

	public constructor(width: number, height: number) {
		super({width, height});
	}

	public place<T extends Child>(child: T, rect: Rect): T {
		this.places.set(child, rect);
		this.addChild(child);
		return child;
	}

	public override layout(rect: Rect, context: UIContext): void {
		super.layout(rect, context);

		this.layoutChildren(this.children.map((child) => ({
			child,
			rect: this.places.get(child) ?? rect,
		})), context);
	}
}
