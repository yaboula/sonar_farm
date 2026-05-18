import js from '@eslint/js';
import globals from 'globals';
import reactHooks from 'eslint-plugin-react-hooks';
import reactRefresh from 'eslint-plugin-react-refresh';
import tseslint from 'typescript-eslint';

// ============================================================
// Farm Sonar NUI — ESLint flat config (ESLint 9+).
// ============================================================
//
// Rationale:
// - TypeScript strict already covers most issues; ESLint adds
//   React-specific lints + dead code detection.
// - max-warnings: 0 in package.json scripts treats warnings as errors
//   in CI / pre-commit. Be deliberate.
// - exhaustive-deps as ERROR, not warn: stale-closure bugs in NUI
//   contexts are nightmares to debug inside FiveM.
// ============================================================

export default tseslint.config(
    { ignores: ['dist', 'node_modules', '*.config.js', '*.config.ts'] },
    {
        extends: [js.configs.recommended, ...tseslint.configs.recommended],
        files: ['**/*.{ts,tsx}'],
        languageOptions: {
            ecmaVersion: 2022,
            globals: globals.browser,
        },
        plugins: {
            'react-hooks': reactHooks,
            'react-refresh': reactRefresh,
        },
        rules: {
            ...reactHooks.configs.recommended.rules,
            'react-refresh/only-export-components': [
                'warn',
                { allowConstantExport: true },
            ],
            'react-hooks/exhaustive-deps': 'error',
            '@typescript-eslint/no-unused-vars': [
                'error',
                { argsIgnorePattern: '^_', varsIgnorePattern: '^_' },
            ],
            '@typescript-eslint/consistent-type-imports': [
                'error',
                { prefer: 'type-imports' },
            ],
        },
    }
);
