import {Color, Point, Rect, Size} from "../types/uiTypes";

export interface UISurfaceAdapter {
	getSize(): { width: number; height: number };

	clear(backgroundColor?: number): void;
}

export interface TerminalLike {
	getSize(): [number, number];

	clear(): void;

	clearLine(): void;

	setCursorPos(x: number, y: number): void;

	getCursorPos(): [number, number];

	write(text: string): void;

	setTextColor(color: number): void;

	getTextColor(): number;

	setBackgroundColor(color: number): void;

	getBackgroundColor(): number;

	isColor(): boolean;
}

interface StringBlitTerminalLike extends TerminalLike {
	blit(text: string, textColors: string, backgroundColors: string): void;
}

export interface UIDrawSurface extends UISurfaceAdapter {
	getWidth(): number;

	getHeight(): number;

	setCursor(position: Point): void;

	getCursor(): Point;

	write(text: string): void;

	writeAt(position: Point, text: string): void;

	blitAt(position: Point, text: string, textColors: string, backgroundColors: string): void;

	clearLine(y: number, backgroundColor?: Color): void;

	fillRect(rect: Rect, character?: string, backgroundColor?: number, foregroundColor?: number): void;

	strokeRect(rect: Rect, character?: string, backgroundColor?: number, foregroundColor?: number): void;

	setForegroundColor(color: number): void;

	getForegroundColor(): number;

	setBackgroundColor(color: number): void;

	getBackgroundColor(): number;

	withColors(
		options: {
			foreground?: number;
			background?: number;
		},
		fn: () => void,
	): void;

	isColorSupported(): boolean;
}

function repeat(value: string, count: number): string {
	let result = "";

	for (let index = 0; index < count; index += 1) {
		result += value;
	}

	return result;
}

export class ComputerCraftSurfaceAdapter implements UIDrawSurface {
	private readonly target: TerminalLike;

	public constructor(target: TerminalLike) {
		this.target = target;
	}

	public static fromTerminal(target?: TerminalLike): ComputerCraftSurfaceAdapter {
		return new ComputerCraftSurfaceAdapter(target ?? (term.current() as TerminalLike));
	}

	public static fromMonitor(target: TerminalLike): ComputerCraftSurfaceAdapter {
		return new ComputerCraftSurfaceAdapter(target);
	}

	public getSize(): Size {
		const [width, height] = this.target.getSize();

		return {
			width,
			height,
		};
	}

	public getWidth(): number {
		return this.getSize().width;
	}

	public getHeight(): number {
		return this.getSize().height;
	}

	public clear(backgroundColor?: number): void {
		if (backgroundColor === undefined) {
			this.target.clear();
			return;
		}

		this.withColors({background: backgroundColor}, () => {
			this.target.clear();
		});
	}

	public clearLine(y: number, backgroundColor?: number): void {
		if (y < 1 || y > this.getHeight()) {
			return;
		}

		const currentCursor = this.getCursor();

		this.withColors(
			{background: backgroundColor},
			() => {
				this.target.setCursorPos(1, y);
				this.target.clearLine();
			},
		);

		this.setCursor(currentCursor);
	}

	public setCursor(position: Point): void {
		this.target.setCursorPos(position.x, position.y);
	}

	public getCursor(): Point {
		const [x, y] = this.target.getCursorPos();

		return {x, y};
	}

	public write(text: string): void {
		this.target.write(text);
	}

	public writeAt(position: Point, text: string): void {
		this.withCursor(position, () => {
			this.target.write(text);
		});
	}

	public blitAt(
		position: Point,
		text: string,
		textColors: string,
		backgroundColors: string,
	): void {
		const target = this.target as Partial<StringBlitTerminalLike>;

		this.withCursor(position, () => {
			if (typeof target.blit === "function") {
				target.blit(text, textColors, backgroundColors);
				return;
			}

			this.target.write(text);
		});
	}

	public fillRect(
		rect: Rect,
		character = " ",
		backgroundColor?: number,
		foregroundColor?: number,
	): void {
		if (rect.width <= 0 || rect.height <= 0) {
			return;
		}

		const fillCharacter = character.length > 0 ? character[0] : " ";
		const line = repeat(fillCharacter, rect.width);

		this.withColors(
			{
				background: backgroundColor,
				foreground: foregroundColor,
			},
			() => {
				for (let row = 0; row < rect.height; row += 1) {
					this.writeAt(
						{x: rect.x, y: rect.y + row},
						line,
					);
				}
			},
		);
	}

	public strokeRect(
		rect: Rect,
		character = "#",
		backgroundColor?: number,
		foregroundColor?: number,
	): void {
		if (rect.width <= 0 || rect.height <= 0) {
			return;
		}

		if (rect.width === 1 && rect.height === 1) {
			this.withColors(
				{
					background: backgroundColor,
					foreground: foregroundColor,
				},
				() => {
					this.writeAt({x: rect.x, y: rect.y}, character[0] ?? "#");
				},
			);

			return;
		}

		const strokeCharacter = character.length > 0 ? character[0] : "#";

		this.withColors(
			{
				background: backgroundColor,
				foreground: foregroundColor,
			},
			() => {
				const horizontal = repeat(strokeCharacter, rect.width);

				this.writeAt({x: rect.x, y: rect.y}, horizontal);

				if (rect.height > 1) {
					this.writeAt(
						{x: rect.x, y: rect.y + rect.height - 1},
						horizontal,
					);
				}

				for (let row = 1; row < rect.height - 1; row += 1) {
					this.writeAt(
						{x: rect.x, y: rect.y + row},
						strokeCharacter,
					);

					if (rect.width > 1) {
						this.writeAt(
							{x: rect.x + rect.width - 1, y: rect.y + row},
							strokeCharacter,
						);
					}
				}
			},
		);
	}

	public setForegroundColor(color: number): void {
		this.target.setTextColor(color);
	}

	public getForegroundColor(): number {
		return this.target.getTextColor();
	}

	public setBackgroundColor(color: number): void {
		this.target.setBackgroundColor(color);
	}

	public getBackgroundColor(): number {
		return this.target.getBackgroundColor();
	}

	public withColors(
		options: {
			foreground?: number;
			background?: number;
		},
		fn: () => void,
	): void {
		const previousForeground = this.getForegroundColor();
		const previousBackground = this.getBackgroundColor();

		if (options.foreground !== undefined) {
			this.setForegroundColor(options.foreground);
		}

		if (options.background !== undefined) {
			this.setBackgroundColor(options.background);
		}

		try {
			fn();
		} finally {
			this.setForegroundColor(previousForeground);
			this.setBackgroundColor(previousBackground);
		}
	}

	public isColorSupported(): boolean {
		return this.target.isColor();
	}

	private withCursor(position: Point, fn: () => void): void {
		const previousCursor = this.getCursor();

		try {
			this.setCursor(position);
			fn();
		} finally {
			this.setCursor(previousCursor);
		}
	}
}