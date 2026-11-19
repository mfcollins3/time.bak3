// @ts-check

// Copyright 2026 Michael F. Collins, III
// Licensed under the Naked Time license. See LICENSE.md for details.

import { defineConfig } from 'eslint/config';
import tseslint from 'typescript-eslint';

export default defineConfig({
  files: ['apphost.mts'],
  extends: [tseslint.configs.base],
  languageOptions: {
    parserOptions: {
      project: './tsconfig.apphost.json',
      tsconfigRootDir: import.meta.dirname,
    },
  },
  rules: {
    '@typescript-eslint/no-floating-promises': ['error', { checkThenables: true }],
  },
});
