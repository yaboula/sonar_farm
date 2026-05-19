fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

name        'sonar_farm_core'
author      'Gusto (Farm Sonar)'
version     '0.1.0'
description 'Farm Sonar — premium farming simulation core (server + client logic). Part of the Sonar product family.'
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
}

-- ============================================================
-- Server scripts
-- ============================================================
server_scripts {
    'server/main.lua',
    'server/admin/bridge_test_command.lua',
}

-- ============================================================
-- Client scripts
-- ============================================================
client_scripts {
    'client/main.lua',
}

-- ============================================================
-- Files exposed (locales for ox_lib; future slices add UI files)
-- ============================================================
files {
    'locales/*.json',
}

-- ============================================================
-- Lua language server: opt-in to safer globals
-- ============================================================
provide 'sonar_farm_core'
