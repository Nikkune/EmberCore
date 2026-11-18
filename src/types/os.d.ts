export {};

declare global {
	interface DateTable {
		year: number;
		month: number;
		day: number;
		hour: number;
		min: number;
		sec: number;
		wday?: number;
		yday?: number;
		isdst?: boolean;
	}

	// @noSelf is required: without it this merged declaration compiles to os:date(...) (self = os).
	/** @noSelf */
	namespace os {
		function date(format: '*t', time?: number): DateTable;
	}
}
