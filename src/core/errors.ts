export interface ErrorContext {
	[key: string]: unknown;
}

export class EmberError extends Error {
	public readonly code: string;
	public readonly context?: ErrorContext;

	public constructor(message: string, code = "EMBER_ERROR", context?: ErrorContext) {
		super(message);
		this.name = "EmberError";
		this.code = code;
		this.context = context;
	}

	public toString(): string {
		return `[${this.code}] ${this.message}`;
	}
}

export class ConfigError extends EmberError {
	public constructor(message: string, context?: ErrorContext) {
		super(message, "CONFIG_ERROR", context);
		this.name = "ConfigError";
	}
}

export class PeripheralError extends EmberError {
	public constructor(message: string, context?: ErrorContext) {
		super(message, "PERIPHERAL_ERROR", context);
		this.name = "PeripheralError";
	}
}

export class InventoryError extends EmberError {
	public constructor(message: string, context?: ErrorContext) {
		super(message, "INVENTORY_ERROR", context);
		this.name = "InventoryError";
	}
}

export class TankError extends EmberError {
	public constructor(message: string, context?: ErrorContext) {
		super(message, "TANK_ERROR", context);
		this.name = "TankError";
	}
}
export class RuntimeError extends EmberError {
	public constructor(message: string, context?: ErrorContext) {
		super(message, "RUNTIME_ERROR", context);
		this.name = "RuntimeError";
	}
}