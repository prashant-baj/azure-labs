// ESLint 9 "flat" config for TypeScript - Session 13 quality gates (E-003, E-006).
import js from '@eslint/js';
import globals from 'globals';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  { ignores: ['node_modules/', 'coverage/', 'dist/', 'build/', 'reports/'] },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    languageOptions: { globals: { ...globals.node } },
    rules: {
      complexity: ['error', 10], // E-003 - match the limit in your constitution
      'no-empty': ['error', { allowEmptyCatch: false }], // E-006 - no swallowed errors
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      eqeqeq: 'error',
    },
  },
);
