import tseslint from '@typescript-eslint/eslint-plugin';
import parser from '@typescript-eslint/parser';
import importX from 'eslint-plugin-import-x';

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
			'import-x': importX,
		},
		settings: {
			// tsconfig path aliases (@core/*, @modules/*, ...) count as internal imports, not npm packages.
			'import-x/internal-regex': '^@(core|modules|projects|utils)/',
		},
		rules: {
			'import-x/newline-after-import': ['error', {count: 1}],
			'import-x/order': [
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
					// max-len has no "ignoreImports" option: skip import lines through a pattern instead.
					ignorePattern: '^\\s*import\\s',
					ignoreStrings: true,
					ignoreTemplateLiterals: true,
				},
			],
		},
	},
];
