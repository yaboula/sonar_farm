# Contributing to Farm Sonar

> Internal development guide. Spanish founder-facing prose, English code/identifiers (per `[.windsurf/rules/03_languages.md](./.windsurf/rules/03_languages.md)`).

---

## 1. Lectura previa obligatoria

Antes de tocar código:

1. [`docs/00_BIBLE.md`](./docs/00_BIBLE.md) — producto canon (5 pilares, anti-features, stack).
2. [`docs/01_ROADMAP.md`](./docs/01_ROADMAP.md) — slices ordenados con DoD.
3. [`docs/03_AI_PLAYBOOK.md`](./docs/03_AI_PLAYBOOK.md) — sistema operativo (PM + sub-agents + workflows).
4. [`.windsurf/rules/`](./.windsurf/rules) — 5 reglas always-on (context, naming, languages, DoD, anti-patterns).

Si trabajas con AI agents (Cascade, Opus): usa los workflows `/start-slice`, `/spawn-pm`, `/end-slice` definidos en [`.windsurf/workflows/`](./.windsurf/workflows).

---

## 2. Setup del entorno local

### Requisitos

| Tool | Versión mínima | Razón |
|---|---|---|
| **Node.js** | `>= 20.10` | Vite 6, ESLint 9, TS 5.7 |
| **pnpm** | `>= 9.0` | Workspace + lockfile speed |
| **Git** | `>= 2.40` | Husky hooks |
| **selene** | latest | Lua linter — instalar vía `cargo install selene` o binario de [github.com/Kampfkarren/selene/releases](https://github.com/Kampfkarren/selene/releases) |
| **FiveM dev server** | latest | QBox **y** QBCore para smoke en ambos frameworks |

### Instalación

```bash
git clone https://github.com/yaboula/sonar_farm.git
cd sonar_farm
pnpm install
pnpm prepare    # configures husky hooks
```

### Comandos del workspace

```bash
pnpm dev          # Vite dev server NUI con HMR (localhost:3000)
pnpm build        # Build NUI a sonar_farm_tablet/web/dist
pnpm lint         # selene (Lua) + ESLint (TS) — 0 warnings
pnpm format       # Prettier --write en TS/JSON/MD/CSS
pnpm type-check   # tsc --noEmit estricto
```

---

## 3. Workflow por slice

Para CADA slice del roadmap:

1. **Sesión Cascade fresca** (no arrastrar contexto rancio entre slices).
2. Ejecutar `/start-slice <SXX>` → genera `docs/slices/<SXX>_<name>.md`.
3. Si complejidad **L** o **XL** → ejecutar `/spawn-pm` en sesión propia y abrir sesiones frescas para cada sub-agent (Backend / Frontend / Integration / QA).
4. Implementar siguiendo el mini-brief.
5. Commit local frecuente con mensajes en formato Conventional Commits.
6. Cuando se complete → ejecutar `/end-slice <SXX>` → verifica DoD universal (12 checks), actualiza Roadmap a `DONE`, genera commit final + ADRs si aplica.
7. `git push origin main`.

---

## 4. Convenciones de commit

Formato: **Conventional Commits**.

```
<type>(<scope>): <subject>

<body>

<footer>
```

| Type | Uso |
|---|---|
| `feat` | Nueva feature visible |
| `fix` | Bug fix |
| `chore` | Tooling, deps, infra (sin feature) |
| `docs` | Solo documentación |
| `refactor` | Cambio de código sin cambiar comportamiento |
| `test` | Solo tests |
| `perf` | Mejora de performance |

Scopes típicos: `core`, `tablet`, `bridge`, `banca`, `plot`, `crop`, `ui`, `db`, `workspace`.

Cierre de slice: `feat(<scope>): SXX — <slice name>` con footer `Closes SXX.`.

---

## 5. Reglas inviolables

- **Sin secretos en el repo.** API keys, tokens, IBANs reales → `.env` (gitignored).
- **Sin direct calls entre resources.** Eventos `sonar:farm:*` o `Bridge.*` (rule `05_anti_patterns.md` §1).
- **Sin hardcoded values.** Todo en `config/*.lua` (anti-pattern §3).
- **Sin strings user-facing hardcoded.** Todo en `locales/{en,es}.json` (rule `03_languages.md`).
- **Sin client-authoritative state.** Server siempre fuente de verdad (anti-pattern §2).
- **Lineage append-only.** `lineage_chain` nunca se muta, solo se extiende (anti-pattern §8).

Un sub-agent que viole cualquiera de estas → rechazar output, pegar la regla, pedir refactor.

---

## 6. Pre-commit hook

Husky corre `lint-staged` automáticamente en cada `git commit`:

- `*.lua` → `selene` (no errores).
- `sonar_farm_tablet/web/**/*.{ts,tsx}` → `eslint --fix --max-warnings 0`.
- `*.{ts,tsx,json,md,css}` → `prettier --write`.

Si el hook bloquea un commit, **no lo hagas con `--no-verify`**. Arregla el código.

**Excepción única**, documentada en ADR-004: el commit inicial de un slice cuando >20 archivos completamente nuevos disparen el bug de `lint-staged` + `--include-untracked` (los archivos quedan en el stash y prettier/eslint no los encuentran). En ese caso, sólo se permite tras validar manualmente que `pnpm lint && pnpm build` pasan, y SIEMPRE con un ADR aprobado en `docs/02_DECISIONS.md`.

---

## 7. Estructura del repo

```
.
├── .windsurf/                       Rules + workflows Cascade
├── .husky/                          Git hooks (pre-commit)
├── .selene/                         selene custom stdlibs (FiveM + ox_lib)
├── docs/                            Documentación canónica + slices + ADRs + spikes + research
├── sonar_farm_core/                 Lua server + client + shared (logic)
│   ├── server/                        Server services (FSMs, validations, DB)
│   ├── client/                        Client glue (anims, props, target zones)
│   ├── shared/                        Cross-side utilities
│   ├── config/                        Tunable constants per domain
│   ├── locales/                       en.json + es.json (ox_lib pattern)
│   └── database/migrations/           Versioned SQL migrations
└── sonar_farm_tablet/               NUI resource
    ├── client/                        NUI focus / messaging glue
    ├── locales/                       UI strings ES + EN
    └── web/                           React 18 + Vite + TS + Tailwind v4 SPA
        ├── src/                         App code
        └── dist/                        Built bundle (generated, not committed — see .gitignore)
```

---

## 8. Bugs / questions

- Issue tracker: privado por ahora (Tebex pre-launch).
- Para founder: chatear con Cascade en sesión fresca con `docs/03_AI_PLAYBOOK.md` cargado.
