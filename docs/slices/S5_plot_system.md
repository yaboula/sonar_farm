# S5 — Plot system

> **Status:** ACTIVE
> **Phase:** Phase 1 — First Crop End-to-End ⭐
> **Complexity:** M (3-7 days)
> **Roadmap reference:** [`docs/01_ROADMAP.md` — S5](../01_ROADMAP.md)
> **Started:** 2026-05-19
> **Closed:** —
> **Author:** Cascade + Backend / Integration / QA responsibilities in-session

---

## 1. Scope

S5 ships the plot system as a core server-authoritative entity. It creates `sonar_farm_plots`, seeds the initial MLO plots from configuration, and exposes a `PlotService` for CRUD and state refresh operations.

Roadmap S5 requires the table to be designed for delta-calc from day one: `last_updated_ts`, `planted_ts`, and `next_stage_ts` must exist even before S6 implements the crop lifecycle scheduler. Bible §13.2 requires real-time persistence, downtime-safe advancement, and idempotent boot behavior. Bible §17 defines a plot as a cultivable terrain unit with type and persistent soil score.

S5 does not implement planting, crop stages, rendering, inventory, quality tracking, or the Plots NUI app. Those belong to S6/S7/S8/S27. This slice only establishes the authoritative plot registry that later slices consume.

## 2. Goal (Wooow Test outcome)

Developer/admin-visible outcome: on clean boot, Farm Sonar creates the eight canonical MLO plots, exposes them through `PlotService`, and allows an admin to reload the seeded config without duplicating rows.

## 3. Dependencies

| Slice                                 | Reason                                                                                                                     | Status |
| ------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- | ------ |
| S2 — DB foundation + migration system | S5 needs versioned migrations, `Sonar.Farm.DB`, migration metadata in `fxmanifest.lua`, and boot-time migration execution. | DONE   |

No blocking dependency is open.

## 4. Deliverables

- [ ] Migration `sonar_farm_core/database/migrations/004_plots.sql` — creates `sonar_farm_plots` with delta-calc timestamps and rollback notes.
- [ ] `sonar_farm_core/config/plots.lua` — seed config for the 8 initial MLO plots: 4 `extensive`, 3 `horticultural`, 1 `greenhouse`.
- [ ] `sonar_farm_core/server/plots/plot_service.lua` — exposes `PlotService` under `Sonar.Farm.PlotService` with CRUD/read methods and seed sync.
- [ ] `sonar_farm_core/server/plots/init.lua` — plot domain boot coordinator called after DB migrations succeed.
- [ ] `sonar_farm_core/server/admin/plots_reload_command.lua` — admin command `/sonarfarm:plots:reload`.
- [ ] `sonar_farm_core/fxmanifest.lua` — registers migration `004_plots.sql`, config, services, admin command in deterministic load order.
- [ ] `sonar_farm_core/locales/en.json` and `sonar_farm_core/locales/es.json` — admin command and boot messages.
- [ ] Event emitted: `sonar:farm:plot:state_changed` whenever a persisted plot row changes state through the service.
- [ ] Tests or smoke helpers where practical for migration shape, seed idempotency, reload idempotency, and timestamp availability.

## 5. Universal DoD checklist

(from `.windsurf/rules/04_dod_universal.md`, reproduced here for closure verification)

- [ ] Works end-to-end on QBox (smoke documented in §10).
- [ ] Works end-to-end on QBCore (smoke documented in §10).
- [ ] Smoke test of happy path documented in §10.
- [ ] Automated tests where they make sense.
- [ ] No hardcoded user-facing strings — `locales/{es,en}.json` complete.
- [ ] No hardcoded magic numbers — config files used.
- [ ] Respects the 5 Pillars of Bible §3.
- [ ] Respects Bible §9.4 anti-patterns.
- [ ] Respects naming conventions (rule `02_naming_conventions.md`).
- [ ] DB migration versioned + rollbackable, if DB was touched.
- [ ] Mini-brief updated with what was actually built.
- [ ] ADR created in `docs/02_DECISIONS.md` if non-obvious decision was taken.
- [ ] Bible §18 changelog updated if product canon changed.

## 6. Slice-specific DoD

- [ ] Boot creates the seeded plots if they do not exist.
- [ ] Reboot is idempotent: seeded plots are not duplicated and manually persisted state is not overwritten unexpectedly.
- [ ] `/sonarfarm:plots:reload` admin command resyncs the configured plot registry and reports counts via localized messages.
- [ ] Schema supports delta-calc trivially: `last_updated_ts`, `planted_ts`, and `next_stage_ts` can be queried for every plot.
- [ ] `soil_score` is persisted per plot and never stored client-side as source of truth.
- [ ] `sonar:farm:plot:state_changed` is emitted by every service method that changes persisted plot state.

## 7. Sub-agents involved

| Agent             | Role in this slice                                                                                 | Prompt block in `.prompts.md` |
| ----------------- | -------------------------------------------------------------------------------------------------- | ----------------------------- |
| Backend Agent     | Owns migration, table design, `PlotService`, idempotent seed sync, and event payloads.             | no                            |
| Frontend Agent    | Not needed; S5 has no NUI surface beyond future S27 consumption.                                   | no                            |
| Integration Agent | Owns fxmanifest load order, admin command, config loading, and smoke procedure across QBox/QBCore. | no                            |
| QA Agent          | Owns lint, DB shape verification, idempotency smoke, and DoD audit.                                | no                            |

S5 is complexity M, so `/spawn-pm` is optional and not required at slice start. Cascade can implement directly in this session unless the founder chooses to split Backend/QA into fresh sessions.

## 8. Architecture notes

### 8.1 Canonical constraints

- Bible §3 Pillar 5: all tunable values live in config, not code.
- Bible §9.2: server-authoritative; client only renders later.
- Bible §9.3 and naming rule: table is `sonar_farm_plots`, event is `sonar:farm:plot:state_changed`, service file is `plot_service.lua`, service table is `PlotService`.
- Bible §13.2: timestamp fields must allow idempotent delta-calc on boot in S6/S16.
- Roadmap S5: initial plots are predefined in config; placement GUI is deferred.

### 8.2 Proposed table contract

Minimum intended columns for `sonar_farm_plots`:

| Column                             | Purpose                                               |
| ---------------------------------- | ----------------------------------------------------- |
| `plot_id`                          | Stable config-defined ID, primary key or unique key.  |
| `plot_type`                        | `extensive`, `horticultural`, or `greenhouse`.        |
| `display_name_key`                 | Locale key or stable display reference for future UI. |
| `state`                            | Initial lifecycle state, expected `fallow` in S5.     |
| `soil_score`                       | Persistent 0-100 soil value.                          |
| `coords_x`, `coords_y`, `coords_z` | World anchor from MLO config.                         |
| `radius`                           | Interaction/rendering area for later slices.          |
| `last_updated_ts`                  | UNIX timestamp used for delta-calc.                   |
| `planted_ts`                       | Nullable UNIX timestamp; populated by S6.             |
| `next_stage_ts`                    | Nullable UNIX timestamp; populated by S6 scheduler.   |
| `created_at`, `updated_at`         | DB audit timestamps.                                  |

The exact migration can add indexes for `plot_type`, `state`, and `next_stage_ts` if useful for S6's scheduler query.

### 8.3 Service contract draft

`Sonar.Farm.PlotService` should expose a single table, following service naming rules:

- `Boot() -> boolean`
- `SyncSeededPlots() -> result`
- `ListPlots() -> plots`
- `GetPlot(plot_id) -> plot | nil`
- `CreatePlot(plot) -> ok, error_or_row`
- `UpdatePlotState(plot_id, state_patch, reason) -> ok, error_or_row`
- `ReloadSeededPlots(src) -> result`

All state-changing methods must emit `sonar:farm:plot:state_changed` with a payload shape documented at implementation time.

### 8.4 Migration registration contract

S2's migrator discovers migrations through `fxmanifest.lua` metadata:

```lua
sonar_farm_migration 'database/migrations/004_plots.sql'
```

The migration file must also remain covered by:

```lua
files {
    'database/migrations/*.sql',
}
```

## 9. ADRs created

- None at slice start. Create an ADR only if S5 chooses a non-obvious plot identity, seeding, or geometry strategy that affects future slices.

## 10. Smoke test (happy path)

Document final results at `/end-slice S5`. Initial target procedure:

1. Start `sonar_farm_core` on a clean QBox dev server with an empty Farm Sonar DB.
2. Confirm migration `004_plots` is applied in `sonar_farm_migrations`.
3. Query `sonar_farm_plots` and confirm exactly 8 seeded rows exist: 4 `extensive`, 3 `horticultural`, 1 `greenhouse`.
4. Confirm every row has `last_updated_ts`; `planted_ts` and `next_stage_ts` exist and are nullable.
5. Restart `sonar_farm_core` immediately and confirm the row count remains 8.
6. Run `/sonarfarm:plots:reload` as admin and confirm localized success output plus no duplicate rows.
7. Repeat the same procedure on QBCore or QBCore bridge mode.

## 11. Closing summary (filled at /end-slice)

### What shipped

- TBD.

### Deviations from plan

- TBD.

### Discoveries / lessons

- TBD.

### Unblocks

- S6 — Trigo lifecycle físico.
- S7 — Item Físico universal, indirectly through plot origin metadata.
- S8 — Sistema calidad: 7 factores stub, through persistent `soil_score`.
- S16 — Persistencia offline delta-calc, through timestamp-ready plot rows.
- S27 — Tablet de campo apps, through future Plots app data source.

### Commit message

```text
feat(plots): S5 — plot system

- Add plot migration and seeded MLO plot registry
- Add PlotService boot/sync/reload flow
- Emit plot state change events

Closes S5.
```
