import {BaseContainerComponent, drawBox, type DrawBoxOptions, getInnerRect, normalizeInsets, type UIDrawSurface}                                                                           from '@modules/ui';
import type {ComponentDependencies, CrossAxisAlignment, LayoutConstraints, MainAxisAlignment, MeasuredSize, Rect, RenderContext, StackProps, StackStyle, UIComponent, UIContext, WrapMode} from '@modules/ui/types';
import {createOptions}                                                                                                                                                                     from '@utils/helpers';

interface MeasuredChild<TChild extends UIComponent<UIDrawSurface>> {
	child: TChild;
	size: MeasuredSize;
	index: number;
}

interface StackLine<TChild extends UIComponent<UIDrawSurface>> {
	items: MeasuredChild<TChild>[];
	mainSize: number;
	crossSize: number;
}

interface StackPlacement<TChild extends UIComponent<UIDrawSurface>> {
	child: TChild;
	rect: Rect;
}

export class StackComponent<TChild extends UIComponent<UIDrawSurface> = UIComponent<UIDrawSurface>> extends BaseContainerComponent<'stack', StackProps, UIDrawSurface, StackStyle, TChild> {
	public constructor(props: StackProps, dependencies: ComponentDependencies = {}, children: TChild[] = []) {
		super('stack', props, dependencies, children);
	}

	public override measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize {
		const style            = this.getResolvedStyle(context);
		const innerConstraints = this.getInnerConstraints(constraints, style);

		const direction = this.props.direction ?? 'column';
		const spacing   = this.props.spacing ?? 0;
		const wrap      = this.props.wrap ?? 'nowrap';

		const children = this.children.map((child, index) => ({
			child,
			index,
			size: child.measure(innerConstraints, context),
		}));

		const lines = this.createLines(children, direction, wrap, spacing, direction === 'row' ? innerConstraints.maxWidth : innerConstraints.maxHeight);

		const contentMain  = lines.reduce((max, line) => Math.max(max, line.mainSize), 0);
		const contentCross = lines.reduce((sum, line) => sum + line.crossSize, 0) + Math.max(0, lines.length - 1) * spacing;

		const contentWidth  = direction === 'row' ? contentMain : contentCross;
		const contentHeight = direction === 'row' ? contentCross : contentMain;

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

	protected override getResolvedStyle(context: UIContext | RenderContext<UIDrawSurface>): Partial<StackStyle> {
		return this.getStyle(context, (themeStyle) => createOptions<StackStyle>(themeStyle)
			.with('foregroundColor', this.props.foregroundColor ?? themeStyle.foregroundColor ?? context.theme.palette.text)
			.with('backgroundColor', this.props.backgroundColor ?? themeStyle.backgroundColor ?? context.theme.palette.surface)
			.with('padding', themeStyle.padding ?? 0)
			.done());
	}

	private getInnerConstraints(constraints: LayoutConstraints, style: Partial<StackStyle>): LayoutConstraints {
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

	private createPlacements(innerRect: Rect, context: UIContext): StackPlacement<TChild>[] {
		const children  = [...this.children];
		const direction = this.props.direction ?? 'column';
		const spacing   = this.props.spacing ?? 0;
		const alignment = this.props.alignment ?? 'start';
		const justify   = this.props.justify ?? 'start';
		const wrap      = this.props.wrap ?? 'nowrap';

		if (children.length === 0 || innerRect.width <= 0 || innerRect.height <= 0) {
			return [];
		}

		const measured: MeasuredChild<TChild>[] = children.map((child, index) => {
			const size = child.measure({
				minWidth:  0,
				maxWidth:  innerRect.width,
				minHeight: 0,
				maxHeight: innerRect.height,
			}, context);

			return {
				child,
				index,
				size,
			};
		});

		const availableMain  = direction === 'row' ? innerRect.width : innerRect.height;
		const availableCross = direction === 'row' ? innerRect.height : innerRect.width;

		const lines = this.createLines(measured, direction, wrap, spacing, availableMain);

		const totalCross = lines.reduce((sum, line) => sum + line.crossSize, 0) + Math.max(0, lines.length - 1) * spacing;

		const remainingCross = Math.max(0, availableCross - totalCross);
		const crossJustify   = this.resolveCrossJustify(remainingCross, spacing, lines.length, justify);

		const placements: StackPlacement<TChild>[] = [];
		let currentCross                           = crossJustify.startOffset;

		for (const line of lines) {
			const remainingMain = Math.max(0, availableMain - line.mainSize);
			const mainJustify   = this.resolveMainJustify(remainingMain, spacing, line.items.length, justify);

			let currentMain = mainJustify.startOffset;

			for (const item of line.items) {
				const itemMain  = direction === 'row' ? item.size.width : item.size.height;
				const itemCross = direction === 'row' ? item.size.height : item.size.width;

				const crossOffset    = this.resolveCrossOffset(alignment, line.crossSize, itemCross);
				const stretchedCross = alignment === 'stretch' ? line.crossSize : itemCross;

				const rect = direction === 'row' ? {
					x:      innerRect.x + currentMain,
					y:      innerRect.y + currentCross + crossOffset,
					width:  itemMain,
					height: stretchedCross,
				} : {
					x:      innerRect.x + currentCross + crossOffset,
					y:      innerRect.y + currentMain,
					width:  stretchedCross,
					height: itemMain,
				};

				placements.push({
					child: item.child,
					rect,
				});

				currentMain += itemMain + mainJustify.betweenSpacing;
			}

			currentCross += line.crossSize + crossJustify.betweenSpacing;
		}

		return placements;
	}

	private createLines(children: MeasuredChild<TChild>[], direction: 'row' | 'column', wrap: WrapMode, spacing: number, availableMain: number): StackLine<TChild>[] {
		if (children.length === 0) {
			return [];
		}

		if (wrap === 'nowrap') {
			return [this.createLine(children, direction, spacing)];
		}

		const lines: StackLine<TChild>[]     = [];
		let current: MeasuredChild<TChild>[] = [];
		let currentMain                      = 0;

		for (const item of children) {
			const itemMain = direction === 'row' ? item.size.width : item.size.height;
			const nextMain = current.length === 0 ? itemMain : currentMain + spacing + itemMain;

			if (current.length > 0 && nextMain > availableMain) {
				lines.push(this.createLine(current, direction, spacing));
				current     = [item];
				currentMain = itemMain;
				continue;
			}

			current.push(item);
			currentMain = nextMain;
		}

		if (current.length > 0) {
			lines.push(this.createLine(current, direction, spacing));
		}

		return lines;
	}

	private createLine(items: MeasuredChild<TChild>[], direction: 'row' | 'column', spacing: number): StackLine<TChild> {
		const mainSize = items.reduce((sum, item) => {
			const size = direction === 'row' ? item.size.width : item.size.height;
			return sum + size;
		}, 0) + Math.max(0, items.length - 1) * spacing;

		const crossSize = items.reduce((max, item) => {
			const size = direction === 'row' ? item.size.height : item.size.width;
			return Math.max(max, size);
		}, 0);

		return {
			items,
			mainSize,
			crossSize,
		};
	}

	private resolveMainJustify(remainingMain: number, spacing: number, childCount: number, justify: MainAxisAlignment): {
		startOffset: number;
		betweenSpacing: number;
	} {
		if (childCount <= 0) {
			return {
				startOffset:    0,
				betweenSpacing: spacing,
			};
		}

		switch (justify) {
			case 'center':
				return {
					startOffset:    Math.floor(remainingMain / 2),
					betweenSpacing: spacing,
				};

			case 'end':
				return {
					startOffset:    remainingMain,
					betweenSpacing: spacing,
				};

			case 'space-between':
				return {
					startOffset:    0,
					betweenSpacing: childCount > 1 ? spacing + Math.floor(remainingMain / (childCount - 1)) : spacing,
				};

			case 'space-around': {
				const gap = childCount > 0 ? Math.floor(remainingMain / childCount) : 0;
				return {
					startOffset:    Math.floor(gap / 2),
					betweenSpacing: spacing + gap,
				};
			}

			case 'space-evenly': {
				const gap = Math.floor(remainingMain / (childCount + 1));
				return {
					startOffset:    gap,
					betweenSpacing: spacing + gap,
				};
			}

			case 'start':
			default:
				return {
					startOffset:    0,
					betweenSpacing: spacing,
				};
		}
	}

	private resolveCrossJustify(remainingCross: number, spacing: number, lineCount: number, justify: MainAxisAlignment): {
		startOffset: number;
		betweenSpacing: number;
	} {
		if (lineCount <= 0) {
			return {
				startOffset:    0,
				betweenSpacing: spacing,
			};
		}

		if (justify === 'space-between' && lineCount > 1) {
			return {
				startOffset:    0,
				betweenSpacing: spacing + Math.floor(remainingCross / (lineCount - 1)),
			};
		}

		if (justify === 'space-around') {
			const gap = Math.floor(remainingCross / lineCount);
			return {
				startOffset:    Math.floor(gap / 2),
				betweenSpacing: spacing + gap,
			};
		}

		if (justify === 'space-evenly') {
			const gap = Math.floor(remainingCross / (lineCount + 1));
			return {
				startOffset:    gap,
				betweenSpacing: spacing + gap,
			};
		}

		if (justify === 'center') {
			return {
				startOffset:    Math.floor(remainingCross / 2),
				betweenSpacing: spacing,
			};
		}

		if (justify === 'end') {
			return {
				startOffset:    remainingCross,
				betweenSpacing: spacing,
			};
		}

		return {
			startOffset:    0,
			betweenSpacing: spacing,
		};
	}

	private resolveCrossOffset(alignment: CrossAxisAlignment, availableCross: number, childCross: number): number {
		const remaining = Math.max(0, availableCross - childCross);

		switch (alignment) {
			case 'center':
				return Math.floor(remaining / 2);

			case 'end':
				return remaining;

			case 'stretch':
			case 'start':
			default:
				return 0;
		}
	}
}