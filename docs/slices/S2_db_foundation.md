# S2 — DB foundation + migrations system

> **Status:** DONE
> **Phase:** Phase 0 — Foundation 🧱
> **Complexity:** M (3-7 days)
> **Roadmap reference:** [`docs/01_ROADMAP.md` — S2](../01_ROADMAP.md)
> **Started:** 2026-05-19
> **Closed:** 2026-05-19
> **Author:** PM Agent (Cascade) + Backend / Integration / QA sub-agents

---

## 1. Scope

S2 creates the persistence foundation for Farm Sonar: versioned SQL migrations, a server-side migration runner, and a small `oxmysql` wrapper used by later services. The goal is not to model gameplay tables yet. The goal is to make future DB changes safe, repeatable, idempotent and visible during boot.

This slice is intentionally infrastructure-only. It must not create plot/crop/company/batch schemas yet unless they are strictly required by the migration system. Domain tables belong to their own future slices.

The canonical DB naming rule applies from day one: all production tables use the `sonar_farm_*` prefix, columns use `snake_case`, and migration files use `database/migrations/NNN_<description>.sql` with a 3-digit zero-padded prefix.

## 2. Goal (Wooow Test outcome)

Developer-visible outcome: on a clean QBox or QBCore server with `oxmysql` configured, `ensure sonar_farm_core` applies pending migrations in order, logs what ran, refuses to continue if the DB is unreachable, and a second restart is idempotent with no duplicate effects.

## 3. Dependencies

| Slice | Reason                                                                   | Status  |
| ----- | ------------------------------------------------------------------------ | ------- |
| S0    | Workspace/resource skeleton, dependency declarations, tooling            | DONE ✅ |
| S1    | Bridge foundation closed; server boot conventions and locales stabilized | DONE ✅ |

If any dependency regresses from `DONE`, do not implement S2 — escalate to founder.

## 4. Deliverables

### Lua server

- [x] `sonar_farm_core/server/db/db.lua` — `oxmysql` wrapper exposing `db.scalar`, `db.row`, `db.rows`, `db.execute`, `db.transaction`.
- [x] `sonar_farm_core/server/db/migrator.lua` — migration discovery, ordering, applied-state check, execution and logging.
- [x] `sonar_farm_core/server/main.lua` — boot integration: DB validation + migrations run before future services start.
- [x] `sonar_farm_core/fxmanifest.lua` — include DB scripts and migration files in correct order.

### SQL migrations

- [x] `sonar_farm_core/database/migrations/001_init_migrations_table.sql` — creates `sonar_farm_migrations`.
- [x] `sonar_farm_core/database/migrations/002_smoke_table.sql` — creates a temporary smoke table used only to validate migration mechanics; documented for removal in S3.

### Config / locales / docs

- [x] `sonar_farm_core/config.lua` — no DB/migration tunables were added because S2 needed none.
- [x] `sonar_farm_core/locales/en.json` and `sonar_farm_core/locales/es.json` — DB boot/migration/admin-visible messages if added.
- [x] `sonar_farm_core/database/README.md` — migration authoring rules + manual rollback procedure.

### Tests / verification

- [x] Smoke procedure documented in §10 for clean boot, idempotent restart and manual rollback.
- [x] Minimal automated/static validation considered; QA accepted `pnpm lint`, `git diff --check`, filename/table naming audit and real-server smoke for this infrastructure slice.

## 5. Universal DoD checklist

(from `.windsurf/rules/04_dod_universal.md`, reproduced here for closure verification)

- [x] Works end-to-end on QBox (smoke documented in §10 A-C).
- [x] Works end-to-end on QBCore — **exception:** runtime smoke deferred to Phase 0 closure by ADR-007 because S2 is framework-independent and no QBCore server was available.
- [x] Smoke test of happy path documented in §10.
- [x] Automated tests where they make sense; S2 uses lint/static checks plus real-server smoke rather than over-engineered unit tests around `oxmysql`.
- [x] No hardcoded user-facing strings — `locales/{es,en}.json` complete for admin-visible boot strings.
- [x] No hardcoded magic numbers — no tunables added; migration numeric prefixes are file IDs, not configurable values.
- [x] Respects 5 Pillars of Bible §3, especially Pillar 5: configurable, not hardcoded.
- [x] Respects Bible §9.4 anti-patterns: async DB, no hot-path sync DB reads, no downstream workaround.
- [x] Respects naming conventions: `sonar_farm_*` tables, `snake_case` Lua files, migration `NNN_<description>.sql`.
- [x] DB migration is versioned and rollbackable.
- [x] Mini-brief updated with what was actually built.
- [x] ADR-007 created for closing S2 with runtime smoke exceptions.
- [x] Bible §18 changelog not updated; S2 changed infrastructure, not product canon.

## 6. Slice-specific DoD

(from Roadmap S2)

- [x] Boot applies pending migrations and logs which migrations ran.
- [x] Migration run is idempotent: second boot applies nothing and does not duplicate state.
- [x] Rollback manual possible by deleting a row from `sonar_farm_migrations`; documented in `database/README.md` and smoke-tested on the smoke table.
- [x] DB integrity validation is fail-fast if `oxmysql`/database is unreachable — **exception:** code path implemented and reviewed, runtime DB-unreachable smoke deferred to Phase 0 closure by ADR-007.

## 7. Sub-agents involved

| Agent             | Role in this slice                                                                                     | Prompt block in `.prompts.md` |
| ----------------- | ------------------------------------------------------------------------------------------------------ | ----------------------------- |
| Backend Agent     | Owns `db.lua`, migrator logic, SQL migration semantics and boot flow                                   | yes                           |
| Integration Agent | Owns `fxmanifest.lua`, `oxmysql` integration details, resource boot ordering and config/locales wiring | yes                           |
| QA Agent          | Owns smoke matrix, idempotency/rollback verification and DoD audit                                     | yes                           |
| Frontend Agent    | Not needed; S2 has no NUI/UI deliverables                                                              | no                            |

Prompts file: `docs/slices/S2_db_foundation.prompts.md`.

## 8. Architecture notes

Initial PM guidance before implementation:

- Keep S2 minimal: migration system + DB wrapper only. No gameplay schemas.
- Prefer async/await oxmysql usage; never introduce sync DB reads in hot paths.
- `sonar_farm_migrations` is the authoritative record of applied migrations.
- Migration SQL files should be loaded from resource files using `LoadResourceFile` or another FiveM-compatible pattern; do not assume Node/npm at runtime.
- Failure to connect to DB or apply a migration should fail fast and leave a clear admin-facing log.
- The smoke table exists only to validate infrastructure and should be removed in S3 or the first real schema slice.

Backend implementation notes:

- `Sonar.Farm.DB` exposes the exact requested helper names: `scalar`, `row`, `rows`, `execute`, and `transaction`; `ping` is an extra boot-only connectivity helper for Integration.
- `Sonar.Farm.Migrator` exposes `discover`, `run_pending`, and `run_pending_safe`; Integration should call `run_pending_safe` during boot and stop further service startup when it returns `false`.
- Migration discovery uses explicit `fxmanifest.lua` metadata entries under key `sonar_farm_migration`, read through `GetNumResourceMetadata` / `GetResourceMetadata`, then sorted by the 3-digit filename prefix.
- SQL files are loaded through `LoadResourceFile(GetCurrentResourceName(), path)`, so Integration must expose migration files in the resource manifest.
- `sonar_farm_migrations` schema is: `id VARCHAR(16) PRIMARY KEY`, `name VARCHAR(191)`, `filename VARCHAR(255)`, `applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP`.
- The migrator creates `sonar_farm_migrations` defensively before checking applied state, then still applies and records `001_init_migrations_table` as a normal migration for idempotent history.

Integration implementation notes:

- `fxmanifest.lua` loads `@oxmysql/lib/MySQL.lua`, then `server/db/db.lua`, then `server/db/migrator.lua`, then `server/main.lua`.
- Migration files are exposed through `files { 'database/migrations/*.sql' }` and registered explicitly with `sonar_farm_migration` metadata entries.
- `server/main.lua` calls `Sonar.Farm.Migrator.run_pending_safe()` during `onResourceStart` immediately after the existing version/locale boot log and before the debug/future-services section.
- If the DB wrapper, migrator, DB connection or migration execution fails, boot returns early and does not proceed as healthy.

## 9. ADRs created

- ADR-007 — Cerrar S2 con smoke runtime parcial documentado — see `docs/02_DECISIONS.md`.

## 10. Smoke test (happy path)

### A) Clean QBox boot ✅ PASSED (2026-05-19)

1. Configure a QBox dev server with `oxmysql` connected to an empty database.
2. Ensure dependencies start before `sonar_farm_core`: `ox_lib`, `oxmysql`, `ox_inventory`, `ox_target`.
3. `ensure sonar_farm_core`.
4. Expected logs:
   - `[sonar_farm_core] Farm Sonar core booted (v0.1.0)`;
   - `[sonar_farm_core] DB connectivity check and migrations starting`;
   - `[sonar_farm_core][db] applying migration 001_init_migrations_table`;
   - `[sonar_farm_core][db] applied migration 001_init_migrations_table`;
   - `[sonar_farm_core][db] applying migration 002_smoke_table`;
   - `[sonar_farm_core][db] applied migration 002_smoke_table`;
   - `[sonar_farm_core][db] migrations complete: 2 applied, 0 already applied`;
   - `[sonar_farm_core] DB boot ready: 2 migrations applied, 0 already applied, 2 registered`.
5. Verify DB contains `sonar_farm_migrations` with rows for both migrations.
6. Verify DB contains the smoke table created by migration 002.

**Actual result:** Logs matched exactly. DB verification: 2 rows in `sonar_farm_migrations` (001, 002), tables `sonar_farm_migrations` and `sonar_farm_migration_smoke` exist.

### B) Idempotent restart ✅ PASSED (2026-05-19)

1. Restart `sonar_farm_core` without touching DB.
2. Expected logs:
   - `[sonar_farm_core][db] migrations complete: no pending migrations (2 already applied)`;
   - `[sonar_farm_core] DB boot ready: 0 migrations applied, 2 already applied, 2 registered`.
3. Verify no duplicate rows exist in `sonar_farm_migrations`.

**Actual result:** Logs matched exactly. `COUNT(*)` from `sonar_farm_migrations` = 2 (no duplicates).

### C) Manual rollback smoke ✅ PASSED (2026-05-19)

1. Stop `sonar_farm_core`.
2. Manually delete the row for `002_smoke_table` from `sonar_farm_migrations`.
3. Drop the smoke table if the migration uses `CREATE TABLE` without destructive reset.
4. Restart `sonar_farm_core`.
5. Expected logs:
   - `[sonar_farm_core][db] applying migration 002_smoke_table`;
   - `[sonar_farm_core][db] applied migration 002_smoke_table`;
   - `[sonar_farm_core][db] migrations complete: 1 applied, 1 already applied`;
   - `[sonar_farm_core] DB boot ready: 1 migrations applied, 1 already applied, 2 registered`.
6. Document exact SQL used in `database/README.md`.

**Actual result:** Logs matched exactly. After rollback and restart, `sonar_farm_migrations` had 2 rows again (001, 002). Rollback procedure in README.md verified.

### D) QBCore repeat ⏸️ SKIPPED (2026-05-19)

Repeat A-C on a QBCore dev server. Expected behavior is identical because S2 persistence is framework-independent.

**Skipped reason:** Founder does not have QBCore dev server available. S2 code is framework-independent (no QBox-specific calls), so QBCore behavior is expected to be identical. This can be validated in a future slice when QBCore environment is available.

### E) DB unreachable fail-fast ⏸️ SKIPPED (2026-05-19)

1. Break the DB connection string or stop the DB service on a dev server.
2. Restart `sonar_farm_core`.
3. Expected: clear `[sonar_farm_core][db][ERROR] ...` plus `[sonar_farm_core][ERROR] DB boot failed: ...` and no later services start as if persistence were healthy.

**Skipped reason:** Runtime DB-unreachable smoke deferred to Phase 0 closure by ADR-007. Fail-fast behavior is implemented in code (db.lua:ping(), migrator.lua:run_pending() error handling, main.lua early return) but not runtime-tested yet.

## 11. Closing summary (QA Report 2026-05-19)

### What shipped

**Backend Agent:**

- `sonar_farm_core/server/db/db.lua` — oxmysql wrapper with scalar, row, rows, execute, transaction, ping
- `sonar_farm_core/server/db/migrator.lua` — migration discovery, ordering, applied-state check, execution
- `sonar_farm_core/database/migrations/001_init_migrations_table.sql` — creates sonar_farm_migrations table
- `sonar_farm_core/database/migrations/002_smoke_table.sql` — smoke table for validation

**Integration Agent:**

- `sonar_farm_core/fxmanifest.lua` — added @oxmysql/lib/MySQL.lua, server scripts order, migration files and metadata
- `sonar_farm_core/server/main.lua` — added run_persistence_boot() with DB validation and migrator execution
- `sonar_farm_core/locales/en.json` and `es.json` — added boot.db_unavailable, boot.migrator_unavailable, boot.db_check_started, boot.db_boot_failed, boot.db_boot_ready
- `sonar_farm_core/database/README.md` — migration authoring rules and manual rollback procedure

### Deviations from plan

- **Config.lua:** No config keys added (Integration Agent decision — no tunables needed for S2, avoids over-engineering)
- **Smoke test coverage:** QBCore smoke (D) and DB-unreachable fail-fast runtime smoke (E) are deferred to Phase 0 closure by ADR-007. S2 closes with QBox A/B/C evidence plus implementation review for framework-independent/fail-fast code paths.

### Discoveries / lessons

- Migration discovery via fxmanifest metadata (`sonar_farm_migration` key) works correctly with GetNumResourceMetadata/GetResourceMetadata
- Idempotency verified: second restart applies 0 migrations, no duplicate rows
- Manual rollback procedure works: delete row + drop table → restart reapplies only that migration
- S2 is genuinely framework-independent: no QBox-specific code, only oxmysql dependency

### Unblocks

- S3 — Banca Sonar foundation (can now create gameplay tables)
- S5+ domain slices that require persistent tables

### Smoke test results

| Test                  | Status     | Evidence                                             |
| --------------------- | ---------- | ---------------------------------------------------- |
| A: Clean QBox boot    | ✅ PASSED  | Logs matched, 2 migrations applied, DB verified      |
| B: Idempotent restart | ✅ PASSED  | 0 migrations applied, 2 already applied, COUNT(\*)=2 |
| C: Manual rollback    | ✅ PASSED  | 002 reapplied alone, rollback procedure verified     |
| D: QBCore repeat      | ⏸️ SKIPPED | No QBCore dev server available                       |
| E: DB unreachable     | ⏸️ SKIPPED | Runtime smoke deferred to Phase 0 closure by ADR-007 |

### Closure exception

- ADR-007 records the founder-approved exception to close S2 before QBCore runtime smoke and DB-unreachable runtime smoke are executed.
- These checks are not deleted from quality expectations; they are deferred to Phase 0 closure before the foundation phase can be considered fully complete.

### Commit message

```text
feat(db): S2 — DB foundation and migrations

- add oxmysql wrapper and migration runner
- add initial migrations table and smoke migration
- document DB smoke, idempotency and rollback
- wire DB boot validation into server/main.lua

Smoke: A/B/C passed on QBox (D/E skipped)
```
