import tseslint from "@typescript-eslint/eslint-plugin";
import parser from "@typescript-eslint/parser";

export default [
	{
		files: ["**/*.ts"],
		languageOptions: {
			parser,
			parserOptions: {
				sourceType: "module",
				ecmaVersion: "latest",
			},
		},
		plugins: {
			"@typescript-eslint": tseslint,
		},
		rules: {
			"@typescript-eslint/consistent-type-imports": [
				"error",
				{
					prefer: "type-imports",
					fixStyle: "separate-type-imports",
				},
			],

			"@typescript-eslint/no-unused-vars": "warn",
		},
	},
]