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
