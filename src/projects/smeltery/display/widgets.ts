import {ContainerComponent}                                                         from '@modules/ui/components';
import {BaseComponent}                                                              from '@modules/ui/core/components/coreComponent';
import type {UIDrawSurface}                                                         from '@modules/ui/render/surfaceAdapter';
import type {BaseProps, LabelStyle, LayoutConstraints, MeasuredSize, Rect, RenderContext, UIComponent, UIContext} from '@modules/ui/types';

/** Draws on the monitor with absolute coordinates (1-based, as CC), each call with its own colors. */
export class Painter {
	public constructor(private readonly draw: UIDrawSurface) {
	}

	public text(x: number, y: number, text: string, foreground: number, background: number = colors.black): void {
		if (text.length === 0) return;
		this.draw.withColors({foregroundColor: foreground, backgroundColor: background}, () => this.draw.writeAt({x, y}, text));
	}

	public fill(x: number, y: number, width: number, height: number, background: number): void {
		if (width <= 0 || height <= 0) return;
		this.draw.fillRect({x, y, width, height}, ' ', background);
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
		this.props.paint(new Painter(context.draw));
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
