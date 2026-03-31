import {FocusableComponent}                                                                                                                                                  from '@modules/ui';
import type {BaseProps, ComponentDependencies, ComponentKind, InvalidationRequest, LayoutConstraints, MeasuredSize, RenderContext, UIContext, UIEvent, UIPressableComponent} from '@modules/ui/types';

export abstract class PressableComponent<TKind extends ComponentKind, TProps extends BaseProps = BaseProps, TDraw = unknown> extends FocusableComponent<TKind, TProps, TDraw> implements UIPressableComponent<TDraw> {
	protected constructor(kind: TKind, props: TProps, dependencies: ComponentDependencies = {}) {
		super(kind, props, dependencies);
	}

	public press(context: UIContext): boolean {
		return this.onPress(context);
	}

	protected override handleEvent(event: UIEvent, context: UIContext): InvalidationRequest | null {
		switch (event.type) {
			case 'mouse_click':
			case 'monitor_touch': {
				this.focus();

				const changed = this.press(context);

				if (!changed) return null;

				return this.createStateInvalidation();
			}

			default:
				return null;
		}
	}

	protected onPress(_context: UIContext): boolean {
		return false;
	}

	public abstract override measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize;

	public abstract override render(context: RenderContext<TDraw>): void;
}