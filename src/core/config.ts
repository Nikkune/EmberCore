import {ConfigError} from './errors';
import {Logger}      from './logger';

const log = new Logger('Config', 'info');

export class Config {
	/**
	 * Loads a config file (textutils.serialise format) merged with its defaults:
	 * - nested tables are merged key by key, so new default keys appear in old files;
	 * - a value of the wrong type keeps the default (with a warning);
	 * - keys that are not in the defaults are dropped.
	 * A missing file is created with the defaults; an interrupted save is recovered.
	 */
	public static load<T extends object>(path: string, defaults: T): T {
		this.recoverInterruptedSave(path);

		if (!fs.exists(path)) {
			log.warn('Config file not found, creating default', {
				path,
				action: 'create_config',
			});

			this.save(path, defaults);
			return defaults;
		}

		const file = fs.open(path, 'r') as ReadHandle | undefined;

		if (!file) {
			throw new ConfigError(`Failed to open config file '${path}'`, {
				path,
				action: 'open_read',
			});
		}

		const content = file.readAll();
		file.close();

		if (!content || content.length === 0) {
			log.warn('Config file empty, using defaults', {
				path,
				action: 'empty_config',
			});

			return defaults;
		}

		const parsed = textutils.unserialise(content) as unknown;

		if (parsed === undefined || parsed === null) {
			log.error('Failed to parse config, using defaults', {
				path,
				action: 'parse_error',
			});

			return defaults;
		}

		return this.merge(defaults, parsed, path, '');
	}

	/**
	 * Saves through a temporary file: the previous file is only replaced once the new content is
	 * fully written, so a crash never leaves a truncated config (see recoverInterruptedSave).
	 */
	public static save<T extends object>(path: string, data: T): void {
		const tempPath = this.tempPath(path);
		const file     = fs.open(tempPath, 'w') as WriteHandle | undefined;

		if (!file) {
			throw new ConfigError(`Failed to write config file '${path}'`, {
				path,
				action: 'open_write',
			});
		}

		file.write(textutils.serialise(data));
		file.close();

		if (fs.exists(path)) {
			fs.delete(path);
		}

		fs.move(tempPath, path);

		log.info('Config saved', {
			path,
			action: 'save_config',
		});
	}

	private static tempPath(path: string): string {
		return `${path}.tmp`;
	}

	/**
	 * A leftover temp file means a save was interrupted: if the config itself is gone, the temp
	 * file holds the complete new content (it is only moved once written); otherwise the temp
	 * file may be partial and is discarded.
	 */
	private static recoverInterruptedSave(path: string): void {
		const tempPath = this.tempPath(path);

		if (!fs.exists(tempPath)) return;

		if (fs.exists(path)) {
			fs.delete(tempPath);
			return;
		}

		fs.move(tempPath, path);
		log.warn('Recovered config from an interrupted save', {
			path,
			action: 'recover_config',
		});
	}

	private static merge<T extends object>(defaults: T, loaded: unknown, path: string, prefix: string): T {
		const result = {} as T;
		const source = (type(loaded) === 'table' ? loaded : {}) as Record<string, unknown>;

		for (const key in defaults) {
			const fallback = defaults[key];
			const value    = source[key];

			if (value === undefined) {
				result[key] = fallback;
				continue;
			}

			if (type(value) !== type(fallback)) {
				log.warn('Config value has the wrong type, using default', {
					path,
					key:      `${prefix}${key}`,
					expected: type(fallback),
					actual:   type(value),
				});
				result[key] = fallback;
				continue;
			}

			if (type(fallback) === 'table' && !Array.isArray(fallback)) {
				result[key] = this.merge(fallback as object, value, path, `${prefix}${key}.`) as T[typeof key];
				continue;
			}

			result[key] = value as T[typeof key];
		}

		return result;
	}
}
