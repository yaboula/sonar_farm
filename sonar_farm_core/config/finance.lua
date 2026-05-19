-- ============================================================
-- Farm Sonar — Finance layer config.
-- ============================================================
--
-- S3: Finance compatibility layer. The active adapter controls
-- which bank/money implementation handles Farm money mutations.
-- Changing this value requires a server restart.
--
-- Anti-pattern §3: no tunable values in production code. All here.
--
-- Loaded as a shared script so Config.Farm.Finance is readable
-- on both server and client (finance logic itself is server-only).
--

Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.Finance = Config.Farm.Finance or {}

-- Active finance adapter.
-- Allowed values in S3 baseline: 'native_bridge'
-- 'native_bridge' delegates money reads/mutations to Sonar.Farm.Bridge
-- so no additional bank resource is required on the server.
--
-- Future optional adapters (only when verified API + adapter file exist):
--   'sonar_bank'       — Sonar bank ecosystem (future)
--   'renewed_banking'  — Renewed Banking (future)
--   'okok_banking'     — okokBanking (future)
--   'qs_banking'       — qs-style banking (future)
--
-- If the configured adapter is not registered at boot time, the system
-- logs a warning and falls back to 'native_bridge'. Never fails silently.
Config.Farm.Finance.Adapter = 'native_bridge'
