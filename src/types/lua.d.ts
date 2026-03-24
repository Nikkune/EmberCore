declare function error(message?: string, level?: number): never;
declare function type(value: unknown): string;
declare function tostring(value: unknown): string;
declare function next<K, V>(
	table: LuaTable<K, V>,
	index?: K
): LuaMultiReturn<[K, V]>;

declare function pairs<K, V>(
	table: LuaTable<K, V>
): Iterable<LuaMultiReturn<[K, V]>>;