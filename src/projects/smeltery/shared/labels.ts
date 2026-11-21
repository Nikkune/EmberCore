/**
 * A Tinkers material for the screen and the log: 'tconstruct:nahuatl' -> 'nahuatl',
 * 'tconstruct:copper#oxidized' -> 'oxidized copper', 'tconstruct:slimewood#composite' -> 'slimewood'.
 */
export function materialLabel(this: void, material: string): string {
	const name    = material.substring(material.indexOf(':') + 1);
	const hash    = name.indexOf('#');
	const base    = (hash >= 0 ? name.substring(0, hash) : name).split('_').join(' ');
	const variant = hash >= 0 ? name.substring(hash + 1).split('_').join(' ') : '';
	return variant === '' || variant === 'default' || variant === 'composite' ? base : `${variant} ${base}`;
}
