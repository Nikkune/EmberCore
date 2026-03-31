import {BaseComponent, drawText, type DrawTextOptions, resolveTextLines, type UIDrawSurface}                           from '@modules/ui';
import type {ComponentDependencies, LabelProps, LabelStyle, LayoutConstraints, MeasuredSize, RenderContext, UIContext} from '@modules/ui/types';
import {createOptions}                                                                                                 from '@utils/helpers';

export class LabelComponent extends BaseComponent<'label', LabelProps, UIDrawSurface> {
	public constructor(props: LabelProps, dependencies: ComponentDependencies = {}) {
		super('label', props, dependencies);
	}

	public override measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize {
		const style = this.getStyle<LabelStyle>(context);

		const width = this.props.width ?? this.props.minWidth ?? constraints.maxWidth;

		const lines = resolveTextLines({
			text:  this.props.text,
			width: Math.max(0, width),
			style,
		});

		const contentWidth  = lines.reduce((max, line) => Math.max(max, line.text.length), 0);
		const contentHeight = Math.max(1, lines.length);

		return this.createMeasuredSize(this.props.width ?? this.props.minWidth ?? contentWidth, this.props.height ?? this.props.minHeight ?? contentHeight, constraints);
	}

	public override render(context: RenderContext<UIDrawSurface>) {
		if (!this.visible) return;
		if (this.width <= 0 || this.height <= 0) return;

		const style = this.getStyle<LabelStyle>(context, createOptions<LabelStyle>({})
			.with('foregroundColor', this.props.foregroundColor)
			.with('backgroundColor', this.props.backgroundColor)
			.done());

		drawText(context, createOptions<DrawTextOptions>({
			rect:           this.rect,
			text:           this.props.text,
			style,
			fillBackground: style.backgroundColor !== undefined,
		})
			.with('clipRect', context.clipRect)
			.done());
	}
}