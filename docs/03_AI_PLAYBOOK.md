# 🤖 Farm Sonar — AI Playbook

> **Versión:** 1.0 (firmada, living document).
> **Fecha:** 2026-05-04.
> **Lectura previa:** `docs/00_BIBLE.md` + `docs/01_ROADMAP.md`.
> **Propósito:** definir cómo trabajamos los humanos + AI agents para construir Farm Sonar de forma eficiente, repetible y sin perder calidad entre sesiones.

---

## 0. Cómo se usa este documento

Este Playbook describe **el sistema operativo** del proyecto: cómo arrancan las sesiones, cómo se reparte el trabajo entre agentes, cómo se cierra un slice, qué herramientas activar y cuándo.

- Lo lee Cascade en cada sesión nueva (vía rules `01_farm_sonar_context.md`).
- Lo lee el founder cuando duda sobre el siguiente paso operacional.
- Se actualiza cuando aprendamos algo que vale la pena codificar como proceso (no por cada experimento).

**No describe el producto** — eso es Bible. **No describe el plan** — eso es Roadmap. Este describe **cómo trabajamos**.

---

## 1. Principio operativo central

> **Cada slice se ejecuta en una o varias sesiones frescas, coordinadas por un PM Agent que delega a 2-4 sub-agents especializados, todos guiados por las foundation docs (Bible + Roadmap + AI Playbook + slice mini-brief).**

Esto se traduce en 4 reglas de oro:

1. **Sesiones frescas por slice o fase.** No dejamos sesiones eternas que arrastran contexto rancio. Cuando cambia el slice, cerramos sesión y abrimos otra.
2. **Cada sesión empieza leyendo las foundation docs** (vía rules always-on; el founder no tiene que recordarlo).
3. **PM Agent reparte, sub-agents ejecutan.** Cascade no programa todo a la vez en una sesión maratón — divide y vencerás.
4. **DoD universal antes de cerrar.** Sin excepciones. El workflow `/end-slice` lo enforce.

---

## 2. Capacidades de Cascade activadas

Hemos activado el conjunto completo de capacidades de Cascade para este proyecto:

### 2.1 Rules (`.windsurf/rules/*.md`)

Reglas siempre activas, leídas automáticamente en cada sesión:

| Archivo                    | Qué impone                                                                                      |
| -------------------------- | ----------------------------------------------------------------------------------------------- |
| `01_farm_sonar_context.md` | Identidad del proyecto + orden de lectura de foundation docs + perfil del founder.              |
| `02_naming_conventions.md` | DB `sonar_farm_*`, eventos `sonar:farm:*`, archivos snake/PascalCase, etc.                      |
| `03_languages.md`          | Inglés en código, español sólo en docs founder-facing, i18n obligatorio en strings UI.          |
| `04_dod_universal.md`      | Los 12 checks universales antes de cerrar slice.                                                |
| `05_anti_patterns.md`      | 10 anti-patrones técnicos prohibidos (no llamadas directas entre resources, server-auth, etc.). |

**Estas reglas se aplican a TODO agente Cascade del proyecto sin excepción.** Si un sub-agent las viola, el founder debe rechazarlo.

### 2.2 Workflows (`.windsurf/workflows/*.md`)

Comandos slash invocables por el founder o por Cascade en cualquier momento:

| Workflow             | Cuándo usarlo                                                                                        |
| -------------------- | ---------------------------------------------------------------------------------------------------- |
| `/start-slice <SXX>` | Al arrancar un slice. Lee contexto, crea mini-brief, planifica todo list.                            |
| `/spawn-pm`          | Cuando un slice es complejo (L o XL). Cascade adopta rol PM y genera prompts para sub-agents.        |
| `/end-slice <SXX>`   | Antes de marcar un slice DONE. Verifica DoD universal + específico, actualiza Roadmap, registra ADR. |
| `/spike <topic>`     | Cuando hay incógnita técnica time-boxed (ej. R2 drones NUI viability).                               |
| `/research <topic>`  | Cuando necesitas docs externas (QBox/QBCore/ox_lib/cfx-re/shadcn). Sale reporte con citas.           |
| `/ui-design <app>`   | Antes de implementar una app NUI. Genera brief para v0.dev + review checklist.                       |

### 2.3 Tools (built-in de Cascade)

Cascade tiene acceso nativo a:

- **`code_search`** — explora la codebase semánticamente. Primer paso para cualquier exploración.
- **`grep_search`** — búsqueda regex precisa.
- **`find_by_name`** — localiza archivos por patrón.
- **`read_file`** — lee con número de línea (citaciones precisas).
- **`search_web`** — Google search desde Cascade.
- **`read_url_content`** — fetch de URL específica + chunking.
- **`run_command`** — ejecuta PowerShell con confirmación del founder.
- **`browser_preview`** — preview HTTP de servidores dev (Vite NUI).
- **Memory system** — persistencia de decisiones cross-session.

### 2.4 Skills externas

| Tool                              | Para qué                                            | Cuándo                                                                                                                 |
| --------------------------------- | --------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **v0.dev**                        | UI mockups React + Tailwind + shadcn.               | Antes de cualquier slice con UI nueva. Workflow `/ui-design` lo coordina.                                              |
| **Claude Opus** (sesión separada) | Implementación profunda de slices grandes (XL).     | Cuando PM Agent decide que un sub-agent backend o frontend necesita un modelo más potente para una sub-tarea concreta. |
| **Figma** (opcional, fase 2+)     | Wireframes de flujos completos (no por componente). | Cuando v0.dev no basta para diseñar un flujo multi-pantalla.                                                           |

---

## 3. Flujo macro de un slice

Pipeline canónico desde "vamos a hacer SXX" hasta "SXX cerrado y DONE":

```
┌─────────────────────────────────────────────────────────────────────┐
│ 1. /start-slice SXX                                                 │
│    ↓                                                                │
│ 2. Cascade lee Bible + Roadmap + AI Playbook + dependencias         │
│    ↓                                                                │
│ 3. Crea docs/slices/SXX_<name>.md desde _TEMPLATE                   │
│    ↓                                                                │
│ 4. Roadmap: PLANNED → ACTIVE                                        │
│    ↓                                                                │
│ 5. ¿Complejidad ≥ L?                                                │
│    ├─ Sí → /spawn-pm                                                │
│    │       ↓                                                        │
│    │       PM Agent genera SXX_<name>.prompts.md                    │
│    │       ↓                                                        │
│    │       Founder abre 2-4 sesiones frescas, una por sub-agent     │
│    │       ↓                                                        │
│    │       Sub-agents implementan en paralelo o secuencia           │
│    │       ↓                                                        │
│    │       Founder integra outputs (commits)                        │
│    └─ No → Cascade implementa directo en sesión actual              │
│    ↓                                                                │
│ 6. Smoke test manual en QBox + QBCore                               │
│    ↓                                                                │
│ 7. /end-slice SXX                                                   │
│    ↓                                                                │
│ 8. DoD check (12 universales + específicos)                         │
│    ├─ Falla algún check → vuelve a paso 5/6                         │
│    └─ Todo OK → Roadmap: ACTIVE → DONE                              │
│                ↓                                                    │
│                ADR si aplica + Bible §18 changelog si aplica        │
│                ↓                                                    │
│                Commit con mensaje conventional                      │
│                ↓                                                    │
│                ✅ Slice cerrado                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 4. Sistema PM + Sub-agents

### 4.1 Rol del PM Agent

Cuando se invoca `/spawn-pm`, **Cascade adopta el rol de PM Agent en esa sesión**. Reglas:

- **NO programa producción** — sólo planifica y delega.
- **NO toma decisiones arquitectónicas unilateralmente** — eso pertenece al founder + Bible + ADRs.
- **SÍ descompone el slice** en trabajo discreto por especialidad.
- **SÍ produce un solo artefacto**: `docs/slices/<SXX>_<name>.prompts.md`.

### 4.2 Las 4 especialidades fijas

| Sub-agent             | Owns                                                                                                                                                 |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Backend Agent**     | Lua server-side, DB migrations, services, FSMs, eventos `sonar:farm:*`, validaciones server-authoritative, lógica económica.                         |
| **Frontend Agent**    | React 18 + TS strict + Tailwind v4 + shadcn + Framer Motion, NUI shell, Bento apps, Recharts.                                                        |
| **Integration Agent** | Capa `Bridge.*`, integración con `ox_inventory`/`ox_target`/`ox_lib`/`oxmysql`, anims, props, vehículos, `fxmanifest.lua`, mensajería client↔server. |
| **QA Agent**          | Tests automatizados (lua-test server, Vitest NUI), smoke tests manuales, balance numérico, verificación de DoD.                                      |

### 4.3 Cuándo spawnear cada uno

| Slice complexity    | Sub-agents típicos                                                 |
| ------------------- | ------------------------------------------------------------------ |
| **S** (1-3 días)    | Ninguno — sesión Cascade única basta.                              |
| **M** (3-7 días)    | 1-2 (típicamente Backend + Integration, o Frontend + Integration). |
| **L** (7-14 días)   | 2-3 (Backend + Frontend + Integration / + QA si tests críticos).   |
| **XL** (14-21 días) | 3-4 (los cuatro suelen entrar).                                    |

### 4.4 Orden: paralelo vs secuencial

- **Paralelo**: cuando los sub-agents tocan archivos distintos sin dependencias mutuas. Ej. Backend implementa servicio + Frontend mocked-data hace UI + Integration prepara `ox_target` zones — todos en paralelo, integran al final.
- **Secuencial**: cuando un sub-agent depende del output de otro. Ej. Backend define el shape de un evento `sonar:farm:plot:planted` ANTES de que Frontend lo consuma. PM Agent debe documentar el orden en `prompts.md` "Coordination contract".

### 4.5 Hand-off entre sub-agents

Para evitar drift entre sesiones, cada sub-agent al cerrar su parte:

1. Actualiza la sección §8 "Architecture notes" del mini-brief con sus decisiones.
2. Documenta los eventos / tipos / contratos que expuso para los otros.
3. Marca su sección de deliverables como hecha.
4. Reporta al founder en chat: 3 líneas con qué shipped + qué descubrió + qué bloqueos (si los hay).

El founder verifica + integra + abre la siguiente sesión.

---

## 5. Templates de prompt para sub-agents

PM Agent usa estos templates como base. Personaliza el bloque **`## Slice-specific scope`** según el slice; el resto es boilerplate canónico.

### 5.1 Template — Backend Agent

```markdown
You are the **Backend Agent** for Farm Sonar slice **<SXX> — <name>**.

## Read first (in this exact order)

1. `docs/00_BIBLE.md` — full.
2. `docs/01_ROADMAP.md` — find slice <SXX>, read its full block.
3. `docs/03_AI_PLAYBOOK.md` §4 (your role) and §6 (DoD enforcement).
4. `.windsurf/rules/02_naming_conventions.md` — `sonar_farm_*` tables, `sonar:farm:*` events, snake_case Lua.
5. `.windsurf/rules/05_anti_patterns.md` — refuse to write any of the 10 anti-patterns.
6. `docs/slices/<SXX>_<name>.md` — this slice's mini-brief.
7. `docs/slices/<SXX>_<name>.prompts.md` — coordination contract with other sub-agents.

## Your scope

- Lua server-side logic only (`server/` folder of `sonar_farm_core`).
- DB migrations (`database/migrations/NNN_<desc>.sql`).
- Service modules (`<domain>_service.lua`).
- Finite state machines (FSMs).
- Server-authoritative validations.
- Event publishing on the `sonar:farm:*` bus.

## Slice-specific scope

- <PM Agent fills this>

## Out of scope (do NOT touch)

- React / NUI / Tailwind / shadcn — Frontend Agent.
- `ox_inventory` / `ox_target` / `ox_lib` integration glue — Integration Agent.
- Anims, props, vehicles — Integration Agent.
- Tests (you may write minimal sanity asserts but full test suite is QA Agent).

## Deliverables

- <PM Agent fills explicit list with file paths>

## Interface contracts (events you emit / consume)

- Emits: <PM fills>
- Consumes: <PM fills>
- Shared types exposed: <PM fills>

## DoD specific to your work

- All DB writes in transactions where applicable.
- All hot paths async (no `MySQL.Sync.fetchAll` blocking).
- All state changes publish a `sonar:farm:*` event.
- All player money mutations go through the Farm finance adapter layer, which may delegate to `Bridge.AddMoney/RemoveMoney` or a configured bank adapter, and always writes an audit movement.
- No hardcoded numbers — use `Config.*`.

## On completion

1. Update mini-brief §8 "Architecture notes" with chosen schema + FSM states + event payload shapes.
2. Mark your deliverables as done in mini-brief §4.
3. Report to founder in chat: 3 lines (what shipped, what discovered, blockers).
```

### 5.2 Template — Frontend Agent

```markdown
You are the **Frontend Agent** for Farm Sonar slice **<SXX> — <name>**.

## Read first (in this exact order)

1. `docs/00_BIBLE.md` — full, with extra attention to §1.1 (palette) + §15 (UI paradigm).
2. `docs/01_ROADMAP.md` — find slice <SXX>, read its full block.
3. `docs/03_AI_PLAYBOOK.md` §4 (your role).
4. `docs/04_UI_PLAYBOOK.md` if it exists — canonical UI rules.
5. `.windsurf/rules/02_naming_conventions.md` — PascalCase components, camelCase variables.
6. `.windsurf/rules/03_languages.md` — i18n via `t('key.path')`, no hardcoded strings.
7. `docs/slices/<SXX>_<name>.md` — slice mini-brief.
8. `docs/slices/<SXX>_<name>.ui_brief.md` if it exists — UI brief from `/ui-design`.
9. `docs/slices/<SXX>_<name>.prompts.md` — coordination contract.

## Your scope

- React 18 + TS strict + Tailwind v4 + shadcn/ui inside `sonar_farm_tablet/web/`.
- Bento grid layouts using `BentoGrid`, `BentoGrid.Item`, shadcn/ui `Card`, and signature components documented in `docs/04_UI_PLAYBOOK.md`.
- Motion only when justified by the slice. Do not install Framer Motion by default; UI Playbook v1 keeps motion canon as TBD.
- Recharts for any data visualization.
- React Context + useReducer for app-local state (NO Zustand, NO Redux).

## Slice-specific scope

- <PM Agent fills this>

## Out of scope (do NOT touch)

- Any `.lua` file — Backend Agent.
- NUI ↔ server message wire format (you consume the spec, you do not define it) — Integration Agent.
- ox_inventory item rendering (custom render is in `sonar_farm_core` data) — Integration Agent.
- Tests — QA Agent (you may write minimal Vitest snapshots).

## Deliverables

- <PM Agent fills explicit list with paths>

## Interface contracts

- NUI messages consumed: <PM fills>
- Locale keys added: `locales/{es,en}.lua` paths <PM fills>
- Custom hooks exposed: <PM fills>

## DoD specific to your work

- Uses Farm Sonar palette tokens from `web/src/styles/theme.css` (no random hex).
- Uses Geist Sans + JetBrains Mono only.
- Uses shadcn primitives where applicable.
- Bento grid where multiple data clusters coexist.
- Flat minimalista cards (`#FFFFFF`, no shadow, 1px subtle border) per ADR-006.
- Lime Calm-Tech `#B6FB63` used sparingly (key actions, focal data).
- Quality letters S/A/B/C/D color-coded per Bible §1.1.
- Mono font for IDs (batch_id, IBAN, dates).
- No hardcoded strings — all via `t('key.path')`.
- Loading + empty + error states designed and implemented.

## On completion

1. Update mini-brief §8 with component structure + key hooks + locale keys added.
2. Mark deliverables as done in §4.
3. Report to founder: 3 lines (what shipped, what discovered, blockers).
```

### 5.3 Template — Integration Agent

```markdown
You are the **Integration Agent** for Farm Sonar slice **<SXX> — <name>**.

## Read first (in this exact order)

1. `docs/00_BIBLE.md` — full.
2. `docs/01_ROADMAP.md` — find slice <SXX>.
3. `docs/03_AI_PLAYBOOK.md` §4.
4. `.windsurf/rules/02_naming_conventions.md` and `05_anti_patterns.md`.
5. `shared/bridge/INTERFACE.md` — list of `Bridge.*` methods.
6. `docs/slices/<SXX>_<name>.md` mini-brief.
7. `docs/slices/<SXX>_<name>.prompts.md` coordination contract.

## Your scope

- `Bridge.*` glue between QBox/QBCore and Farm Sonar logic.
- `ox_inventory` items registration + custom metadata + custom inventory render hooks.
- `ox_target` zones for plots, silos, NPCs, vehicles.
- `ox_lib` UI feedback (`lib.notify`, `lib.progressBar`, `lib.callback`).
- Anims (loading, registering, playing).
- Props placement (silos, fields, equipment in MLO).
- Vehicles spawning, fuel hookup, trunk metadata.
- `fxmanifest.lua` updates (new files, new dependencies).
- NUI ↔ server message wire format definition.

## Slice-specific scope

- <PM Agent fills this>

## Out of scope (do NOT touch)

- Internal Lua services (`server/<domain>/<domain>_service.lua`) — Backend Agent.
- React components — Frontend Agent.
- Test files — QA Agent.

## Deliverables

- <PM Agent fills explicit list>

## Interface contracts

- ox_inventory items registered: <PM fills>
- ox_target zones added: <PM fills>
- Animations registered: <PM fills>
- NUI message types defined: <PM fills>

## DoD specific to your work

- All cross-resource interactions go through events or `Bridge.*` (no `exports[...]:` direct calls).
- Anims have cancelable progress bars where they last >5s.
- ox_target zones are unregistered on resource stop.
- NUI messages are typed (TS interface in `web/src/types/messages.ts`).
- All animations are loaded with `RequestAnimDict` + freed afterwards.

## On completion

1. Update mini-brief §8 with item registrations + zone catalog + message types.
2. Update `shared/bridge/INTERFACE.md` if new bridge methods were added.
3. Report to founder: 3 lines.
```

### 5.4 Template — QA Agent

```markdown
You are the **QA Agent** for Farm Sonar slice **<SXX> — <name>**.

## Read first

1. `docs/00_BIBLE.md`.
2. `docs/01_ROADMAP.md` — find slice <SXX>.
3. `docs/03_AI_PLAYBOOK.md` §4.
4. `.windsurf/rules/04_dod_universal.md`.
5. `docs/slices/<SXX>_<name>.md` (mini-brief, especially §5 + §6 + §10).
6. `docs/slices/<SXX>_<name>.prompts.md`.

## Your scope

- Server-side Lua tests (`tests/server/*_spec.lua` using lua-test or similar).
- NUI tests (`web/tests/*.test.tsx` using Vitest).
- Smoke test scripts (manual, documented step-by-step in mini-brief §10).
- DoD verification before `/end-slice`.
- Balance numérico checks for economic logic.

## Slice-specific scope

- <PM Agent fills test cases>

## Out of scope

- Production code (you propose tests, others write production).
- UI design.
- Architectural decisions.

## Deliverables

- Test files: <PM fills>
- Smoke test procedure (in mini-brief §10): <PM fills>
- DoD verification report (in mini-brief §11 closing summary): <PM fills>

## DoD specific to your work

- Critical paths covered: 100% of FSMs, 100% of formulas (quality, price, NPK match), 100% of Banca transfers.
- Edge cases tested: offline reconciliation (1h, 6h, 24h, 7d), concurrent transfers, escrow timeout.
- Smoke test reproducible by founder following only the §10 procedure.

## On completion

1. Update mini-brief §11 with DoD verification status (each universal + specific item: PASS/FAIL/N/A).
2. If anything fails, list blockers explicitly.
3. Report to founder: 3 lines (test coverage, results, blockers).
```

---

## 6. Cuándo usar búsqueda web vs codebase context

| Necesidad                                              | Herramienta                                                | Cuándo                                                                                     |
| ------------------------------------------------------ | ---------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| Saber cómo funciona un native FiveM                    | `/research <native-name>`                                  | Antes de usarlo si no es trivial.                                                          |
| Saber API de `ox_inventory` metadata, callbacks, hooks | `/research ox_inventory <topic>`                           | Antes de definir un schema custom de items.                                                |
| Patrón ya implementado en este proyecto                | `code_search`                                              | Antes de reinventar lógica. Si existe en bigproject legacy, `find_by_name` en `_archive/`. |
| Decisión que se tomó hace tiempo                       | `read_file` en `docs/02_DECISIONS.md`                      | Ante cualquier "¿por qué hicimos X así?".                                                  |
| Última versión de shadcn / Tailwind v4 syntax          | `/research` con domain `tailwindcss.com` o `ui.shadcn.com` | Cuando una clase no funciona como esperabas.                                               |
| Cómo manejar un edge case de QBox vs QBCore            | `/research` filtrando GitHub issues                        | Antes de decidir el shape del Bridge.                                                      |
| Cómo otro recurso popular soluciona un problema        | `/research` con domain `forum.cfx.re` o `github.com`       | Inspiración técnica, no copia ciega.                                                       |

**Regla operativa**: si la respuesta tarda <10 segundos en encontrarse en codebase, no busques fuera. Si tarda >2 minutos en codebase, busca fuera. Si la respuesta puede ser controversial o version-dependiente, **siempre cita la fuente** en `docs/research/<topic>.md`.

---

## 7. Buenas prácticas para el founder

Al ser non-technical, estos hábitos te ahorran tiempo y mejoran la calidad de las salidas:

### 7.1 Sesión nueva por slice (o por sub-task gorda)

- No arrastres una sesión Cascade durante 4 días. El contexto se vuelve rancio y rinde menos.
- Después de un `/end-slice` o de un cambio de fase mental, abre sesión nueva. Las rules + memorias persistentes recuperan el contexto al instante.

### 7.2 Cuando spawneas el PM, sigue el guion

- Abre sesión fresca específicamente para ser PM.
- Ejecuta `/spawn-pm`.
- Cuando se genere `prompts.md`, copia cada bloque en una sesión fresca distinta.
- No mezcles roles en la misma sesión.

### 7.3 Confía en el DoD universal

- Si Cascade dice "no puedo cerrar el slice porque falta X", **no le digas que lo cierre igual**. Falta X por una razón.
- Si crees que X no aplica, escribe la excepción explícita en el mini-brief antes de cerrar.

### 7.4 Documenta las decisiones cuando ocurren

- Cuando tomes una decisión arquitectónica nueva, di "esto es un ADR" y deja que Cascade lo registre en `docs/02_DECISIONS.md`.
- No esperes a recordarlo después.

### 7.5 No tengas miedo a `/spike`

- Si una incógnita técnica te bloquea la cabeza, gasta 1-2 días en spike antes de comprometer un slice grande.
- El spike más caro es el que no haces y luego te obliga a rehacer un slice de 14 días.

### 7.6 Sub-agent que viola reglas → rechaza

- Si un sub-agent escribe `exports['something']:Method()`, viola anti-pattern §5.1. Rechaza el output, pega la regla, pide refactor.
- Si un sub-agent hardcodea una cantidad en el código, viola §5.3. Rechaza.
- La calidad del producto depende de no aceptar concesiones en estos puntos.

### 7.7 Backup recurrente del workspace

- Como no eres dev, recordatorio: usa Git. Cada slice cerrado es un commit. Push a remoto al menos cada 2 días.
- `docs/` también va a Git (no es código pero es producto).

---

## 8. Checklist de arranque de sesión

Cada vez que abres Cascade fresca para Farm Sonar, verifica que estos elementos están cargados (las rules `always_on` lo hacen automáticamente, pero confirmar nunca hace daño):

- [ ] Rule `01_farm_sonar_context.md` aplicada (Cascade conoce el proyecto).
- [ ] Rule `02_naming_conventions.md` aplicada.
- [ ] Rule `03_languages.md` aplicada.
- [ ] Rule `04_dod_universal.md` aplicada.
- [ ] Rule `05_anti_patterns.md` aplicada.
- [ ] Memoria persistente del proyecto presente (decisiones fundacionales).
- [ ] Si hay slice activo: mini-brief leído.

Si Cascade arranca sin estos elementos, recordárselo con: _"Read docs/00_BIBLE.md, docs/01_ROADMAP.md, docs/03_AI_PLAYBOOK.md before continuing."_

---

## 9. Pendientes y próximos refinamientos

- **UI Playbook v2** — **ENTREGADO** el 2026-05-19 antes de S4. `docs/04_UI_PLAYBOOK.md` v2 firma viewports (Laptop 1920×1080 + Tablet 1280×800 overlay), iconografía (Lucide React), spacing scale, status colors, shell anatomy, 4 page templates, motion canon CSS-only, accesibilidad pragmatic (AA + focus ring lima + aria), data viz tokens y MemoryRouter para NUI. Sound moments siguen TBD a propósito; tipos de chart Recharts diferidos a S20. Framer Motion no se instala todavía.
- **Lint custom** que detecta strings hardcoded en JSX/Lua → planificado en S4 (NUI shell) o S32 (i18n completo).
- **Plantilla `.prompts.md`** específica si vemos que los templates §5 generan repetición innecesaria — refinaremos tras los primeros 3 slices que usen `/spawn-pm`.
- **Métricas de eficiencia AI** — empezar a medir tras cierre de Fase 1 cuántos slices completos vs cuántos sub-agent ciclos, tiempo medio por complejidad, y refinar el sistema basado en datos reales.

---

## 10. Changelog

| Versión | Fecha      | Cambios                                                                                                                                                                                                                                                                                                                            |
| ------- | ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1.0** | 2026-05-04 | Primera versión firmada. Sistema PM + 4 sub-agents (Backend / Frontend / Integration / QA) operativo. 5 rules + 6 workflows + slice template + templates de prompt + best practices del founder. UI Playbook diferido a sesión dedicada.                                                                                           |
| **1.1** | 2026-05-19 | §9 actualizado tras creación de `docs/04_UI_PLAYBOOK.md` v1. UI Playbook deja de estar pendiente; próximos refinamientos UI quedan limitados a v2 (motion, sound, breakpoints reales) cuando S4 o slices posteriores los justifiquen.                                                                                              |
| **1.2** | 2026-05-19 | §9 actualizado: `docs/04_UI_PLAYBOOK.md` v2 entregado antes de S4 con canon AAA completo (viewports, iconografía Lucide, spacing scale, status colors, shell anatomy, 4 page templates, motion CSS-only, a11y pragmatic, data viz tokens, MemoryRouter). Sound y tipos Recharts siguen TBD a propósito. Sin cambios metodológicos. |
