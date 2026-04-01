import {InteractiveComponent}                                                                                                                  from '@modules/ui';
import type {BaseProps, ComponentDependencies, ComponentKind, LayoutConstraints, MeasuredSize, RenderContext, UIContext, UIFocusableComponent} from '@modules/ui/types';

export abstract class FocusableComponent<TKind extends ComponentKind, TProps extends BaseProps = BaseProps, TDraw = unknown, TStyle extends object = never> extends InteractiveComponent<TKind, TProps, TDraw, TStyle> implements UIFocusableComponent<TDraw> {
	protected _focused = false;

	protected constructor(kind: TKind, props: TProps, dependencies: ComponentDependencies = {}) {
		super(kind, props, dependencies);
	}

	public get focused(): boolean {
		return this._focused;
	}

	public focus(): void {
		if (this._focused) {
			return;
		}

		this._focused = true;
		this.invalidate({
			reason: 'state',
			kind:   'region',
			rect:   this.rect,
		});
	}

	public blur(): void {
		if (!this._focused) {
			return;
		}

		this._focused = false;
		this.invalidate({
			reason: 'state',
			kind:   'region',
			rect:   this.rect,
		});
	}

	protected abstract override getResolvedStyle(context: UIContext | RenderContext<TDraw>): Partial<TStyle>;

	public abstract override measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize;

	public abstract override render(context: RenderContext<TDraw>): void;
}