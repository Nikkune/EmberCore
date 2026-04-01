import {ConfigError} from './errors';
import {Logger}      from './logger';

const log = new Logger('Config', 'info');

export class Config {
	public static load<T extends object>(path: string, defaults: T): T {
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

		const parsed = textutils.unserialise(content) as T;

		if (!parsed) {
			log.error('Failed to parse config, using defaults', {
				path,
				action: 'parse_error',
			});

			return defaults;
		}

		return this.merge(defaults, parsed);
	}

	public static save<T extends object>(path: string, data: T): void {
		const file = fs.open(path, 'w') as WriteHandle | undefined;

		if (!file) {
			throw new ConfigError(`Failed to write config file '${path}'`, {
				path,
				action: 'open_write',
			});
		}

		file.write(textutils.serialise(data));
		file.close();

		log.info('Config saved', {
			path,
			action: 'save_config',
		});
	}

	private static merge<T extends object>(defaults: T, loaded: Partial<T>): T {
		const result: any = {};

		for (const key in defaults) {
			if (loaded[key] !== undefined) {
				result[key] = loaded[key];
			}
			else {
				result[key] = (defaults as any)[key];
			}
		}

		return result as T;
	}
}
