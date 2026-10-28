// ESLint 9 "flat" config - Session 13 quality gates (E-003 complexity, E-006 no silent failure).
// Copy to the folder with your package.json. qa:lint runs `npx eslint .` there.
import js from '@eslint/js';
import globals from 'globals';

export default [
  { ignores: ['node_modules/', 'coverage/', 'dist/', 'build/', 'reports/', '*.min.js'] },
  js.configs.recommended,
  {
    languageOptions: { ecmaVersion: 2023, sourceType: 'module', globals: { ...globals.node } },
    rules: {
      complexity: ['error', 10], // E-003 - match the limit in your constitution
      'no-empty': ['error', { allowEmptyCatch: false }], // E-006 - no swallowed errors
      'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      eqeqeq: 'error',
    },
  },
  // TypeScript? Use eslint.config.typescript.mjs instead (rename it to eslint.config.mjs)
];
