import { Logger } from "./logger";
import { EmberError, RuntimeError } from "./errors";
import { Result, Results } from "./result";

const log = new Logger("Loop", "info");

export type LoopTask = () => void;
export type LoopCondition = () => boolean;
export type LoopResultTask<T> = () => Result<T, EmberError>;

export interface RetryOptions {
	attempts: number;
	delaySeconds?: number;
	label?: string;
}

export class Loop {
	public static sleep(seconds: number): void {
		if (seconds < 0) {
			throw new RuntimeError("Sleep duration cannot be negative", {
				seconds,
				action: "sleep",
			});
		}

		sleep(seconds);
	}

	public static forever(task: LoopTask, intervalSeconds = 0): never {
		while (true) {
			task();

			if (intervalSeconds > 0) {
				this.sleep(intervalSeconds);
			}
		}
	}

	public static every(intervalSeconds: number, task: LoopTask): never {
		if (intervalSeconds < 0) {
			throw new RuntimeError("Loop interval cannot be negative", {
				intervalSeconds,
				action: "every",
			});
		}

		while (true) {
			task();
			this.sleep(intervalSeconds);
		}
	}

	public static until(condition: LoopCondition, task: LoopTask, intervalSeconds = 0): void {
		if (intervalSeconds < 0) {
			throw new RuntimeError("Loop interval cannot be negative", {
				intervalSeconds,
				action: "until",
			});
		}

		while (!condition()) {
			task();

			if (intervalSeconds > 0) {
				this.sleep(intervalSeconds);
			}
		}
	}

	public static retry<T>(task: LoopResultTask<T>, options: RetryOptions): Result<T, EmberError> {
		const attempts = options.attempts;
		const delaySeconds = options.delaySeconds ?? 0;
		const label = options.label ?? "retry_task";

		if (attempts <= 0) {
			return Results.err(
				new RuntimeError("Retry attempts must be greater than 0", {
					attempts,
					action: "retry",
					label,
				}),
			);
		}

		let lastError: EmberError | undefined;

		for (let attempt = 1; attempt <= attempts; attempt++) {
			const result = task();

			if (result.ok) {
				if (attempt > 1) {
					log.info("Retry succeeded", {
						action: "retry",
						label,
						attempt,
						status: "ok",
					});
				}

				return result;
			}

			lastError = result.error;

			log.warn("Retry attempt failed", {
				action: "retry",
				label,
				attempt,
				attempts,
				code: result.error.code,
				status: "failed",
			});

			if (attempt < attempts && delaySeconds > 0) {
				this.sleep(delaySeconds);
			}
		}

		return Results.err(
			lastError ??
			new RuntimeError("All retry attempts failed", {
				action: "retry",
				label,
				attempts,
				status: "failed",
			}),
		);
	}
}