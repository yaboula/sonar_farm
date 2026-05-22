# S11 — Persistence delta-calc + 6h cap

## 1. Canon

- Bible §9 decision 6 / Pillar 5: tunables live in config, not inline code.
- Bible §13.2: server-authoritative offline persistence; boot reconciliation must be idempotent; negative events are capped after long downtime.
- Roadmap S11: boot reconciler, delta calculator, tests for 1h / 6h / 24h / 7d, boot logging, admin dry-run command.

## 2. What was built

- `sonar_farm_core/server/persistence/delta_calculator.lua`
  - Computes offline delta from `plot.last_updated_ts` to `now_ts`.
  - Advances crop stages using crop config durations.
  - Applies capped irrigation / pest penalties using config-driven rates and floor cap.
- `sonar_farm_core/server/persistence/boot_reconciler.lua`
  - Scans active crops on boot.
  - Applies crop / plot / quality mutations atomically enough for the current architecture.
  - Emits `sonar:farm:persistence:reconciled` after successful apply.
  - Supports dry-run previews.
- `sonar_farm_core/server/admin/persistence_dryrun_command.lua`
  - Adds `/sonarfarm:persistence:dryrun` (ACE: `sonar.farm.admin`).
- `sonar_farm_core/database/migrations/010_quality_offline_tracking.sql`
  - Adds nullable offline timers to `sonar_farm_quality_tracking`:
    - `next_irrigation_due_ts`
    - `pest_detected_ts`
- `sonar_farm_core/config.lua`
  - Adds `Config.Farm.Persistence` tunables:
    - `OfflineCapHours`
    - `MaxFactorPenalty`
    - `IrrigationPenaltyPerHour`
    - `PestPenaltyPerHour`
- `sonar_farm_core/server/main.lua`
  - Runs offline reconciliation after quality boot and before lifecycle scheduler boot.

## 3. Non-obvious decision

Offline risk markers are persisted in `sonar_farm_quality_tracking` instead of inferred from current factor score only. See ADR-016.

## 4. Validation

Automated validation passed:

- `lua sonar_farm_core/tests/server/persistence_spec.lua`
- `pnpm run lint:lua`
- Regression specs:
  - `quality_spec.lua`
  - `physical_item_spec.lua`
  - `lifecycle_spec.lua`
  - `storage_spec.lua`
  - `sale_spec.lua`

## 5. Happy-path smoke script

1. Plant wheat on a plot.
2. Manually set an offline condition:
   - set `next_irrigation_due_ts` in the past and/or `pest_detected_ts` in the past,
   - stop the resource or server.
3. Wait or simulate long downtime.
4. Run `/sonarfarm:persistence:dryrun` before restart verification if desired.
5. Start the resource.
6. Verify:
   - crop stage matches elapsed time,
   - irrigation / pest penalties are capped after 6h,
   - immediate re-ensure does not apply extra delta.

## 6. Current status

- **Code:** implemented.
- **Automated tests:** pass.
- **QBox smoke:** pending founder runtime verification.
- **QBCore smoke:** pending founder runtime verification.
