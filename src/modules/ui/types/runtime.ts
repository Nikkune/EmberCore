import type {Rect} from './core';
import type {Theme} from './theme';

// ============================================================
// Render / invalidation / runtime
// ============================================================

export type SurfaceKind = 'terminal' | 'monitor';
export type InvalidationReason = 'mount' | 'layout' | 'state' | 'theme' | 'event' | 'manual';

export interface RenderContext<TDraw = unknown> {
	surface: SurfaceKind;
	theme: Theme;
	tick: number;
	draw: TDraw;
}

export interface DirtyRegion extends Rect {
}

export interface InvalidationRequest {
	reason: InvalidationReason;
	rect?: DirtyRegion;
}

export interface UIContext {
	theme: Theme;
	surface: SurfaceKind;
	activeElement?: string;
}

export interface UIInvalidator {
	invalidate(request?: InvalidationRequest): void;
}