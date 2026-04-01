import type {DirtyRegion, InvalidationRequest, LayoutConstraints, Rect, RenderContext, RuntimeSurface, SurfaceKind, Theme, UIContext, UIEvent, UIEventBus, UIInteractiveComponent, UIInvalidator, UIRenderResult} from '@modules/ui/types';
import {createOptions}                                                                                                                                                                                            from '@utils/helpers';

export interface UIRuntimeOptions<TDrawSurface extends RuntimeSurface> {
	root: UIInteractiveComponent<TDrawSurface>;
	eventBus: UIEventBus;
	theme: Theme;
	surface: TDrawSurface;
	surfaceKind: SurfaceKind;
	maxDirtyRegionsBeforeFullRedraw?: number;
	fullRedrawCoverageThreshold?: number;
}

export class UIRuntime<TDrawSurface extends RuntimeSurface> implements UIInvalidator {
	private readonly root: UIInteractiveComponent<TDrawSurface>;
	private readonly eventBus: UIEventBus;
	private readonly surface: TDrawSurface;
	private readonly surfaceKind: SurfaceKind;
	private readonly maxDirtyRegionsBeforeFullRedraw: number;
	private readonly fullRedrawCoverageThreshold: number;

	private theme: Theme;
	private tick                        = 0;
	private dirty                       = true;
	private fullRedraw                  = true;
	private dirtyRegions: DirtyRegion[] = [];
	private activeElement?: string | undefined;

	public constructor(options: UIRuntimeOptions<TDrawSurface>) {
		this.root                            = options.root;
		this.eventBus                        = options.eventBus;
		this.theme                           = options.theme;
		this.surface                         = options.surface;
		this.surfaceKind                     = options.surfaceKind;
		this.maxDirtyRegionsBeforeFullRedraw = options.maxDirtyRegionsBeforeFullRedraw ?? 8;
		this.fullRedrawCoverageThreshold     = options.fullRedrawCoverageThreshold ?? 0.6;
	}

	public invalidate(request: InvalidationRequest = {
		reason: 'manual',
		kind:   'full',
	}): void {
		this.dirty = true;

		const kind = request.kind ?? (request.rect ? 'region' : 'full');

		if (kind === 'full' || !request.rect) {
			this.fullRedraw = true;
			this.dirtyRegions = [];
			return;
		}

		this.dirtyRegions.push(this.clampRegionToSurface(request.rect));
	}

	public dispatch(event: UIEvent): boolean {
		const request = this.dispatchToRoot(event);

		if (!request) {
			return false;
		}

		this.eventBus.dispatch(event);
		this.invalidate(request);

		return true;
	}

	public render(): UIRenderResult {
		if (!this.dirty) {
			return {
				rendered:     false,
				tick:         this.tick,
				fullRedraw:   false,
				dirtyRegions: [],
			};
		}

		this.tick += 1;

		const uiContext   = this.createUIContext();
		const constraints = this.createRootConstraints();
		const rootRect    = this.createRootRect();

		this.root.measure(constraints, uiContext);
		this.root.layout(rootRect, uiContext);

		const dirtyRegions      = this.normalizeDirtyRegions(this.dirtyRegions);
		const fullRedraw        = this.shouldFullRedraw(dirtyRegions);
		const baseRenderContext = this.createRenderContext();

		if (fullRedraw) {
			this.clearSurface();
			this.root.render(baseRenderContext);
		}
		else {
			this.renderDirtyRegions(baseRenderContext, dirtyRegions);
		}

		const result: UIRenderResult = {
			rendered: true,
			tick:     this.tick,
			fullRedraw,
			dirtyRegions,
		};

		this.dirty        = false;
		this.fullRedraw   = false;
		this.dirtyRegions = [];

		return result;
	}

	public forceRender(): UIRenderResult {
		this.dirty      = true;
		this.fullRedraw = true;
		return this.render();
	}

	public setTheme(theme: Theme): void {
		this.theme = theme;
		this.invalidate({
			reason: 'theme',
			kind:   'full',
		});
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

	public isFullRedrawPending(): boolean {
		return this.fullRedraw;
	}

	public getDirtyRegions(): ReadonlyArray<DirtyRegion> {
		return [...this.dirtyRegions];
	}

	public getActiveElement(): string | undefined {
		return this.activeElement;
	}

	public setActiveElement(elementId?: string): void {
		this.activeElement = elementId;
	}

	private createUIContext(): UIContext {
		return createOptions<UIContext>({
			theme:   this.theme,
			surface: this.surfaceKind,
		})
			.with('activeElement', this.activeElement)
			.done();
	}

	private createRenderContext(): RenderContext<TDrawSurface> {
		return {
			theme:   this.theme,
			surface: this.surfaceKind,
			tick:    this.tick,
			draw:    this.surface,
		};
	}

	private createRootConstraints(): LayoutConstraints {
		const {
			      width,
			      height,
		      } = this.surface.getSize();

		return {
			minWidth:  0,
			minHeight: 0,
			maxWidth:  width,
			maxHeight: height,
		};
	}

	private createRootRect(): Rect {
		const {
			      width,
			      height,
		      } = this.surface.getSize();

		return {
			x: 1,
			y: 1,
			width,
			height,
		};
	}

	private clearSurface(): void {
		if (typeof this.surface.clear === 'function') {
			this.surface.clear(this.theme.palette.backgroundColor);
		}
	}

	private renderDirtyRegions(baseContext: RenderContext<TDrawSurface>, regions: ReadonlyArray<DirtyRegion>): void {
		for (const region of regions) {
			this.root.render({
				...baseContext,
				clipRect: region,
			});
		}
	}

	private shouldFullRedraw(regions: ReadonlyArray<DirtyRegion>): boolean {
		if (this.fullRedraw) {
			return true;
		}

		if (regions.length === 0) {
			return true;
		}

		if (regions.length >= this.maxDirtyRegionsBeforeFullRedraw) {
			return true;
		}

		const {
			      width,
			      height,
		      }                = this.surface.getSize();
		const totalSurfaceArea = width * height;
		const dirtyArea        = this.computeRegionsArea(regions);

		if (totalSurfaceArea <= 0) {
			return true;
		}

		return dirtyArea / totalSurfaceArea >= this.fullRedrawCoverageThreshold;
	}

	private computeRegionsArea(regions: ReadonlyArray<DirtyRegion>): number {
		let total = 0;

		for (const region of regions) {
			total += Math.max(0, region.width) * Math.max(0, region.height);
		}

		return total;
	}

	private normalizeDirtyRegions(regions: ReadonlyArray<DirtyRegion>): DirtyRegion[] {
		if (regions.length === 0) {
			return [];
		}

		const clamped = regions
			.map((region) => this.clampRegionToSurface(region))
			.filter((region) => region.width > 0 && region.height > 0);

		if (clamped.length <= 1) {
			return clamped;
		}

		const merged: DirtyRegion[] = [];

		for (const region of clamped) {
			this.mergeRegionIntoList(merged, region);
		}

		return merged;
	}

	private mergeRegionIntoList(regions: DirtyRegion[], nextRegion: DirtyRegion): void {
		let current   = nextRegion;
		let mergedAny = false;

		for (let index = 0; index < regions.length; index++) {
			const existing = regions[index];

			if (existing) {
				if (!this.regionsOverlapOrTouch(existing, current)) {
					continue;
				}

				current = this.mergeRegions(existing, current);
				regions.splice(index, 1);
				index -= 1;
				mergedAny = true;
			}
		}

		regions.push(current);

		if (mergedAny) {
			const normalized = this.normalizeDirtyRegions(regions);
			regions.length   = 0;
			regions.push(...normalized);
		}
	}

	private regionsOverlapOrTouch(a: DirtyRegion, b: DirtyRegion): boolean {
		const aRight  = a.x + a.width - 1;
		const aBottom = a.y + a.height - 1;
		const bRight  = b.x + b.width - 1;
		const bBottom = b.y + b.height - 1;

		return !(aRight + 1 < b.x || bRight + 1 < a.x || aBottom + 1 < b.y || bBottom + 1 < a.y);
	}

	private mergeRegions(a: DirtyRegion, b: DirtyRegion): DirtyRegion {
		const left   = Math.min(a.x, b.x);
		const top    = Math.min(a.y, b.y);
		const right  = Math.max(a.x + a.width - 1, b.x + b.width - 1);
		const bottom = Math.max(a.y + a.height - 1, b.y + b.height - 1);

		return {
			x:      left,
			y:      top,
			width:  right - left + 1,
			height: bottom - top + 1,
		};
	}

	private clampRegionToSurface(region: DirtyRegion): DirtyRegion {
		const {
			      width:  surfaceWidth,
			      height: surfaceHeight,
		      } = this.surface.getSize();

		const left   = Math.max(1, region.x);
		const top    = Math.max(1, region.y);
		const right  = Math.min(surfaceWidth, region.x + region.width - 1);
		const bottom = Math.min(surfaceHeight, region.y + region.height - 1);

		return {
			x:      left,
			y:      top,
			width:  Math.max(0, right - left + 1),
			height: Math.max(0, bottom - top + 1),
		};
	}

	private dispatchToRoot(event: UIEvent): InvalidationRequest | null {
		if ('x' in event && 'y' in event) {
			if (!this.root.hitTest({ x: event.x, y: event.y })) {
				return null;
			}
		}

		const request = this.root.dispatch(event, this.createUIContext());

		if (request && event.targetId) {
			this.activeElement = event.targetId;
		}

		return request;
	}
}
