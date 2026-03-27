import type {DirtyRegion, InvalidationRequest, LayoutConstraints, RenderContext, SurfaceKind, Theme, UIComponent, UIContext, UIEvent, UIEventBus,} from "./uiTypes";
import type {UIDrawSurface} from "./surfaceAdapter";

export interface UIInvalidator {
	invalidate(request?: InvalidationRequest): void;
}

export interface UIRuntimeOptions {
	root: UIComponent;
	eventBus: UIEventBus;
	theme: Theme;
	surface: UIDrawSurface;
	surfaceKind: SurfaceKind;
}

export interface UIRenderResult {
	rendered: boolean;
	tick: number;
	dirtyRegions: ReadonlyArray<DirtyRegion>;
	fullRedraw: boolean;
}

export class UIRuntime implements UIInvalidator {
	private readonly root: UIComponent;
	private readonly eventBus: UIEventBus;
	private readonly surface: UIDrawSurface;
	private readonly surfaceKind: SurfaceKind;
	private theme: Theme;

	private tick = 0;
	private dirty = true;
	private fullRedraw = true;
	private dirtyRegions: DirtyRegion[] = [];
	private activeElement?: string;

	public constructor(options: UIRuntimeOptions) {
		this.root = options.root;
		this.eventBus = options.eventBus;
		this.theme = options.theme;
		this.surface = options.surface;
		this.surfaceKind = options.surfaceKind;
	}

	public invalidate(request: InvalidationRequest = {reason: "manual"}): void {
		this.dirty = true;

		if (!request.rect) {
			this.fullRedraw = true;
			return;
		}

		this.dirtyRegions.push(request.rect);
	}

	public dispatch(event: UIEvent): boolean {
		const didDispatch = this.dispatchToRoot(event);

		if (didDispatch) {
			this.eventBus.dispatch(event);
			this.invalidate({reason: "event"});
		}

		return didDispatch;
	}

	public render(): UIRenderResult {
		if (!this.dirty) {
			return {
				rendered: false,
				tick: this.tick,
				dirtyRegions: [],
				fullRedraw: false,
			};
		}

		this.tick += 1;

		const {width, height} = this.surface.getSize();

		const constraints: LayoutConstraints = {
			minWidth: 0,
			minHeight: 0,
			maxWidth: width,
			maxHeight: height,
		};

		const uiContext: UIContext = {
			theme: this.theme,
			surface: this.surfaceKind,
			activeElement: this.activeElement,
		};

		const renderContext: RenderContext<UIDrawSurface> = {
			surface: this.surfaceKind,
			theme: this.theme,
			tick: this.tick,
			draw: this.surface,
		};

		this.root.measure(constraints, uiContext);

		this.root.layout(
			{
				x: 1,
				y: 1,
				width,
				height,
			},
			uiContext,
		);

		// V1.1: on garde les dirty regions, mais on fait encore un full redraw.
		this.surface.clear(this.theme.palette.backgroundColor);
		this.root.render(renderContext);

		const result: UIRenderResult = {
			rendered: true,
			tick: this.tick,
			dirtyRegions: [...this.dirtyRegions],
			fullRedraw: this.fullRedraw || this.dirtyRegions.length > 0,
		};

		this.dirty = false;
		this.fullRedraw = false;
		this.dirtyRegions = [];

		return result;
	}

	public forceRender(): UIRenderResult {
		this.dirty = true;
		this.fullRedraw = true;
		return this.render();
	}

	public setTheme(theme: Theme): void {
		this.theme = theme;
		this.invalidate({reason: "theme"});
	}

	public getTheme(): Theme {
		return this.theme;
	}

	public getTick(): number {
		return this.tick;
	}

	public isDirty(): boolean {
		return this.dirty;
	}

	public getDirtyRegions(): ReadonlyArray<DirtyRegion> {
		return [...this.dirtyRegions];
	}

	public setActiveElement(elementId?: string): void {
		this.activeElement = elementId;
	}

	private dispatchToRoot(event: UIEvent): boolean {
		if ("x" in event && "y" in event) {
			if (!this.root.hitTest({x: event.x, y: event.y})) {
				return false;
			}
		}

		const uiContext: UIContext = {
			theme: this.theme,
			surface: this.surfaceKind,
			activeElement: this.activeElement,
		};

		const handled = this.root.dispatch(event, uiContext);

		if (handled && event.targetId) {
			this.activeElement = event.targetId;
		}

		return handled;
	}
}