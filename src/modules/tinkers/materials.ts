import type {ItemDetail} from '@core/inventory';

export interface MaterialOverride {
	/** Exact item id, e.g. 'minecraft:obsidian'. */
	item: string;
	/** Fluid it melts into, e.g. 'tconstruct:molten_obsidian'. */
	fluid: string;
}

export interface MaterialMapOptions {
	/** Tags of the form '<prefix><material>' that name the material of an item. */
	tagPrefixes?: string[];
	/** Fluid name built from a material: '%s' is replaced by the material. */
	fluidPattern?: string;
	/** Checked before the tags: items whose fluid cannot be guessed from their tags. */
	overrides?: MaterialOverride[];
	/**
	 * Only these materials are accepted ('iron', 'gold', ...). Without it, any material named by a tag
	 * is, so a stick (forge:rods/wooden) would count as 'wooden'.
	 */
	materials?: string[];
}

export const DEFAULT_TAG_PREFIXES = [
	'forge:ingots/',
	'forge:nuggets/',
	'forge:storage_blocks/',
	'forge:raw_materials/',
	'forge:ores/',
	'forge:dusts/',
	'forge:plates/',
	'forge:gears/',
	'forge:rods/',
];

export const DEFAULT_FLUID_PATTERN = 'tconstruct:molten_%s';

/**
 * Tells which fluid an item melts into, from its tags (forge:ingots/iron → tconstruct:molten_iron).
 * Answers undefined when it cannot tell for sure: no matching tag, or tags naming two materials.
 */
export class MaterialMap {
	private readonly tagPrefixes: string[];
	private readonly fluidPattern: string;
	private readonly overrides = new Map<string, string>();
	private readonly materials?: Set<string>;

	public constructor(options: MaterialMapOptions = {}) {
		this.tagPrefixes  = options.tagPrefixes ?? DEFAULT_TAG_PREFIXES;
		this.fluidPattern = options.fluidPattern ?? DEFAULT_FLUID_PATTERN;

		if (options.materials !== undefined) this.materials = new Set(options.materials);

		for (const override of options.overrides ?? []) {
			this.overrides.set(override.item, override.fluid);
		}
	}

	public fluidOf(item: Pick<ItemDetail, 'name' | 'tags'>): string | undefined {
		const override = this.overrides.get(item.name);
		if (override !== undefined) return override;

		const material = this.materialOf(item);
		return material === undefined ? undefined : this.fluidPattern.replace('%s', material);
	}

	public materialOf(item: Pick<ItemDetail, 'name' | 'tags'>): string | undefined {
		if (!item.tags) return undefined;

		let found: string | undefined;

		for (const [tag, present] of item.tags) {
			if (!present) continue;

			const material = this.materialOfTag(tag);
			if (material === undefined) continue;

			if (found !== undefined && found !== material) return undefined;
			found = material;
		}

		return found;
	}

	private materialOfTag(tag: string): string | undefined {
		for (const prefix of this.tagPrefixes) {
			if (!tag.startsWith(prefix)) continue;

			let material = tag.substring(prefix.length);

			// forge:storage_blocks/raw_iron is a block of raw iron: its material is iron.
			if (material.startsWith('raw_')) material = material.substring(4);

			// A nested tag (forge:ores/iron/deepslate) or an empty one names no single material.
			if (material.length === 0 || material.includes('/')) return undefined;
			if (this.materials !== undefined && !this.materials.has(material)) return undefined;

			return material;
		}

		return undefined;
	}
}
