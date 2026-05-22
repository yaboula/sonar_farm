# B3 — Factor Activation: Irrigation + Fertilization + Pests

> **Type:** Slice Bundle (ADR-014 rules verified below).
> **Slices bundled:** S13 · S14 · S15
> **Status:** ACTIVE
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

- [ ] `config/items.lua` — register `sonar_water_tank`, `sonar_fertilizer_n/p/k/npk`,
  `sonar_pesticide_contact`, `sonar_pesticide_systemic` with ox_inventory item data.
- [ ] `config/irrigation.lua` — global irrigation config (well coords, tank max_charges,
  optimal/overwater thresholds, recharge duration).
- [ ] Per-crop fertilization + pest config blocks added to `config/crops/wheat.lua`,
  `config/crops/corn.lua`, `config/crops/barley.lua`.
- [ ] Upgrade `server/quality/factors/irrigation.lua` — add `IrrigationFactor.TrackWatering(plot_id, charges_used, stage) -> ok, new_score, error` method on top of existing `track`/`get`.
- [ ] Upgrade `server/quality/factors/fertilization.lua` — add `FertilizationFactor.TrackApplication(plot_id, item_name, stage) -> ok, new_score, error`.
- [ ] Upgrade `server/quality/factors/pest.lua` — add `PestFactor.Appear(plot_id, pest_type) -> ok`, `PestFactor.Treat(plot_id, pesticide_item) -> ok, new_score`, `PestFactor.GetStatus(plot_id) -> { active_pest, severity, detected_ts }`.
- [ ] `server/pests/pest_service.lua` — `Sonar.Farm.PestService` with `Boot()`, `TickCrops(active_crops)` (called from scheduler), FSM transitions.
- [ ] `server/admin/debug_pest_spawn.lua` — `/sonarfarm:debug:pest <plot_id> <pest_type>` for smoke testing.
- [ ] Tests: `tests/server/irrigation_spec.lua`, `tests/server/fertilization_spec.lua`, `tests/server/pest_spec.lua`.

### Integration (S13 + S14 + S15)

- [ ] `client/irrigation_interactions.lua` — ox_target on plot for "Water crop" + ox_target on well prop for "Refill tank"; lib.progressBar; lib.callback to server; item charge metadata update.
- [ ] `client/fertilization_interactions.lua` — ox_target on plot for "Fertilize"; item selection from inventory; lib.progressBar; lib.callback.
- [ ] `client/pest_interactions.lua` — ox_target on infested plot for "Treat pest" (canInteract = pest active); lib.progressBar; lib.callback; pest prop overlay spawn/despawn.
- [ ] `server/main.lua` — add `run_pest_service_boot()`; integrate `PestService.TickCrops` into the existing lifecycle scheduler tick; register 3 new lib callbacks.
- [ ] `fxmanifest.lua` — add all new configs, server files, client files to load order.
- [ ] `locales/en.json` + `es.json` — all new B3 keys.

### QA

- [ ] `tests/server/irrigation_spec.lua` — optimal water → score up; over-water → penalty; idempotent boot.
- [ ] `tests/server/fertilization_spec.lua` — correct NPK → score up; wrong type → small penalty; over-fertilize → floor.
- [ ] `tests/server/pest_spec.lua` — pest appears (mock tick); pest treated → score restored; pest ignored > 24h → SEVERE; FSM transitions.
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
-- Reads current score, applies delta, calls existing :track() to persist.

-- fertilization.lua
FertilizationFactor.TrackApplication(plot_id, item_name, crop_type, stage)
-- -> ok (bool), new_score (number), error (string|nil)
-- Reads application count this stage from DB, calculates outcome, calls :track().

-- pest.lua (most extended)
PestFactor.Appear(plot_id, pest_type)        -- stamps pest_detected_ts, sets FSM
PestFactor.Treat(plot_id, pesticide_item)    -- clears pest, calls :track() with restored score
PestFactor.GetStatus(plot_id)                -- { active_pest, severity, detected_ts } | nil
```

Anti-pattern §8 note: `sonar_farm_quality_tracking` is append-only on key columns; `pest_detected_ts`
is set to NULL on treatment (this is a state flag, not a lineage chain — no violation).

### 8.2 Events emitted (B3)

| Event | Emitter | Payload |
|-------|---------|---------|
| `sonar:farm:plot:watered` | `IrrigationFactor.TrackWatering` | `{ plot_id, player_cid, charges_used, new_score, stage }` |
| `sonar:farm:plot:fertilized` | `FertilizationFactor.TrackApplication` | `{ plot_id, player_cid, item_name, new_score, stage }` |
| `sonar:farm:pest:appeared` | `PestService.TickCrops` | `{ plot_id, pest_type, stage, detected_ts }` |
| `sonar:farm:pest:treated` | `PestFactor.Treat` | `{ plot_id, player_cid, pesticide_item, new_score }` |
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

### 8.4 Pest visual prop (B3 scope)

B3 uses a **native GTA V particle effect** on the plot zone to indicate infestation — no custom
MLO prop needed. Confirmed approach from `docs/Catálogo-de-Assets-y-Referencias/CATALOGO_COMPLETO.md`:

- Particle dict: `core` → effect `exp_grd_bzgas_cloud` (yellow-ish, low opacity) — placeholder.
  The Integration Agent may choose a more fitting particle from the catalog; document the choice.
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
inside the same tick loop — **no new thread**. The scheduler passes the list of active crops
it already fetches; PestService filters for `stage >= 1 AND stage <= 3` and applies probability.

Anti-pattern §4 compliance: pest tick shares the existing 30s scheduler. No per-frame loop.

### 8.7 lib.callback registrations (new in B3)

| Callback | Handler |
|----------|---------|
| `sonar:farm:plot:water` | `IrrigationFactor.TrackWatering(src, plot_id, charges_used)` |
| `sonar:farm:plot:fertilize` | `FertilizationFactor.TrackApplication(src, plot_id, item_name, crop_type, stage)` |
| `sonar:farm:plot:treat_pest` | `PestFactor.Treat(src, plot_id, pesticide_item)` |

All three: server validates item ownership via `exports.ox_inventory:Search` before calling the
factor method. Server removes item on success. Client never trusts its own score calculation.

### 8.8 No DB migration for irrigation/fertilization scoring

The `sonar_farm_quality_tracking` table already has `irrigation` and `fertilization` columns
(migration 007). Tracking application count per stage requires a lightweight approach — **store
it in the existing columns** via the score delta (no new column). Application count is inferred
server-side from the score value and config thresholds, not stored as a separate integer.
This avoids a migration for S13/S14. Only S15 needs a migration (§8.3 `pest_severity` column).

---

## 9. ADRs

_(to be filled during implementation)_

- Candidate: sharing the lifecycle scheduler tick for pest spawning vs. a dedicated pest thread.
- Candidate: `pest_severity` column vs. inferring severity from `pest_detected_ts` age.
- Candidate: native GTA V particle for pest visual vs. custom prop.

---

## 10. Smoke test (happy path)

_(QA Agent fills detail; PM baseline procedure below)_

### Pre-conditions

- B1 + B2 + S11 + S12 foundations running.
- `Config.Farm.Debug = true`.
- Debug commands: `/sonarfarm:debug:fastforward`, `/sonarfarm:debug:plant`, `/sonarfarm:debug:pest` (new).

### QBox smoke

**S13 — Irrigation**
1. Plant wheat. `/giveitem sonar_water_tank 1`.
2. `ox_target` on plot → "Water crop" → progress bar 10s → confirm irrigation score increased in DB.
3. Water same plot twice more in same stage → confirm overwater penalty.
4. `ox_target` on well → "Refill tank" → charges restored.

**S14 — Fertilization**
1. Plant wheat. `/giveitem sonar_fertilizer_npk 1`.
2. `ox_target` on plot → "Fertilize" → confirm fertilization score increased.
3. `/giveitem sonar_fertilizer_k 1` → apply wrong type → confirm small penalty.
4. Apply same correct fertilizer twice same stage → confirm over-fertilize floor.

**S15 — Pests**
1. Plant wheat. Advance to stage 2. `/sonarfarm:debug:pest <plot_id> blight`.
2. Confirm: `pest_detected_ts` stamped in DB, `pest_severity = 'detected'`, particle visible in world.
3. `/giveitem sonar_pesticide_contact 1` → `ox_target` → "Treat pest" → progress bar 12s.
4. Confirm: `pest_detected_ts = NULL`, `pest_severity = 'none'`, `pest_impact` score restored, particle gone.
5. Spawn pest again, do NOT treat, advance time past `SeverityHours` → confirm `pest_severity = 'severe'`.

**Quality integration check**
1. Full run: plant wheat, skip all irrigation + wrong fertilizer + untreated pest.
2. Harvest. Confirm `sonar_farm_batches.quality` is C or D.
3. Full run with optimal actions. Harvest. Confirm grade A or S.

---

## 11. Closing summary

_(filled at /end-slice B3)_
