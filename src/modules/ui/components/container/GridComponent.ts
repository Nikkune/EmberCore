import {BaseContainerComponent, drawBox, type DrawBoxOptions, getInnerRect, normalizeInsets, type UIDrawSurface}                        from '@modules/ui';
import type {ComponentDependencies, GridProps, GridStyle, LayoutConstraints, MeasuredSize, Rect, RenderContext, UIComponent, UIContext} from '@modules/ui/types';
import {createFilledArray}                                                                                                              from '@modules/ui/utils/arrays';
import {createOptions}                                                                                                                  from '@utils/helpers';

interface GridPlacement<TChild extends UIComponent<UIDrawSurface>> {
	child: TChild;
	rect: Rect;
}

export class GridComponent<TChild extends UIComponent<UIDrawSurface> = UIComponent<UIDrawSurface>> extends BaseContainerComponent<'grid', GridProps, UIDrawSurface, GridStyle, TChild> {
	public constructor(props: GridProps, dependencies: ComponentDependencies = {}, children: TChild[] = []) {
		super('grid', props, dependencies, children);
	}

	public override measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize {
		const style            = this.getResolvedStyle(context);
		const innerConstraints = this.getInnerConstraints(constraints, style);

		const columns       = this.getColumns();
		const columnSpacing = this.props.columnSpacing ?? 0;
		const rowSpacing    = this.props.rowSpacing ?? 0;

		const childrenSizes = this.measureChildren(innerConstraints, context);

		if (childrenSizes.length === 0) {
			return this.createMeasuredSize(this.getRequestedWidth(0), this.getRequestedHeight(0), constraints);
		}

		const columnWidths         = createFilledArray(columns, 0);
		const rowHeights: number[] = [];

		for (let index = 0; index < childrenSizes.length; index += 1) {
			const size   = childrenSizes[index]!;
			const column = index % columns;
			const row    = Math.floor(index / columns);

			columnWidths[column] = Math.max(columnWidths[column] ?? 0, size.width);
			rowHeights[row]      = Math.max(rowHeights[row] ?? 0, size.height);
		}

		const contentWidth = columnWidths.reduce((sum, width) => sum + width, 0) + Math.max(0, columnWidths.length - 1) * columnSpacing;

		const contentHeight = rowHeights.reduce((sum, height) => sum + height, 0) + Math.max(0, rowHeights.length - 1) * rowSpacing;

		const padding = normalizeInsets(style.padding);
		const borderX = style.border?.enabled ? 2 : 0;
		const borderY = style.border?.enabled ? 2 : 0;

		return this.createMeasuredSize(this.getRequestedWidth(contentWidth + padding.left + padding.right + borderX), this.getRequestedHeight(contentHeight + padding.top + padding.bottom + borderY), constraints);
	}

	public override layout(rect: {
		x: number;
		y: number;
		width: number;
		height: number;
	}, context: UIContext): void {
		super.layout(rect, context);

		const style      = this.getResolvedStyle(context);
		const innerRect  = getInnerRect(this.rect, style);
		const placements = this.createPlacements(innerRect, context);

		this.layoutChildren(placements, context);
	}

	public override render(context: RenderContext<UIDrawSurface>): void {
		if (!this.visible) return;
		if (this.width <= 0 || this.height <= 0) return;

		const style            = this.getResolvedStyle(context);
		const borderCharacters = style.border?.enabled ? context.theme.borders[style.border.preset ?? 'single'] : undefined;

		drawBox(context.draw, createOptions<DrawBoxOptions>({
			rect: this.rect,
			style,
		})
			.with('borderCharacters', borderCharacters)
			.with('clipRect', context.clipRect)
			.done());

		this.renderChildren(context);
	}

	protected override getResolvedStyle(context: UIContext | RenderContext<UIDrawSurface>): Partial<GridStyle> {
		return this.getStyle(context, (themeStyle) => createOptions<GridStyle>(themeStyle)
			.with('foregroundColor', this.props.foregroundColor ?? themeStyle.foregroundColor ?? context.theme.palette.text)
			.with('backgroundColor', this.props.backgroundColor ?? themeStyle.backgroundColor ?? context.theme.palette.surface)
			.with('padding', themeStyle.padding ?? 0)
			.done());
	}

	private getColumns(): number {
		return Math.max(1, this.props.columns ?? 1);
	}

	private getInnerConstraints(constraints: LayoutConstraints, style: Partial<GridStyle>): LayoutConstraints {
		const padding = normalizeInsets(style.padding);
		const borderX = style.border?.enabled ? 2 : 0;
		const borderY = style.border?.enabled ? 2 : 0;

		const horizontal = padding.left + padding.right + borderX;
		const vertical   = padding.top + padding.bottom + borderY;

		return {
			minWidth:  Math.max(0, constraints.minWidth - horizontal),
			maxWidth:  Math.max(0, constraints.maxWidth - horizontal),
			minHeight: Math.max(0, constraints.minHeight - vertical),
			maxHeight: Math.max(0, constraints.maxHeight - vertical),
		};
	}

	private createPlacements(innerRect: Rect, context: UIContext): GridPlacement<TChild>[] {
		const children      = [...this.children];
		const columns       = this.getColumns();
		const columnSpacing = this.props.columnSpacing ?? 0;
		const rowSpacing    = this.props.rowSpacing ?? 0;

		if (children.length === 0 || innerRect.width <= 0 || innerRect.height <= 0) {
			return [];
		}

		const availableWidth  = Math.max(0, innerRect.width - Math.max(0, columns - 1) * columnSpacing);
		const baseColumnWidth = columns > 0 ? Math.floor(availableWidth / columns) : 0;
		let extraWidth        = columns > 0 ? availableWidth % columns : 0;

		const columnWidths = createFilledArray(columns, baseColumnWidth).map((width) => {
			if (extraWidth > 0) {
				extraWidth -= 1;
				return width + 1;
			}

			return width;
		});

		const rowCount   = Math.ceil(children.length / columns);
		const rowHeights = createFilledArray(rowCount, 0);

		for (let index = 0; index < children.length; index += 1) {
			const child       = children[index]!;
			const column      = index % columns;
			const row         = Math.floor(index / columns);
			const columnWidth = columnWidths[column] ?? 0;

			const measured = child.measure({
				minWidth:  0,
				maxWidth:  columnWidth,
				minHeight: 0,
				maxHeight: innerRect.height,
			}, context);

			rowHeights[row] = Math.max(rowHeights[row] ?? 0, measured.height);
		}

		const placements: GridPlacement<TChild>[] = [];

		let currentY = innerRect.y;

		for (let row = 0; row < rowCount; row += 1) {
			let currentX    = innerRect.x;
			const rowHeight = rowHeights[row] ?? 0;

			for (let column = 0; column < columns; column += 1) {
				const index = row * columns + column;
				const child = children[index];

				if (!child) {
					break;
				}

				const columnWidth = columnWidths[column] ?? 0;

				placements.push({
					child,
					rect: {
						x:      currentX,
						y:      currentY,
						width:  columnWidth,
						height: rowHeight,
					},
				});

				currentX += columnWidth + columnSpacing;
			}

			currentY += rowHeight + rowSpacing;
		}

		return placements;
	}
}