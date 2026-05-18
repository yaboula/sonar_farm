import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
import path from 'node:path';

// ============================================================
// Farm Sonar NUI — Vite config
// ============================================================
//
// - `base: './'` is mandatory: FiveM serves the SPA from a non-root
//   path inside the resource. Absolute paths break the bundle.
// - `build.outDir: 'dist'` matches what fxmanifest.lua exposes via
//   `ui_page` and `files`.
// - Tailwind v4 plugin replaces the legacy postcss + tailwind setup;
//   theme tokens are defined in `src/styles/theme.css` via @theme.
// - Path alias `@` maps to `src/` (mirrored in tsconfig.json).
// ============================================================

export default defineConfig({
    base: './',
    plugins: [react(), tailwindcss()],
    resolve: {
        alias: {
            '@': path.resolve(__dirname, './src'),
        },
    },
    server: {
        port: 3000,
        strictPort: true,
        host: '127.0.0.1',
    },
    build: {
        outDir: 'dist',
        emptyOutDir: true,
        sourcemap: false,
        target: 'es2022',
        // Inline assets <4KiB; FiveM's NUI handles small bundles best.
        assetsInlineLimit: 4096,
    },
});
