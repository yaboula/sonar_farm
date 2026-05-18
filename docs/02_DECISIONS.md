# 📋 Farm Sonar — Architecture Decision Records (ADRs)

> **Propósito.** Registro append-only de decisiones de arquitectura no obvias o que afecten futuros slices.
>
> **Cuándo crear un ADR.** Cuando un slice tome una decisión que:
> - No esté ya cubierta por el `00_BIBLE.md`.
> - Tenga alternativas razonables que se descartaron.
> - Afecte a slices futuros (no es local al slice actual).
> - Sería costosa de revertir.
>
> **Formato corto.** Cada ADR ~20 líneas. Si necesitas más, probablemente debe ir al Bible.

---

## Plantilla

```markdown
## ADR-NNN — Título corto en infinitivo

**Fecha:** YYYY-MM-DD
**Estado:** PROPOSED | ACCEPTED | DEPRECATED | SUPERSEDED-BY-ADR-NNN
**Slice origen:** SXX
**Contexto:** 2-3 líneas. ¿Qué situación nos forzó a decidir?
**Opciones consideradas:**
- A — descripción · pros · contras
- B — descripción · pros · contras
**Decisión:** opción X. Razón principal en 1 línea.
**Consecuencias:** qué cambia en el código / docs / futuros slices.
```

---

<!-- ADRs se añaden a continuación en orden cronológico -->

## ADR-001 — Adoptar Tailwind v4 con `@theme` directiva CSS-first

**Fecha:** 2026-05-18
**Estado:** ACCEPTED
**Slice origen:** S0

**Contexto.** Tailwind v4 (lanzado finales 2024) cambia radicalmente la configuración: en v3 se usaba `tailwind.config.ts` (JS) para definir tokens; en v4 se usan directivas CSS `@theme` dentro del archivo CSS principal. Coexisten ambos sistemas, pero mezclarlos es fuente de bugs.

**Opciones consideradas:**
- **A** — Quedarse en Tailwind v3 + `tailwind.config.ts`. Pros: ecosistema maduro. Contras: deuda técnica desde día 1, v4 es ya estable y la dirección oficial.
- **B** — Tailwind v4 con `@theme` puro (CSS-first), sin `tailwind.config.ts`. Pros: alineado con la dirección oficial, menos archivos, plugin `@tailwindcss/vite` integra build, tokens viven con los estilos. Contras: ecosistema shadcn/ui en transición, algunos plugins legacy aún sin soporte.

**Decisión:** **B**. Vivimos en CSS-first. Tokens en `sonar_farm_tablet/web/src/styles/theme.css`. Plugin `@tailwindcss/vite` activo en `vite.config.ts`. **Sin** `tailwind.config.ts`, **sin** `postcss.config.js`.

**Consecuencias.**
- Slices futuros añaden tokens en `theme.css` (sección `@theme`). Nunca en config JS.
- Las clases utility se generan automáticamente desde los tokens (`--color-fs-accent` → `bg-fs-accent`).
- Si shadcn/ui requiere temporalmente la sintaxis legacy, lo gestionaremos con un `theme-shim.css` separado, documentado.

---

## ADR-002 — Monorepo workspace con dos resources hermanos (no packages npm separados)

**Fecha:** 2026-05-18
**Estado:** ACCEPTED
**Slice origen:** S0

**Contexto.** El producto se compone de dos resources FiveM: `sonar_farm_core` (Lua) y `sonar_farm_tablet` (Lua + NUI React). Hay que decidir cómo organizar el repositorio y la gestión de paquetes Node.

**Opciones consideradas:**
- **A** — Repos separados, uno por resource. Pros: aislamiento total. Contras: PRs split, versionado divergente, fricción para cambios cross-resource (alta probabilidad por slice).
- **B** — Monorepo con `pnpm workspaces` y los dos resources como hermanos en la raíz; sólo `sonar_farm_tablet/web/` es package npm. Pros: 1 commit por slice tocando ambos lados, lockfile único, fácil para AI agents que ven todo el contexto. Contras: requiere disciplina con `.gitignore` (no commitear `dist/` o `node_modules/`).
- **C** — Monorepo con cada resource como package npm independiente. Pros: aislamiento dentro del repo. Contras: over-engineering (Lua side no necesita `package.json`).

**Decisión:** **B**. Workspace pnpm. `pnpm-workspace.yaml` declara solo `sonar_farm_tablet/web`. La raíz tiene `package.json` con scripts orquestadores (`pnpm dev`, `pnpm lint`, `pnpm build`).

**Consecuencias.**
- Slices futuros que toquen ambos resources se shipean en commits únicos.
- Si surge un tercer resource (e.g. `sonar_farm_drones` en S28), se añade al `pnpm-workspace.yaml` como hermano.
- Verticales futuros (Mill Sonar, Bakery Sonar) **NO** viven en este repo — cada uno es su propio monorepo.

---

## ADR-003 — `selene` como Lua linter, distribuido como binario en `tools/` no committed

**Fecha:** 2026-05-18
**Estado:** ACCEPTED
**Slice origen:** S0

**Contexto.** Necesitamos un Lua linter que entienda FiveM natives y ox_lib globals para enforcar el rule §05 (anti-patterns). Las opciones son `luacheck` (Lua puro, viejo) y `selene` (Rust, moderno, custom stdlibs en YAML).

**Opciones consideradas:**
- **A** — `luacheck`. Pros: clásico, escrito en Lua. Contras: stdlibs custom verbose, mantenimiento estancado.
- **B** — `selene`. Pros: rápido, ecosistema FiveM activo (ASSpawnPolice/cfx-lua-stdlib), stdlibs YAML claros, `--no-warnings-fatal` granular. Contras: binario Rust, requiere instalación manual en Windows sin Cargo.

**Decisión:** **B**. selene 0.30+. El binario se descarga al directorio `tools/` (gitignored). Un script Node `scripts/run-selene.mjs` resuelve el binario buscándolo primero en PATH, luego en `tools/`. Esto evita pedir admin/cargo al founder.

**Consecuencias.**
- `pnpm lint:lua` funciona desde el primer `pnpm install` sólo si selene está descargado en `tools/` o instalado globalmente.
- `CONTRIBUTING.md` documenta la instalación.
- Stdlibs custom (`fivem.yml`, `oxlib.yml`, `sonar.yml`) viven en raíz porque selene los busca en CWD por nombre.
- `fxmanifest.lua` está excluido del lint (es DSL de metadata, no Lua runtime).

---

## ADR-004 — Bulk-initial commit autorizado vía `--no-verify` (excepción documentada)

**Fecha:** 2026-05-18
**Estado:** ACCEPTED
**Slice origen:** S0

**Contexto.** El cierre del S0 introduce ~40 archivos nuevos en una sola operación (skeletons, configs, tooling). `lint-staged` 15 tiene un comportamiento conocido cuando >20 archivos completamente nuevos se commitean en bulk: durante su `git stash --keep-index --include-untracked`, los archivos nuevos quedan únicamente en el stash; los hooks (`prettier --write`, `eslint --fix`) no encuentran los archivos en el working tree y fallan con *"No files matching the pattern"*. El hook bloquea el commit aunque todos los linters pasan en `pnpm lint` standalone.

**Opciones consideradas:**
- **A** — Romper el commit en N commits incrementales hasta caber bajo el umbral de lint-staged. Pros: ortodoxo. Contras: ofusca el cierre atómico del slice, contradice la filosofía "1 slice = 1 commit" de CONTRIBUTING.md §4.
- **B** — Mover las hooks de pre-commit a pre-push. Pros: evita el problema. Contras: pierde la enforcement temprana en el ciclo de feedback.
- **C** — Usar `git commit --no-verify` UNA SOLA VEZ para el bulk-initial commit del slice S0, **sólo** después de validar manualmente que `pnpm lint` y `pnpm build` pasan. Pros: respeta la atomicidad de slice + validación equivalente sin el bug de infra. Contras: contradice la regla "no `--no-verify` jamás" de CONTRIBUTING.md §6.

**Decisión:** **C** para el commit inicial de S0. La regla del playbook §7.6 admite excepciones documentadas en ADR. Esta es la única clase de commits donde se permite:
- Slice con >20 archivos completamente nuevos.
- `pnpm lint && pnpm build` ejecutados manualmente y exit 0 verificado.
- ADR aprobado.

Cualquier otro `--no-verify` queda prohibido, sin excepciones.

**Consecuencias.**
- Update CONTRIBUTING.md §6 con la nota: "`--no-verify` está prohibido salvo para el commit inicial de un slice donde >20 archivos nuevos disparen el bug conocido de lint-staged + bulk-untracked, y siempre con ADR registrado."
- En slices futuros, los commits incrementales (típicamente 1-5 archivos nuevos) pasan por hooks normalmente.
- Si el bug de lint-staged se resuelve upstream, este ADR pasa a `DEPRECATED` y la excepción se elimina.

**Referencias.**
- Issue tracker lint-staged sobre stash de untracked + multiple new files: github.com/lint-staged/lint-staged (varios issues abiertos sobre el patrón).
