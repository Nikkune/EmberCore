import type {Color, Rect} from './core';
import type {Theme}       from './theme';

// ============================================================
// Render / invalidation / runtime
// ============================================================

export type SurfaceKind = 'terminal' | 'monitor';
export type InvalidationReason = 'mount' | 'layout' | 'state' | 'theme' | 'event' | 'manual';
export type InvalidationKind = 'full' | 'region';

export interface DirtyRegion extends Rect {}

export interface InvalidationRequest {
	reason: InvalidationReason;
	kind?: InvalidationKind;
	rect?: DirtyRegion;
}
export interface RenderContext<TDraw = unknown> {
	surface: SurfaceKind;
	theme: Theme;
	tick: number;
	draw: TDraw;
	clipRect?: Rect;
}

export interface UIContext {
	theme: Theme;
	surface: SurfaceKind;
	activeElement?: string;
}

export interface UIInvalidator {
	invalidate(request?: InvalidationRequest): void;
}

export interface UIRenderResult {
	rendered: boolean;
	tick: number;
	fullRedraw: boolean;
	dirtyRegions: ReadonlyArray<DirtyRegion>;
}

export interface RuntimeSurface {
	getSize(): {
		width: number;
		height: number;
	};

	clear?(backgroundColor?: Color): void;
}