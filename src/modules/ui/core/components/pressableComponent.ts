import {FocusableComponent} from '@modules/ui/core/components/focusableComponent';
import type {BaseProps, ComponentDependencies, ComponentKind, InvalidationRequest, LayoutConstraints, MeasuredSize, RenderContext, UIContext, UIEvent, UIPressableComponent} from '@modules/ui/types';

export abstract class PressableComponent<
	TKind extends ComponentKind,
	TProps extends BaseProps = BaseProps,
	TDraw = unknown,
	TStyle extends object = never,
> extends FocusableComponent<TKind, TProps, TDraw, TStyle> implements UIPressableComponent<TDraw> {
	protected constructor(kind: TKind, props: TProps, dependencies: ComponentDependencies = {}) {
		super(kind, props, dependencies);
	}

	/** Duration of the highlight shown when the component is clicked. */
	public static readonly FLASH_SECONDS = 0.2;

	/** True during the short highlight after a click. */
	protected flashing = false;

	public press(context: UIContext): boolean {
		return this.onPress(context);
	}

	protected override handleEvent(event: UIEvent, context: UIContext): InvalidationRequest | null {
		switch (event.type) {
			case 'mouse_click':
			case 'monitor_touch': {
				this.focus();

				const changed = this.press(context);
				const flashed = this.flash();

				if (!changed && !flashed) return null;

				return this.createStateInvalidation();
			}

			default:
				return null;
		}
	}

	/** Starts the click highlight; ends it with the runtime scheduler (no effect without one). */
	protected flash(): boolean {
		const invalidator = this.invalidator;

		if (!invalidator?.schedule) return false;

		this.flashing = true;
		invalidator.schedule(PressableComponent.FLASH_SECONDS, () => {
			this.flashing = false;
			this.invalidate(this.createStateInvalidation());
		});

		return true;
	}

	protected onPress(_context: UIContext): boolean {
		return false;
	}

	protected abstract override getResolvedStyle(context: UIContext | RenderContext<TDraw>): Partial<TStyle>;

	public abstract override measure(constraints: LayoutConstraints, context: UIContext): MeasuredSize;

	public abstract override render(context: RenderContext<TDraw>): void;
}