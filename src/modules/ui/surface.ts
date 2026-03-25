import {Color, ColorPair, Point, Rect, Size} from "./types";
import {Peripheral, PeripheralName} from "../../core/peripheral";

export interface ISurface {
	getSize(): Size;

	getWidth(): number;

	getHeight(): number;

	setScale(scale: number): void;

	clear(): void;

	clearLine(y?: number): void;

	setCursor(pos: Point): void;

	getCursor(): Point;

	write(text: string): void;

	writeAt(pos: Point, text: string): void;

	drawTextLine(y: number, text: string): void;

	fillLine(y: number, char?: string): void;

	fillRect(rect: Rect, char?: string): void;

	outlineRect(rect: Rect, char?: string): void;

	setColor(color: Color): void;

	setBackgroundColor(color: Color): void;

	getColor(): Color;

	getBackgroundColor(): Color;

	withColors(options: Partial<ColorPair>, fn: () => void): void;

	isColorSupported(): boolean;

	blit(text: string, textColor: string, backgroundColor: string): void;
}

export class Surface implements ISurface {
	private readonly term: Redirect;

	constructor(term: Redirect) {
		this.term = term;
	}

	public static fromTerminal(): Surface {
		return new Surface(term.current());
	}

	public static fromMonitor(name: PeripheralName): Surface {
		const monitor = Peripheral.require<Redirect>(name);
		return new Surface(monitor);
	}

	public getSize(): Size {
		const [width, height] = this.term.getSize();
		return {width, height};
	}

	public getWidth(): number {
		return this.getSize().width;
	}

	public getHeight(): number {
		return this.getSize().height;
	}

	public setScale(scale: number) {
		const target = this.term as Redirect & { setTextScale?: (scale: number) => void };
		target.setTextScale?.(scale);
	}

	public clear(): void {
		this.term.clear();
		this.term.setCursorPos(1, 1);
	}

	public clearLine(y?: number) {
		if (y !== undefined && y >= 1) {
			this.term.setCursorPos(1, y);
		}
		this.term.clearLine();
	}

	public setCursor(pos: Point) {
		this.term.setCursorPos(pos.x, pos.y);
	}

	public getCursor(): Point {
		const [x, y] = this.term.getCursorPos();
		return {x, y};
	}

	public write(text: string): void {
		this.term.write(text);
	}

	public writeAt(pos: Point, text: string): void {
		this.term.setCursorPos(pos.x, pos.y);
		this.term.write(text);
	}

	public drawTextLine(y: number, text: string) {
		this.term.setCursorPos(1, y);
		this.term.write(text);
	}

	public fillLine(y: number, char = " ") {
		if (y >= 1) {
			this.term.setCursorPos(1, y);
			this.term.write(char.repeat(this.getWidth()));
		}
	}

	public fillRect(rect: Rect, char = " ") {
		const {x, y, width, height} = rect;
		const bottom = y + height - 1;
		for (let i = y; i <= bottom; i++) {
			this.term.setCursorPos(x, i);
			this.term.write(char.repeat(width));
		}
	}

	public outlineRect(rect: Rect, char = " ") {
		const {x, y, width, height} = rect;
		const bottom = y + height - 1;
		const right = x + width - 1;
		this.term.setCursorPos(x, y);
		this.term.write(char.repeat(width));
		this.term.setCursorPos(x, bottom);
		this.term.write(char.repeat(width));
		for (let i = y; i <= bottom; i++) {
			this.writeAt({x, y: i}, char);
			this.writeAt({x: right, y: i}, char);
		}
	}

	public setColor(color: Color): void {
		this.term.setTextColor(color);
	}

	public setBackgroundColor(color: Color): void {
		this.term.setBackgroundColor(color);
	}

	public getColor(): Color {
		return this.term.getTextColor()
	}

	public getBackgroundColor(): Color {
		return this.term.getBackgroundColor()
	}

	public withColors(options: Partial<ColorPair>, fn: () => void) {
		const oldColor = this.getColor();
		const oldBackgroundColor = this.getBackgroundColor();

		this.term.setTextColor(options.foreground ?? oldColor);
		this.term.setBackgroundColor(options.background ?? oldBackgroundColor);

		try {
			fn();
		} finally {
			this.term.setTextColor(oldColor);
			this.term.setBackgroundColor(oldBackgroundColor);
		}
	}

	public isColorSupported(): boolean {
		return this.term.isColor()
	}

	public blit(text: string, textColor: string, backgroundColor: string) {
		const target = this.term as Redirect & { blit: (text: string, textColor: string, backgroundColor: string) => void };
		target.blit(text, textColor, backgroundColor);
	}
}