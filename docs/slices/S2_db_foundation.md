# S2 — DB foundation + migrations system

> **Status:** ACTIVE
> **Phase:** Phase 0 — Foundation 🧱
> **Complexity:** M (3-7 days)
> **Roadmap reference:** [`docs/01_ROADMAP.md` — S2](../01_ROADMAP.md)
> **Started:** 2026-05-19
> **Closed:** —
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

- [ ] `sonar_farm_core/server/db/db.lua` — `oxmysql` wrapper exposing `db.scalar`, `db.row`, `db.rows`, `db.execute`, `db.transaction`.
- [ ] `sonar_farm_core/server/db/migrator.lua` — migration discovery, ordering, applied-state check, execution and logging.
- [ ] `sonar_farm_core/server/main.lua` — boot integration: DB validation + migrations run before future services start.
- [ ] `sonar_farm_core/fxmanifest.lua` — include DB scripts and migration files in correct order.

### SQL migrations

- [ ] `sonar_farm_core/database/migrations/001_init_migrations_table.sql` — creates `sonar_farm_migrations`.
- [ ] `sonar_farm_core/database/migrations/002_smoke_table.sql` — creates a temporary smoke table used only to validate migration mechanics; documented for removal in S3.

### Config / locales / docs

- [ ] `sonar_farm_core/config.lua` — DB/migration tunables if any numeric values are needed.
- [ ] `sonar_farm_core/locales/en.json` and `sonar_farm_core/locales/es.json` — DB boot/migration/admin-visible messages if added.
- [ ] `sonar_farm_core/database/README.md` — migration authoring rules + manual rollback procedure.

### Tests / verification

- [ ] Smoke procedure documented in §10 for clean boot, idempotent restart and manual rollback.
- [ ] Minimal automated/static validation if useful and not over-engineered (for example migration filename/order checks). If skipped, QA must justify why S2 relies on real-server smoke.

## 5. Universal DoD checklist

(from `.windsurf/rules/04_dod_universal.md`, reproduced here for closure verification)

- [ ] Works end-to-end on QBox (smoke documented in §10).
- [ ] Works end-to-end on QBCore (smoke documented in §10).
- [ ] Smoke test of happy path documented in §10.
- [ ] Automated tests where they make sense.
- [ ] No hardcoded user-facing strings — `locales/{es,en}.json` complete for any admin-visible strings.
- [ ] No hardcoded magic numbers — config files used for tunables.
- [ ] Respects 5 Pillars of Bible §3, especially Pillar 5: configurable, not hardcoded.
- [ ] Respects Bible §9.4 anti-patterns: async DB calls, no blocking hot-path sync DB reads, no downstream workaround.
- [ ] Respects naming conventions: `sonar_farm_*` tables, `snake_case` Lua files, migration `NNN_<description>.sql`.
- [ ] DB migration is versioned and rollbackable.
- [ ] Mini-brief updated with what was actually built.
- [ ] ADR created in `docs/02_DECISIONS.md` if S2 takes a non-obvious architectural decision.
- [ ] Bible §18 changelog updated if product canon changes.

## 6. Slice-specific DoD

(from Roadmap S2)

- [ ] Boot applies pending migrations and logs which migrations ran.
- [ ] Migration run is idempotent: second boot applies nothing and does not duplicate state.
- [ ] Rollback manual possible by deleting a row from `sonar_farm_migrations`; documented in `database/README.md` and smoke-tested on the smoke table.
- [ ] DB integrity validation is fail-fast if `oxmysql`/database is unreachable.

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

## 9. ADRs created

- Pending. Create an ADR only if implementation chooses a non-obvious architecture beyond the Roadmap baseline.

## 10. Smoke test (happy path)

### A) Clean QBox boot

1. Configure a QBox dev server with `oxmysql` connected to an empty database.
2. Ensure dependencies start before `sonar_farm_core`: `ox_lib`, `oxmysql`, `ox_inventory`, `ox_target`.
3. `ensure sonar_farm_core`.
4. Expected logs:
   - core boot log still appears;
   - DB connectivity check succeeds;
   - migrations `001_init_migrations_table` and `002_smoke_table` apply in order;
   - final migration summary says 2 applied.
5. Verify DB contains `sonar_farm_migrations` with rows for both migrations.
6. Verify DB contains the smoke table created by migration 002.

### B) Idempotent restart

1. Restart `sonar_farm_core` without touching DB.
2. Expected logs: migration runner reports no pending migrations.
3. Verify no duplicate rows exist in `sonar_farm_migrations`.

### C) Manual rollback smoke

1. Stop `sonar_farm_core`.
2. Manually delete the row for `002_smoke_table` from `sonar_farm_migrations`.
3. Drop the smoke table if the migration uses `CREATE TABLE` without destructive reset.
4. Restart `sonar_farm_core`.
5. Expected logs: only migration 002 runs again.
6. Document exact SQL used in `database/README.md`.

### D) QBCore repeat

Repeat A-C on a QBCore dev server. Expected behavior is identical because S2 persistence is framework-independent.

### E) DB unreachable fail-fast

1. Break the DB connection string or stop the DB service on a dev server.
2. Restart `sonar_farm_core`.
3. Expected: clear `[sonar_farm_core][ERROR]` log and no later services start as if persistence were healthy.

## 11. Closing summary (filled at /end-slice)

### What shipped

- <filled during /end-slice>

### Deviations from plan

- <filled during /end-slice>

### Discoveries / lessons

- <filled during /end-slice>

### Unblocks

- S3 — Banca Sonar foundation.
- S5+ domain slices that require persistent tables.

### Commit message

```text
feat(db): S2 — DB foundation and migrations

- add oxmysql wrapper and migration runner
- add initial migrations table and smoke migration
- document DB smoke, idempotency and rollback

Closes S2.
```
