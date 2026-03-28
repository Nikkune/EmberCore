import { withDefined } from '@utils/helpers';

export function makeColorOptions(style?: { foregroundColor?: number | undefined; backgroundColor?: number | undefined }) {
	const result: { foregroundColor?: number; backgroundColor?: number } = {};

	withDefined(result, 'foregroundColor', style?.foregroundColor);
	withDefined(result, 'backgroundColor', style?.backgroundColor);

	return result;
}
