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

local function run_storage_reload(caller_src)
    if not Sonar.Farm.StorageService or type(Sonar.Farm.StorageService.ReloadSeededStorage) ~= 'function' then
        log_line(caller_src, t('storage.reload.unavailable'))
        return
    end

    log_line(caller_src, t('storage.reload.header'))

    local ok, result_or_error = pcall(Sonar.Farm.StorageService.ReloadSeededStorage, caller_src)
    if not ok then
        log_line(caller_src, t('storage.reload.failed', tostring(result_or_error)))
        log_line(caller_src, t('storage.reload.footer'))
        return
    end

    local result = result_or_error
    log_line(caller_src, t('storage.reload.summary', result.created, result.updated, result.unchanged, result.skipped, result.total))

    if result.skipped > 0 then
        log_line(caller_src, t('storage.reload.skipped_warning', result.skipped))
    end

    log_line(caller_src, t('storage.reload.footer'))
end

RegisterCommand('sonarfarm:storage:reload', function(source)
    local caller_src = tonumber(source) or 0

    if caller_src > 0 and not IsPlayerAceAllowed(caller_src, 'sonar.farm.admin') then
        log_line(caller_src, t('storage.reload.ace_required'))
        return
    end

    run_storage_reload(caller_src)
end, false)
