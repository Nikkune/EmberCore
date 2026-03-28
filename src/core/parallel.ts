import type { EmberError } from './errors';
import { RuntimeError } from './errors';
import { Logger } from './logger';
import type { Result } from './result';
import { Results } from './result';

const log = new Logger('Parallel', 'info');

export type ParallelTask = () => void;
export type ParallelResultTask<T> = () => Result<T, EmberError>;

export class Parallel {
	public static all(...tasks: ParallelTask[]): void {
		if (tasks.length === 0) {
			throw new RuntimeError('Parallel.all requires at least one task', {
				action: 'parallel_all',
			});
		}

		log.debug('Running parallel all', {
			action: 'parallel_all',
			taskCount: tasks.length,
			status: 'start',
		});

		parallel.waitForAll(...tasks);

		log.debug('Parallel all completed', {
			action: 'parallel_all',
			taskCount: tasks.length,
			status: 'done',
		});
	}

	public static any(...tasks: ParallelTask[]): number {
		if (tasks.length === 0) {
			throw new RuntimeError('Parallel.any requires at least one task', {
				action: 'parallel_any',
			});
		}

		log.debug('Running parallel any', {
			action: 'parallel_any',
			taskCount: tasks.length,
			status: 'start',
		});

		const completedIndex = parallel.waitForAny(...tasks) as unknown as number;

		log.debug('Parallel any completed', {
			action: 'parallel_any',
			taskCount: tasks.length,
			completedIndex,
			status: 'done',
		});

		return completedIndex;
	}

	public static race(...tasks: ParallelTask[]): number {
		return this.any(...tasks);
	}

	public static tryAll(...tasks: ParallelTask[]): Result<void, EmberError> {
		return Results.try(() => {
			this.all(...tasks);
		});
	}

	public static tryAny(...tasks: ParallelTask[]): Result<number, EmberError> {
		return Results.try(() => this.any(...tasks));
	}

	public static withHeartbeat(task: ParallelTask, heartbeat: ParallelTask): void {
		this.all(task, heartbeat);
	}

	public static daemon(task: ParallelTask): never {
		this.any(task, () => {
			while (true) {
				sleep(999999);
			}
		});

		throw new RuntimeError('Parallel.daemon unexpectedly returned', {
			action: 'parallel_daemon',
		});
	}

	public static service(mainTask: ParallelTask, ...backgroundTasks: ParallelTask[]): void {
		this.all(mainTask, ...backgroundTasks);
	}
}
