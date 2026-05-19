# Farm Sonar database migrations

S2 owns only the migration foundation. Gameplay schemas must be added by their own future slices.

## Authoring rules

- Create migration files under `database/migrations/`.
- Use the filename format `NNN_<description>.sql`, with a 3-digit zero-padded numeric prefix.
- Use only `sonar_farm_*` table names.
- Use `snake_case` column names.
- Make migrations idempotent when possible, for example with `CREATE TABLE IF NOT EXISTS`.
- Register each migration in `fxmanifest.lua` with a `sonar_farm_migration` metadata entry.
- Ensure migration SQL files remain included in `fxmanifest.lua` under `files`.

## Runtime behavior

On resource start, `server/main.lua` runs the migration runner before future services start. Applied migrations are recorded in `sonar_farm_migrations`.

## Manual rollback procedure

Manual rollback is an admin-only recovery workflow for development and emergency operations. Always stop `sonar_farm_core` before changing migration state manually.

For the S2 smoke migration:

```sql
DELETE FROM `sonar_farm_migrations`
WHERE `id` = '002';

DROP TABLE IF EXISTS `sonar_farm_migration_smoke`;
```

After running the SQL above, start `sonar_farm_core` again. The runner should apply only `002_smoke_table`.

For migration 003 (S3 finance core):

```sql
DELETE FROM `sonar_farm_migrations`
WHERE `id` = '003';

DROP TABLE IF EXISTS `sonar_farm_finance_movements`;
```

After running the SQL above, start `sonar_farm_core` again. The runner should apply only `003_finance_core`.

**Warning:** deleting rows from `sonar_farm_finance_movements` is irreversible for audit purposes. Only perform this rollback in development/staging environments, never on live servers with real player data.

For future migrations, rollback must be documented by the slice that introduces the migration. Do not delete rows from `sonar_farm_migrations` unless the schema/data changes made by that migration have also been safely reverted.
