# 📋 Farm Sonar — Architecture Decision Records (ADRs)

> **Propósito.** Registro append-only de decisiones de arquitectura no obvias o que afecten futuros slices.
>
> **Cuándo crear un ADR.** Cuando un slice tome una decisión que:
>
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

## ADR-011 — `batch_id` format: `sf-` prefix + 8 random hex chars

**Date:** 2026-05-22
**Status:** ACCEPTED
**Origin slice:** B1 (S7)

**Context.** Every harvested batch needs a unique, human-readable identifier that appears in logs, ox_inventory tooltips, DB audit rows, and future sale screens. UUID v4 (32 hex + 4 dashes) is standard but verbose; a shorter format is preferable for display without sacrificing practical uniqueness at RP server scale.

**Options considered:**

- **A** — UUID v4 (`xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx`). Pros: universally unique, standard. Cons: 36 chars, visually noisy in tooltips, over-engineered for < 1M batches/year.
- **B** — `sf-` + 8 random hex chars (e.g. `sf-a1b2c3d4`). Pros: short, readable, `sf-` prefix makes Farm Sonar IDs recognizable in any log, collision probability negligible at RP scale. Cons: not globally unique (acceptable — scoped to one server DB).
- **C** — Sequential integer. Pros: trivially short. Cons: leaks harvest volume to players; no prefix to identify origin.

**Decision:** **B**. `string.format('sf-%08x', math.random(0, 0xFFFFFFFF))`. Server-generated only (anti-pattern §2). Validated by regex `^sf%-[0-9a-f]{8}$` in `PhysicalItem.ValidateMetadata`.

**Consequences.**

- `sonar_farm_batches.batch_id` is `VARCHAR(32) PRIMARY KEY`.
- If a future vertical (Mill Sonar, etc.) produces items, they use a different prefix (`ms-`, `bs-`) to avoid cross-resource collisions.
- If server scale ever exceeds ~1M batches, revisit with UUID v4 and a new ADR.

---

## ADR-012 — Scheduler tick: configurable `Wait(N*1000)`, default 30 s, no per-frame polling

**Date:** 2026-05-22
**Status:** ACCEPTED
**Origin slice:** B1 (S6)

**Context.** The crop lifecycle scheduler must advance plot stages when `next_stage_ts <= now()`. Anti-pattern §4 forbids per-frame loops. The tick interval determines both responsiveness and server overhead.

**Options considered:**

- **A** — Per-frame loop (`Wait(0)`). Pros: instant transitions. Cons: forbidden by anti-pattern §4; burns CPU for a mechanic that changes at most 4 times per 18h cycle.
- **B** — Fixed 30 s tick hardcoded. Pros: simple. Cons: hardcoded magic number (anti-pattern §3).
- **C** — `Wait(Config.Farm.Scheduler.TickSeconds * 1000)`, default 30 s. Pros: configurable without code change; dev servers can set 5 s for fast testing; prod can increase to 60 s for lower overhead. Cons: stage transitions are not instant (acceptable — RP servers don't need sub-second crop transitions).

**Decision:** **C**. `Config.Farm.Scheduler.TickSeconds = 30` in `config.lua`. Scheduler queries only plots with `next_stage_ts <= UNIX_TIMESTAMP()` per tick — not all active crops.

**Consequences.**

- Stage transitions may lag up to `TickSeconds` behind the scheduled time. This is acceptable and expected.
- `/sonarfarm:debug:fastforward` sets `next_stage_ts` in the past; the scheduler picks it up on the next tick (≤ 30 s default).
- Future slices that need finer resolution (e.g. real-time pest spread) should introduce a separate domain scheduler rather than lowering this global tick.

---

## ADR-013 — `sonar_farm_crops` uses surrogate `INT AUTO_INCREMENT` PK (not `plot_id`)

**Date:** 2026-05-22
**Status:** ACCEPTED
**Origin slice:** B1 (S6)

**Context.** Unlike `sonar_farm_plots` (ADR-010, natural key `plot_id`), the crops table records individual planting events. A plot can be replanted many times; using `plot_id` as PK would prevent multiple records for the same plot (one active + historical).

**Options considered:**

- **A** — `plot_id VARCHAR(64) PRIMARY KEY`. Pros: matches ADR-010 style. Cons: prevents replanting history; DELETE on harvest is required (no audit trail of past harvests).
- **B** — Surrogate `INT UNSIGNED AUTO_INCREMENT PRIMARY KEY` + unique constraint `uq_sfcrop_plot (plot_id)` on active crops only. Pros: allows historical rows if ever needed (remove unique constraint later); surrogate FK is stable across `plot_id` renames; race condition protection from DB-level unique key. Cons: slightly more complex join.

**Decision:** **B**. Surrogate PK. Unique key `uq_sfcrop_plot` enforces the "one active crop per plot" invariant at DB level (complementing the service-layer check). On harvest, the crop row is deleted — no history kept in B1; a future slice (S11 or later) may repurpose the row as an archive by removing the unique constraint and adding a `harvested_at` column.

**Consequences.**

- `sonar_farm_batches.crop_id` FK references `sonar_farm_crops.id` (surrogate), not `plot_id`.
- Race condition protection: two simultaneous `Plant` calls produce a DB unique-key violation on the second insert, which the service catches and returns as `{ ok=false }`.

---

## ADR-014 — Slice Bundle pattern: pilot with B1 (S6+S7+S8), measure before formalizing

**Date:** 2026-05-22
**Status:** ACCEPTED
**Origin slice:** B1

**Context.** Roadmap slices S6+S7+S8 are explicitly marked as developing in parallel and closing together. The standard workflow (one mini-brief + one `/spawn-pm` per slice) would pay 3× context setup cost for contracts that are identical across the three slices. A "Slice Bundle" pattern groups them into one mini-brief, one prompts file, and one `/end-slice` call.

**Options considered:**

- **A** — Keep slice-per-slice workflow. Pros: lower risk, proven pattern. Cons: 3× redundant setup cost (~40-60 k tokens) for tightly coupled slices.
- **B** — Slice Bundle: one mini-brief (`B1_*.md`), one prompts file (`B1_*.prompts.md`), four horizontally-scoped sub-agent prompts (Backend → Integration + Frontend in parallel → QA). Pros: single §Contracts section paid once; sub-agents receive exact DB schemas, event payloads, and TypeScript interfaces without re-deriving them; DoD closed in one `/end-slice`. Cons: larger PR surface; if one sub-agent breaks the shared contract, it breaks N slices simultaneously; needs careful DoD tracking per slice within the bundle.

**Decision:** **B** as a pilot. No permanent methodology until B1 closes and results are measured.

**Bundle eligibility rules (provisional, to be hardened after pilot):**

1. Slices share a DB schema, event payload, or service API (acoplamiento de contrato).
2. Same technical surface (same files/sub-agents touched).
3. DoD of one cannot be verified without the others.
4. Aggregated complexity ≤ XL (≤ ~21 AI-days).

**B1 pilot results:**

- 4 sub-agents (Backend → Integration + Frontend → QA) executed across ~2 days.
- 16/16 unit tests green; QBox founder smoke PASS.
- Two documented deviations (cooldown→fallow lazy flip; NUI quality wire format gap) — both non-blocking and caught before close.
- Estimated token saving vs. 3 separate slices: ~35-45% setup overhead eliminated.

**Consequences.**

- `B2` (S13+S14+S15) and subsequent bundles may adopt this pattern if they meet the 4 eligibility rules.
- The `/end-slice` workflow should be extended to accept a bundle ID (`/end-slice B1`) and verify DoD per slice individually within the bundle closing report.
- If a future bundle produces more than 2 non-blocking deviations at QA stage, the pattern should be reconsidered for that bundle.

---

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

**Contexto.** El cierre del S0 introduce ~40 archivos nuevos en una sola operación (skeletons, configs, tooling). `lint-staged` 15 tiene un comportamiento conocido cuando >20 archivos completamente nuevos se commitean en bulk: durante su `git stash --keep-index --include-untracked`, los archivos nuevos quedan únicamente en el stash; los hooks (`prettier --write`, `eslint --fix`) no encuentran los archivos en el working tree y fallan con _"No files matching the pattern"_. El hook bloquea el commit aunque todos los linters pasan en `pnpm lint` standalone.

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

---

## ADR-005 — Diseño del Bridge layer (namespace, detección, Player shape, cobertura)

**Fecha:** 2026-05-19
**Estado:** ACCEPTED
**Slice origen:** S1

**Contexto.** El Bridge es la capa de abstracción que permite a Farm Sonar funcionar transparentemente sobre QBox y QBCore. Define la API que TODOS los slices futuros (S2-S35) consumen para acceder al jugador, dinero y notificaciones. Cualquier cambio posterior en sus contratos rompería N slices de golpe. Por tanto, las 4 decisiones de diseño se cierran HOY y se documentan con justificación textual del founder.

### Decisión 1 — Namespace global: `Sonar.Farm.Bridge.*`

**Opciones consideradas:**

- A — `Bridge.GetPlayer(src)` — global plano corto. Patrón de QBCore/QBX.
- B — `Sonar.Farm.Bridge.GetPlayer(src)` — anidado bajo `Sonar.Farm`.
- C — `Sonar.Bridge.GetPlayer(src)` — anidado bajo `Sonar` compartido entre verticales.

**Decisión:** **B**. Coherente con `Sonar.Farm.Version` (S0). Cero conflictos cross-resource. Cuando saquemos Mill Sonar / Bakery Sonar, cada vertical podrá tener su propio bridge bajo `Sonar.<Vertical>.Bridge` sin colisión con Farm.

**Consecuencias.**

- La rule `.windsurf/rules/02_naming_conventions.md` se actualiza para reflejar que el bridge se invoca como `Sonar.Farm.Bridge.PascalCase(args)` en vez de `Bridge.PascalCase(args)`.
- Los 5 anti-patrones de `05_anti_patterns.md` que mencionan `Bridge.GetPlayer(src)` también se actualizan.

### Decisión 2 — Estrategia de detección: híbrida (autodetect + convar override)

**Opciones consideradas:**

- A — Solo por presencia de exports.
- B — Solo por convar.
- C — Solo por dependency en fxmanifest.
- D — Híbrida: autodetect por defecto + convar opcional.

**Decisión:** **D**. Justificación textual del founder:

> "Plug & Play Real (Auto-detección): Para el 95% de los clientes, compran el script, lo meten en la carpeta `resources`, y arranca. El Bridge busca `exports.qbx_core` y `exports['qb-core']` y se configura solo. El 'Botón de Pánico' (Override): Para ese 5% de clientes con servidores raros, les pones en la documentación: 'Si el script no detecta tu framework, añade `setr sonar:framework qbcore` en tu server.cfg'. Les das una solución técnica sin que tengan que tocar tu código Lua."

**Consecuencias.**

- `init.lua` lee primero `GetConvar('sonar:framework', 'auto')`. Si es `'auto'`, autodetecta por exports. Si es `'qbox'` o `'qbcore'`, fuerza ese adapter (con warning si el export no existe).
- Si la autodetección falla (ningún export presente), el bridge entra en modo `_unsupported.lua` que loggea el mensaje canónico y desactiva todos los métodos públicos.
- Documentado en `CONTRIBUTING.md` para troubleshooting + en `INTERFACE.md` §Detection.

### Decisión 3 — Forma del objeto Player: POJO + funciones globales stateless

**Opciones consideradas:**

- A — POJO snapshot de solo lectura.
- B — Wrapper con métodos (`player:GetMoney('bank')`).
- C — POJO + funciones globales del bridge (`Bridge.AddMoney(src, ...)`).

**Decisión:** **C**. `Sonar.Farm.Bridge.GetPlayer(src)` devuelve una tabla congelada de datos. Las mutaciones SIEMPRE pasan por funciones del bridge globales que reciben `src`. Patrón de servicios stateless.

**Razones:**

- Refuerza Pillar **Server-Authoritative** del Bible §3 (las lecturas son snapshots, las escrituras son siempre intencionales).
- Stateless es testeable trivialmente (cada llamada es independiente).
- `src` jamás se pierde dentro de un wrapper que después se pasa entre threads.
- Si un slice tiene el POJO viejo y el dinero ha cambiado, está obligado a llamar a `GetPlayer(src)` de nuevo — no puede leer un valor staleness pensando que es actual.

**Forma exacta del POJO** (contrato congelado):

```lua
{
    src         = number,        -- player source (FiveM net ID)
    citizen_id  = string,        -- canonical player identifier
    name        = string,        -- "FirstName LastName" combinado
    job_name    = string,        -- e.g. "farmer"
    job_grade   = number,        -- 0..N, framework-defined
    cash        = number,        -- saldo cash (actual al momento de la llamada)
    bank        = number,        -- saldo bank
    framework   = string,        -- "qbox" | "qbcore" (info-only, no usar para branching)
}
```

### Decisión 4 — Cobertura inicial: 5 métodos mínimos (just-in-time)

**Opciones consideradas:**

- A — Mínima: 5 métodos.
- B — Estándar: ~10 métodos.
- C — Exhaustiva: ~15-20 métodos.

**Decisión:** **A**. Solo los 5 métodos imprescindibles para `/sonarfarm:bridgetest` (S1) + S2 (DB) + S3 (Banca):

1. `Sonar.Farm.Bridge.GetPlayer(src) -> Player | nil`
2. `Sonar.Farm.Bridge.AddMoney(src, account, amount, reason) -> ok, error`
3. `Sonar.Farm.Bridge.RemoveMoney(src, account, amount, reason) -> ok, error`
4. `Sonar.Farm.Bridge.GetMoney(src, account) -> number`
5. `Sonar.Farm.Bridge.Notify(src, message, type) -> nil`

Donde `account ∈ {'cash', 'bank'}` y `type ∈ {'success', 'error', 'info', 'warning'}`.

**Razones.**

- YAGNI per Bible §6.
- Cada slice futuro que requiera un método nuevo debe justificarlo en su mini-brief y añadirlo via PR al bridge con tests propios.
- Reduce la superficie de testing en S1 (testear 5 métodos × 2 frameworks = 10 cases vs 20 o 40).

**Consecuencias del paquete completo (D1+D2+D3+D4).**

- INTERFACE.md documenta exhaustivamente estos 5 métodos + el contrato del POJO.
- Slices S2-S5 que necesiten p.ej. `GetIdentifier`, `RegisterUsableItem`, `GetPlayers`, etc. los añadirán con su propio mini-ADR.
- La regla `02_naming_conventions.md` queda actualizada con `Sonar.Farm.Bridge.PascalCase(args)`.

---

## ADR-006 — Acabado de superficies: Flat Minimalista sobre Glassmorphism

**Fecha:** 2026-05-19
**Estado:** ACCEPTED
**Slice origen:** Foundation doc (`04_UI_PLAYBOOK.md` v1)
**Supersedes:** parcialmente Bible §1 línea 33 (que firmaba "Glassmorphism cards").

**Contexto.** Bible §1 firmó "Glassmorphism cards" como acabado de tarjetas Bento, alineado con Arc Browser y la moda 2023-2024. Al refinar la paleta en sesión dedicada UI (founder + Cascade PM) usando AgriSphere como ancla visual de referencia, surgió un acabado distinto: tarjetas blancas puras flat con borde 1px sutil. Coexistían dos direcciones; había que elegir antes de v0.dev y antes de S4.

**Opciones consideradas:**

- **A** — Mantener glassmorphism (`bg-white/70` + `backdrop-blur-md` + sombra suave). Pros: efecto premium moderno, alineado con Arc/Linear 2023. Contras: en NUI in-game 960×540 el blur lee como "borroso/sucio"; sobre background ya claro (`#D9EAE3`) el contraste es demasiado bajo y los datos densos (Stripe-like) se vuelven ilegibles; degrada la legibilidad de la tipografía Geist 400/500 que es nuestra única jerarquía.
- **B** — Flat minimalista (`bg-white` puro `#FFFFFF`, `shadow-none`, `border-1` color `#969C9C/20`). Pros: legibilidad máxima sobre menta, encaja con tono "Calm-Tech / iPad-like / AgriSphere", la jerarquía depende del whitespace + contraste con `--fs-nav` negro, escala mejor a densidad de datos. Contras: sacrifica el efecto "wow" de glass que era parte de la identidad propuesta inicialmente.

**Decisión:** **B**. Flat minimalista es la firma de superficies de Farm Sonar a partir de v1.2 del Bible. El "wow" se traslada a otros vectores: pulso lima `#B6FB63` (`<LimePulse>`), micro-motion calm (futuro UI Playbook v2), y composición Bento generosa (gap 16px + rounded-2xl + padding comfortable).

**Consecuencias.**

- Bible §1 línea 33 actualizada: `Glassmorphism cards` → `Flat minimalista cards (white #FFFFFF, 1px border)`.
- Bible §1.1 actualizada: tabla de paleta pasa de "valor propuesto" a **firmado v1.2** con los hex finales (ver `04_UI_PLAYBOOK.md` para la justificación visual y `00_BIBLE.md §18` para el bump de versión).
- Componente custom `<GlassCard>` propuesto en sesiones previas queda **descartado**. Los custom signatures firmados son: `<BentoGrid>`, `<BentoGrid.Item>`, `<BatchChip>`, `<LimePulse>`.
- shadcn/ui `Card` se usa stock con override de estilos (`bg-white border-fs-border/20 shadow-none rounded-2xl p-6`).
- Cualquier slice futuro que quiera reintroducir blur/shadow debe abrir nuevo ADR superseding este.

---

## ADR-007 — Cerrar S2 con smoke runtime parcial documentado

**Fecha:** 2026-05-19
**Estado:** ACCEPTED
**Slice origen:** S2

**Contexto.** S2 implementa infraestructura DB/migrations común a QBox y QBCore, sin llamadas a framework ni Bridge. QA verificó clean boot, idempotency y rollback en QBox, pero no había entorno QBCore disponible al cierre y el smoke runtime DB-unreachable no se ejecutó. El founder decidió no bloquear S3 por validaciones runtime pendientes que se repetirán al cierre de la fase completa.

**Opciones consideradas:**

- **A** — Mantener S2 `ACTIVE/IN_REVIEW` hasta disponer de QBCore y ejecutar DB-unreachable. Pros: DoD literal intacto. Contras: bloquea S3 aunque el código S2 no depende de framework y el fail-fast está cubierto por code path.
- **B** — Cerrar S2 con excepción documentada y deuda QA explícita para cierre de Fase 0. Pros: permite avanzar a S3; la desviación queda visible. Contras: relaja temporalmente el DoD universal/runtime.

**Decisión:** **B**. S2 se cierra con excepción controlada: QBCore runtime smoke y DB-unreachable runtime smoke se difieren hasta el cierre de Fase 0, antes de considerar completa la fase foundation.

**Consecuencias.**

- `docs/slices/S2_db_foundation.md` registra la excepción y conserva evidencia de QBox A/B/C.
- Roadmap marca S2 `DONE` con nota de QBCore smoke deferred.
- Antes de cerrar Fase 0 completa, se deben ejecutar los smokes QBCore y DB-unreachable para S2 o abrir un nuevo ADR si siguen imposibles.

---

## ADR-008 — Design Farm finance as a compatibility adapter layer, not a hard bank dependency

**Date:** 2026-05-19
**Status:** ACCEPTED
**Origin slice:** S3

**Context.** The founder already has a separate advanced `sonar_bank` / `sonar_bank_app` ecosystem, but Farm Sonar must ship as an independent farming script. Roadmap S3 originally implied that Farm Banca would become the source of truth and framework money would become a mirror. That would make Farm Sonar harder to install on QBox/QBCore servers that already use qb-banking, Renewed Banking, okokBanking, qs-style banking or similar stacks.

**Options considered:**

- **A** — Make Farm Banca the mandatory source of truth and mirror framework money. Pros: strongest internal consistency. Cons: conflicts with existing server banks and violates the plug-and-play promise.
- **B** — Depend directly on `sonar_bank` when present. Pros: reuses the advanced Sonar bank. Cons: creates a hard cross-resource dependency and blocks standalone customers.
- **C** — Build a Farm finance adapter layer. Pros: standalone by default, compatible with QBox/QBCore native money and future external bank adapters; `sonar_bank` can be integrated later as one adapter. Cons: less feature-rich in S3 than a full bank.

**Decision:** **C**. S3 is a finance compatibility layer with an internal Farm audit ledger, not a full mandatory bank replacement.

**Consequences.**

- Farm Sonar never hard-depends on `sonar_bank`, `sonar_bank_app`, Renewed, okok, qs or any other bank resource.
- Money mutations go through a Farm finance adapter contract and record Farm-local movements for audit/idempotency.
- QBox/QBCore native money via `Sonar.Farm.Bridge` is the baseline adapter.
- Future adapters may support `sonar_bank`, Renewed Banking, okokBanking, qs-style banking or custom server banks when their API is verified.

---

## ADR-009 — Close S3 with QBCore finance smoke deferred to Phase 0 closure

**Date:** 2026-05-19
**Status:** ACCEPTED
**Origin slice:** S3

**Context.** S3 implements the Farm finance compatibility layer on top of `Sonar.Farm.Bridge` and validates the QBox path with runtime smoke run `1779208796`. The baseline `native_bridge` adapter contains no QBox/QBCore direct calls; framework-specific behavior remains in the S1 Bridge. A QBCore runtime environment was still unavailable at S3 closure, matching the Phase 0 constraint already documented by ADR-007 for S2.

**Options considered:**

- **A** — Keep S3 open until QBCore runtime smoke is available. Pros: literal universal DoD compliance. Cons: blocks the roadmap even though S3 uses the already-reviewed Bridge boundary and has no QBCore-specific finance code.
- **B** — Close S3 with a documented exception and require QBCore finance smoke before closing Phase 0. Pros: preserves momentum and keeps the debt visible. Cons: temporarily relaxes runtime verification.

**Decision:** **B**. S3 is closed with QBCore finance smoke deferred to Phase 0 closure.

**Consequences.**

- `docs/slices/S3_finance_compatibility_layer.md` records QBox PASS and QBCore DEFERRED.
- Before Phase 0 can be considered complete, QBCore smoke must cover S1 Bridge, S2 DB boot and S3 finance credit/debit/idempotency paths.
- Any QBCore-specific failure found later must be fixed upstream in `Sonar.Farm.Bridge` or the finance adapter contract, not patched downstream in gameplay slices.

---

## ADR-010 — Plot identity as config-owned natural key + idempotent seed sync semantics

**Date:** 2026-05-19
**Status:** ACCEPTED
**Origin slice:** S5

**Context.** S5 needs to persist 8 MLO plots that are pre-defined in config (Roadmap S5 defers placement GUI). Two non-obvious decisions had to be made before implementation: (1) the shape of `plot_id` (surrogate auto-increment vs. natural key driven by config), and (2) what happens to a row when the founder edits `config/plots.lua` and runs `/sonarfarm:plots:reload` against a server where `soil_score`, `state`, `planted_ts` or `next_stage_ts` already carry gameplay value.

**Options considered:**

- **A — Surrogate `INT` `plot_id` + separate `config_key`.** Pros: classic relational identity, immutable PK across renames. Cons: every other slice (S6 batches, S7 inventory `origin.plot_id`, S27 tablet routing) would have to join through `config_key` to talk about a plot, and the config still has to provide a stable identifier anyway. Adds a layer with no real benefit for a registry of 8-30 fixed plots.
- **B — Config-owned `VARCHAR(64)` natural key as PK + reload preserves gameplay-owned columns.** Pros: zero indirection between config and DB; `lineage_chain` and `origin.plot_id` references in future slices stay human-readable; reload is safe to run on live servers because `state`/`soil_score`/`planted_ts`/`next_stage_ts` are never overwritten by config. Cons: renaming a `plot_id` orphans the previous row instead of mutating it in place; documented as a deliberate constraint.
- **C — Config-owned natural key as PK but reload resets every column from config.** Pros: trivially simple. Cons: `/sonarfarm:plots:reload` would silently destroy `soil_score` progress and reset live planted plots back to `fallow`, which is a footgun and breaks Bible §13.2 "downtime-safe" guarantee.

**Decision:** **B**. `plot_id` is a config-owned `VARCHAR(64)` primary key. `PlotService.SyncSeededPlots` distinguishes config-owned columns (`plot_type`, `display_name_key`, `coords_x`, `coords_y`, `coords_z`, `radius`) from gameplay-owned columns (`state`, `soil_score`, `planted_ts`, `next_stage_ts`, `last_updated_ts`). Reload may update the former and may insert missing rows, but never resets the latter. Renaming a `plot_id` is treated as a deprecation of the old row plus creation of a new row, never an in-place rename.

**Consequences.**

- `sonar_farm_plots.plot_id` is `VARCHAR(64) PRIMARY KEY`; future foreign keys (`sonar_farm_batches.origin_plot_id`, etc.) will use the same shape.
- `/sonarfarm:plots:reload` is safe to run on a live server.
- The Backend service exposes `PlotService.UpdatePlotState(plot_id, patch, reason)` with a strict allowlist of patchable fields (`state`, `soil_score`, `planted_ts`, `next_stage_ts`); config-owned columns are unreachable from this entry point on purpose.
- Removing a plot from `config/plots.lua` does **not** delete the DB row. Cleanup of orphaned plots is deferred to a future admin tool with explicit confirmation.
- If a future slice ever needs to rename a `plot_id`, the migration must be authored by hand (insert new row with carried-over `soil_score`, then delete old row) and accompanied by a new ADR.

---

## ADR-015 — ox_inventory dual-write via post-hook event (not validation hook)

**Date:** 2026-05-22
**Status:** ACCEPTED
**Origin slice:** B2 (S9)

**Context.** S9 storage needs to mirror ox_inventory stash operations to `sonar_farm_storage_contents` for audit and freshness tracking. ox_inventory provides `registerHook('swapItems')` with two phases: validation callback (pre-swap) and post-hook event (after swap succeeds). The audit write must happen only after the inventory move succeeds, but ox_inventory docs state validation callbacks should avoid side effects.

**Options considered:**

- **A** — Write audit row inside validation callback. Pros: single code path. Cons: violates ox_inventory docs (validation should be pure); if the swap fails after validation, audit row is orphaned; no rollback mechanism.
- **B** — Write audit row in post-hook event using the returned `hookId`. Pros: audit only written after successful swap; matches ox_inventory recommended pattern; can implement rollback (delete row) if DB write fails. Cons: dual-write pattern (inventory + DB) cannot be ACID across systems; requires explicit error handling.
- **C** — Skip audit layer, trust ox_inventory stash as source of truth. Pros: simpler. Cons: no freshness tracking in DB; no audit trail for sales; future slices (S19 freshness decay) need DB metadata.

**Decision:** **B**. Use `exports.ox_inventory:registerHook('swapItems', nil, { inventoryFilter = { '^sonar_farm_silo_' } })` to get `hookId`, then `AddEventHandler(hookId, function(success, payload) ... end)` for audit writes. On DB write failure, attempt to restore the item via `exports.ox_inventory:RemoveItem` and roll back `sold_ts` if sale path.

**Consequences.**

- `sonar_farm_storage_contents` is an audit layer, not the source of truth. ox_inventory stash is authoritative for item presence.
- Cross-system ACID is impossible; B2 documents the limitation and implements best-effort rollback.
- Future storage slices (S13 cold storage, S28 drone silo) must follow the same post-hook pattern.
- If ox_inventory changes hook API, this ADR may need superseding.

---

## ADR-016 — Persist explicit offline risk timestamps in `sonar_farm_quality_tracking`

**Date:** 2026-05-22
**Status:** ACCEPTED
**Origin slice:** S11

**Context.** Bible §13.2 requires offline reconciliation on boot with capped negative accumulation for missed irrigation and untreated pests. Current B1 quality rows only stored current factor scores (`irrigation`, `pest_impact`) but not *when* an offline risk started. Inferring risk start from the score alone is ambiguous and non-idempotent.

**Options considered:**

- **A** — Infer offline penalties from current factor score only. Pros: no migration. Cons: cannot know when the missed irrigation / pest actually started; repeated boots become guessy; violates the risk-first intent of S11.
- **B** — Persist explicit nullable timestamps (`next_irrigation_due_ts`, `pest_detected_ts`) in `sonar_farm_quality_tracking`. Pros: deterministic boot reconciliation; future S13/S15 trackers can set/clear them naturally; works with current schema. Cons: adds a migration before the full irrigation / pest gameplay loops exist.
- **C** — Create a separate offline-events table. Pros: more extensible. Cons: over-engineered for current slices; extra joins and write paths.

**Decision:** **B**. Add `next_irrigation_due_ts` and `pest_detected_ts` to `sonar_farm_quality_tracking` via migration `010_quality_offline_tracking.sql`. S11 reads these timestamps to compute capped offline penalties; future slices own writing them.

**Consequences.**

- S11 is deterministic and idempotent across immediate reboots.
- S13 irrigation and S15 pest gameplay should update these fields rather than inventing separate offline markers.
- If future quality risks need offline accumulation, extend the same row before introducing a new table.
