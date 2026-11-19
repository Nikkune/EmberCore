/**
 * TypeScriptToLua plugin: makes project entries find the EmberCore modules in game.
 *
 * In CC:Tweaked, every program gets its own `require`, which looks next to the program
 * (projects/<name>/core/config.lua) and in /rom, never at the root of the computer where core/,
 * modules/ and utils/ are installed. The first line of each projects/<name>/main.lua adds the root to
 * package.path, before any require runs.
 */
import type {Plugin} from 'typescript-to-lua';

export const ROOT_PATH_LINE = 'package.path = "/?.lua;/?/init.lua;" .. package.path';

const ENTRY_PATTERN = /[\\/]projects[\\/][^\\/]+[\\/]main\.lua$/;

const plugin: Plugin = {
	beforeEmit(_program, _options, _emitHost, result) {
		for (const file of result) {
			if (ENTRY_PATTERN.test(file.outputPath) && !file.code.startsWith(ROOT_PATH_LINE)) {
				file.code = `${ROOT_PATH_LINE}\n${file.code}`;
			}
		}
	},
};

export default plugin;
