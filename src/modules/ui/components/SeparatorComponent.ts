import {BaseComponent} from "../core/baseComponent";
import {mergeComponentStyle} from "../theme/theme";
import type {ComponentDependencies, LayoutConstraints, MeasuredSize, RenderContext, SeparatorProps, SeparatorStyle, UIContext} from "../types/uiTypes";
import type {UIDrawSurface} from "../render/surfaceAdapter";
import {drawHorizontalLine, drawTextLine} from "../render/renderHelpers";

export class SeparatorComponent extends BaseComponent<SeparatorProps, UIDrawSurface> {
	public constructor(props: SeparatorProps, dependencies: ComponentDependencies = {}) {
		super('separator', props, dependencies.eventBus, dependencies.invalidator);
	}

	public measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize {
		const label = this.props.label ?? '';
		const width = this.resolveAvailableWidth(constraints, label.length);
		const height = Math.max(constraints.minHeight, Math.min(1, constraints.maxHeight));
		return {width, height};
	}

	public render(context: RenderContext<UIDrawSurface>): void {
		if (!this.visible || this.rect.width <= 0 || this.rect.height <= 0) return;

		const style = this.getResolvedStyle(context.theme);
		const character = this.resolveCharacter(style);
		const y = this.rect.y;

		drawHorizontalLine(context.draw, {x: this.rect.x, y}, this.rect.width, character, style?.foregroundColor, style?.backgroundColor);

		const label = this.props.label;

		if (!label || label.length === 0) return;

		const labelText = ` ${label} `;
		const labelWidth = Math.min(labelText.length, this.rect.width);
		const labelX = this.rect.x + Math.max(0, Math.floor((this.rect.width - labelWidth) / 2));

		drawTextLine(context.draw, {
			position: {x: labelX, y},
			width: labelWidth,
			text: labelText,
			style: {
				foregroundColor: style?.labelStyle?.foregroundColor ?? style?.foregroundColor,
				backgroundColor: style?.labelStyle?.backgroundColor ?? style?.backgroundColor,
				alignment: 'left',
			},
		});
	}

	private getResolvedStyle(theme: UIContext["theme"]): SeparatorStyle | undefined {
		return mergeComponentStyle(theme.components?.separator, this.props.style);
	}

	private resolveAvailableWidth(constraints: LayoutConstraints, contentWidth: number): number {
		if (this.props.width !== undefined) return Math.max(constraints.minWidth, Math.min(this.props.width, constraints.maxWidth));
		return Math.max(constraints.minWidth, Math.min(contentWidth > 0 ? contentWidth : 1, constraints.maxWidth));
	}

	private resolveCharacter(style?: SeparatorStyle): string {
		const value = style?.character;

		if (!value || value.length === 0) return '-';

		return value[0];
	}
}