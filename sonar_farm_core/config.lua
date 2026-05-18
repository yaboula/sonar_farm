-- ============================================================
-- Farm Sonar — Root config placeholder.
-- ============================================================
--
-- Future slices will populate this. Per anti-pattern §3, ALL tunable
-- values must live here or in `config/*.lua` partials, never inline
-- in code.
--
-- Loaded as a shared script in fxmanifest.lua so both server and
-- client see the same Config table.
--

Config = Config or {}
Config.Farm = Config.Farm or {}

-- Default locale fallback (per rule 03_languages.md).
Config.Farm.Locale = 'en'

-- Debug flag: toggles verbose logs and admin commands. NEVER true in production.
Config.Farm.Debug = false
