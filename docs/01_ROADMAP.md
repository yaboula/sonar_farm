# 🗺️ Farm Sonar — Roadmap de Vertical Slices

> **Versión:** 1.0 (firmada, living document).
> **Fecha:** 2026-05-04.
> **Estado:** plan ejecutable. 6 fases · 36 slices · ~5-7 meses con AI agents.
> **Lectura previa obligatoria:** `docs/00_BIBLE.md`.

---

## 0. Cómo se usa este documento

Es el **plan de batalla** desde commit 0 hasta producto en Tebex.

- Cada slice se ejecuta en orden salvo excepciones documentadas en su sección "Dependencias".
- Cada slice tiene un mini-brief independiente en `docs/slices/SXX_<nombre>.md` que se redacta JUSTO ANTES de empezar a programarlo (no antes), siguiendo la metodología híbrida del Bible §16.
- Cada slice cierra con **DoD universal (§2)** + **DoD específico** del slice. Si no cumple ambos, no se cierra.
- El roadmap es vivo: si un slice descubre que necesita partirse en dos, lo partimos. Cualquier cambio se refleja aquí + ADR si afecta arquitectura.
- Ningún slice se salta sin justificación documentada en `docs/02_DECISIONS.md`.

---

## 1. Convenciones

### 1.1 Complejidad

| Sigla  | Esfuerzo   | Ejemplo típico                                             |
| ------ | ---------- | ---------------------------------------------------------- |
| **S**  | 1-3 días   | Migración DB simple, app NUI con 1 vista                   |
| **M**  | 3-7 días   | Sistema con 2-3 mecánicas integradas                       |
| **L**  | 7-14 días  | Sistema completo con UI + lógica + tests                   |
| **XL** | 14-21 días | Mecánica core con riesgo (drones, persistencia delta-calc) |

> Estimaciones asumen **1 dev humano + AI agents** (Cascade lógica/diseño · v0.dev UI · Opus implementación). Sin AI estaríamos al doble o triple.

### 1.2 Marcadores

- ⭐ **Marketing slice**: cierra con un clip o screenshot vendible.
- 🚨 **Risk slice**: contiene incertidumbre técnica o de diseño que puede forzar refactor.
- 🔓 **Unlock slice**: desbloquea muchos slices posteriores. Su delay propaga.
- 🧱 **Foundation slice**: sin valor jugable independiente, base de todo lo demás.

### 1.3 Estados

```
PLANNED  →  ACTIVE  →  IN_REVIEW  →  DONE
                ↓
            BLOCKED  (con razón documentada en mini-brief)
```

---

## 2. Definition of Done universal

Todo slice, sin excepción, debe cumplir antes de marcarse `DONE`:

- [ ] Funciona end-to-end en **QBox** y en **QBCore** (smoke en ambos).
- [ ] Tests automatizados donde tenga sentido (lógica económica, validaciones server, fórmulas). UI puramente visual exenta.
- [ ] Respeta los **5 Pilares** del Bible §3.
- [ ] Respeta el **naming técnico** del Bible §9.3 (`sonar_farm_*`, `sonar:farm:*`).
- [ ] Respeta los **anti-patrones técnicos prohibidos** del Bible §9.4 (no llamadas directas entre resources, server-authoritative, sin hardcoding).
- [ ] **UI** (si la hay) sigue paleta + Bento + glassmorphism + tipografía Geist/Mono del Bible §1.1 + §15.
- [ ] **i18n**: cero strings hardcoded. Todo string user-facing en `locales/es.lua` + `locales/en.lua`.
- [ ] **Mini-brief del slice actualizado** con lo realmente hecho (no con lo planeado).
- [ ] **ADR creado** en `docs/02_DECISIONS.md` si el slice tomó alguna decisión arquitectónica no obvia.
- [ ] **Migración DB versionada** y rollbackeable si tocó DB.
- [ ] **Smoke test manual** del happy path documentado.
- [ ] **Bible §18 changelog actualizado** si el slice cambió algo del producto canon.

---

## 3. Mapa de fases

```
┌──────────────────────────────────────────────────────────────────┐
│ FASE 0  Foundation                        ~2-3 sem · S0  → S4   │
│   Milestone: laptop abre, dashboard vacío con identidad visual   │
├──────────────────────────────────────────────────────────────────┤
│ FASE 1  First Crop End-to-End ⭐          ~4-5 sem · S5  → S11  │
│   Milestone: CLIP DE 15s — plantar trigo → cosecha → venta       │
├──────────────────────────────────────────────────────────────────┤
│ FASE 2  Depth & Scale                     ~4-5 sem · S12 → S18  │
│   Milestone: granja completa con 8 cultivos + clima + plagas     │
├──────────────────────────────────────────────────────────────────┤
│ FASE 3  Economy Alive                     ~3-4 sem · S19 → S22  │
│   Milestone: mundo vivo solo, NPCs piden, contratos B2B vivos    │
├──────────────────────────────────────────────────────────────────┤
│ FASE 4  Empresa multi-rol                 ~3-4 sem · S23 → S27  │
│   Milestone: equipo de 4 jugadores con permisos opera limpio     │
├──────────────────────────────────────────────────────────────────┤
│ FASE 5  WOOOW Tech Stack ⭐⭐             ~3-4 sem · S28 → S31  │
│   Milestone: drones + probe + market intel = trailer Tebex       │
├──────────────────────────────────────────────────────────────────┤
│ FASE 6  Polish & Launch                   ~3-4 sem · S32 → S35  │
│   Milestone: 🏁 producto en Tebex con Asset Escrow              │
└──────────────────────────────────────────────────────────────────┘
```

---

## FASE 0 — Foundation 🧱

**Objetivo:** dejar el workspace listo para que cualquier slice posterior se pueda implementar sin tropiezos. Sin valor jugable per se. Es **el cimiento**.

**Duración estimada:** 2-3 semanas.

**Milestone de fase:** abrir el Laptop en la oficina del MLO devuelve un dashboard React vacío (skeleton) con la paleta + tipografía aplicadas. El primer `#B6FB63` aparece en pantalla.

---

### S0 — Workspace skeleton 🧱 · Complejidad: S · **Estado: `DONE`** (2026-05-18)

> Mini-brief: [`docs/slices/S0_workspace_skeleton.md`](./slices/S0_workspace_skeleton.md).
> QBox boot smoke ✅ validado por founder (commit `1b0c5e5` + edit defensivo en `server/main.lua` con `_G.locale` fallback). QBCore smoke deferido a S1 (Bridge layer) por convención: S0 no contiene código framework-specific, así que la validación cross-framework tiene sentido en el slice donde de verdad existe lógica QBox/QBCore-aware.

**Scope.** Bootstrap del repo FiveM. `fxmanifest.lua` configurado. Estructura estándar (`server/`, `client/`, `shared/`, `web/`, `locales/`, `config/`, `database/migrations/`). NUI Vite + React 18 + TS strict + Tailwind v4 con tokens del Bible §1.1.

**Deliverables.**

- `sonar_farm_core/fxmanifest.lua` con metadata + dependencias declaradas (`ox_lib`, `ox_inventory`, `ox_target`, `oxmysql`).
- `sonar_farm_core/config.lua` placeholder.
- `sonar_farm_tablet/` resource separado para la NUI.
- `package.json` + `tsconfig.json` + `vite.config.ts` + `tailwind.config.ts`.
- Hot-reload NUI vía Vite dev server.
- Lua linter (`selene` o `lua-language-server`) configurado.
- Git hooks: pre-commit con lint Lua + ESLint TS.
- README + `CONTRIBUTING.md` enlazando al Bible.

**DoD específico.**

- `pnpm dev` levanta NUI con HMR.
- `start sonar_farm_core` y `start sonar_farm_tablet` arrancan sin error en QBox y QBCore.
- Linter pasa en CI local.

**Dependencias:** ninguna.

**Riesgo:** bajo. Plomería conocida.

---

### S1 — Bridge layer (QBox + QBCore) 🧱🔓 · Complejidad: M · **Estado: `DONE`** (2026-05-19, closure commit pending)

> Mini-brief: [`docs/slices/S1_bridge_layer.md`](./slices/S1_bridge_layer.md).

**Scope.** Capa `bridge/` con interfaz común para QBox y QBCore. Cualquier slice posterior consume `Sonar.Farm.Bridge.GetPlayer(src)`, `Sonar.Farm.Bridge.GetMoney(src, account)`, `Sonar.Farm.Bridge.AddMoney(src, account, amount, reason)`, `Sonar.Farm.Bridge.RemoveMoney(src, account, amount, reason)` y `Sonar.Farm.Bridge.Notify(src, msg, type)`. Detección automática del framework activo en boot.

**Deliverables.**

- `shared/bridge/init.lua` autodetect.
- `shared/bridge/qbox.lua`, `shared/bridge/qbcore.lua`.
- `shared/bridge/_unsupported.lua` fallback inerte para frameworks no soportados.
- Interfaz documentada en `shared/bridge/INTERFACE.md` con la lista exhaustiva de métodos.
- Comando admin `/sonarfarm:bridgetest` que devuelve datos del jugador.

**DoD específico.**

- Comando de test devuelve datos correctamente en ambos frameworks.
- Si detecta framework no soportado, log claro: _"Farm Sonar requires QBox or QBCore. ESX bridge planned for wave 2+."_

**Dependencias:** S0.

**Riesgo:** medio. Las APIs de QBox y QBCore divergen en detalles. Documentar bien las equivalencias.

---

### S2 — DB foundation + sistema de migrations 🧱🔓 · Complejidad: M · **Estado: `DONE`** (2026-05-19, QBCore + DB-unreachable runtime smokes deferred by ADR-007 to Phase 0 closure)

**Scope.** Migrations versionadas en `database/migrations/NNN_<descripcion>.sql`. Runner Lua que ejecuta migrations pendientes en boot. Tabla `sonar_farm_migrations` que registra estado. Smoke de `oxmysql`.

**Deliverables.**

- `server/db/migrator.lua` con runner.
- `database/migrations/001_init_migrations_table.sql`.
- `database/migrations/002_smoke_table.sql` (se elimina en S3).
- `server/db/db.lua` wrapper sobre `oxmysql` con helpers (`db.scalar`, `db.row`, `db.rows`, `db.execute`, `db.transaction`).
- Validación de integridad en boot (fail-fast si DB inalcanzable).

**DoD específico.**

- Boot aplica migrations pendientes y loggea cuáles. Idempotente.
- Rollback manual posible eliminando row de `sonar_farm_migrations` (documentado).

**Dependencias:** S0, S1.

**Riesgo:** bajo-medio. Tener este sistema desde día 1 evita dolor masivo después.

---

### S3 — Finance compatibility layer 🧱🔓 · Complejidad: L · **Estado: `DONE`** (2026-05-19, smoke QBox PASS `1779208796`, smoke QBCore diferido por ADR-009)

**Scope.** Capa financiera fundacional para que Farm Sonar sea independiente y compatible con bancos existentes. Farm Sonar no depende de `sonar_bank` ni asume ser el banco global del servidor. En S3, el dinero externo se toca solo vía adapters (`qbox`, `qbcore`, `renewed_banking`, `okok_banking`, `qs`/similares cuando exista API estable) y un fallback nativo sobre el Bridge. Farm Sonar mantiene su propio ledger mínimo de movimientos agrícolas para auditoría interna, idempotency y trazabilidad, pero el banco externo/framework sigue siendo la fuente inmediata de saldo del jugador hasta que un servidor active un adapter dedicado.

**Deliverables.**

- Migration `003_finance_core.sql` (`sonar_farm_finance_movements`; idempotency colapsado en la misma tabla por limitación single-query del migrator S2).
- `server/finance/money_adapter.lua` con interfaz: `Init`, `GetBalance`, `Credit`, `Debit`, `Transfer` stub, `CanAfford`, `GetActiveAdapter`.
- Adapter inicial `native_bridge` para QBox/QBCore vía `Sonar.Farm.Bridge`; adapters externos quedan como extensión futura solo con API verificada.
- `server/finance/movement_service.lua` como ledger agrícola append-only para auditoría interna, no como reemplazo obligatorio del banco externo.
- `server/finance/init.lua`, `config/finance.lua`, locales y smoke command admin `sonarfarm:financesmoke`.
- Eventos: `sonar:farm:banca:movement_created`, `sonar:farm:banca:adapter_selected`.
- Tests de debit/credit/idempotency/adapter selection y smoke QBox PASS; QBCore smoke antes de cerrar Fase 0.

**DoD específico.**

- Ninguna llamada directa a `sonar_bank`, `sonar_bank_app` u otro banco externo fuera de adapters.
- QBox/QBCore native money funciona vía Bridge sin banco adicional instalado.
- Adapter selection es configurable y visible en boot logs.
- Money mutations son idempotentes y dejan movement audit row en `sonar_farm_finance_movements`.
- Escrow no se implementa en S3; queda diferido para slice posterior sin depender de un banco específico.

**Dependencias:** S2.

**Riesgo:** alto. Compatibilidad bancaria FiveM es fragmentada; S3 debe priorizar independencia, adapters y degradación segura antes que features avanzadas de banca propia.

---

### S4 — NUI shell + design system 🧱🔓 · Complejidad: L · **Estado: `DONE`** (2026-05-19; impl `b4fbf17`)

**Scope.** Shell React de la Tablet/Laptop con design system. Router de apps (placeholders). Entrypoints físicos: `ox_target` sobre el laptop de la oficina abre Manager Panel; keybind global `F6` (configurable) abre Tablet de campo. Tokens Tailwind v4 con `@theme` siguiendo paleta del Bible §1.1.

**Deliverables.**

- `web/src/main.tsx`, `web/src/App.tsx`.
- `web/src/styles/theme.css` con tokens canónicos (`--fs-bg`, `--fs-nav`, `--fs-accent`, etc.).
- `web/src/components/layout/{BentoGrid}.tsx` + shadcn/ui `Card` styled per `docs/04_UI_PLAYBOOK.md`.
- `web/src/components/ui/{BatchChip,LimePulse}.tsx`.
- `web/src/components/typography/{Heading, Body, Mono}.tsx`.
- `web/src/router/AppRouter.tsx` con rutas placeholder: `/dashboard`, `/plots`, `/batches`, `/market`, `/contracts`, `/personnel`, `/finance`, `/log`, `/tasks`, `/messages`.
- `client/laptop_interaction.lua` (anim sentarse + ox_target + abrir NUI mode `manager`).
- `client/tablet_interaction.lua` (keybind + abrir NUI mode `field`).
- Bridge NUI ↔ server (mensajes tipados, callbacks ox_lib).
- 1 demo card en `/dashboard` con un dato fake + el `#B6FB63` visible.

**DoD específico.**

- Abrir Laptop con `ox_target` → NUI fullscreen, modo `manager`, dashboard placeholder con identidad visual aplicada.
- Abrir Tablet con keybind → NUI overlay, modo `field`, app placeholder.
- ESC cierra NUI, libera focus, devuelve control al juego.

**Dependencias:** S0.

**Riesgo:** medio. Es el primer contacto del jugador con el producto. Tiene que ser pulido.

**Cierre.** Smoke completo PASS: Tablet F6 → `/plots`, ESC libera foco, Laptop `ox_target` → manager `/dashboard`, repeated open/close sin bloqueo, QBCore bridge activo. Bug `useLocation() outside Router` cerrado moviendo `MemoryRouter` al nivel del shell completo.

---

## FASE 1 — First Crop End-to-End ⭐

**Objetivo:** un jugador puede plantar trigo, verlo crecer en stages 3D, cosecharlo, almacenarlo y venderlo a un NPC, recibiendo dinero en su Banca Sonar. **Persistencia delta-calc se incluye AQUÍ** para validar el diseño risk-first.

**Duración estimada:** 4-5 semanas.

**Milestone de fase:** ⭐ **El clip de 15 segundos**. Grabamos un video sin editar que pasa el Wooow Test del Bible §4.

---

### S5 — Parcela system 🧱🔓 · Complejidad: M · **Estado: `DONE`** (2026-05-19, closure commit pending)

> Mini-brief: [`docs/slices/S5_plot_system.md`](./slices/S5_plot_system.md).
> QBox smoke PASS por founder (8 parcelas seeded, distribución 4/3/1, reload idempotente, ACE gate `sonar.farm.admin`, `soil_score` preservado por reload). QBCore PASS por bridge (`native_bridge` mode). ADR-010 firmado: `plot_id` natural key + reload preserva columnas gameplay-owned.

**Scope.** Sistema de parcelas como entidad core. Tabla `sonar_farm_plots` con timestamps designed-for-delta-calc desde día 1 (`last_updated_ts`, `planted_ts`, `next_stage_ts`). Soil score persistente. Tipos: `extensive` (cereales), `horticultural` (hortalizas/hojas/bulbos/tubérculos), `greenhouse` (invernadero). En oleada 1, el MLO trae las parcelas pre-definidas en config (GUI de placement se difiere).

**Deliverables.**

- Migration `004_plots.sql`.
- `server/plots/plot_service.lua` con CRUD.
- `config/plots.lua` con seed de las 8 parcelas iniciales del MLO (4 extensive + 3 horticultural + 1 greenhouse).
- Comando `/sonarfarm:plots:reload` admin.
- Eventos: `sonar:farm:plot:state_changed`.

**DoD específico.**

- Boot crea las parcelas seeded si no existen.
- Schema soporta delta-calc trivialmente (validar consultando los timestamps requeridos).

**Dependencias:** S2.

---

### S6 — Trigo lifecycle físico ⭐🚨 · Complejidad: XL · **Estado: `DONE`** (2026-05-22, bundle B1 con S7+S8)

**Scope.** **El slice más importante de Fase 1.** Flujo físico completo:

1. Jugador con saco de semillas de trigo en inventario.
2. `ox_target` sobre parcela arada: "Plantar trigo" (consume semilla).
3. Anim de plantado (~3s).
4. Stage 0 (sembrado, tierra húmeda visible).
5. Tras X tiempo según multiplicador: Stage 1 (germinación) → Stage 2 (crecimiento) → Stage 3 (maduración) → Stage 4 (ready, espigas doradas).
6. `ox_target` sobre parcela ready: "Cosechar".
7. Anim cosecha (~5s, configurable por crop).
8. Crea batch (`sonar_farm_batches` row) con `quality` calculada por S8 + item físico en inventario (S7).
9. Parcela vuelve a `fallow` con cooldown.

**Deliverables.**

- Migration `005_crops_and_batches.sql` (`sonar_farm_crops`, `sonar_farm_batches`).
- `config/crops/wheat.lua` con stages, duraciones, ranges óptimos NPK/agua/clima, soil compatibility.
- `server/lifecycle/crop_lifecycle_service.lua` (gestor de transiciones de stage).
- `server/lifecycle/scheduler.lua` (tick que evalúa qué parcelas necesitan transición; 1 tick cada N segundos, no per-frame).
- 4 modelos 3D para los stages.
- `client/plot_renderer.lua` que mantiene el modelo correcto cargado según stage.
- Anims de plantar/cosechar.
- Eventos: `sonar:farm:plot:planted`, `sonar:farm:plot:stage_advanced`, `sonar:farm:plot:harvested`, `sonar:farm:batch:created`.

**DoD específico.**

- Plantar trigo + `/sonarfarm:debug:fastforward N` para testing → ver stages 3D cambiar → cosechar → batch en inventario.
- Anims responsive (el jugador no se siente trabado).
- Eventos publicados con `batch_id`.

**Dependencias:** S5, S7 (parcial), S8 (parcial). En la práctica S6, S7, S8 se desarrollan en paralelo y cierran juntos.

**Riesgo:** alto. Es el corazón de Farm Sonar. Tests obligatorios de race conditions.

**Marketing value:** ⭐⭐⭐ — clip principal del trailer.

---

### S7 — Item Físico universal · Complejidad: M · **Estado: `DONE`** (2026-05-22, bundle B1 con S6+S8)

**Scope.** Schema de "Item Físico" en `ox_inventory`. Cualquier item productivo hereda este schema:

```ts
{
  batch_id: string         // único, UUID v4 + checksum
  weight: number           // gramos exactos
  quality: 'S'|'A'|'B'|'C'|'D' | null  // null para items no-output
  freshness: number        // 0-100, decae con el tiempo
  origin: { plot_id, company_id, player_cid, harvested_ts } | null
  lineage_chain: string[]  // batch_ids ancestros, [] para origen
  created_at: number       // UNIX
}
```

**Deliverables.**

- `shared/items/physical_item.lua` con factory + validación.
- Integración con `ox_inventory` metadata.
- Items registrados: `sonar_seed_wheat`, `sonar_batch_wheat` (resto en sus slices).
- Inventory UI hook (custom render en ox_inventory) que muestra `quality` con color del Bible (S/A → lime, B → blanco, C → ámbar, D → rojo) + frescura como bar.
- Eventos: `sonar:farm:item:created`, `sonar:farm:item:freshness_decayed`.

**DoD específico.**

- Item de cosecha se crea con todos los campos completos.
- Lineage_chain se preserva al transferir entre inventarios.
- Frescura decae correctamente con el delta de tiempo.

**Dependencias:** S2, S6 parcial.

---

### S8 — Sistema calidad: 7 factores stub · Complejidad: L · **Estado: `DONE`** (2026-05-22, bundle B1 con S6+S7)

**Scope.** Implementación de los 7 factores de calidad (Bible §10). Trackeo durante el ciclo del cultivo. Fórmula stub inicial (media ponderada con pesos uniformes; balance fino en S33). Mapping numérico → S/A/B/C/D.

**Deliverables.**

- Migration `006_quality_tracking.sql` (tabla `sonar_farm_quality_tracking` con un row por parcela activa, columnas para cada uno de los 7 factores).
- `server/quality/factors/` con 7 archivos: `soil.lua`, `irrigation.lua`, `pest.lua`, `weather.lua`, `seed.lua`, `fertilization.lua`, `harvest_timing.lua`. Cada uno expone `:track(plotId, event, data)` y `:get(plotId)`.
- `server/quality/calculator.lua` con la fórmula final.
- Pesos en `config.lua`: `Config.Farm.Quality.weights = { soil = 1.0, irrigation = 1.0, ... }`.
- En oleada 1.5+, UI breakdown que muestra al jugador cómo se calculó cada factor.

**DoD específico.**

- Plantar trigo con todos los factores neutros (sin riego/fert/plagas/cosecha temprana) → calidad B esperada.
- Plantar trigo con todo óptimo → calidad A o S esperada.

**Dependencias:** S5, S6, S7.

**Nota.** En Fase 1 algunos factores son neutros (default 70) porque sus mecánicas se implementan en Fase 2. El factor existe en schema desde día 1.

---

### S9 — Almacén físico (silo) · Complejidad: M · **Estado: `DONE`** (2026-05-22, bundle B2 con S10)

> Mini-brief: [`docs/slices/B2_storage_npc_sale.md`](./slices/B2_storage_npc_sale.md).
> QBox smoke PASS (deposit/withdraw audit rows, capacity rejection). QBCore smoke postponed by founder decision (B2 uses bridge abstraction only). ADR-015 signed for ox_inventory post-hook/dual-write pattern.

**Scope.** Silo físico en el MLO. `ox_target` para depositar lote → seleccionas item del inventario → se mueve al inventario virtual del silo (preserve `batch_id`). Capacidad limitada (config). Frescura sigue decayendo dentro (más lento si silo refrigerado/seco; en oleada 1 solo seco).

**Deliverables.**

- Migration `008_storage.sql` (tabla `sonar_farm_storage_units` + `sonar_farm_storage_contents`).
- `server/storage/storage_service.lua`.
- Integración con `ox_inventory` (silo = stash con metadata Farm Sonar).
- `ox_target` zone sobre el modelo del silo del MLO.
- Eventos: `sonar:farm:storage:deposited`, `sonar:farm:storage:withdrawn`.
- `/sonarfarm:storage:reload` admin command.

**DoD específico.**

- Depositar batch trigo en silo, verificar persistencia en DB, retirar, batch_id preservado.
- Boot idempotent on re-ensure.

**Dependencias:** S7, S2.

---

### S10 — NPC comprador único + venta física ⭐ · Complejidad: L · **Estado: `DONE`** (2026-05-22, bundle B2 con S9)

> Mini-brief: [`docs/slices/B2_storage_npc_sale.md`](./slices/B2_storage_npc_sale.md).
> QBox smoke PASS (NPC sale, finance movement, sold_ts stamp, lineage preservation, notify). QBCore smoke postponed by founder decision (B2 uses bridge abstraction only).

**Scope.** Primer NPC comprador (Molino Pedro stub). Vendor marker físico (ped + zona ox_target). Jugador llega con camión cargado, descarga físicamente (anim ~30s), recibe pago en Banca Sonar. Precio calculado con fórmula simple (precio canon × tier calidad × 1.0 todo lo demás stub).

**Deliverables.**

- Seed en `config/npcs.lua` con Molino Pedro stub.
- `server/npcs/npc_buyer_service.lua`.
- `client/npc_vendor_interaction.lua` con anim de descarga.
- Integración con S3 Banca para depósito atómico tras venta.
- Eventos: `sonar:farm:sale:initiated`, `sonar:farm:sale:completed`.
- Confirmación visual: notificación lime neón "+€XXX en tu cuenta SF...".

**DoD específico.**

- Vender 100 kg trigo calidad B → recibir cantidad correcta en Banca → batch_id sale del inventario.
- Lineage_chain del batch se preserva en historial de venta.

**Dependencias:** S3, S7, S9.

**Marketing value:** ⭐⭐ — el "money shot" del clip de 15s.

---

### S11 — Persistencia delta-calc + cap 6h 🚨 · Complejidad: XL · **Estado: `DONE`** (2026-05-22)

> Mini-brief: [`docs/slices/S11_persistence_delta_calc.md`](./slices/S11_persistence_delta_calc.md).
> Automated validation PASS (`persistence_spec.lua` + full Lua regression pack + `pnpm run lint:lua`). Founder QBox smoke PASS. QBCore smoke deferred by founder decision after B3 start (ADR-017).

**Scope.** **Risk-first.** Implementación del modelo de persistencia del Bible §13.2. Al server boot, para cada parcela activa, calcular el delta UNIX desde `last_updated_ts` y aplicar:

- Avance de stage si correspondería.
- Acumulación de daño por falta de riego (si el riego estaba programado y no se ejecutó).
- Acumulación de daño por plagas no tratadas (si la plaga ya estaba detectada).
- **Cap**: si delta > 6h (configurable), los daños acumulados se limitan a -30% sobre cada factor afectado. Nunca matamos una planta entera.

**Deliverables.**

- `server/persistence/boot_reconciler.lua`.
- `server/persistence/delta_calculator.lua` con caps.
- Tests unitarios (caso 1h offline, 6h, 24h, 7 días).
- Logging detallado en boot: cuántas parcelas reconciliadas, cuántas con caps aplicados.
- Comando admin `/sonarfarm:persistence:dryrun` para previsualizar sin aplicar.

**DoD específico.**

- Server con 50 parcelas en estados variados → kill server → wait 8h real → restart → todas las parcelas en estado correcto + caps aplicados donde corresponde.
- Idempotencia: re-boot inmediato no aplica deltas adicionales.
- Smoke test pasado en QBox y QBCore.

**Dependencias:** S5, S6, S7, S8.

**Riesgo:** alto. Si la arquitectura de timestamps en S5 no fue correcta, este slice fuerza refactor. Por eso lo metemos en Fase 1, no Fase 6.

---

## FASE 2 — Depth & Scale

**Objetivo:** convertir la granja de un cultivo en una granja completa con los 8 cultivos + las mecánicas que alimentan los factores de calidad (riego, fertilización, plagas, clima).

**Duración estimada:** 4-5 semanas.

**Milestone de fase:** los 8 cultivos plantables + clima activo + plagas detectables. La calidad de los lotes refleja decisiones del jugador.

---

### S12 — Cereales restantes vía config-only 🔓 · Complejidad: S · **Estado: `DONE`** (2026-05-22)

> Mini-brief: [`docs/slices/S12_remaining_cereals_config_only.md`](./slices/S12_remaining_cereals_config_only.md).
> Corn + barley configs shipped. Minimal upstream de-hardcoding was required to restore the intended config-driven contract (Pillar 5); automated validation PASS (`crop_config_spec.lua` + regression pack + `pnpm run lint:lua`). Founder QBox smoke PASS. QBCore smoke deferred by founder decision after B3 start (ADR-017).

**Scope.** Añadir maíz y cebada **sin tocar código**. Solo `config/crops/corn.lua`, `config/crops/barley.lua`, items en `ox_inventory` data, modelos 3D de stages. Validamos que el sistema cumple Pilar 5.

**Deliverables.**

- 2 archivos config completos.
- 2×4 = 8 modelos 3D (4 stages cada uno).
- Items registrados.
- Smoke: plantar maíz + cebada funciona idéntico a trigo sin modificar lógica.

**DoD específico.**

- Si tocaste cualquier `.lua` que no sea config en este slice → revertir y arreglar el sistema, no este slice.

**Dependencias:** S6.

---

### S13 — Riego físico (cisterna) · Complejidad: L · **Estado: `DONE`** (2026-05-22, bundle B3 con S14+S15)

> Mini-brief: [`docs/slices/B3_factor_activation.md`](./slices/B3_factor_activation.md).
> QBox smoke PASS (founder verified). QBCore smoke postponed by founder decision (bridge-only). ADR-018 signed.

**Scope.** Mecánica física de regar. Cisterna como vehículo o item portable. `ox_target` sobre parcela: "Regar". Anim ~10s. Riego saturado/óptimo/insuficiente impacta `irrigation_score`. Riego excesivo penaliza también (encharcado).

**Deliverables.**

- Item `sonar_water_tank` portable + entity vehículo cisterna.
- Anim de regar.
- `server/factors/irrigation_tracker.lua` extendido.
- Eventos: `sonar:farm:plot:watered`.

**DoD específico.**

- Regar parcela cuando está sedienta → factor sube. Regar sobreabundantemente → penaliza.

**Dependencias:** S6, S8.

---

### S14 — Fertilización física (NPK) · Complejidad: L · **Estado: `DONE`** (2026-05-22, bundle B3 con S13+S15)

> Mini-brief: [`docs/slices/B3_factor_activation.md`](./slices/B3_factor_activation.md).
> QBox smoke PASS. QBCore smoke postponed.

**Scope.** Items de fertilizante (3 tipos NPK + complejos). Fertilizadora vehículo. `ox_target` "Fertilizar". NPK óptimo para cada cultivo en `config/crops/<crop>.lua`. Sub-óptimo penaliza, óptimo bonifica, exceso penaliza (curva campana).

**Deliverables.**

- Items `sonar_fertilizer_n`, `sonar_fertilizer_p`, `sonar_fertilizer_k`, `sonar_fertilizer_npk`.
- Vehículo fertilizadora + anim.
- `server/factors/fertilization_tracker.lua`.
- Eventos: `sonar:farm:plot:fertilized`.

**Dependencias:** S6, S8.

---

### S15 — Plagas + fumigadora · Complejidad: L · **Estado: `DONE`** (2026-05-22, bundle B3 con S13+S14)

> Mini-brief: [`docs/slices/B3_factor_activation.md`](./slices/B3_factor_activation.md).
> QBox smoke PASS. QBCore smoke postponed. ADR-019 signed (pest_severity explicit column).

**Scope.** Sistema de plagas selectivo. Cada cultivo define lista de plagas que lo afectan + probabilidad por estación. Plaga aparece visualmente en parcela (overlay 3D distintivo, manchas, hojas amarillentas). Detección visual del jugador o vía Tablet (en S30 con probe). Fumigadora + pesticida específico → eliminar plaga. Plaga no tratada impacta `pest_impact`.

**Deliverables.**

- Items `sonar_pesticide_a`, `sonar_pesticide_b` (placeholders por tipo de plaga).
- Vehículo fumigadora + anim.
- `server/pests/pest_service.lua` con lifecycle de plaga.
- 3-5 plagas configuradas.
- Eventos: `sonar:farm:pest:appeared`, `sonar:farm:pest:treated`.

**Dependencias:** S6, S8.

---

### S16 — Clima dinámico + 4 estaciones 🚨 · Complejidad: XL

**Scope.** Sistema climático server-authoritative. Estaciones rotan según multiplicador del Bible §13.1. Eventos meteorológicos: lluvia (afecta `irrigation_score` positivo si moderado, negativo si torrencial), sequía, granizo (penalty crítico), heladas. El cliente sincroniza weather y time con el server-authoritative state. `weather_match` factor finalmente activo.

**Deliverables.**

- Migration `008_climate.sql` (`sonar_farm_climate_state` con state + historial).
- `server/climate/climate_service.lua` con scheduler de eventos meteorológicos por estación.
- `client/weather_sync.lua` que aplica el weather correspondiente.
- 7 eventos meteorológicos: lluvia suave, lluvia torrencial, sequía corta, sequía larga, granizo, helada, día soleado óptimo.
- Eventos: `sonar:farm:climate:season_changed`, `sonar:farm:climate:event_started`, `sonar:farm:climate:event_ended`.
- App **Weather** en Laptop (oleada 1.5+, en este slice solo HUD discreto).

**DoD específico.**

- Estaciones rotan correctamente con multiplicador 1x.
- Eventos meteorológicos impactan factores de calidad de las parcelas activas.

**Dependencias:** S5, S8, S11.

**Riesgo:** alto. La integración con el weather del cliente FiveM tiene gotchas conocidos.

---

### S17 — Hortícolas + invernadero · Complejidad: L

**Estado:** 🟢 ACTIVE (B4)

**Scope.** Los 5 cultivos hortícolas (tomate, pimiento, lechuga, cebolla, patata) vía config-only siguiendo Pilar 5. Sub-nodos Hortalizas/Hojas/Bulbos/Tubérculos plenamente operativos. **Invernadero (cristal industrial)** como tipo especial de parcela: `weather_match` neutro siempre (climas externos no afectan dentro), pero con coste operativo de mantenimiento y sin bonus de optimal weather.

**Deliverables.**

- 5 archivos `config/crops/*.lua`.
- 5×4 modelos 3D de stages.
- Lógica especial de tipo `greenhouse` en `plot_lifecycle_service`.
- Smoke: plantar los 5 cultivos en parcelas + invernadero funciona end-to-end.

**Dependencias:** S6, S12.

---

### S18 — Maquinaria estado + mantenimiento · Complejidad: L

**Scope.** Sistema paralelo de "machinery state" (Bible §10.3). Cada vehículo agrícola tiene durabilidad 0-100 que decae con uso. <30 → mayor probabilidad de avería durante operación (anim de avería + tiempo de pause + reparación). Mantenimiento preventivo en granero (item `sonar_machinery_kit` o NPC mecánico) restaura durabilidad. Vehículo roto = inoperativo hasta reparado.

**Deliverables.**

- Migration `009_machinery.sql` (`sonar_farm_machinery_state` por vehículo).
- `server/machinery/machinery_service.lua`.
- Anims de avería + reparación.
- App **Machinery** en Laptop (oleada 1.5+, este slice solo lógica + ox_target básico).

**Dependencias:** S2, S6.

---

## FASE 3 — Economy Alive

**Objetivo:** que el mundo se sienta vivo cuando el jugador está solo. Catálogo NPCs completo, precios oscilando, contratos B2B, reputación.

**Duración estimada:** 3-4 semanas.

**Milestone de fase:** un jugador en server vacío juega 2h y siente que está en un negocio real.

---

### S19 — Catálogo completo NPCs + UI Mercado ⭐ · Complejidad: L

**Scope.** Los 6-10 NPCs compradores del Bible §12. Personalidad (cultivos preferidos, calidad mínima, volumen, frecuencia, rango precio) en `config/npcs.lua`. Cada NPC con vendor marker físico distintivo (ped + ubicación). App **Market** en Laptop con cards Bento por NPC: lo que paga hoy por cada cultivo × calidad, su threshold, su disponibilidad para contratos.

**Deliverables.**

- `config/npcs.lua` completo con 6-10 NPCs (ej. Molino Pedro, Supermercado Casals, Restaurante La Plaza, Distribuidora Vega, Conservera del Sur).
- Migration `010_npc_buyers.sql` (state runtime: precio actual, etc.).
- `web/src/apps/Market/MarketApp.tsx` con grid Bento.
- Mockup v0.dev validado antes de implementar.

**Dependencias:** S10, S4.

**Marketing value:** ⭐ — primera UI Bento bonita visible en screenshot.

---

### S20 — Random walk diario + histórico 7 días · Complejidad: M

**Scope.** Al inicio de cada día in-game, calcular nuevo precio de mercado por cultivo aplicando random walk acotado ±10% sobre el precio canon (Bible §12.2). Histórico 7 días persistido. UI Market muestra mini-gráfica Recharts del histórico por cultivo. Persistencia: si server reinicia, el día actual no se recalcula (idempotente).

**Deliverables.**

- Migration `011_market_prices.sql`.
- `server/market/random_walk.lua`.
- `web/src/apps/Market/PriceHistory.tsx` con Recharts mini.

**Dependencias:** S19.

---

### S21 — Contratos B2B recurrentes 🚨 · Complejidad: XL

**Scope.** Sistema de contratos. NPC ofrece contrato con términos: cultivo, calidad mínima, cantidad, frecuencia, número de ciclos, precio por unidad. Jugador firma desde Market. Entrega lotes a tiempo → reputación sube + bonus + contrato renovable o escalable. Incumple → penalty reputación + posible cancelación. Usa Banca escrow FSM para garantizar pagos.

**Deliverables.**

- Migration `012_contracts.sql`.
- `server/contracts/contract_service.lua` con FSM (`OFFERED → ACTIVE → DELIVERED_OK | DELIVERED_FAIL → COMPLETED | CANCELLED`).
- Integración con S3 Banca escrow.
- App **Contracts** en Laptop (lista + detalle + acciones firmar/cumplir/cancelar).
- Mockup v0.dev.

**DoD específico.**

- Firmar contrato → escrow de pago hold → entregar batch correcto → escrow release → reputación sube.
- Caso fail también cubierto: timeout sin entrega → escrow refund + penalty.

**Dependencias:** S3, S10, S19, S20.

**Riesgo:** alto. La FSM de contratos toca dinero real del jugador. Tests obligatorios.

---

### S22 — Reputación con NPCs + tiers premium · Complejidad: M

**Scope.** Cada jugador acumula reputación 0-100 con cada NPC del catálogo. Subir reputación abre tiers de contratos premium (que pagan más pero exigen más). UI: badge de reputación en cada NPC card. Decay lento de reputación si no se interactúa por X tiempo (config).

**Deliverables.**

- Migration `013_reputation.sql`.
- `server/reputation/reputation_service.lua`.
- UI integration en Market app.

**Dependencias:** S19, S21.

---

## FASE 4 — Empresa multi-rol

**Objetivo:** escalar de single-player a equipo. 4 roles + 5 toggles + Personnel app + salarios + temporales + Manager Panel completo + Tablet de campo apps.

**Duración estimada:** 3-4 semanas.

**Milestone de fase:** un equipo de 4 jugadores con permisos distintos puede operar la granja sin pisarse.

---

### S23 — Empresa core 🔓 · Complejidad: L

**Scope.** Refactor de single-player owner-only (que ha funcionado desde Fase 1) a sistema empresa formal. Una empresa tiene: nombre, founder (CID), fecha founding, IBAN empresa, roster (lista de miembros + rol). Migration desde estado actual: a cada jugador con parcelas registradas se le crea automáticamente una "empresa solo-owner" con su nombre.

**Deliverables.**

- Migration `014_companies.sql` con migration de datos previos.
- `server/companies/company_service.lua`.
- App **Company** en Laptop (sección "Mi Empresa") con info básica.

**Dependencias:** S3, S5, todo lo anterior.

---

### S24 — Roles + 5 toggles + Personnel app ⭐ · Complejidad: L

**Scope.** Implementación de los 4 roles + 5 toggles del Bible §11. App Personnel con cards Bento por empleado fijo, 5 toggles iOS-style cada una.

**Deliverables.**

- Migration `015_company_members_permissions.sql`.
- `server/companies/permissions_service.lua` con check granular en cada acción sensible.
- App **Personnel** en Laptop.
- Mockup v0.dev (icónico — los toggles iOS son su sello).

**DoD específico.**

- Toggle "Capital" off → empleado no puede mover dinero, intento devuelve denied notification.
- Toggle "B2B" on con límite L€ → empleado puede firmar contratos hasta L€, no más.

**Dependencias:** S23.

**Marketing value:** ⭐⭐ — la screenshot del Personnel con toggles iOS es icónica.

---

### S25 — Salarios automáticos + empleados temporales · Complejidad: L

**Scope.** Salarios fijos ejecutados periódicamente (default cada día in-game) sobre la cuenta empresa → cuenta empleado. Si caja no cubre → log + alerta al dueño. Empleados temporales: contrato por jornada (8h juego) con monto fijo, pago automático al cerrar jornada o al completar tarea acordada. UI: vista "Nóminas" en Personnel app.

**Deliverables.**

- Migration `016_payroll.sql`.
- `server/companies/payroll_service.lua`.
- Cron-like scheduler.

**Dependencias:** S3, S24.

---

### S26 — Manager Panel completo ⭐ · Complejidad: L

**Scope.** Apps Dashboard + Finance + Bitácora + Tasks del Laptop completas con dashboards Recharts. Es el pulido de la experiencia de oficina.

**Deliverables.**

- 4 apps React fully designed + functional.
- Mockups v0.dev validados antes de implementar.
- Integración Recharts con datos reales de Banca, parcelas, lotes, contratos.

**Dependencias:** S3, S5, S6, S19-S22, S24-S25.

**Marketing value:** ⭐⭐ — screenshots del dashboard completo son material clave de Tebex.

---

### S27 — Tablet de campo apps · Complejidad: M

**Scope.** Apps reducidas de la Tablet de campo (Bible §15.2): Plots (mapa con estado en vivo), Tasks (tareas asignadas/pendientes), Messages (chat empresa + NPCs).

**Deliverables.**

- 3 apps React reducidas.
- Mockups v0.dev.

**Dependencias:** S4, S5, S26.

---

## FASE 5 — WOOOW Tech Stack ⭐⭐

**Objetivo:** las 4 features que hacen a Farm Sonar incomparable en su categoría. **Subset Tier A esencial** elegido por el founder: drones de monitorización + drones de fumigación + soil analyzer + market intelligence. W4/W5/W7 (smart irrigation, weather station, greenhouse controls) quedan como ases para oleada 2.

**Duración estimada:** 3-4 semanas.

**Milestone de fase:** se puede grabar el **trailer Tebex de 60 segundos** que vende el producto solo.

---

### S28 — W1: Drones de monitorización ⭐⭐ 🚨 · Complejidad: XL

**Scope.** Item `sonar_drone_recon` desplegable desde la Tablet de campo. Despegue autónomo desde la posición del jugador. Cámara aérea con feed en vivo en pantalla de la Tablet (FiveM scaleform render-to-texture o método equivalente). Mapa overlay 2D con parcelas. **Modo térmico** que destaca zonas de plaga en rojo y zonas secas en azul. Batería limitada (config), retorno a base automático.

**Deliverables.**

- Drone como entity (vehículo aéreo pequeño o ped flying).
- `client/drones/drone_recon.lua` con AI flight pattern programable.
- NUI en Tablet con feed cam + overlays.
- Sync con `pest_service` para overlay térmico de plagas.
- Sync con `irrigation_tracker` para overlay de zonas secas.
- Eventos: `sonar:farm:drone:deployed`, `sonar:farm:drone:returned`, `sonar:farm:drone:scan_completed`.
- 2-3 sound design assets (despegue, vuelo, retorno).

**DoD específico.**

- Desplegar drone → ver feed en vivo en Tablet → activar overlay térmico → identificar parcela con plaga → drone retorna a base.
- Wooow Test ✅: clip de 15s del drone vendible.

**Dependencias:** S4, S5, S15, S27.

**Riesgo:** muy alto. FiveM scaleform/render-to-texture en NUI tiene gotchas serios. **Spike técnico obligatorio antes de comprometerse al slice completo** (1-2 días para probar la viabilidad del render-to-texture en NUI antes de planificar el resto).

**Marketing value:** ⭐⭐⭐⭐ — **EL** plano principal del trailer.

---

### S29 — W2: Drones autónomos de fumigación ⭐⭐ · Complejidad: L

**Scope.** Tras detectar plaga con S28, jugador despliega drone de spray. Drone vuela patrón programado sobre la parcela afectada y "fumiga" (efecto de partículas de spray + sonido). Consume pesticida del inventario. Plaga eliminada cuando termina. Anim ~30s.

**Deliverables.**

- Drone spray entity.
- Flight pattern (zigzag sobre parcela polygon).
- Particle effects de spray.
- Sync con `pest_service` para tratar plaga al completar.

**DoD específico.**

- Drone despega + sigue patrón + suelta spray físico + plaga removida + lote impactado positivamente en `pest_impact`.

**Dependencias:** S15, S28.

**Marketing value:** ⭐⭐⭐ — segundo plano clave del trailer.

---

### S30 — W3: Soil analyzer físico (probe) ⭐ · Complejidad: M

**Scope.** Item `sonar_soil_probe`. Jugador con probe en mano se acerca a parcela, `ox_target` "Analizar suelo", anim de clavar probe ~5s, datos en Tablet: NPK actuales, pH, humedad, soil score, recomendación contextual ("este cultivo necesita +N", "demasiado P para este cultivo").

**Deliverables.**

- Item + anim.
- App **Soil Analysis** en Tablet con visualización Recharts.
- Algoritmo de recomendación contextual.
- Mockup v0.dev (icónico — visualización densa de datos).

**Dependencias:** S5, S8, S14, S27.

**Marketing value:** ⭐⭐ — captura el "tactical depth" del producto.

---

### S31 — W6: Market Intelligence dashboard ⭐⭐ · Complejidad: L

**Scope.** App **Market Intelligence** en el Laptop. Recharts profundo: tendencias de precio 30 días, predicciones simples (linear regression sobre histórico), heatmap de mejor momento para vender por cultivo, alertas configurables ("avísame cuando trigo > X€"). Estética **estilo Bloomberg agrícola**.

**Deliverables.**

- App React densa con 4-6 visualizaciones Recharts.
- Mockup v0.dev (este es el slice que ancla el "Wall Street agrícola" del producto).
- Backend: agregaciones desde `sonar_farm_market_prices` (S20) + sistema de alertas push a Tablet.

**Dependencias:** S20, S26.

**Marketing value:** ⭐⭐⭐⭐ — el screenshot que convence al CEO/Owner del servidor.

---

## FASE 6 — Polish & Launch

**Objetivo:** producto en Tebex sin sobresaltos. Beta cerrada + balance + i18n + packaging.

**Duración estimada:** 3-4 semanas.

**Milestone de fase:** 🏁 **Producto en Tebex con Asset Escrow.**

---

### S32 — i18n completo · Complejidad: M

**Scope.** Auditoría exhaustiva: ningún string hardcoded en código. Locales `es.lua` + `en.lua` completos. NUI usa `t('key')` everywhere via `react-i18next` o sistema custom ligero. Fallback locale: `en`.

**Deliverables.**

- 2 archivos locale completos.
- Tests: cargar producto en `Config.Locale = 'es'` y `'en'` → todos los strings traducidos.
- Tooling para detectar strings hardcoded olvidados (script de scan).

**Dependencias:** todo lo anterior.

---

### S33 — Smoke tests automatizados + balance pass · Complejidad: L

**Scope.** Suite de smoke tests que verifica los happy paths críticos: boot resource, migrations, plantar/cosechar trigo, vender a NPC, firmar y cumplir contrato, drone deploy. **Balance pass** de toda la economía: precios canon por cultivo ajustados, salarios, costes operativos, calibración de fórmula de calidad. Foco: ratio de ingresos/gastos del Bible §14.3 (120-140% para sesión casual).

**Deliverables.**

- Tests automatizados (lua-test o similar para server, vitest para NUI).
- `config/economy.lua` finalmente balanceado.
- Documento `docs/economy_balance_v1.md` con la mesa de números canon firmada.

**Dependencias:** todo lo anterior.

---

### S34 — Closed beta + iteración · Complejidad: XL

**Scope.** 3-5 servidores partner reciben Farm Sonar v0.9. Recogida de feedback estructurada (cuestionario + sesiones de debug remoto). Iteración sobre los 3-5 issues más impactantes.

**Deliverables.**

- Build v0.9 distribuible.
- Cuestionario beta + canal Discord privado para partners.
- Bug fixes priorizados.
- v0.95 build con fixes.

**Dependencias:** S33.

---

### S35 — Tebex packaging + Asset Escrow + docs cliente 🏁 · Complejidad: L

**Scope.** Empaquetado final del producto. Asset Escrow encriptado para los archivos protegibles (sin romper deps). Documentación cliente: install guide, config reference, admin commands, troubleshooting. Página Tebex con descripción + screenshots + trailer (grabados durante slices marcados ⭐).

**Deliverables.**

- Build v1.0 con escrow.
- `docs/cliente/install.md` (en + es).
- `docs/cliente/config.md`.
- `docs/cliente/admin_commands.md`.
- `docs/cliente/troubleshooting.md`.
- Trailer 60s editado.
- 8-10 screenshots clave.
- Tebex listing publicado.

**Dependencias:** S34.

**Marketing value:** 🏁 — el slice de cierre. Lanzamiento público.

---

## 4. Risk Register

Riesgos identificados que debemos vigilar a lo largo del roadmap:

| ID  | Riesgo                                               | Slice afectado | Mitigación                                                   |
| --- | ---------------------------------------------------- | -------------- | ------------------------------------------------------------ |
| R1  | Persistencia delta-calc rompe arquitectura           | S5, S11        | Risk-first en Fase 1, schema con timestamps desde día 1      |
| R2  | Drones (NUI render-to-texture) técnicamente inviable | S28            | Spike técnico 1-2 días antes de comprometerse al slice       |
| R3  | Balance económico desbalanceado a la salida          | S33            | Closed beta + iteración con datos reales                     |
| R4  | Bridge QBox/QBCore divergencias profundas            | S1             | Documentar interfaz exhaustiva, tests en ambos por slice     |
| R5  | Performance con muchas parcelas activas              | S6, S11, S16   | Scheduler tick-based, no per-frame; budgets de DB query      |
| R6  | UI design no escala al subir densidad de datos       | S26, S31       | Mockups v0.dev validados antes de cada app                   |
| R7  | i18n con strings olvidados al final                  | S32            | Lint custom desde S4 que detecta strings hardcoded           |
| R8  | Asset Escrow bloquea extensibilidad por terceros     | S35            | Definir qué archivos son escrow-protegidos vs config abierto |
| R9  | Contratos B2B con bugs en escrow → pérdida dinero    | S21            | Tests obligatorios FSM + reconciliación en boot              |
| R10 | Clima FiveM cliente desync con server-authoritative  | S16            | Documentar gotchas conocidos, sync pattern probado           |

---

## 5. Cadencia de demos internos

Para mantener momentum + validación temprana, demos cortos al cierre de cada fase:

| Demo       | Cuándo        | Qué se enseña                                            | Audiencia                         |
| ---------- | ------------- | -------------------------------------------------------- | --------------------------------- |
| **Demo 0** | Cierre Fase 0 | Laptop abre con dashboard placeholder + identidad visual | Founder + circle interno          |
| **Demo 1** | Cierre Fase 1 | ⭐ Clip 15s: plantar → cosechar → vender trigo           | Founder + posibles beta partners  |
| **Demo 2** | Cierre Fase 2 | Granja con 8 cultivos + clima + plagas                   | Founder + beta partners           |
| **Demo 3** | Cierre Fase 3 | Mundo vivo: NPCs piden, contratos vivos                  | Founder + beta partners           |
| **Demo 4** | Cierre Fase 4 | Equipo 4 jugadores con permisos operando                 | Founder + beta partners           |
| **Demo 5** | Cierre Fase 5 | ⭐⭐ Trailer Tebex 60s con drones + market intel         | Founder + público (teaser social) |
| **Demo 6** | Cierre Fase 6 | 🏁 Producto en Tebex live                                | Mundo                             |

---

## 6. Mapa de dependencias clave

```
S0 ──┬─ S1 ── S2 ── S3 (Banca) ──┐
     │                            │
     └─ S4 (NUI shell) ───────────┤
                                  ▼
                          S5 (Plots) ── S6 (Trigo) ── S7 (Item Físico)
                                              │            │
                                              ▼            │
                                          S8 (Calidad) ◄───┘
                                              │
                                              ▼
                              S9 (Silo) ── S10 (NPC vendor) ── S11 (Persistencia)
                                                                   │
                              ┌────────────────────────────────────┘
                              ▼
                S12-S18 (Depth & Scale) ── S19-S22 (Economy Alive)
                                                    │
                                                    ▼
                                          S23-S27 (Empresa)
                                                    │
                                                    ▼
                                      S28-S31 (WOOOW Tech Stack)
                                                    │
                                                    ▼
                                       S32-S35 (Polish & Launch)
                                                    │
                                                    ▼
                                            🏁 Tebex live
```

---

## 7. Próximos pasos inmediatos

1. **Validar este roadmap** con el founder. ✅
2. **Mini-brief de S0** en `docs/slices/S0_workspace_skeleton.md` cuando arranquemos implementación.
3. **Spike técnico de R2 (drones NUI render-to-texture)** programado para antes de empezar S28 — idealmente entre Fase 2 y Fase 3 (cuando hay menos presión de slices core) para tener tiempo de pivotar si el approach técnico no funciona.
4. **Sesión v0.dev dedicada** antes de S4 para refinar paleta hex exacta + componentes shadcn base del design system.
5. **Crear `docs/02_DECISIONS.md`** vacío (ADR log) listo para recibir ADRs durante slices.
6. **Crear `docs/slices/`** vacío listo para mini-briefs.

---

## 8. Changelog

| Versión | Fecha      | Cambios                                                                                                                                                                                                                                                              |
| ------- | ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1.0** | 2026-05-04 | Primera versión firmada. 6 fases · 36 slices · ~5-7 meses con AI agents. Risk-first: persistencia delta-calc en Fase 1. Marketing-driven: Fase 5 WOOOW Tech Stack (drones + probe + market intel) antes del launch para competir con grandes estudios FiveM premium. |
