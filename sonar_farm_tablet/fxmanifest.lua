fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name        'sonar_farm_tablet'
author      'Gusto (Farm Sonar)'
version     '0.1.0'
description 'Farm Sonar — NUI Tablet/Laptop app (React + Tailwind v4 + shadcn/ui).'
repository  'https://github.com/yaboula/sonar_farm'

dependencies {
    'ox_lib',
    'ox_target',
    'sonar_farm_core',
}

ox_lib 'locale'

-- ============================================================
-- NUI: built React SPA lives at web/dist/.
-- During development, run `pnpm dev` from web/ for HMR; the FiveM
-- side keeps reading dist/ but devtools (F8) can attach to localhost.
-- ============================================================
ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/**/*',
    'locales/*.json',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
    'client/laptop_interaction.lua',
    'client/tablet_interaction.lua',
}

provide 'sonar_farm_tablet'
