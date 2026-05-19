-- ============================================================
-- Farm Sonar — Cross-cutting shared initialization.
-- ============================================================
--
-- Runs FIRST on both server and client (after @ox_lib/init.lua,
-- before any other Sonar script). Responsibilities:
--
--   1. Initialise the ox_lib locale module so the global
--      `locale(key, ...)` function becomes available. Without
--      this call, `locale` stays nil and our i18n breaks.
--      Per docs: https://overextended.dev/ox_lib/Modules/Locale/Shared
--
-- This file MUST stay minimal and side-effect free beyond the
-- documented bootstrap calls. Anything domain-specific belongs
-- in its own module.
-- ============================================================

-- Loads locale files from `locales/*.json` per the convar
-- `ox:locale` (default 'en'). Registers `locale` as a global.
lib.locale()
