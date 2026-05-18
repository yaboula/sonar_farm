// ============================================================
// Farm Sonar — Single source of truth for the NUI app version.
// ============================================================
//
// Mirrors `sonar_farm_core/shared/version.lua` Sonar.Farm.Version.
// Anti-pattern §3 (no hardcoded values): NEVER inline this version
// elsewhere. Always import from this module.
//
// Bumped at every /end-slice closure that ships user-visible changes.
// ============================================================

export const VERSION = '0.1.0' as const;
export const CODENAME = 'foundation' as const;
