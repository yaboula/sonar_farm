#!/usr/bin/env node
// ============================================================
// Farm Sonar — eslint runner for lint-staged.
// ============================================================
//
// lint-staged passes absolute paths to all matched files. We need to
// invoke the workspace's local eslint (installed under
// sonar_farm_tablet/web/node_modules) with those paths.
//
// Resolution: spawn `pnpm --filter @sonar/farm-tablet-web exec eslint`
// from the repo root. We cannot use a `pnpm --filter ...` string in
// `package.json` lint-staged config because lint-staged appends the
// file paths AFTER the command, and pnpm interprets them as scripts.
//
// This script forwards them as eslint args explicitly.
// ============================================================

import { spawnSync } from 'node:child_process';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(__dirname, '..');

const files = process.argv.slice(2);

if (files.length === 0) {
    process.exit(0);
}

const result = spawnSync(
    process.platform === 'win32' ? 'pnpm.cmd' : 'pnpm',
    [
        '--filter',
        '@sonar/farm-tablet-web',
        'exec',
        'eslint',
        '--fix',
        '--max-warnings',
        '0',
        ...files,
    ],
    {
        stdio: 'inherit',
        cwd: repoRoot,
    }
);

process.exit(result.status ?? 1);
