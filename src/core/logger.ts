export type LogLevel = 'debug' | 'info' | 'warn' | 'error';

const LOG_LEVEL_ORDER: Record<LogLevel, number> = {debug: 0, info: 1, warn: 2, error: 3};

function getLevelColor(level: LogLevel): number {
	switch (level) {
		case "debug":
			return colors.lightBlue;
		case "info":
			return colors.white;
		case "warn":
			return colors.orange;
		case "error":
			return colors.red;
	}
}

function pad(value: number): string {
	return value < 10 ? `0${value}` : `${value}`;
}

function getTimestamp(): string {
	const now = os.date("*t");

	const year = now.year;
	const month = pad(now.month);
	const day = pad(now.day);
	const hour = pad(now.hour);
	const minute = pad(now.min);
	const second = pad(now.sec);

	return `${year}-${month}-${day} ${hour}:${minute}:${second}`;
}

function formatMeta(meta?: Record<string, unknown>): string {
	if (!meta) return '';

	const parts: string[] = [];

	for (const key in meta) {
		const value = meta[key];

		if (value === undefined) continue;

		parts.push(`${key}=${String(value)}`);
	}

	return parts.join(' ');
}

export class Logger {
	public constructor(
		private readonly scope = 'EmberCore',
		private level: LogLevel = 'info',
		private readonly useColors = true,
	) {
	}

	public setLevel(level: LogLevel): void {
		this.level = level;
	}

	public debug(message: string, meta?: Record<string, unknown>): void {
		this.log('debug', message, meta);
	}

	public info(message: string, meta?: Record<string, unknown>): void {
		this.log('info', message, meta);
	}

	public warn(message: string, meta?: Record<string, unknown>): void {
		this.log('warn', message, meta);
	}

	public error(message: string, meta?: Record<string, unknown>): void {
		this.log('error', message, meta);
	}


	private log(level: LogLevel, message: string, meta?: Record<string, unknown>): void {
		if (LOG_LEVEL_ORDER[level] < LOG_LEVEL_ORDER[this.level]) return;

		const timestamp = getTimestamp();
		const levelStr = level.toUpperCase();
		const metaStr = formatMeta(meta);

		let line = `${timestamp} | ${levelStr} | ${this.scope} |`;

		if (metaStr.length > 0) line += ` ${metaStr}`;

		if (message.length > 0) line += ` msg="${message}"`;

		this.writeLine(level, line);
	}

	private writeLine(level: LogLevel, line: string): void {
		if (!this.useColors) {
			print(line);
			return;
		}

		const previousColor = term.getTextColor();
		term.setTextColor(getLevelColor(level));
		print(line);
		term.setTextColor(previousColor);
	}
}