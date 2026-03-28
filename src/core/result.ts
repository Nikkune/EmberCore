import {EmberError} from './errors';

export interface Ok<T> {
	readonly ok: true;
	readonly value: T;
}

export interface Err<E = EmberError> {
	readonly ok: false;
	readonly error: E;
}

export type Result<T, E = EmberError> = Ok<T> | Err<E>;

export function ok<T>(value: T): Ok<T> {
	return {
		ok: true,
		value,
	};
}

export function err<E = EmberError>(error: E): Err<E> {
	return {
		ok: false,
		error,
	};
}

export class Results {
	public static ok<T>(value: T): Ok<T> {
		return ok(value);
	}

	public static err<E = EmberError>(error: E): Err<E> {
		return err(error);
	}

	public static isOk<T, E>(result: Result<T, E>): result is Ok<T> {
		return result.ok;
	}

	public static isErr<T, E>(result: Result<T, E>): result is Err<E> {
		return !result.ok;
	}

	public static map<T, U, E>(result: Result<T, E>, fn: (value: T) => U): Result<U, E> {
		if (!result.ok) {
			return result;
		}

		return ok(fn(result.value));
	}

	public static mapError<T, E, F>(result: Result<T, E>, fn: (error: E) => F): Result<T, F> {
		if (result.ok) {
			return result;
		}

		return err(fn(result.error));
	}

	public static unwrap<T, E>(result: Result<T, E>): T {
		if (!result.ok) {
			error(`Tried to unwrap an error result: ${tostring(result.error)}`, 2);
		}

		return result.value;
	}

	public static unwrapOr<T, E>(result: Result<T, E>, fallback: T): T {
		if (!result.ok) {
			return fallback;
		}

		return result.value;
	}

	public static try<T>(fn: () => T): Result<T, EmberError> {
		try {
			return ok(fn());
		} catch (caught) {
			if (caught instanceof EmberError) {
				return err(caught);
			}

			return err(new EmberError('Unknown error', 'UNKNOWN_ERROR', {
				cause: tostring(caught),
			}));
		}
	}
}
