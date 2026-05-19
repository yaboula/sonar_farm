-- ============================================================
-- Farm Sonar — Server entrypoint.
-- ============================================================
--
-- S0 scope: just announce the boot. No game logic yet.
-- Future slices register their services here in a controlled order.
--

local function log_info(message)
    print(('[sonar_farm_core] %s'):format(message))
end

local function log_error(message)
    print(('[sonar_farm_core][ERROR] %s'):format(message))
end

local function run_finance_boot()
    if not Sonar.Farm.Finance or type(Sonar.Farm.Finance.Boot) ~= 'function' then
        log_error(locale('finance.boot.boot_failed'))
        return false
    end

    return Sonar.Farm.Finance.Boot()
end

local function run_persistence_boot()
    if not Sonar.Farm.DB then
        log_error(locale('boot.db_unavailable'))
        return false
    end

    if not Sonar.Farm.Migrator then
        log_error(locale('boot.migrator_unavailable'))
        return false
    end

    log_info(locale('boot.db_check_started'))

    local ok, result_or_error = Sonar.Farm.Migrator.run_pending_safe()
    if not ok then
        log_error(locale('boot.db_boot_failed'):format(result_or_error))
        return false
    end

    log_info(locale('boot.db_boot_ready'):format(result_or_error.applied, result_or_error.skipped, result_or_error.total))
    return true
end

AddEventHandler('onResourceStart', function(resource_name)
    if resource_name ~= GetCurrentResourceName() then
        return
    end

    if not Sonar or not Sonar.Farm or not Sonar.Farm.Version then
        log_error('shared/version.lua failed to load. Check fxmanifest.lua shared_scripts order.')
        return
    end

    -- ox_lib's `locale()` helper resolves keys from locales/*.json
    -- according to the active server locale (config: ox:locale convar).
    -- `locale()` is registered as a global by ox_lib's `locale` module,
    -- loaded through the `ox_lib 'locale'` fxmanifest metadata directive.
    local boot_message = locale('boot.ready', Sonar.Farm.Version)

    log_info(boot_message)

    if not run_persistence_boot() then
        return
    end

    -- Finance boot is gated on DB success and is non-fatal:
    -- if it fails, Credit/Debit calls will fail gracefully at runtime
    -- but the rest of the resource (Bridge, DB, future slices) still boots.
    run_finance_boot()

    if Config and Config.Farm and Config.Farm.Debug then
        log_info('debug mode ENABLED')
    end
end)

AddEventHandler('onResourceStop', function(resource_name)
    if resource_name ~= GetCurrentResourceName() then
        return
    end

    log_info('shutting down')
end)
