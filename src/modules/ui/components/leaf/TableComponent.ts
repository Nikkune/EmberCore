import {BaseComponent, drawBox, type DrawBoxOptions, drawHorizontalLine, drawText, type DrawTextOptions, makeColors, type UIDrawSurface}            from '@modules/ui';
import type {ColumnDefinition, ComponentDependencies, LayoutConstraints, MeasuredSize, RenderContext, TableProps, TableStyle, TextStyle, UIContext} from '@modules/ui/types';
import {createOptions}                                                                                                                              from '@utils/helpers';

interface ResolvedColumn<T = Record<string, unknown>> {
	column: ColumnDefinition<T>;
	width: number;
}

export class TableComponent<T = Record<string, unknown>> extends BaseComponent<'table', TableProps<T>, UIDrawSurface, TableStyle> {
	public constructor(props: TableProps<T>, dependencies: ComponentDependencies = {}) {
		super('table', props, dependencies);
	}

	public override measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize {
		const style      = this.getResolvedStyle(context);
		const showHeader = style.showHeader ?? true;

		const columnWidths = this.resolveColumnWidths(constraints.maxWidth, style);
		const contentWidth = columnWidths.reduce((sum, col) => sum + col.width, 0) + (style.showBorders ? Math.max(0, columnWidths.length - 1) : 0);

		const rowCount       = this.props.rows.length + (showHeader ? 1 : 0);
		const separatorCount = style.showBorders ? Math.max(0, rowCount - 1) : 0;

		const contentHeight = rowCount + separatorCount;

		return this.createMeasuredSize(this.getRequestedWidth(contentWidth), this.getRequestedHeight(Math.max(1, contentHeight)), constraints);
	}

	public override render(context: RenderContext<UIDrawSurface>): void {
		if (!this.visible) return;
		if (this.width <= 0 || this.height <= 0) return;

		const style            = this.getResolvedStyle(context);
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

		const columns     = this.resolveColumnWidths(innerRect.width, style);
		const showHeader  = style.showHeader ?? true;
		const showBorders = style.showBorders ?? false;

		let currentY = innerRect.y;

		if (showHeader && currentY < innerRect.y + innerRect.height) {
			this.renderHeaderRow(context, columns, currentY, style, innerRect);
			currentY += 1;

			if (showBorders && currentY < innerRect.y + innerRect.height) {
				drawHorizontalLine(context.draw, {
					x: innerRect.x,
					y: currentY,
				}, innerRect.width, '─', style.separatorColor, style.backgroundColor, context.clipRect);
				currentY += 1;
			}
		}

		for (let rowIndex = 0; rowIndex < this.props.rows.length; rowIndex += 1) {
			if (currentY >= innerRect.y + innerRect.height) {
				break;
			}

			const row = this.props.rows[rowIndex]!;
			this.renderDataRow(context, columns, row, rowIndex, currentY, style, innerRect);
			currentY += 1;

			if (showBorders && rowIndex < this.props.rows.length - 1 && currentY < innerRect.y + innerRect.height) {
				drawHorizontalLine(context.draw, {
					x: innerRect.x,
					y: currentY,
				}, innerRect.width, '─', style.separatorColor, style.backgroundColor, context.clipRect);
				currentY += 1;
			}
		}
	}

	protected override getResolvedStyle(context: UIContext | RenderContext<UIDrawSurface>): Partial<TableStyle> {
		return this.getStyle(context, (themeStyle) => createOptions<TableStyle>(themeStyle)
			.with('foregroundColor', this.props.foregroundColor ?? themeStyle.foregroundColor ?? context.theme.palette.text)
			.with('backgroundColor', this.props.backgroundColor ?? themeStyle.backgroundColor ?? context.theme.palette.surface)
			.with('showHeader', themeStyle.showHeader ?? true)
			.with('showBorders', themeStyle.showBorders ?? true)
			.with('separatorColor', themeStyle.separatorColor ?? context.theme.palette.border)
			.with('headerStyle', createOptions<TextStyle>(themeStyle.headerStyle ?? {})
				.with('alignment', themeStyle.headerStyle?.alignment ?? 'left')
				.with('wrap', themeStyle.headerStyle?.wrap ?? 'none')
				.with('ellipsis', themeStyle.headerStyle?.ellipsis ?? true)
				.with('foregroundColor', themeStyle.headerStyle?.foregroundColor ?? context.theme.palette.text)
				.with('backgroundColor', themeStyle.headerStyle?.backgroundColor ?? themeStyle.backgroundColor)
				.done())
			.with('rowStyle', createOptions<TextStyle>(themeStyle.rowStyle ?? {})
				.with('alignment', themeStyle.rowStyle?.alignment ?? 'left')
				.with('wrap', themeStyle.rowStyle?.wrap ?? 'none')
				.with('ellipsis', themeStyle.rowStyle?.ellipsis ?? true)
				.with('foregroundColor', themeStyle.rowStyle?.foregroundColor ?? context.theme.palette.text)
				.with('backgroundColor', themeStyle.rowStyle?.backgroundColor ?? themeStyle.backgroundColor)
				.done())
			.done());
	}

	private resolveColumnWidths(availableWidth: number, style: Partial<TableStyle>): ResolvedColumn<T>[] {
		const columns = this.props.columns;
		if (columns.length === 0) return [];

		const showBorders    = style.showBorders ?? false;
		const separatorWidth = showBorders ? Math.max(0, columns.length - 1) : 0;
		const usableWidth    = Math.max(0, availableWidth - separatorWidth);

		const fixedWidth        = columns.reduce((sum, column) => sum + (column.width ?? 0), 0);
		const flexibleColumns   = columns.filter((column) => column.width === undefined);
		const remainingWidth    = Math.max(0, usableWidth - fixedWidth);
		const baseFlexibleWidth = flexibleColumns.length > 0 ? Math.floor(remainingWidth / flexibleColumns.length) : 0;
		let extraWidth          = flexibleColumns.length > 0 ? remainingWidth % flexibleColumns.length : 0;

		return columns.map((column) => {
			let width = column.width ?? Math.max(column.minWidth ?? 1, baseFlexibleWidth);

			if (column.width === undefined && extraWidth > 0) {
				width += 1;
				extraWidth -= 1;
			}

			if (column.minWidth !== undefined) {
				width = Math.max(width, column.minWidth);
			}

			if (column.maxWidth !== undefined) {
				width = Math.min(width, column.maxWidth);
			}

			width = Math.max(1, width);

			return {
				column,
				width,
			};
		});
	}

	private renderHeaderRow(context: RenderContext<UIDrawSurface>, columns: ResolvedColumn<T>[], y: number, style: Partial<TableStyle>, innerRect: {
		x: number;
		y: number;
		width: number;
		height: number
	}): void {
		let currentX      = innerRect.x;
		const showBorders = style.showBorders ?? false;

		for (let index = 0; index < columns.length; index += 1) {
			const {
				      column,
				      width,
			      } = columns[index]!;

			drawText(context, createOptions<DrawTextOptions>({
				rect:           {
					x:      currentX,
					y,
					width,
					height: 1,
				},
				text:           column.title,
				fillBackground: style.headerStyle?.backgroundColor !== undefined,
			})
				.with('style', this.resolveHeaderCellStyle(column, style))
				.with('clipRect', context.clipRect)
				.done());

			currentX += width;

			if (showBorders && index < columns.length - 1) {
				drawText(context, createOptions<DrawTextOptions>({
					rect:           {
						x:      currentX,
						y,
						width:  1,
						height: 1,
					},
					text:           '│',
					fillBackground: style.backgroundColor !== undefined,
				})
					.with('style', makeColors({
						foregroundColor: style.separatorColor,
						backgroundColor: style.backgroundColor,
					}))
					.with('clipRect', context.clipRect)
					.done());

				currentX += 1;
			}
		}
	}

	private renderDataRow(context: RenderContext<UIDrawSurface>, columns: ResolvedColumn<T>[], row: T, rowIndex: number, y: number, style: Partial<TableStyle>, innerRect: {
		x: number;
		y: number;
		width: number;
		height: number
	}): void {
		let currentX              = innerRect.x;
		const showBorders         = style.showBorders ?? false;
		const alternateBackground = style.alternateRowBackgroundColor;
		const rowBackground       = alternateBackground !== undefined && rowIndex % 2 === 1 ? alternateBackground : style.rowStyle?.backgroundColor;

		for (let index = 0; index < columns.length; index += 1) {
			const {
				      column,
				      width,
			      }    = columns[index]!;
			const text = this.renderCellValue(column, row, rowIndex);

			drawText(context, createOptions<DrawTextOptions>({
				rect:           {
					x:      currentX,
					y,
					width,
					height: 1,
				},
				text,
				fillBackground: rowBackground !== undefined,
			})
				.with('style', createOptions<TextStyle>(this.resolveRowCellStyle(column, style))
					.with('backgroundColor', rowBackground)
					.done())
				.with('clipRect', context.clipRect)
				.done());

			currentX += width;

			if (showBorders && index < columns.length - 1) {
				drawText(context, createOptions<DrawTextOptions>({
					rect:           {
						x:      currentX,
						y,
						width:  1,
						height: 1,
					},
					text:           '│',
					fillBackground: rowBackground !== undefined || style.backgroundColor !== undefined,
				})
					.with('style', makeColors({
						foregroundColor: style.separatorColor,
						backgroundColor: rowBackground ?? style.backgroundColor,
					}))
					.with('clipRect', context.clipRect)
					.done());

				currentX += 1;
			}
		}
	}

	private resolveHeaderCellStyle(column: ColumnDefinition<T>, style: Partial<TableStyle>): Partial<TextStyle> {
		return createOptions<TextStyle>(style.headerStyle ?? {})
			.with('alignment', column.alignment ?? style.headerStyle?.alignment ?? 'left')
			.done();
	}

	private resolveRowCellStyle(column: ColumnDefinition<T>, style: Partial<TableStyle>): Partial<TextStyle> {
		return createOptions<TextStyle>(style.rowStyle ?? {})
			.with('alignment', column.alignment ?? style.rowStyle?.alignment ?? 'left')
			.done();
	}

	private renderCellValue(column: ColumnDefinition<T>, row: T, rowIndex: number): string {
		if (column.render) {
			return column.render(row, rowIndex);
		}

		const value = (row as Record<string, unknown>)[String(column.key)];
		return value === undefined || value === null ? '' : String(value);
	}
}