export function splitWords(text: string): string[] {
	const normalized = text
		.replaceAll("\t", " ")
		.replaceAll("\n", " ")
		.replaceAll("\r", " ");

	const result: string[] = [];

	for (const word of normalized.split(" ")) {
		if (word.length > 0) {
			result.push(word);
		}
	}

	return result;
}