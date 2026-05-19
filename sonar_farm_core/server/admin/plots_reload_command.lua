-- ============================================================
-- Farm Sonar — Admin command: /sonarfarm:plots:reload
-- ============================================================
--
-- Re-runs `PlotService.ReloadSeededPlots()` so the founder/admin
-- can apply edits to `config/plots.lua` without restarting the
-- resource. Idempotent: safe to run repeatedly. Per ADR-010,
-- reload never resets gameplay-owned columns (`state`,
-- `soil_score`, `planted_ts`, `next_stage_ts`) for existing rows.
--
-- Usage from server console:
--     sonarfarm:plots:reload
--
-- Usage from in-game admin chat (must have ace permission):
--     /sonarfarm:plots:reload
--
-- ACE permission required: `sonar.farm.admin`
--   Add to server.cfg:
--     add_ace group.admin sonar.farm.admin allow
--
-- Mirrors the auth pattern of:
--   server/admin/bridge_test_command.lua
--   server/admin/finance_smoke_test.lua
-- ============================================================

local function t(key, ...)
    return locale(key, ...)
end

---@param target_src number      who to log to (0 = server console).
---@param line       string
local function log_line(target_src, line)
    if target_src == 0 then
        print(line)
    else
        TriggerClientEvent('chat:addMessage', target_src, {
            color = Config.Farm.Chat.BrandColor,
            args  = { t('ui.brand_name'), line },
        })
    end
end

---@param caller_src number
local function run_plots_reload(caller_src)
    if not Sonar.Farm.PlotService or type(Sonar.Farm.PlotService.ReloadSeededPlots) ~= 'function' then
        log_line(caller_src, t('plots.reload.unavailable'))
        return
    end

    log_line(caller_src, t('plots.reload.header'))

    local ok, result_or_error = pcall(Sonar.Farm.PlotService.ReloadSeededPlots, caller_src)
    if not ok then
        log_line(caller_src, t('plots.reload.failed', tostring(result_or_error)))
        log_line(caller_src, t('plots.reload.footer'))
        return
    end

    local result = result_or_error
    log_line(caller_src, t('plots.reload.summary',
        result.created,
        result.updated,
        result.unchanged,
        result.skipped,
        result.total
    ))

    if result.skipped > 0 then
        log_line(caller_src, t('plots.reload.skipped_warning', result.skipped))
    end

    log_line(caller_src, t('plots.reload.footer'))
end

RegisterCommand('sonarfarm:plots:reload', function(source)
    local caller_src = tonumber(source) or 0

    -- ACE check (skip for console which is always implicitly allowed).
    if caller_src > 0 and not IsPlayerAceAllowed(caller_src, 'sonar.farm.admin') then
        log_line(caller_src, t('plots.reload.ace_required'))
        return
    end

    run_plots_reload(caller_src)
end, false) -- restricted=false; ACE check is done inside the handler
