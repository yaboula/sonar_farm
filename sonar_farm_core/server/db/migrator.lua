Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}

local migrator = {}

local MIGRATION_METADATA_KEY = 'sonar_farm_migration'
local MIGRATIONS_TABLE = 'sonar_farm_migrations'

local function log_info(message)
    print(('[sonar_farm_core][db] %s'):format(message))
end

local function log_error(message)
    print(('[sonar_farm_core][db][ERROR] %s'):format(message))
end

local function get_db()
    if not Sonar.Farm.DB then
        error('Sonar.Farm.DB is unavailable. Ensure server/db/db.lua loads before server/db/migrator.lua.', 3)
    end

    return Sonar.Farm.DB
end

local function get_resource_name()
    return GetCurrentResourceName()
end

local function parse_migration_path(path)
    local filename = path:match('([^/\\]+)$') or path
    local id, name = filename:match('^(%d%d%d)_(.+)%.sql$')

    if not id then
        error(('Invalid migration filename "%s". Expected NNN_<description>.sql.'):format(path), 3)
    end

    return id, name
end

local function compare_migrations(left, right)
    return left.id < right.id
end

local function discover_migrations()
    local resource_name = get_resource_name()
    local count = GetNumResourceMetadata(resource_name, MIGRATION_METADATA_KEY)
    local migrations = {}
    local seen = {}

    for index = 0, count - 1 do
        local path = GetResourceMetadata(resource_name, MIGRATION_METADATA_KEY, index)

        if type(path) == 'string' and path ~= '' then
            local id, name = parse_migration_path(path)

            if seen[id] then
                error(('Duplicate migration id %s in %s and %s.'):format(id, seen[id], path), 2)
            end

            seen[id] = path
            migrations[#migrations + 1] = {
                id = id,
                name = name,
                path = path,
            }
        end
    end

    table.sort(migrations, compare_migrations)

    return migrations
end

local function read_migration_sql(migration)
    local sql = LoadResourceFile(get_resource_name(), migration.path)

    if type(sql) ~= 'string' or sql == '' then
        error(('Unable to load migration file %s. Ensure it is listed in fxmanifest files.'):format(migration.path), 3)
    end

    return sql
end

local function ensure_migrations_table()
    get_db().execute(([[
        CREATE TABLE IF NOT EXISTS `%s` (
            `id` VARCHAR(16) NOT NULL,
            `name` VARCHAR(191) NOT NULL,
            `filename` VARCHAR(255) NOT NULL,
            `applied_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]):format(MIGRATIONS_TABLE), {})
end

local function load_applied_migrations()
    local rows = get_db().rows(('SELECT `id` FROM `%s` ORDER BY `id` ASC'):format(MIGRATIONS_TABLE), {})
    local applied = {}

    for _, row in ipairs(rows or {}) do
        applied[tostring(row.id)] = true
    end

    return applied
end

local function apply_migration(migration)
    local sql = read_migration_sql(migration)

    get_db().transaction({
        { query = sql, values = {} },
        {
            query = ('INSERT INTO `%s` (`id`, `name`, `filename`) VALUES (?, ?, ?)'):format(MIGRATIONS_TABLE),
            values = { migration.id, migration.name, migration.path },
        },
    })
end

function migrator.discover()
    return discover_migrations()
end

function migrator.run_pending()
    local db = get_db()

    if not db.ping() then
        error('DB connectivity check failed.', 2)
    end

    local migrations = discover_migrations()

    if #migrations == 0 then
        error(('No migrations registered in fxmanifest metadata key "%s".'):format(MIGRATION_METADATA_KEY), 2)
    end

    ensure_migrations_table()

    local applied = load_applied_migrations()
    local applied_count = 0
    local skipped_count = 0

    for _, migration in ipairs(migrations) do
        if applied[migration.id] then
            skipped_count = skipped_count + 1
        else
            log_info(('applying migration %s_%s'):format(migration.id, migration.name))
            apply_migration(migration)
            applied_count = applied_count + 1
            log_info(('applied migration %s_%s'):format(migration.id, migration.name))
        end
    end

    if applied_count == 0 then
        log_info(('migrations complete: no pending migrations (%d already applied)'):format(skipped_count))
    else
        log_info(('migrations complete: %d applied, %d already applied'):format(applied_count, skipped_count))
    end

    return {
        applied = applied_count,
        skipped = skipped_count,
        total = #migrations,
    }
end

function migrator.run_pending_safe()
    local ok, result = pcall(migrator.run_pending)

    if not ok then
        log_error(tostring(result))
        return false, tostring(result)
    end

    return true, result
end

Sonar.Farm.Migrator = migrator
