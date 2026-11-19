/**
 * What travels over rednet. The `net` marker tells EmberCore messages apart from anything else
 * using the same protocol; a message without it is ignored.
 */
export interface Envelope {
	net: 1;
	type: string;
	/** Set on a request: the receiver answers with a reply carrying the same id in `replyTo`. */
	id?: number;
	/** Set on a reply: the id of the request it answers. */
	replyTo?: number;
	/** Set on a reply: whether the request succeeded. */
	ok?: boolean;
	payload?: unknown;
	/** Set on a failed reply. */
	error?: string;
}

export const REPLY_TYPE = 'reply';

export function isEnvelope(this: void, value: unknown): value is Envelope {
	if (type(value) !== 'table') return false;

	const message = value as Record<string, unknown>;
	return message['net'] === 1 && type(message['type']) === 'string';
}
