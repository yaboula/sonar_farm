-- ============================================================
-- Farm Sonar — Plot domain boot coordinator (S5).
-- ============================================================
--
-- Exposes `Sonar.Farm.Plots.Boot()` called by server/main.lua
-- after DB migrations succeed. Mirrors the finance boot pattern
-- (server/finance/init.lua): a thin orchestrator that calls
-- the public `PlotService` API and produces localized log
-- output. No duplication of service logic.
--
-- Preconditions (enforced by fxmanifest.lua load order):
--   config/plots.lua loaded as a shared script.
--   server/db/db.lua loaded.
--   server/db/migrator.lua loaded and migrations applied.
--   server/plots/plot_service.lua loaded immediately before
--   THIS file, which loads before server/main.lua.

Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Plots = Sonar.Farm.Plots or {}

local function log_info(message)
    print(('[sonar_farm_core] %s'):format(message))
end

local function log_error(message)
    print(('[sonar_farm_core][ERROR] %s'):format(message))
end

function Sonar.Farm.Plots.Boot()
    if not Sonar.Farm.PlotService or type(Sonar.Farm.PlotService.SyncSeededPlots) ~= 'function' then
        log_error(locale('plots.boot.unavailable'))
        return false
    end

    log_info(locale('plots.boot.started'))

    local ok, result_or_error = pcall(Sonar.Farm.PlotService.SyncSeededPlots)
    if not ok then
        log_error(locale('plots.boot.boot_failed'):format(tostring(result_or_error)))
        return false
    end

    local result = result_or_error

    if result.skipped > 0 then
        log_error(locale('plots.boot.skipped_entries'):format(result.skipped))
    end

    log_info(locale('plots.boot.ready'):format(
        result.created,
        result.updated,
        result.unchanged,
        result.skipped,
        result.total
    ))

    return result.skipped == 0
end
