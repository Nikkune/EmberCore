import {EmberError}             from '@core/errors';
import {Logger}                 from '@core/logger';
import {Peripheral}             from '@core/peripheral';
import type {Result}            from '@core/result';
import {err, ok}                from '@core/result';

import {isEnvelope, REPLY_TYPE} from './message';
import type {Envelope}          from './message';

const log = new Logger('Net', 'info');

export interface ChannelOptions {
	/** rednet protocol: only messages of this protocol are seen. */
	protocol: string;
	/** Modem to open. Default: the first wireless modem, otherwise the first modem. */
	modem?: string;
	/** Seconds a request waits for its reply. Default 3. */
	timeoutSeconds?: number;
	/** When set, messages from any other computer are ignored. */
	peers?: number[];
}

/** Handles a message; for a request, what it returns is sent back as the reply (throw to fail it). */
export type MessageHandler = (payload: unknown, from: number) => unknown;

export type ReplyCallback = (result: Result<unknown, string>) => void;

interface PendingRequest {
	to: number;
	timer: number;
	callback: ReplyCallback;
}

/** @noSelf */
interface ModemPeripheral {
	isWireless(): boolean;
}

/**
 * Messages between computers over rednet: fire-and-forget messages, broadcasts, and requests
 * answered by a reply (or a timeout).
 *
 * The channel does not own the event loop: feed it every event with handleEvent() from whatever loop
 * the program runs (a UIRuntime's onEvent, a controller loop), or run listen() in a Parallel task.
 */
export class Channel {
	public readonly protocol: string;

	private readonly modemName?: string;
	private readonly timeoutSeconds: number;
	private readonly peers?: Set<number>;
	private readonly handlers = new Map<string, MessageHandler>();
	private readonly pending  = new Map<number, PendingRequest>();
	private readonly timers   = new Map<number, number>();
	private openedModem: string | undefined;
	private nextId            = 1;

	public constructor(options: ChannelOptions) {
		this.protocol       = options.protocol;
		this.timeoutSeconds = options.timeoutSeconds ?? 3;
		if (options.modem !== undefined) this.modemName = options.modem;
		if (options.peers !== undefined) this.peers = new Set(options.peers);
	}

	/** Opens the modem for rednet. Returns its name. */
	public open(): string {
		const name = this.modemName ?? Channel.findModem();

		if (name === undefined) {
			throw new EmberError('No modem found to open rednet', 'NET_ERROR', {protocol: this.protocol, action: 'open'});
		}

		rednet.open(name);
		this.openedModem = name;
		log.info('Rednet opened', {modem: name, protocol: this.protocol});
		return name;
	}

	public close(): void {
		if (this.openedModem !== undefined) {
			rednet.close(this.openedModem);
			this.openedModem = undefined;
		}
	}

	/** Makes this computer findable by lookup() under `hostname`. */
	public host(hostname: string): void {
		rednet.host(this.protocol, hostname);
	}

	/** Finds the computer hosting `hostname` (waits up to 2 s: call it at startup, not inside a UI loop). */
	public lookup(hostname: string): number | undefined {
		const found = rednet.lookup(this.protocol, hostname);
		return type(found) === 'number' ? found as number : undefined;
	}

	/** Registers the handler of a message type (replaces the previous one). */
	public on(messageType: string, handler: MessageHandler): void {
		this.handlers.set(messageType, handler);
	}

	public send(to: number, messageType: string, payload?: unknown): void {
		rednet.send(to, this.envelope(messageType, payload) as unknown as object, this.protocol);
	}

	public broadcast(messageType: string, payload?: unknown): void {
		rednet.broadcast(this.envelope(messageType, payload) as unknown as object, this.protocol);
	}

	/**
	 * Sends a request; `callback` gets the reply payload, or an error (refused by the receiver, or no
	 * answer within the timeout). Returns the request id.
	 */
	public request(to: number, messageType: string, payload: unknown, callback: ReplyCallback, timeoutSeconds?: number): number {
		const id      = this.nextId++;
		const message = this.envelope(messageType, payload);
		message.id    = id;

		const timer = os.startTimer(timeoutSeconds ?? this.timeoutSeconds);
		this.pending.set(id, {to, timer, callback});
		this.timers.set(timer, id);

		rednet.send(to, message as unknown as object, this.protocol);
		return id;
	}

	/** Requests still waiting for their reply. */
	public pendingCount(): number {
		return this.pending.size;
	}

	/**
	 * Gives an event to the channel. Returns true when the event was for it (a message of its protocol,
	 * or the timeout of one of its requests); other events are left to the caller.
	 */
	public handleEvent(raw: unknown[]): boolean {
		const [name] = raw;

		if (name === 'timer') return this.handleTimer(raw[1] as number);
		if (name !== 'rednet_message') return false;

		const [, from, message, protocol] = raw as [string, number, unknown, string | undefined];

		if (protocol !== this.protocol) return false;
		if (this.peers !== undefined && !this.peers.has(from)) return true;
		if (!isEnvelope(message)) return true;

		if (message.type === REPLY_TYPE) {
			this.handleReply(from, message);
		}
		else {
			this.handleMessage(from, message);
		}

		return true;
	}

	/** Pulls events forever and handles them (for a Parallel task). Other events are ignored. */
	public listen(): never {
		while (true) {
			this.handleEvent([...os.pullEvent()]);
		}
	}

	private static findModem(): string | undefined {
		let anyModem: string | undefined;

		for (const name of peripheral.getNames()) {
			if (!Peripheral.hasType(name, 'modem')) continue;

			const modem = peripheral.wrap(name) as unknown as ModemPeripheral;
			if (modem.isWireless()) return name;
			anyModem ??= name;
		}

		return anyModem;
	}

	private envelope(messageType: string, payload?: unknown): Envelope {
		const message: Envelope = {net: 1, type: messageType};
		if (payload !== undefined) message.payload = payload;
		return message;
	}

	private handleTimer(timer: number): boolean {
		const id = this.timers.get(timer);
		if (id === undefined) return false;

		this.timers.delete(timer);
		const request = this.pending.get(id);

		if (request !== undefined) {
			this.pending.delete(id);
			request.callback(err('timeout'));
		}

		return true;
	}

	private handleReply(from: number, message: Envelope): void {
		if (message.replyTo === undefined) return;

		const request = this.pending.get(message.replyTo);

		// A reply from another computer than the one asked is not an answer.
		if (request === undefined || request.to !== from) return;

		this.pending.delete(message.replyTo);
		this.timers.delete(request.timer);
		os.cancelTimer(request.timer);

		request.callback(message.ok === true ? ok(message.payload) : err(message.error ?? 'request failed'));
	}

	private handleMessage(from: number, message: Envelope): void {
		const handler = this.handlers.get(message.type);

		if (handler === undefined) {
			log.warn('No handler for message', {type: message.type, from, protocol: this.protocol});
			if (message.id !== undefined) this.reply(from, message.id, false, undefined, `unknown message type '${message.type}'`);
			return;
		}

		try {
			const result = handler(message.payload, from);
			if (message.id !== undefined) this.reply(from, message.id, true, result);
		}
		catch (error) {
			// Ctrl+T raises "Terminated" inside the handler: it must stop the program, not become a reply.
			if (error === 'Terminated') throw error;
			const text = error instanceof Error ? error.message : tostring(error);
			log.error('Message handler failed', {type: message.type, from, error: text});
			if (message.id !== undefined) this.reply(from, message.id, false, undefined, text);
		}
	}

	private reply(to: number, replyTo: number, success: boolean, payload?: unknown, error?: string): void {
		const message   = this.envelope(REPLY_TYPE, payload);
		message.replyTo = replyTo;
		message.ok      = success;
		if (error !== undefined) message.error = error;

		rednet.send(to, message as unknown as object, this.protocol);
	}
}
