// Lua globals not covered by @mechazawa/cc-types.
// `this: void` is required: without it TypeScriptToLua passes an extra `nil` self argument
// (it would compile type(value) to type(nil, value), which always returns "nil").

declare function error(this: void, message?: string, level?: number): never;

declare function type(this: void, value: unknown): string;

declare function tostring(this: void, value: unknown): string;

declare function next<K extends AnyNotNil, V>(this: void, table: LuaTable<K, V>, index?: K): LuaMultiReturn<[K, V]>;

// LuaIterable makes `for (const [k, v] of pairs(t))` compile to a native `for k, v in pairs(t)` loop.
declare function pairs<K extends AnyNotNil, V>(this: void, table: LuaTable<K, V>): LuaIterable<LuaMultiReturn<[K, V]>>;
