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
    local boot_message
    if _G.locale then
        boot_message = locale('boot.ready', Sonar.Farm.Version)
    else
        boot_message = ('Farm Sonar core booted (v%s)'):format(Sonar.Farm.Version)
    end

    log_info(boot_message)

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
