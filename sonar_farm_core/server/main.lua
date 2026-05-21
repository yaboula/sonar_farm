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

local function format_locale_message(key, replacements)
    local message = locale(key)
    if type(message) ~= 'string' then
        return ''
    end

    if type(replacements) ~= 'table' then
        return message
    end

    for token, value in pairs(replacements) do
        message = message:gsub('{' .. token .. '}', tostring(value))
    end

    return message
end

local function get_player_cid(src)
    if not Sonar.Farm.Bridge or type(Sonar.Farm.Bridge.GetPlayer) ~= 'function' then
        return nil
    end

    local player = Sonar.Farm.Bridge.GetPlayer(src)
    if not player or type(player.citizen_id) ~= 'string' or player.citizen_id == '' then
        return nil
    end

    return player.citizen_id
end

local function get_ox_inventory()
    if type(exports) ~= 'table' or not exports.ox_inventory then
        return nil
    end

    return exports.ox_inventory
end

local function run_finance_boot()
    if not Sonar.Farm.Finance or type(Sonar.Farm.Finance.Boot) ~= 'function' then
        log_error(locale('finance.boot.boot_failed'))
        return false
    end

    return Sonar.Farm.Finance.Boot()
end

local function run_plots_boot()
    if not Sonar.Farm.Plots or type(Sonar.Farm.Plots.Boot) ~= 'function' then
        log_error(locale('plots.boot.unavailable'))
        return false
    end

    return Sonar.Farm.Plots.Boot()
end

local function run_quality_boot()
    if not Sonar.Farm.Quality or type(Sonar.Farm.Quality.Boot) ~= 'function' then
        log_error('[quality] boot unavailable. Check fxmanifest.lua server_scripts order.')
        return false
    end

    local ok, result = pcall(Sonar.Farm.Quality.Boot)
    if not ok then
        log_error(('[quality] boot failed: %s'):format(tostring(result)))
        return false
    end

    if result ~= true then
        log_error('[quality] boot failed')
        return false
    end

    return true
end

local function run_lifecycle_boot()
    if not Sonar.Farm.CropLifecycle or type(Sonar.Farm.CropLifecycle.Boot) ~= 'function' then
        log_error('[lifecycle] boot unavailable. Check fxmanifest.lua server_scripts order.')
        return false
    end

    local ok, result = pcall(Sonar.Farm.CropLifecycle.Boot)
    if not ok then
        log_error(('[lifecycle] boot failed: %s'):format(tostring(result)))
        return false
    end

    if result ~= true then
        log_error('[lifecycle] boot failed')
        return false
    end

    local active = 0
    if Sonar.Farm.DB and type(Sonar.Farm.DB.scalar) == 'function' then
        local count_ok, count_or_error = pcall(Sonar.Farm.DB.scalar, 'SELECT COUNT(*) FROM `sonar_farm_crops`', {})
        if count_ok then
            active = tonumber(count_or_error) or 0
        else
            log_error(('[lifecycle] failed to count active crops: %s'):format(tostring(count_or_error)))
        end
    end

    local tick_seconds = tonumber(Config and Config.Farm and Config.Farm.Scheduler and Config.Farm.Scheduler.TickSeconds) or 30

    log_info(format_locale_message('lifecycle.boot.ready', { active = active }))
    log_info(format_locale_message('lifecycle.boot.scheduler_started', { seconds = math.floor(tick_seconds) }))

    return true
end

local function register_plot_callbacks()
    if not lib or not lib.callback or type(lib.callback.register) ~= 'function' then
        log_error('ox_lib callback registry unavailable. Plot callbacks were not registered.')
        return
    end

    lib.callback.register('sonar:farm:plot:list', function()
        if not Sonar.Farm.PlotService or type(Sonar.Farm.PlotService.ListPlots) ~= 'function' then
            return {}
        end

        return Sonar.Farm.PlotService.ListPlots() or {}
    end)

    lib.callback.register('sonar:farm:plot:active_crops', function()
        if not Sonar.Farm.DB or type(Sonar.Farm.DB.rows) ~= 'function' then
            return {}
        end

        local rows = Sonar.Farm.DB.rows([[
            SELECT `plot_id`, `crop_type`, `stage`
            FROM `sonar_farm_crops`
            ORDER BY `plot_id` ASC
        ]], {}) or {}

        local crops = {}
        for index = 1, #rows do
            crops[#crops + 1] = {
                plot_id = rows[index].plot_id,
                crop_type = rows[index].crop_type,
                stage = tonumber(rows[index].stage) or 0,
            }
        end

        return crops
    end)

    lib.callback.register('sonar:farm:plot:plant', function(source, plot_id)
        if type(plot_id) ~= 'string' or plot_id == '' then
            return { ok = false, error = 'invalid_plot_id' }
        end

        if not Sonar.Farm.CropLifecycle or type(Sonar.Farm.CropLifecycle.Plant) ~= 'function' then
            return { ok = false, error = 'lifecycle_unavailable' }
        end

        local player_cid = get_player_cid(source)
        if not player_cid then
            return { ok = false, error = 'player_unavailable' }
        end

        local ox_inventory = get_ox_inventory()
        if not ox_inventory then
            return { ok = false, error = 'inventory_unavailable' }
        end

        local remove_ok, remove_result = pcall(function()
            return ox_inventory:RemoveItem(source, 'sonar_seed_wheat', 1)
        end)

        if not remove_ok or remove_result == false then
            return { ok = false, error = 'seed_missing' }
        end

        local ok, crop_or_error = Sonar.Farm.CropLifecycle.Plant(plot_id, player_cid, 'wheat')
        if not ok then
            pcall(function()
                ox_inventory:AddItem(source, 'sonar_seed_wheat', 1)
            end)
            return { ok = false, error = tostring(crop_or_error) }
        end

        return { ok = true, data = crop_or_error }
    end)

    lib.callback.register('sonar:farm:plot:harvest', function(source, plot_id)
        if type(plot_id) ~= 'string' or plot_id == '' then
            return { ok = false, error = 'invalid_plot_id' }
        end

        if not Sonar.Farm.CropLifecycle or type(Sonar.Farm.CropLifecycle.Harvest) ~= 'function' then
            return { ok = false, error = 'lifecycle_unavailable' }
        end

        local player_cid = get_player_cid(source)
        if not player_cid then
            return { ok = false, error = 'player_unavailable' }
        end

        local ok, harvest_or_error = Sonar.Farm.CropLifecycle.Harvest(plot_id, player_cid)
        if not ok then
            return { ok = false, error = tostring(harvest_or_error) }
        end

        if type(harvest_or_error) ~= 'table' or type(harvest_or_error.metadata) ~= 'table' then
            return { ok = false, error = 'batch_metadata_unavailable' }
        end

        local ox_inventory = get_ox_inventory()
        if not ox_inventory then
            return { ok = false, error = 'inventory_unavailable' }
        end

        local metadata = harvest_or_error.metadata
        local batch_id = tostring(metadata.batch_id or '')
        local suffix = batch_id:sub(-4):upper()
        metadata.item_name = 'sonar_batch_wheat'
        metadata.quality_badge = tostring(metadata.quality or '')
        metadata.freshness_percent = tonumber(metadata.freshness) or 0
        metadata.batch_suffix = suffix

        local add_ok, add_result = pcall(function()
            return ox_inventory:AddItem(source, 'sonar_batch_wheat', 1, metadata)
        end)

        if not add_ok or add_result == false then
            return { ok = false, error = 'batch_add_failed' }
        end

        return {
            ok = true,
            data = {
                batch_id = harvest_or_error.batch_id,
                metadata = metadata,
                quality = harvest_or_error.quality,
            },
        }
    end)
end

local function register_plot_event_relays()
    local relay_events = {
        'sonar:farm:plot:planted',
        'sonar:farm:plot:stage_advanced',
        'sonar:farm:plot:harvested',
        'sonar:farm:plot:state_changed',
    }

    for index = 1, #relay_events do
        local event_name = relay_events[index]
        AddEventHandler(event_name, function(payload)
            TriggerClientEvent(event_name, -1, payload)
        end)
    end
end

register_plot_event_relays()

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

    -- Plot registry boot is also gated on DB success and non-fatal,
    -- mirroring the finance pattern. If seed sync fails or skips
    -- invalid entries, PlotService still answers reads and the rest
    -- of the resource keeps booting; the admin can run
    -- `/sonarfarm:plots:reload` to retry once the config is fixed.
    run_plots_boot()

    -- B1 boot sequence: quality and lifecycle domains after plots.
    -- Both are non-fatal to avoid hard-failing core boot if a single
    -- domain is temporarily misconfigured during development.
    run_quality_boot()
    run_lifecycle_boot()

    register_plot_callbacks()

    if Config and Config.Farm and Config.Farm.Debug then
        log_info('debug mode ENABLED')
    end
end)

AddEventHandler('onResourceStop', function(resource_name)
    if resource_name ~= GetCurrentResourceName() then
        return
    end

    if Sonar.Farm.Lifecycle and Sonar.Farm.Lifecycle.Scheduler and type(Sonar.Farm.Lifecycle.Scheduler.Stop) == 'function' then
        Sonar.Farm.Lifecycle.Scheduler.Stop()
    end

    log_info('shutting down')
end)
