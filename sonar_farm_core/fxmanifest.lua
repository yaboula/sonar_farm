fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

name        'sonar_farm_core'
author      'Gusto (Farm Sonar)'
version     '0.1.0'
description 'Farm Sonar Ã¢â‚¬â€ premium farming simulation core (server + client logic). Part of the Sonar product family.'
repository  'https://github.com/yaboula/sonar_farm'

-- ============================================================
-- Dependencies
-- ============================================================
-- Required runtime dependencies. Server will fail to start if any is missing.
dependencies {
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'oxmysql',
}

-- ============================================================
-- ox_lib modules to auto-load. ox_lib's `init.lua` reads this
-- metadata via `GetResourceMetadata(resource, 'ox_lib', ...)`
-- and, for each entry, loads `imports/<name>/{shared,context}.lua`
-- AND calls the module's init function. For `locale`, this
-- registers the `locale(str, ...)` global AND loads our
-- `locales/<lang>.json` files based on the `ox:locale` convar.
-- ============================================================
ox_lib 'locale'

-- ============================================================
-- Shared scripts (run on both server and client)
-- ============================================================
shared_scripts {
    '@ox_lib/init.lua',
    'shared/version.lua',
    -- Bridge: adapters MUST load before init.lua (init picks one).
    'shared/bridge/qbox.lua',
    'shared/bridge/qbcore.lua',
    'shared/bridge/_unsupported.lua',
    'shared/bridge/init.lua',
    'config.lua',
    'config/finance.lua',
    'config/plots.lua',
    'config/storage.lua',
    'config/npcs.lua',
    'config/machinery.lua',
    'config/irrigation.lua',
    'config/climate.lua',
    'config/climate_client.lua',
    'config/items.lua',
    'config/verified_props.lua',
    'config/crops/wheat.lua',
    'config/crops/corn.lua',
    'config/crops/barley.lua',
    'config/crops/tomato.lua',
    'config/crops/pepper.lua',
    'config/crops/lettuce.lua',
    'config/crops/onion.lua',
    'config/crops/potato.lua',
    'shared/items/item_registry.lua',
}

-- ============================================================
-- Server scripts
-- ============================================================
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/db/db.lua',
    'server/db/migrator.lua',
    -- Finance domain: adapter registry Ã¢â€ â€™ movement ledger Ã¢â€ â€™ facade Ã¢â€ â€™ boot coordinator.
    -- All four must load before server/main.lua (the boot orchestrator).
    'server/finance/adapters/native_bridge.lua',
    'server/finance/movement_service.lua',
    'server/finance/money_adapter.lua',
    'server/finance/init.lua',
    -- Plots domain: service first Ã¢â€ â€™ boot coordinator second.
    -- Both must load before server/main.lua so it can call
    -- Sonar.Farm.Plots.Boot() after run_persistence_boot().
    'server/plots/plot_service.lua',
    'server/plots/init.lua',
    'server/storage/storage_service.lua',
    'server/storage/init.lua',
    'server/npcs/npc_buyer_service.lua',
    'server/npcs/init.lua',
    'server/machinery/machinery_service.lua',
    'server/machinery/init.lua',
    'server/climate/climate_service.lua',
    -- Quality domain: factors first Ã¢â€ â€™ calculator Ã¢â€ â€™ boot.
    'server/quality/factors/soil.lua',
    'server/quality/factors/irrigation.lua',
    'server/quality/factors/pest.lua',
    'server/quality/factors/weather.lua',
    'server/quality/factors/seed.lua',
    'server/quality/factors/fertilization.lua',
    'server/quality/factors/harvest_timing.lua',
    'server/quality/calculator.lua',
    'server/quality/init.lua',
    'server/persistence/delta_calculator.lua',
    'server/persistence/boot_reconciler.lua',
    -- Items domain.
    'server/items/physical_item.lua',
    -- Lifecycle domain: service Ã¢â€ â€™ scheduler.
    'server/lifecycle/crop_lifecycle_service.lua',
    'server/lifecycle/scheduler.lua',
    'server/pests/pest_service.lua',
    'server/main.lua',
    'server/admin/bridge_test_command.lua',
    'server/admin/finance_smoke_test.lua',
    'server/admin/plots_reload_command.lua',
    'server/admin/storage_reload_command.lua',
    'server/admin/persistence_dryrun_command.lua',
    'server/admin/debug_fastforward.lua',
    'server/admin/debug_plant.lua',
    'server/admin/debug_pest_spawn.lua',
    'server/admin/debug_reset_plot.lua',
    'server/admin/debug_plot_status.lua',
    'server/admin/debug_simulate_offline.lua',
    'server/admin/debug_machinery_breakdown.lua',
    'server/admin/debug_climate.lua',
    'server/admin/debug_give_batch.lua',
}

-- ============================================================
-- Client scripts
-- ============================================================
client_scripts {
    'client/main.lua',
    'client/machinery/breakdown.lua',
    'client/machinery/interactions.lua',
    'client/machinery/wear_tracker.lua',
    'client/climate/weather_sync.lua',
    'client/plot_renderer.lua',
    'client/plot_interactions.lua',
    'client/irrigation_interactions.lua',
    'client/fertilization_interactions.lua',
    'client/pest_interactions.lua',
    'client/inventory_render.lua',
    'client/silo_interactions.lua',
    'client/npcs/npc_spawner.lua',
}

-- ============================================================
-- Files exposed (locales for ox_lib; future slices add UI files)
-- ============================================================
files {
    'locales/*.json',
    'database/migrations/*.sql',
}

sonar_farm_migration 'database/migrations/001_init_migrations_table.sql'
sonar_farm_migration 'database/migrations/002_smoke_table.sql'
sonar_farm_migration 'database/migrations/003_finance_core.sql'
sonar_farm_migration 'database/migrations/004_plots.sql'
sonar_farm_migration 'database/migrations/005_crops.sql'
sonar_farm_migration 'database/migrations/006_batches.sql'
sonar_farm_migration 'database/migrations/007_quality_tracking.sql'
sonar_farm_migration 'database/migrations/008_storage.sql'
sonar_farm_migration 'database/migrations/009_finance_amount_decimal.sql'
sonar_farm_migration 'database/migrations/010_quality_offline_tracking.sql'
sonar_farm_migration 'database/migrations/011_pest_severity.sql'
sonar_farm_migration 'database/migrations/012_climate.sql'
sonar_farm_migration 'database/migrations/013_machinery.sql'
sonar_farm_migration 'database/migrations/014_npc_buyers.sql'

-- ============================================================
-- Lua language server: opt-in to safer globals
-- ============================================================
provide 'sonar_farm_core'
