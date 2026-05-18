-- ============================================================
-- Farm Sonar — Single source of truth for the resource version.
-- ============================================================
--
-- Update this value at every /end-slice closure.
-- Anti-pattern §3 (no hardcoded values): version lives here ONLY.
--

Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}

Sonar.Farm.Version = '0.0.1'
Sonar.Farm.Codename = 'foundation'
