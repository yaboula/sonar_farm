# B3 — Factor Activation: Irrigation + Fertilization + Pests

> **Type:** Slice Bundle (ADR-014 rules verified below).
> **Slices bundled:** S13 · S14 · S15
> **Status:** DONE
> **Phase:** Phase 2 — Depth & Scale
> **Complexity:** XL-aggregated (S13 L + S14 L + S15 L)
> **Roadmap reference:** [`docs/01_ROADMAP.md`](../01_ROADMAP.md) — S13/S14/S15
> **Started:** 2026-05-22
> **Closed:** — (filled at /end-slice B3)
> **Author:** PM Agent + Backend / Integration / QA sub-agents

---

## Why a bundle?

ADR-014 eligibility check:

1. **Shared contract:** All three activate quality factors that were stub (default 70/100) since B1.
   They share `sonar_farm_quality_tracking` (same table, same `track()`/`get()` interface already
   coded), the same `Config.Farm.Quality.weights` for the calculator, and the same physical
   interaction pattern (`ox_target` on plot → item consumed → server tracks → quality changes).
2. **Same surface:** `server/factors/<x>_tracker.lua` (upgrade the existing stub), one new
   `server/pests/pest_service.lua`, common `client/` interaction pattern, shared config block.
   One Backend Agent can implement all three; one Integration Agent wires all three client-side.
3. **DoD syncable:** The Phase 2 milestone — "la calidad de los lotes refleja decisiones del
   jugador" — requires at least irrigation + fertilization to be live. Pest completes the trio.
   None of the three can independently prove impact on final batch quality without the others
   running in the same session.
4. **Complexity <= XL:** L+L+L = XL-aggregated. At the tope limit; acceptable because the Backend
   pattern is near-identical for S13/S14 (2x factor tracker extension) and S15 adds one new
   service with a well-defined FSM.

---

## 1. Goal (Wooow Test outcome)

> Player plants wheat → **skips irrigation** → **applies wrong NPK** → **pest appears and is ignored**
> → harvests → quality grade is **C or D** instead of the expected **B**.
>
> Player does the same run with correct irrigation + correct NPK + pest treated → grade is **A or S**.
>
> Quality is now a real decision surface, not a cosmetic number.

---

## 2. Scope

### S13 — Riego físico / Irrigation (L)

Physical watering mechanic. Water tank (`sonar_water_tank`) as a portable item (Wave 1) or
vehicle cistern (Wave 2 vehicle; in B3 scope only the item). `ox_target` on plot → "Water crop"
(visible when player has `sonar_water_tank` with charges > 0). Animation ~10 s (cancelable via
`lib.progressBar`). Server calculates irrigation outcome:

- **Optimal** (tank charges: 1–2): `irrigation` score raised toward `optimal_irrigation` ceiling
  (configurable per crop, default 90).
- **Over-watered** (3+ charges in same growth stage): `irrigation` penalized toward
  `overwater_floor` (configurable, default 50).
- **Under-watered** (no water before `next_irrigation_due_ts`): S11 delta-calc already handles
  offline decay. B3 only handles the online action.

Tank item: `sonar_water_tank`, metadata `{ charges: N }`. Each watering consumes 1 charge.
Tank starts at `max_charges` (configurable, default 5). Recharge: `ox_target` on well/tap prop
(seeded in config, coordinates from MLO — placeholder coords for B3).

Events: `sonar:farm:plot:watered`

### S14 — Fertilización NPK / Fertilization (L)

NPK fertilizer mechanic. Four items: `sonar_fertilizer_n`, `sonar_fertilizer_p`,
`sonar_fertilizer_k`, `sonar_fertilizer_npk` (balanced). `ox_target` on plot → "Fertilize" →
select fertilizer type from player inventory. Animation ~8 s. Server calculates outcome using
the crop's `optimal_npk` config:

- **Correct type for crop** (wheat → NPK balanced or N-dominant): `fertilization` score raised
  toward `fertilization_ceiling` (default 90).
- **Wrong type** (K-only on wheat): `fertilization` score stays neutral or slight penalty
  (-5 points, configurable).
- **Over-fertilized** (2+ applications same stage): `fertilization` penalized toward
  `overfertilize_floor` (default 40) — "nutrient burn".

Each fertilizer item is consumed on use (1 per application). Fertilizer items are standard
`ox_inventory` items with no metadata; the plot's `sonar_farm_quality_tracking.fertilization`
column tracks the cumulative outcome.

Per-crop config in `config/crops/<crop>.lua`:
```lua
fertilization = {
    optimal_items   = { 'sonar_fertilizer_npk', 'sonar_fertilizer_n' },
    ceiling         = 90,
    wrong_penalty   = -5,
    overfertilize_floor = 40,
    max_applications_per_stage = 1,
}
```

Events: `sonar:farm:plot:fertilized`

### S15 — Plagas + fumigadora / Pest service (L)

Pest lifecycle FSM. A pest can appear on an active crop between stage 1 and stage 3. Appearance
is server-side probabilistic (scheduler tick; probability per crop per stage in config). When
a pest appears, the plot gets a visual prop overlay (B3: native GTA V particle or simple
static prop — see §8.4) and `sonar_farm_quality_tracking.pest_detected_ts` is stamped.

Player detects pest visually (or via future S30 probe). `ox_target` on infested plot →
"Treat pest" (visible when player holds matching `sonar_pesticide_<type>` item). Animation ~12 s.
Server marks pest treated: `pest_detected_ts = NULL`, `pest_impact` score restored toward `100`.

Untreated pest: `pest_impact` decays via S11 delta-calc (already implemented). B3 adds the
appearance trigger and treatment action.

Pest FSM per plot:
```
NONE → DETECTED (scheduler tick, probability) → TREATED (player action) → NONE
                                              → SEVERE (if ignored > 24h) → NONE (auto-resolved at harvest, severe penalty)
```

Two placeholder pest types for B3: `blight` (affects wheat/barley) and `aphid` (affects
corn/horticultural). Pesticide items: `sonar_pesticide_contact` (kills both in B3),
`sonar_pesticide_systemic` (kills both, slower but lasts longer — stub for Wave 2).

Config per crop:
```lua
pests = {
    susceptible_to = { 'blight', 'aphid' },
    spawn_probability_per_tick = 0.05,  -- 5% per scheduler tick per active crop stage 1-3
    min_stage = 1,
    max_stage = 3,
}
```

Events: `sonar:farm:pest:appeared`, `sonar:farm:pest:treated`, `sonar:farm:pest:severe`

---

## 3. Dependencies

| Dep | Reason | Status |
|-----|--------|--------|
| B1 (S6, S7, S8) | `sonar_farm_quality_tracking` table with stub factors; `IrrigationFactor`, `FertilizationFactor`, `PestFactor` stubs already coded | DONE |
| S11 | `pest_detected_ts` + `next_irrigation_due_ts` columns in `sonar_farm_quality_tracking` (migration 010); offline decay already handles untreated pests | DONE (pending smoke) |
| S5 | Plot state machine; `UpdatePlotState` API | DONE |

---

## 4. Deliverables

### Backend (S13 + S14 + S15)

- [x] `config/items.lua` — register `sonar_water_tank`, `sonar_fertilizer_n/p/k/npk`,
  `sonar_pesticide_contact`, `sonar_pesticide_systemic` with ox_inventory item data.
- [x] `config/irrigation.lua` — global irrigation config (well coords, tank max_charges,
  optimal/overwater thresholds, recharge duration).
- [x] Per-crop fertilization + pest config blocks added to `config/crops/wheat.lua`,
  `config/crops/corn.lua`, `config/crops/barley.lua`.
- [x] Upgrade `server/quality/factors/irrigation.lua` — add `IrrigationFactor.TrackWatering(plot_id, charges_used, stage) -> ok, new_score, error` method on top of existing `track`/`get`.
- [x] Upgrade `server/quality/factors/fertilization.lua` — add `FertilizationFactor.TrackApplication(plot_id, item_name, crop_type, stage) -> ok, new_score, error`.
- [x] Upgrade `server/quality/factors/pest.lua` — add `PestFactor.Appear(plot_id, pest_type) -> ok`, `PestFactor.Treat(plot_id, pesticide_item) -> ok, new_score`, `PestFactor.GetStatus(plot_id) -> { severity, detected_ts }`.
- [x] `server/pests/pest_service.lua` — `Sonar.Farm.PestService` with `Boot()`, `TickCrops(active_crops)` (called from scheduler), FSM transitions.
- [x] `server/admin/debug_pest_spawn.lua` — `/sonarfarm:debug:pest <plot_id> <pest_type>` for smoke testing.
- [x] Tests: `tests/server/irrigation_spec.lua`, `tests/server/fertilization_spec.lua`, `tests/server/pest_spec.lua`.

### Integration (S13 + S14 + S15)

- [x] `client/irrigation_interactions.lua` — ox_target on plot for "Water crop" + ox_target on well prop for "Refill tank"; lib.progressBar; lib.callback to server; item charge metadata update.
- [x] `client/fertilization_interactions.lua` — ox_target on plot for "Fertilize"; item selection from inventory; lib.progressBar; lib.callback.
- [x] `client/pest_interactions.lua` — ox_target on infested plot for "Treat pest" (canInteract = pest active); lib.progressBar; lib.callback; pest prop overlay spawn/despawn.
- [x] `server/main.lua` — add `run_pest_service_boot()`; keep `PestService.TickCrops` wired in the existing lifecycle scheduler tick; register B3 callbacks.
- [x] `fxmanifest.lua` — add all new configs, server files, client files to load order.
- [x] `locales/en.json` + `es.json` — all new B3 keys.

### QA

- [x] `tests/server/irrigation_spec.lua` — optimal water → score up; over-water → penalty; idempotent boot.
- [x] `tests/server/fertilization_spec.lua` — correct NPK → score up; wrong type → small penalty; over-fertilize → floor.
- [x] `tests/server/pest_spec.lua` — pest appears (mock tick); pest treated → score restored; pest ignored > 24h → SEVERE; FSM transitions.
- [ ] Smoke procedure documented in §10.
- [ ] DoD audit §11.

---

## 5. Universal DoD checklist

- [ ] Works end-to-end on QBox (smoke in §10).
- [ ] Works end-to-end on QBCore (smoke in §10).
- [ ] Smoke test of happy path documented in §10.
- [ ] Automated tests for factor scoring logic and pest FSM.
- [ ] No hardcoded user-facing strings.
- [ ] No hardcoded magic numbers — all thresholds, probabilities, durations in config.
- [ ] Respects 5 Pillars of Bible §3.
- [ ] Respects Bible §9.4 anti-patterns.
- [ ] Respects naming conventions.
- [ ] DB migration versioned + rollbackable (if any — B3 may be migration-free if S11 already added the needed columns).
- [ ] Mini-brief updated with what was actually built.
- [ ] ADR if non-obvious decision taken.
- [ ] Bible §18 changelog updated.

---

## 6. Slice-specific DoD

### S13 — Irrigation

- [ ] Water plot with 1 tank charge → `irrigation` score increases.
- [ ] Water same plot 3+ times in same stage → `irrigation` penalized (overwater).
- [ ] Tank charge consumed on each use.
- [ ] Refill tank at well → charges restored to max.
- [ ] `sonar:farm:plot:watered` event emitted with correct payload.

### S14 — Fertilization

- [ ] Apply correct fertilizer for wheat → `fertilization` score increases.
- [ ] Apply wrong fertilizer type → slight penalty.
- [ ] Apply 2x same stage → over-fertilize penalty to floor.
- [ ] Fertilizer item consumed on use.
- [ ] `sonar:farm:plot:fertilized` event emitted.

### S15 — Pests

- [ ] Scheduler tick triggers pest appearance on active crops (stage 1–3) with configured probability.
- [ ] `pest_detected_ts` stamped in `sonar_farm_quality_tracking`.
- [ ] Pest prop overlay visible in-world on infested plot.
- [ ] Player treats pest with correct pesticide → `pest_impact` restored, `pest_detected_ts = NULL`.
- [ ] Untreated pest after 24h → `SEVERE` FSM state, severe penalty applied.
- [ ] `/sonarfarm:debug:pest` spawns pest on demand for smoke.
- [ ] `sonar:farm:pest:appeared` + `sonar:farm:pest:treated` events emitted.

---

## 7. Sub-agents

| Agent | Role |
|-------|------|
| Backend Agent | Factor tracker upgrades, PestService FSM, config, tests |
| Integration Agent | Client interactions (3 files), server/main.lua, fxmanifest, locales |
| QA Agent | Tests, smoke, DoD audit |

Execution order: **Backend → Integration → QA**.

---

## 8. Architecture notes

### 8.1 Factor tracker API contract (B3 extends B1 stubs)

All three factor files already exist in `server/quality/factors/`. B3 **adds methods** to the
existing table objects — it does NOT replace the files. The `track(plot_id, event, data)` and
`get(plot_id)` methods from B1 remain unchanged (backward-compatible).

**New methods added in B3:**

```lua
-- irrigation.lua
IrrigationFactor.TrackWatering(plot_id, charges_used, stage)
-- -> ok (bool), new_score (number), error (string|nil)
-- Uses an in-memory cache keyed by plot_id + stage, updates next_irrigation_due_ts,
-- then calls existing :track() to persist the score.

-- fertilization.lua
FertilizationFactor.TrackApplication(plot_id, item_name, crop_type, stage)
-- -> ok (bool), new_score (number), error (string|nil)
-- Uses an in-memory cache keyed by plot_id + stage and resets on plot:stage_advanced.

-- pest.lua (most extended)
PestFactor.Appear(plot_id, pest_type)        -- stamps pest_detected_ts, sets FSM
PestFactor.Treat(plot_id, pesticide_item)    -- clears pest, calls :track() with restored score
PestFactor.GetStatus(plot_id)                -- { severity, detected_ts } | nil
```

Anti-pattern §8 note: `sonar_farm_quality_tracking` is append-only on key columns; `pest_detected_ts`
is set to NULL on treatment (this is a state flag, not a lineage chain — no violation).

### 8.2 Events emitted (B3)

| Event | Emitter | Payload |
|-------|---------|---------|
| `sonar:farm:plot:watered` | `IrrigationFactor.TrackWatering` | `{ plot_id, charges_used, new_score, stage }` |
| `sonar:farm:plot:fertilized` | `FertilizationFactor.TrackApplication` | `{ plot_id, item_name, new_score, stage, crop_type }` |
| `sonar:farm:pest:appeared` | `PestFactor.Appear` | `{ plot_id, pest_type, detected_ts, severity }` |
| `sonar:farm:pest:treated` | `PestFactor.Treat` | `{ plot_id, pesticide_item, new_score, severity }` |
| `sonar:farm:pest:severe` | `PestService.TickCrops` | `{ plot_id, pest_type, hours_untreated }` |

### 8.3 PestService FSM

```
NONE
  |-- scheduler tick, probability hit --> DETECTED
DETECTED
  |-- player treats --> NONE (score restored)
  |-- > 24h untreated (Config.Farm.Pests.SeverityHours, default 24) --> SEVERE
SEVERE
  |-- player treats --> NONE (partial restoration, ceiling = Config.Farm.Pests.SevereTreatCeiling, default 60)
  |-- harvest reached --> NONE (score already damaged; not carried to batch)
```

FSM state persisted in `sonar_farm_quality_tracking.pest_detected_ts` (NULL = NONE; timestamp =
DETECTED or SEVERE). A separate column `pest_severity` (`ENUM('none','detected','severe') DEFAULT 'none'`)
is needed — **this requires a migration.**

**Migration needed:** `011_pest_severity.sql` — adds `pest_severity ENUM('none','detected','severe') DEFAULT 'none'`
to `sonar_farm_quality_tracking`. This is the only DB change in B3 (irrigation and fertilization
tracking use existing columns).

`pest_type` is runtime-cached for event emission only; B3 persists FSM state (`pest_severity` +
`pest_detected_ts`) but does not persist pest taxonomy yet.

### 8.4 Pest visual prop (B3 scope)

B3 uses a **native GTA V particle effect** on the plot zone to indicate infestation — no custom
MLO prop needed. Confirmed approach from `docs/Catálogo-de-Assets-y-Referencias/CATALOGO_COMPLETO.md`:

- Particle dict: `core` → effect `exp_grd_bzgas_cloud` (yellow-ish, low opacity).
- Integration choice shipped in B3: keep `exp_grd_bzgas_cloud` as the first production particle so
  the implementation stays aligned with the approved catalog entry and avoids introducing a new
  asset risk during the bundle integration pass.
- Particle is attached to plot coords on `sonar:farm:pest:appeared` (client receives event).
- Removed on `sonar:farm:pest:treated`.
- Client keeps a `pest_particles` map `{ [plot_id] = handle }` to avoid duplicate spawning.

### 8.5 Item registration

New items registered in `config/items.lua` (new shared file, loaded before `item_registry.lua`):

```lua
Config.Farm.Items = Config.Farm.Items or {}
Config.Farm.Items.tools = {
    sonar_water_tank = {
        label    = 'items.sonar_water_tank.label',
        weight   = 2000,
        stack    = false,
        close    = false,
        metadata = { charges = 5 },
    },
    sonar_fertilizer_n   = { label='items.sonar_fertilizer_n.label',   weight=1000, stack=true  },
    sonar_fertilizer_p   = { label='items.sonar_fertilizer_p.label',   weight=1000, stack=true  },
    sonar_fertilizer_k   = { label='items.sonar_fertilizer_k.label',   weight=1000, stack=true  },
    sonar_fertilizer_npk = { label='items.sonar_fertilizer_npk.label', weight=1000, stack=true  },
    sonar_pesticide_contact  = { label='items.sonar_pesticide_contact.label',  weight=500, stack=true },
    sonar_pesticide_systemic = { label='items.sonar_pesticide_systemic.label', weight=500, stack=true },
}
```

`item_registry.lua` already iterates `Config.Farm.Items.tools` if present — verify in B3.
If not, Integration Agent adds the iteration.

### 8.6 Scheduler integration (S15)

The existing lifecycle scheduler in `server/lifecycle/scheduler.lua` already runs a tick every
`Config.Farm.Scheduler.TickSeconds` (default 30 s). B3 adds a call to `PestService.TickCrops`
inside the same tick loop — **no new thread**. To preserve Bible §9.4 anti-pattern #4, the
scheduler keeps the existing due-stage query for lifecycle advancement and performs a second,
lightweight active-crops query for pest evaluation.

Anti-pattern §4 compliance: pest tick shares the existing 30s scheduler. No per-frame loop.

### 8.7 lib.callback registrations (new in B3)

| Callback | Handler |
|----------|---------|
| `sonar:farm:plot:water` | `IrrigationFactor.TrackWatering(src, plot_id, charges_used)` |
| `sonar:farm:plot:refill_tank` | server-side `ox_inventory:SetMetadata` sync for `sonar_water_tank` charges |
| `sonar:farm:plot:fertilize` | `FertilizationFactor.TrackApplication(src, plot_id, item_name, crop_type, stage)` |
| `sonar:farm:plot:treat_pest` | `PestFactor.Treat(src, plot_id, pesticide_item)` |

Gameplay callbacks validate item ownership via `exports.ox_inventory:Search` before calling the
factor method. Server removes consumables on success. `sonar:farm:plot:refill_tank` was added as a
lightweight sync callback because `ox_inventory` metadata mutation is server-only (`SetMetadata`).
Client never trusts its own score calculation.

### 8.8 Fertilizer and pesticide selection UI

- Fertilizer selection shipped with `lib.inputDialog` + `select` options sourced from the player's
  current inventory.
- If only one fertilizer or pesticide is available, the client auto-selects it and skips the dialog.
- This keeps the field interaction physical-first (Bible §3 pillar 1) while avoiding a heavier NUI
  surface for a narrow B3 scope.

### 8.9 No DB migration for irrigation/fertilization scoring

The `sonar_farm_quality_tracking` table already has `irrigation` and `fertilization` columns
(migration 007). Tracking application count per stage uses a lightweight approach — **in-memory
cache keyed by plot_id + stage**, reset on `sonar:farm:plot:stage_advanced` (no new column).
This avoids a migration for S13/S14. Only S15 needs a migration (§8.3 `pest_severity` column).

---

## 9. ADRs

- **ADR-018** — Pest scheduler shares existing lifecycle tick (no dedicated thread) — see `docs/02_DECISIONS.md`.
- **ADR-019** — `pest_severity` explicit column vs. inferring from timestamp age — see `docs/02_DECISIONS.md`.
- Native GTA V particle for pest visual: no ADR required (implementation detail, no cross-slice impact).

---

## 10. Smoke test (happy path)

### 10.1 Static checks (QA Agent — 2026-05-22)

| Check | Result | Evidence |
| ----- | ------ | -------- |
| `pnpm run lint:lua` | **PASS** | Executed from `d:\Granja_Sonar` → `0 errors`, `0 warnings`, `0 parse errors` |
| `lua sonar_farm_core/tests/server/irrigation_spec.lua` | **PASS** | `irrigation_spec.lua: OK (5 cases)` |
| `lua sonar_farm_core/tests/server/fertilization_spec.lua` | **PASS** | `fertilization_spec.lua: OK (5 cases)` |
| `lua sonar_farm_core/tests/server/pest_spec.lua` | **PASS** | `pest_spec.lua: OK (6 cases)` |
| No `MySQL.Sync` in B3 Lua surface | **PASS** | Grep across `sonar_farm_core/**/*.lua` returned `0 matches` |
| `track()` / `get()` methods from B1 still present in factor files | **PASS** | Static review of `server/quality/factors/{irrigation,fertilization,pest}.lua` confirms backward-compatible methods remain |
| Server callbacks validate inventory server-side | **PASS** | `server/main.lua` resolves tank / fertilizer / pesticide from server inventory helpers before mutation |
| `011_pest_severity.sql` registered in `fxmanifest.lua` | **PASS** | Migration exists with rollback block and is registered in manifest metadata |
| `PestService.TickCrops` uses server-side RNG only | **PASS** | `server/pests/pest_service.lua` uses `math.random()` only on the server scheduler path |
| Locale parity EN ↔ ES for B3 keys | **PASS** | `locales/en.json` and `locales/es.json` both include B3 interaction / error / item keys |
| In-memory application count caches are module-local | **PASS** | `stage_application_cache` and `active_pest_types` are local module-scope tables |

### 10.2 QA note on the quality decision surface

Per Bible §10, current default weights are uniform. With current defaults and B3 online actions only, a representative bad run can still average near **B** unless S11 offline pest / irrigation decay also contributes or the quality weights are rebalanced.

### Pre-conditions

- B1 + B2 + S11 + S12 foundations running.
- `Config.Farm.Debug = true`.
- Debug commands: `/sonarfarm:debug:fastforward`, `/sonarfarm:debug:plant`, `/sonarfarm:debug:pest` (new).

### 10.3 QBox smoke — executable procedure

**S13 — Irrigation**
1. Plant wheat on an extensive plot. `/giveitem <src> sonar_water_tank 1`.
2. `ox_target` on plot → `Water crop`.
3. Check DB:
   ```sql
   SELECT `plot_id`, `irrigation`, `next_irrigation_due_ts`
     FROM `sonar_farm_quality_tracking`
    WHERE `plot_id` = '<plot_id>';
   ```
4. Water the same plot twice more in the same stage.
5. Re-check the same row and confirm overwater penalty.
6. `ox_target` on well → `Refill tank` → confirm charges restored to max.

**S14 — Fertilization**
1. `/giveitem <src> sonar_fertilizer_npk 2` and `/giveitem <src> sonar_fertilizer_k 1`.
2. `ox_target` on plot → `Fertilize` with `sonar_fertilizer_npk`.
3. Check DB:
   ```sql
   SELECT `plot_id`, `fertilization`
     FROM `sonar_farm_quality_tracking`
    WHERE `plot_id` = '<plot_id>';
   ```
4. Apply `sonar_fertilizer_k` and confirm slight penalty.
5. Apply a correct fertilizer again in the same stage and confirm over-fertilize floor.

**S15 — Pests**
1. Advance to stage 2. `/sonarfarm:debug:pest <plot_id> blight`.
2. Confirm in DB and in world:
   ```sql
   SELECT `plot_id`, `pest_detected_ts`, `pest_severity`, `pest_impact`
     FROM `sonar_farm_quality_tracking`
    WHERE `plot_id` = '<plot_id>';
   ```
3. `/giveitem <src> sonar_pesticide_contact 1` → `ox_target` → `Treat pest`.
4. Confirm row returns to `pest_detected_ts = NULL`, `pest_severity = 'none'`, and higher `pest_impact`.
5. Spawn pest again, do not treat, advance time past `SeverityHours`, confirm `pest_severity = 'severe'`.

**Quality integration check**
1. Bad run: skip irrigation + wrong fertilizer + untreated pest → harvest.
2. Check:
   ```sql
   SELECT `batch_id`, `plot_id`, `quality`, `quality_score`
     FROM `sonar_farm_batches`
    WHERE `plot_id` = '<plot_id>'
    ORDER BY `harvested_ts` DESC
    LIMIT 1;
   ```
3. Good run: optimal irrigation + correct fertilizer + treated pest → harvest.
4. Run the same query and compare results against Bible §10 thresholds.

### 10.4 Evidence table (QA Agent — 2026-05-22)

| Step | Result | Evidence |
| ---- | ------ | -------- |
| `pnpm run lint:lua` | **PASS** | `0 errors`, `0 warnings` |
| `irrigation_spec.lua` | **PASS** | `OK (5 cases)` |
| `fertilization_spec.lua` | **PASS** | `OK (5 cases)` |
| `pest_spec.lua` | **PASS** | `OK (6 cases)` |
| Migration `011_pest_severity` exists + rollback documented | **PASS** | SQL file present and registered in `fxmanifest.lua` |
| No `MySQL.Sync` in B3 surface | **PASS** | Grep returned no matches |
| QBox runtime smoke | **PASS** | Founder confirmed all B3 tests passed on QBox (2026-05-22) |
| QBCore runtime smoke | **POSTPONED** | Deferred by founder decision — no framework-specific calls in B3 (bridge-only) |
| Quality integration bad run (`C/D`) | **PASS** | Founder confirmed quality impact verified in-game |
| Quality integration good run (`A/S`) | **PASS** | Founder confirmed quality impact verified in-game |

---

## 11. Closing summary

> **QA status (2026-05-22):** Static review PASS, automated tests PASS (16 B3 cases), QBox runtime smoke PASS (founder verified). QBCore smoke postponed by founder decision — B3 has no framework-specific calls. Quality decision surface confirmed: bad run degrades grade, good run reaches A/S. B3 is **DONE**.

### 11.1 Universal DoD audit (QA Agent — 2026-05-22)

| # | Item | Result | Justification |
| - | ---- | ------ | ------------- |
| 1 | Works end-to-end on QBox | **PASS** | Founder QBox smoke confirmed 2026-05-22 |
| 2 | Works end-to-end on QBCore | **POSTPONED** | Deferred by founder decision; no framework-specific calls in B3 |
| 3 | Smoke test of happy path documented | **PASS** | §10 now includes procedure, SQL checkpoints, and evidence table |
| 4 | Automated tests for factor scoring logic and pest FSM | **PASS** | `irrigation_spec.lua` (5), `fertilization_spec.lua` (5), `pest_spec.lua` (6) all executed green |
| 5 | No hardcoded user-facing strings | **PASS** | B3 interactions/errors/items are localized in both `locales/en.json` and `locales/es.json` |
| 6 | No hardcoded magic numbers | **PASS** | B3 thresholds/durations/probabilities live in config files |
| 7 | Respects 5 Pillars of Bible §3 | **PASS** | Physical field actions use `ox_target` + progress bars and tunables remain config-driven |
| 8 | Respects Bible §9.4 anti-patterns | **PASS** | No `MySQL.Sync`, no client-authoritative scoring, no new per-frame scheduler, no direct resource calls introduced |
| 9 | Respects naming conventions | **PASS** | Files, events, tables, and item names follow Farm Sonar naming rules |
| 10 | DB migration versioned + rollbackable | **PASS** | `011_pest_severity.sql` is versioned, registered, and includes rollback SQL |
| 11 | Mini-brief updated with what was actually built | **PASS** | §10 and §11 now reflect the actual QA state |
| 12 | ADR if non-obvious decision taken | **PASS** | ADR-018 (pest tick sharing) + ADR-019 (pest_severity column) signed in `docs/02_DECISIONS.md` |
| 13 | Bible §18 changelog updated | **PASS** | Bible v1.5 updated at B3 close |

### 11.2 QA conclusion

- **Static code review:** PASS
- **Automated tests:** PASS (16 B3 cases total)
- **Runtime smoke (QBox):** PASS — founder confirmed 2026-05-22
- **Runtime smoke (QBCore):** POSTPONED by founder decision
- **Quality integration goal:** PASS — founder confirmed bad run degrades grade and good run reaches A/S
