local function t(key, ...)
    return locale(key, ...)
end

local function log_line(target_src, line)
    if target_src == 0 then
        print(line)
    else
        TriggerClientEvent('chat:addMessage', target_src, {
            color = Config.Farm.Chat.BrandColor,
            args = { t('ui.brand_name'), line },
        })
    end
end

local function run_persistence_dryrun(caller_src)
    local reconciler = Sonar and Sonar.Farm and Sonar.Farm.Persistence and Sonar.Farm.Persistence.BootReconciler or nil
    if not reconciler or type(reconciler.Run) ~= 'function' then
        log_line(caller_src, t('persistence.dryrun.unavailable'))
        return
    end

    log_line(caller_src, t('persistence.dryrun.header'))

    local ok, result_or_error = pcall(reconciler.Run, { dry_run = true })
    if not ok then
        log_line(caller_src, t('persistence.dryrun.failed', tostring(result_or_error)))
        log_line(caller_src, t('persistence.dryrun.footer'))
        return
    end

    local result = result_or_error
    log_line(caller_src, t('persistence.dryrun.summary', result.reconciled, result.unchanged, result.capped, result.skipped, result.total))

    for index = 1, #result.previews do
        local preview = result.previews[index]
        local capped_label = preview.capped and t('persistence.dryrun.capped_yes') or t('persistence.dryrun.capped_no')
        log_line(caller_src, t('persistence.dryrun.preview_line', preview.plot_id, preview.crop_type, preview.stage_advances, capped_label))
    end

    log_line(caller_src, t('persistence.dryrun.footer'))
end

RegisterCommand('sonarfarm:persistence:dryrun', function(source)
    local caller_src = tonumber(source) or 0
    if caller_src > 0 and not IsPlayerAceAllowed(caller_src, 'sonar.farm.admin') then
        log_line(caller_src, t('persistence.dryrun.ace_required'))
        return
    end

    run_persistence_dryrun(caller_src)
end, false)
