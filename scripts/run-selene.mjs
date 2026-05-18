#!/usr/bin/env node
// ============================================================
// Farm Sonar — selene runner (cross-platform).
// ============================================================
//
// Wraps the selene binary so the workspace works the same on Windows,
// macOS and Linux.
//
// Resolution order:
//   1. `selene` on PATH (cargo install / system package).
//   2. Local `tools/selene` (downloaded by `pnpm setup:lua`).
//   3. Hard fail with install instructions.
//
// CLI args are forwarded verbatim to selene.
// ============================================================

import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { dirname } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(__dirname, '..');

function findSelene() {
    const which = spawnSync(
        process.platform === 'win32' ? 'where' : 'which',
        ['selene'],
        { encoding: 'utf8' }
    );
    if (which.status === 0 && which.stdout.trim()) {
        return 'selene';
    }

    const localBinary = join(
        repoRoot,
        'tools',
        process.platform === 'win32' ? 'selene.exe' : 'selene'
    );
    if (existsSync(localBinary)) {
        return localBinary;
    }

    return null;
}

const selenePath = findSelene();

if (!selenePath) {
    console.error('[run-selene] selene binary not found.');
    console.error('');
    console.error('Install options:');
    console.error('  - cargo install selene  (requires Rust)');
    console.error(
        '  - Download release binary from https://github.com/Kampfkarren/selene/releases'
    );
    console.error('    and place selene(.exe) into ./tools/');
    console.error('');
    process.exit(127);
}

const args = process.argv.slice(2);
const result = spawnSync(selenePath, args, {
    stdio: 'inherit',
    cwd: repoRoot,
});

process.exit(result.status ?? 1);
