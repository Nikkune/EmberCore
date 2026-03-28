import tseslint from '@typescript-eslint/eslint-plugin';
import parser from '@typescript-eslint/parser';

export default [
	{
		ignores: ['luas/**', 'build-scripts/**', 'manifests/**', 'node_modules/**'],
	},
	{
		files: ['**/*.ts'],
		languageOptions: {
			parser,
			parserOptions: {
				sourceType: 'module',
				ecmaVersion: 'latest',
			},
		},
		plugins: {
			'@typescript-eslint': tseslint,
		},
		rules: {
			'import/newline-after-import': ['error', {count: 1}],
			'import/order': [
				'error',
				{
					groups: ['builtin', 'external', 'internal', 'parent', 'sibling', 'index'],
					'newlines-between': 'always',
				},
			],

			'@typescript-eslint/consistent-type-imports': [
				'error',
				{
					prefer: 'type-imports',
					fixStyle: 'separate-type-imports',
				},
			],
			'@typescript-eslint/no-unused-vars': [
				'warn',
				{
					argsIgnorePattern: '^_',
					varsIgnorePattern: '^_',
					caughtErrorsIgnorePattern: '^_',
				},
			],
			'@typescript-eslint/no-explicit-any': 'warn',

			eqeqeq: ['error', 'always'],
			'consistent-return': 'error',

			'prefer-const': 'error',

			'max-len': [
				'error',
				{
					code: 140,
					ignoreImports: true,
					ignoreStrings: true,
					ignoreTemplateLiterals: true,
				},
			],
		},
	},
];
