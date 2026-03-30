import type {ComponentDependencies, LabelProps, LayoutConstraints, MeasuredSize, RenderContext, TextStyle, UIContext}                           from '@modules/ui/types';
import {BaseComponent, drawText, type DrawTextOptions, mergeComponentStyle, resolveTextLines, type ResolveTextLinesOptions, type UIDrawSurface} from '@modules/ui';
import {createOptions}                                                                                                                          from '@utils/helpers';

export class LabelComponent extends BaseComponent<LabelProps, UIDrawSurface> {
	public constructor(props: LabelProps, dependencies: ComponentDependencies = {}) {
		super('label', props, dependencies.eventBus, dependencies.invalidator);
	}

	public measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize {
		const style          = this.getResolvedStyle(context.theme);
		const availableWidth = this.resolveAvailableWidth(constraints);

		if (availableWidth <= 0) {
			return {
				width:  constraints.minWidth,
				height: constraints.minHeight,
			};
		}

		const lines = resolveTextLines(createOptions<ResolveTextLinesOptions>({
			text:  this.props.text,
			width: availableWidth,
		})
			.with('style', style)
			.done());

		let measuredWidth = 0;

		for (const line of lines) {
			if (line.text.length > measuredWidth) measuredWidth = line.text.length;
		}

		return {
			width:  Math.max(constraints.minWidth, Math.min(measuredWidth, constraints.maxWidth)),
			height: Math.max(constraints.minHeight, Math.min(lines.length, constraints.maxHeight)),
		};
	}

	public render(context: RenderContext<UIDrawSurface>): void {
		if (!this.visible || this.rect.width <= 0 || this.rect.height <= 0) return;

		const style = this.getResolvedStyle(context.theme);

		drawText(context, createOptions<DrawTextOptions>({
			rect: this.rect,
			text: this.props.text,
		})
			.with('style', style)
			.done());
	}

	private getResolvedStyle(theme: UIContext['theme']): TextStyle | undefined {
		return mergeComponentStyle(theme.components?.label, this.props.style);
	}

	private resolveAvailableWidth(constraints: LayoutConstraints): number {
		if (this.props.width !== undefined) return Math.min(this.props.width, constraints.maxWidth);
		return constraints.maxWidth;
	}
}
