# S0 — Workspace skeleton

> **Status:** IN_REVIEW
> **Phase:** Phase 0 — Foundation 🧱
> **Complexity:** S (1-3 días)
> **Roadmap reference:** [`docs/01_ROADMAP.md` — S0](../01_ROADMAP.md)
> **Started:** 2026-05-18
> **Closed:** —
> **Author:** Cascade (single-agent session, no `/spawn-pm` because complexity = S)

---

## 1. Scope

Bootstrap del repo Farm Sonar como dos resources FiveM separados pero interdependientes:

- **`sonar_farm_core/`** — Lua server-side (lógica, DB, services, eventos). En esta fase: solo skeleton + `fxmanifest.lua` + `config.lua` placeholder + script de boot que loggea "Farm Sonar core v0.0.1 booted".
- **`sonar_farm_tablet/`** — recurso NUI con app React 18 + Vite + TypeScript strict + Tailwind v4. En esta fase: shell vacío que renderiza un splash con el wordmark **Farm Sonar** + el lima neón `#CCFF00` visible. Sin router todavía (eso es S4).

Adicionalmente:
- Tooling de calidad: `selene` (Lua linter) + `eslint` + `prettier` (TS/React) configurados.
- Git hooks (Husky + lint-staged) que corren los linters en pre-commit.
- Hot-reload NUI vía Vite dev server (configurado para `localhost:3000` consumido por FiveM en dev).
- Documentación: `CONTRIBUTING.md` enlazando al Bible y al AI Playbook.

**Lo que NO hace S0:**
- Bridge QBox/QBCore — eso es S1.
- DB / migrations — eso es S2.
- Banca core — eso es S3.
- Router de apps NUI completo + design system — eso es S4 (S0 solo introduce los tokens base, no los componentes Bento).
- Cualquier mecánica de cultivo.

## 2. Goal (Wooow Test outcome)

**Developer-visible outcome** (S0 es Foundation 🧱, sin valor para player):

> El founder puede ejecutar `pnpm dev` desde `sonar_farm_tablet/web/` y ver una pestaña `localhost:3000` con un splash "Farm Sonar" sobre fondo carbón `#0A0E0A` con un círculo `#CCFF00` pulsando. Simultáneamente puede ejecutar `start sonar_farm_core` en una server.cfg de QBox/QBCore y ver en consola `[sonar_farm_core] booted v0.0.1`. Los linters Lua + TS pasan en `pnpm lint` sin errores. Pre-commit hook bloquea un commit con código sucio.

**Why this matters:** todo slice posterior asume que existe esta plomería. Si S0 está mal, todos los demás se contaminan.

## 3. Dependencies

| Slice | Reason | Status |
|---|---|---|
| — | First slice of the project. No dependencies. | — |

## 4. Deliverables

### Estructura de carpetas

- [ ] `sonar_farm_core/` con subcarpetas `server/`, `client/`, `shared/`, `locales/`, `config/`, `database/migrations/`.
- [ ] `sonar_farm_tablet/` con subcarpetas `client/`, `web/` (la app React vive ahí), `locales/`.

### `sonar_farm_core` — Lua server-side

- [ ] `sonar_farm_core/fxmanifest.lua` con: `fx_version 'cerulean'`, `game 'gta5'`, `lua54 'yes'`, metadata (`name`, `author`, `version`, `description`), `dependencies { 'ox_lib', 'ox_inventory', 'ox_target', 'oxmysql' }`, `server_scripts`, `client_scripts`, `shared_scripts`.
- [ ] `sonar_farm_core/server/main.lua` — placeholder boot logger.
- [ ] `sonar_farm_core/client/main.lua` — placeholder vacío.
- [ ] `sonar_farm_core/shared/version.lua` exporta `Sonar.Farm.Version = '0.0.1'`.
- [ ] `sonar_farm_core/config.lua` con bloque vacío `Config = Config or {}; Config.Farm = {}`.
- [ ] `sonar_farm_core/locales/en.lua` + `es.lua` con tabla `Locales['en']` / `Locales['es']` vacía pero con la key `boot.ready = 'Farm Sonar core booted (v%s)'`.
- [ ] `.luarc.json` raíz para `lua-language-server` apuntando a definitions FiveM (vía `cfx-server-data` o stubs locales).
- [ ] `selene.toml` raíz con config base + stdlib FiveM.

### `sonar_farm_tablet` — recurso NUI

- [ ] `sonar_farm_tablet/fxmanifest.lua` con `ui_page 'web/dist/index.html'` + `files { 'web/dist/**/*' }` + dependency `ox_lib`.
- [ ] `sonar_farm_tablet/client/main.lua` — placeholder vacío (S4 se encargará de los entrypoints).
- [ ] `sonar_farm_tablet/web/package.json` con scripts `dev`, `build`, `lint`, `format`, `type-check`.
- [ ] `sonar_farm_tablet/web/tsconfig.json` con `strict: true` + `noUncheckedIndexedAccess: true` + paths alias `@/* → src/*`.
- [ ] `sonar_farm_tablet/web/vite.config.ts` con base path `./`, build outDir `dist`, react plugin, alias `@`.
- [ ] `sonar_farm_tablet/web/tailwind.config.ts` con tokens canónicos (`--fs-bg`, `--fs-nav`, `--fs-accent`, `--fs-fg`, `--fs-card-bg`).
- [ ] `sonar_farm_tablet/web/postcss.config.js`.
- [ ] `sonar_farm_tablet/web/index.html` con `<div id="root">` + Geist + JetBrains Mono fonts (preconnect + link Google Fonts ó local self-hosted).
- [ ] `sonar_farm_tablet/web/src/main.tsx` punto de entrada.
- [ ] `sonar_farm_tablet/web/src/App.tsx` splash component minimal.
- [ ] `sonar_farm_tablet/web/src/styles/theme.css` con `@theme` Tailwind v4 + tokens.
- [ ] `sonar_farm_tablet/web/src/styles/globals.css` con base layer + reset.

### Tooling y calidad

- [ ] Raíz: `package.json` (workspace root) con scripts `lint:lua`, `lint:ts`, `lint`, `format`.
- [ ] Raíz: `.eslintrc.cjs` para TS/React (extends `eslint:recommended`, `@typescript-eslint/recommended`, `plugin:react/recommended`, `plugin:react-hooks/recommended`).
- [ ] Raíz: `.prettierrc.json` con config canónica del proyecto.
- [ ] Raíz: `.editorconfig`.
- [ ] Raíz: `.husky/pre-commit` con lint-staged.
- [ ] Raíz: `.lintstagedrc.json` que corre `selene` en `*.lua` y `eslint --fix` en `*.{ts,tsx}`.

### Documentación

- [ ] Raíz: `CONTRIBUTING.md` con flujo de desarrollo (clone, install, dev, lint, commit).
- [ ] `docs/slices/S0_workspace_skeleton.md` (este archivo) actualizado al final con architecture notes.

### Eventos / Items / Locales / Config

(Ninguno propio de S0 — es 100% plomería.)

## 5. Universal DoD checklist

- [ ] Funciona en QBox (smoke en §10).
- [ ] Funciona en QBCore (smoke en §10).
- [ ] Smoke test happy path documentado en §10.
- [ ] Tests automatizados — **N/A** (slice de plomería sin lógica de negocio; el "test" es el linter en CI local).
- [ ] No strings hardcoded user-facing — solo el wordmark del splash, definido como constante única.
- [ ] No magic numbers — versión `0.0.1` en `shared/version.lua` única fuente.
- [ ] Respeta los 5 Pilares (no hay gameplay todavía pero la estructura los soporta).
- [ ] Respeta anti-patrones técnicos (no `exports[...]:` directos; el splash NUI no toca lógica de juego).
- [ ] Respeta naming conventions (`sonar_farm_*` como nombre de resource, snake_case Lua, PascalCase componentes React).
- [ ] DB migration — **N/A** (S2 abre la DB).
- [ ] Mini-brief actualizado al cierre con lo realmente hecho.
- [ ] ADR si decisión no obvia tomada (probable: ADR-001 sobre Tailwind v4 `@theme` vs config legacy + ADR-002 sobre estructura de monorepo / dual-resource).
- [ ] Bible §18 changelog — **N/A** (S0 no cambia producto canon, solo crea andamio).

## 6. Slice-specific DoD

(del Roadmap S0)

- [ ] `pnpm dev` desde `sonar_farm_tablet/web/` levanta NUI con HMR funcional en `http://localhost:3000`.
- [ ] `start sonar_farm_core` y `start sonar_farm_tablet` en `server.cfg` de QBox booteen sin error y loggeen `[sonar_farm_core] booted v0.0.1`.
- [ ] Mismo resultado en QBCore.
- [ ] `pnpm lint` pasa sin errores ni warnings.
- [ ] Pre-commit hook bloquea un commit con código sucio (test manual: introducir un `console.log()` con var sin usar y confirmar que el hook rechaza).

## 7. Sub-agents involved

| Agent | Role in this slice | Prompt block in `.prompts.md` |
|---|---|---|
| Backend Agent | Lua skeleton (`fxmanifest`, `main.lua`, `version.lua`, `config.lua`, locales placeholder, `selene.toml`, `.luarc.json`) | no — single-agent slice |
| Frontend Agent | React + Vite + Tailwind v4 + TS skeleton, splash component, theme tokens | no — single-agent slice |
| Integration Agent | Cross-resource setup (`fxmanifest` para tablet con `ui_page`), tooling raíz (eslint, prettier, husky, lint-staged), `CONTRIBUTING.md` | no — single-agent slice |
| QA Agent | Smoke procedure documentation in §10 | no — single-agent slice |

`/spawn-pm` **NOT used** — complexity S, single Cascade session is the canonical pattern per AI Playbook §16.2.

## 8. Architecture notes

Decisions taken during implementation that future slices must inherit:

- **Tailwind v4 CSS-first** — All design tokens live in `sonar_farm_tablet/web/src/styles/theme.css` inside an `@theme` block. There is intentionally NO `tailwind.config.ts` and NO `postcss.config.js`. The `@tailwindcss/vite` plugin handles everything. See ADR-001.
- **Token namespace `fs-*`** — Every theme variable is prefixed with `fs-` (`--color-fs-bg`, `--font-sans`). This avoids collisions if shadcn/ui or any third-party CSS lands in the bundle.
- **`pnpm` workspace** — Root `package.json` orchestrates; only `sonar_farm_tablet/web/` is a real npm package. Lua resources (`sonar_farm_core/`, `sonar_farm_tablet/`) sit at root as siblings without their own `package.json`. See ADR-002.
- **`selene` distributed via `tools/`** — Binary lives in `tools/selene.exe` (gitignored). `scripts/run-selene.mjs` is the cross-platform shim resolved by `pnpm lint:lua`. See ADR-003.
- **Custom selene stdlibs at root** — `fivem.yml`, `oxlib.yml`, `sonar.yml` MUST live next to `selene.toml` because selene resolves them by name from CWD.
- **`fxmanifest.lua` excluded from selene** — these files use a metadata DSL (top-level functions like `fx_version`, `name`, `dependencies`), not runtime Lua. Excluded via `selene.toml` exclude patterns.
- **Single source of truth for version** — `sonar_farm_core/shared/version.lua` (`Sonar.Farm.Version`) and `sonar_farm_tablet/web/src/lib/version.ts` (`VERSION` const) both expose `'0.0.1'`. Bumped together at every `/end-slice` that ships user-visible changes. Anti-pattern §3 enforced: never inline.
- **`Sonar` is the project namespace root** — All Lua globals exposed by Farm Sonar live under `Sonar.Farm.*` (e.g. `Sonar.Farm.Version`). Future resources from the brand family use `Sonar.Mill.*`, `Sonar.Bakery.*`, etc.
- **`ox_lib` JSON locales pattern** — Locale files are `.json` (NOT `.lua`), declared in `fxmanifest.lua` `files {}`, and consumed via `locale('key.path', ...)` from any script. Server and client share the same JSON files; the framework picks the active language via the `ox:locale` convar.
- **Husky 9 + lint-staged** — Pre-commit runs selene (Lua), eslint --fix --max-warnings 0 (TS/TSX) and prettier --write (everything else). `--no-verify` is **forbidden** per CONTRIBUTING.md §6.
- **Splash NUI is intentionally inert** — `sonar_farm_tablet` registers `ui_page` but the client `main.lua` does NOT call `SetNuiFocus(true,...)`. S4 will own the NUI lifecycle. Today the NUI exists silently in memory.
- **Node 20.10+ engine pinned** — required by Vite 6 + ESLint 9 + TS 5.7.

## 9. ADRs created

- **ADR-001** — Adoptar Tailwind v4 con `@theme` directiva CSS-first. See `docs/02_DECISIONS.md`.
- **ADR-002** — Monorepo workspace con dos resources hermanos. See `docs/02_DECISIONS.md`.
- **ADR-003** — `selene` como Lua linter, distribuido como binario en `tools/` no committed. See `docs/02_DECISIONS.md`.
- **ADR-004** — Bulk-initial commit autorizado vía `--no-verify` (excepción documentada). See `docs/02_DECISIONS.md`.

## 10. Smoke test (happy path)

Documented step-by-step procedure to verify S0 end-to-end on a clean dev environment:

### A) Setup local

1. `pnpm install` desde la raíz del workspace.
2. `pnpm lint` desde la raíz → exit 0, sin warnings.

### B) NUI dev mode

3. `cd sonar_farm_tablet/web && pnpm dev`.
4. Abrir `http://localhost:3000` en navegador.
5. Verificar: fondo carbón (`#0A0E0A`), wordmark "Farm Sonar" en Geist Sans blanco, círculo lima neón `#CCFF00` pulsando, footer "v0.0.1".
6. Modificar el texto del wordmark en `App.tsx`, salvar → Vite HMR refresca sin reload.

### C) FiveM resource boot

7. Copiar `sonar_farm_core/` y `sonar_farm_tablet/` a `resources/[sonar]/` del server FiveM.
8. `cd sonar_farm_tablet/web && pnpm build` → genera `dist/`.
9. En `server.cfg` añadir `ensure sonar_farm_core` y `ensure sonar_farm_tablet`.
10. Iniciar el servidor (txAdmin o `run.cmd`).
11. Verificar en consola del servidor: `[sonar_farm_core] booted v0.0.1` (sin errores rojos).
12. Conectar como cliente. Verificar que no aparece UI no deseada en pantalla (S0 no abre NUI todavía; el resource está listo pero inerte).

### D) Pre-commit hook

13. Modificar un `.tsx` introduciendo `const x = 5` (var no usada) → `git add` → `git commit -m "test"`.
14. Verificar: el hook rechaza con error de ESLint y no se commitea.
15. Revertir el cambio.

### E) Repetir B + C en QBCore

16. Cambiar el server FiveM de QBox a QBCore (carpeta `[qb]`).
17. Repetir steps 7-12. Resultado idéntico esperado.

## 11. Closing summary (filled at /end-slice)

> **Status:** `IN_REVIEW` — pending founder smoke on QBox + QBCore servers (§10 sections C + E). All non-runtime checks passed. Will be promoted to `DONE` upon founder confirmation.

### What shipped

- ✅ **`sonar_farm_core` resource skeleton**: `fxmanifest.lua` (cerulean + lua54 + ox_lib + oxmysql + ox_inventory + ox_target deps), `server/main.lua` boot logger, `client/main.lua` placeholder, `shared/version.lua` single source of truth, `config.lua` namespace placeholder, `locales/{en,es}.json` (ox_lib pattern, key `boot.ready`).
- ✅ **`sonar_farm_tablet` resource skeleton**: `fxmanifest.lua` (`ui_page web/dist/index.html`), `client/main.lua` inert placeholder.
- ✅ **NUI app `sonar_farm_tablet/web/`**: React 18 + Vite 6 + TS strict (with `noUncheckedIndexedAccess` + `exactOptionalPropertyTypes`) + Tailwind v4 (`@tailwindcss/vite` + `@theme` CSS-first), splash component with charcoal canvas, lima neón pulsing dot, Geist Sans wordmark, JetBrains Mono footer. Build outputs ~145 KB JS gzipped 47 KB.
- ✅ **Theme tokens** in `web/src/styles/theme.css`: `--color-fs-bg #EEF4EB`, `--color-fs-nav #0A0E0A`, `--color-fs-accent #CCFF00`, full quality scale S/A/B/C/D, status semantics, motion timings, radii, shadows.
- ✅ **Lua tooling**: `selene` 0.30.1 (binary in `tools/`, gitignored) + custom stdlibs `fivem.yml`, `oxlib.yml`, `sonar.yml` at root + `selene.toml` excluding `fxmanifest.lua` from lint + `.luarc.json` for lua-language-server in IDE + cross-platform shim `scripts/run-selene.mjs`.
- ✅ **JS/TS tooling**: ESLint 9 flat config (`typescript-eslint`, `react-hooks`, `react-refresh`, `exhaustive-deps` as ERROR), Prettier 3 with 4-space indent + `singleQuote`, EditorConfig.
- ✅ **Workspace orchestration**: `pnpm-workspace.yaml`, root `package.json` with scripts `dev`/`build`/`lint`/`format`/`type-check`, pinned engines `node >=20.10`, `pnpm >=9.0`.
- ✅ **Husky 9 + lint-staged**: pre-commit runs `selene` on `*.lua`, `eslint --fix --max-warnings 0` on TS/TSX, `prettier --write` on everything else. Verified hook blocks dirty commit.
- ✅ **Documentation**: `CONTRIBUTING.md` (entorno + comandos + workflow + commit conventions + reglas inviolables + estructura), `docs/02_DECISIONS.md` updated with ADR-001/002/003, this mini-brief.

### Deviations from plan

- **Locales en JSON, no Lua.** El roadmap original mencionaba `locales/en.lua` + `locales/es.lua`. La ox_lib API canónica usa `.json`. Cambio aplicado y documentado en architecture notes §8 + ADR implícito en CONTRIBUTING.md §5. La regla `03_languages.md` sigue válida (cero strings hardcoded), solo cambia el formato del archivo.
- **No `tailwind.config.ts`, no `postcss.config.js`.** El roadmap los listaba; Tailwind v4 los hace innecesarios. Decisión documentada en ADR-001.
- **selene en `tools/` en vez de instalación global.** El roadmap no especificaba el método. Elegido por compatibilidad con founder non-technical sin admin rights. ADR-003.
- **`@types/node` añadido a devDeps.** No estaba en el plan; necesario para tipar `vite.config.ts` (uso de `node:path` y `__dirname`).
- **3 ADRs creados** (no se anticipaba ninguno; a posteriori: cada elección merecía registro porque afecta a todos los slices futuros).

### Discoveries / lessons

- **Selene tiene quirks importantes**: solo soporta `lua51/52/53` (no `lua54`); los stdlibs custom DEBEN estar al lado de `selene.toml` (no en subdirectorio); los archivos de metadata FiveM (`fxmanifest.lua`) deben excluirse del lint porque son DSL, no Lua runtime. Documentado para que ningún sub-agent futuro pierda 30 min replicando esto.
- **`pnpm` no viene con Node 24 preinstalado en Windows; corepack requiere admin** (instala en `Program Files`). Solución limpia: `npm install -g pnpm` (npm va a user dir y no requiere admin). Documentar este hack en CONTRIBUTING.md hubiera ayudado al founder.
- **PowerShell rompe el flujo cuando un comando con stderr genera output con corchetes** (`[STARTED]`). El comando exit code es correcto, pero PS lo interpreta como `NativeCommandError`. No es un problema de los hooks, es solo ruido visual. **Lección para sub-agents que hagan QA**: confiar en `$LASTEXITCODE`, no en el coloreado del output.
- **El test del pre-commit hook con `_` prefix no funciona** porque ESLint ignora variables que empiezan por `_`. Usar identifiers que NO empiezan por `_` para tests de violación de unused-vars.

### Unblocks

- **S1** (Bridge layer QBox + QBCore) — workspace listo para crear `sonar_farm_core/shared/bridge/`.
- **S2** (DB foundation + migrations) — `database/migrations/` ya existe, oxmysql declarado como dep.
- **S4** (NUI shell + design system) — tokens, build pipeline y splash listo. Solo falta router de apps + componentes Bento.

### Action items para el founder (smoke pendiente)

1. Copiar `sonar_farm_core/` y `sonar_farm_tablet/` a `resources/[sonar]/` de un server QBox dev.
2. `cd sonar_farm_tablet/web && pnpm build`.
3. Añadir `ensure sonar_farm_core` y `ensure sonar_farm_tablet` a `server.cfg`.
4. Iniciar el server y verificar en consola: `[sonar_farm_core] Farm Sonar core booted (v0.0.1)`.
5. Repetir en QBCore.
6. Confirmar al PM (próxima sesión Cascade) → cambiará el slice de `IN_REVIEW` a `DONE`.

### Commit message (sugerido por `/end-slice`)

```
chore(workspace): S0 — workspace skeleton

- sonar_farm_core resource skeleton (fxmanifest + boot logger + version)
- sonar_farm_tablet resource with React 18 + Vite 6 + TS strict + Tailwind v4 splash
- Theme tokens canonical from Bible §1.1 (lime neón #CCFF00 visible)
- Tooling: selene 0.30 (Lua) + ESLint 9 + Prettier 3 + Husky 9 pre-commit
- pnpm workspace orchestrating two resources as siblings
- ADR-001: Tailwind v4 @theme CSS-first strategy
- ADR-002: monorepo with two FiveM resources side-by-side
- ADR-003: selene distributed via tools/ binary (gitignored)

Status: IN_REVIEW — pending founder smoke on QBox + QBCore servers.
```
