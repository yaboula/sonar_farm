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

local storage_swap_hook_id = nil

local function is_non_empty_string(value)
    return type(value) == 'string' and value ~= ''
end

local function get_storage_stash_prefix()
    return Config and Config.Farm and Config.Farm.Storage and Config.Farm.Storage.StashPrefix or 'sonar_farm_silo_'
end

local function get_storage_id_from_inventory(inventory)
    local inventory_id = nil

    if type(inventory) == 'string' then
        inventory_id = inventory
    elseif type(inventory) == 'number' then
        inventory_id = tostring(inventory)
    elseif type(inventory) == 'table' then
        if is_non_empty_string(inventory.id) then
            inventory_id = inventory.id
        elseif is_non_empty_string(inventory.inventory) then
            inventory_id = inventory.inventory
        elseif is_non_empty_string(inventory.name) then
            inventory_id = inventory.name
        end
    end

    local prefix = get_storage_stash_prefix()
    if is_non_empty_string(inventory_id) and inventory_id:sub(1, #prefix) == prefix then
        return inventory_id:sub(#prefix + 1)
    end

    return nil
end

local function get_batch_row(batch_id)
    if not Sonar.Farm.DB or type(Sonar.Farm.DB.row) ~= 'function' then
        return nil
    end

    return Sonar.Farm.DB.row([[
        SELECT `batch_id`, `crop_type`, `quality`, `weight_g`, `sold_ts`
        FROM `sonar_farm_batches`
        WHERE `batch_id` = ?
        LIMIT 1
    ]], { batch_id })
end

local function get_storage_content_row(batch_id)
    if not Sonar.Farm.DB or type(Sonar.Farm.DB.row) ~= 'function' then
        return nil
    end

    return Sonar.Farm.DB.row([[
        SELECT `storage_id`, `batch_id`, `player_cid`, `item_name`, `deposited_ts`
        FROM `sonar_farm_storage_contents`
        WHERE `batch_id` = ?
        LIMIT 1
    ]], { batch_id })
end

local function validate_batch_metadata(metadata)
    if not Sonar.Farm.PhysicalItem or type(Sonar.Farm.PhysicalItem.ValidateMetadata) ~= 'function' then
        return false, 'physical_item_unavailable'
    end

    return Sonar.Farm.PhysicalItem.ValidateMetadata(metadata)
end

local function resolve_inventory_batch(source, batch_id, crop_type)
    local ox_inventory = get_ox_inventory()
    if not ox_inventory then
        return nil, nil, 'inventory_unavailable'
    end

    local item_name = 'sonar_batch_' .. tostring(crop_type)
    local lookup_ok, slots_or_error = pcall(function()
        return ox_inventory:Search(source, 'slots', item_name, { batch_id = batch_id })
    end)

    if not lookup_ok then
        return nil, nil, 'inventory_lookup_failed'
    end

    local slots = type(slots_or_error) == 'table' and slots_or_error or {}
    for index = 1, #slots do
        local slot = slots[index]
        if type(slot) == 'table' and type(slot.metadata) == 'table' and tostring(slot.metadata.batch_id or '') == batch_id then
            return slot, slot.metadata, nil
        end
    end

    return nil, nil, 'batch_not_in_inventory'
end

local function build_sale_preview(source, buyer_id, batch_id)
    if not Sonar.Farm.NPCBuyerService or type(Sonar.Farm.NPCBuyerService.CalculatePayout) ~= 'function' then
        return nil, 'npc_buyer_unavailable'
    end

    local batch = get_batch_row(batch_id)
    if not batch then
        return nil, 'batch_not_found'
    end

    if batch.sold_ts ~= nil then
        return nil, 'batch_already_sold'
    end

    local crop_type = tostring(batch.crop_type or '')
    if crop_type == '' then
        return nil, 'invalid_crop_type'
    end

    local slot, metadata, slot_err = resolve_inventory_batch(source, batch_id, crop_type)
    if slot_err then
        return nil, slot_err
    end

    if not slot or type(metadata) ~= 'table' then
        return nil, 'batch_not_in_inventory'
    end

    local metadata_ok, metadata_err = validate_batch_metadata(metadata)
    if metadata_ok ~= true then
        return nil, metadata_err or 'invalid_batch_metadata'
    end

    local quality = tostring(metadata.quality or batch.quality or '')
    local weight_kg = (tonumber(metadata.weight_g) or tonumber(batch.weight_g) or 0) / 1000
    local payout_ok, payout, breakdown, payout_err = pcall(Sonar.Farm.NPCBuyerService.CalculatePayout, buyer_id, crop_type, quality, weight_kg)
    if not payout_ok then
        return nil, tostring(payout)
    end

    if not payout then
        return nil, payout_err
    end

    return {
        buyer_id = buyer_id,
        batch_id = batch_id,
        crop_type = crop_type,
        quality = quality,
        weight_kg = weight_kg,
        payout = payout,
        breakdown = breakdown,
    }, nil
end

local function record_storage_deposit(source, storage_id, batch_id, item_name, metadata)
    if type(source) ~= 'number' or source <= 0 then
        return false, 'invalid_source'
    end

    if not is_non_empty_string(storage_id) then
        return false, 'invalid_storage_id'
    end

    if not is_non_empty_string(batch_id) then
        return false, 'invalid_batch_id'
    end

    if not is_non_empty_string(item_name) then
        return false, 'invalid_item_name'
    end

    if type(metadata) ~= 'table' then
        return false, 'invalid_batch_metadata'
    end

    local player_cid = get_player_cid(source)
    if not player_cid then
        return false, 'player_unavailable'
    end

    if not Sonar.Farm.StorageService or type(Sonar.Farm.StorageService.GetUnit) ~= 'function' then
        return false, 'storage_unavailable'
    end

    local unit = Sonar.Farm.StorageService.GetUnit(storage_id)
    if not unit then
        return false, 'storage_not_found'
    end

    local metadata_ok, metadata_err = validate_batch_metadata(metadata)
    if metadata_ok ~= true then
        return false, metadata_err or 'invalid_batch_metadata'
    end

    local batch = get_batch_row(batch_id)
    if not batch then
        return false, 'batch_not_found'
    end

    if batch.sold_ts ~= nil then
        return false, 'batch_already_sold'
    end

    local existing = get_storage_content_row(batch_id)
    if existing then
        if tostring(existing.storage_id) == storage_id then
            return true, nil
        end

        return false, 'batch_already_stored'
    end

    local deposited_ts = os.time()
    local transaction_ok, transaction_err = pcall(function()
        Sonar.Farm.DB.transaction({
            {
                query = [[
                    INSERT INTO `sonar_farm_storage_contents` (
                        `storage_id`,
                        `batch_id`,
                        `player_cid`,
                        `item_name`,
                        `deposited_ts`
                    ) VALUES (?, ?, ?, ?, ?)
                ]],
                values = {
                    storage_id,
                    batch_id,
                    player_cid,
                    item_name,
                    deposited_ts,
                },
            },
        })
    end)

    if not transaction_ok then
        return false, tostring(transaction_err)
    end

    TriggerEvent('sonar:farm:storage:deposited', {
        storage_id = storage_id,
        batch_id = batch_id,
        player_cid = player_cid,
        item_name = item_name,
        deposited_ts = deposited_ts,
    })

    return true, nil
end

local function record_storage_withdraw(source, storage_id, batch_id)
    if type(source) ~= 'number' or source <= 0 then
        return false, 'invalid_source'
    end

    if not is_non_empty_string(storage_id) then
        return false, 'invalid_storage_id'
    end

    if not is_non_empty_string(batch_id) then
        return false, 'invalid_batch_id'
    end

    local player_cid = get_player_cid(source)
    if not player_cid then
        return false, 'player_unavailable'
    end

    if not Sonar.Farm.StorageService or type(Sonar.Farm.StorageService.GetUnit) ~= 'function' then
        return false, 'storage_unavailable'
    end

    local unit = Sonar.Farm.StorageService.GetUnit(storage_id)
    if not unit then
        return false, 'storage_not_found'
    end

    local existing = get_storage_content_row(batch_id)
    if not existing then
        return true, nil
    end

    if tostring(existing.storage_id) ~= storage_id then
        return false, 'batch_not_stored'
    end

    local transaction_ok, transaction_err = pcall(function()
        Sonar.Farm.DB.transaction({
            {
                query = 'DELETE FROM `sonar_farm_storage_contents` WHERE `batch_id` = ? LIMIT 1',
                values = { batch_id },
            },
        })
    end)

    if not transaction_ok then
        return false, tostring(transaction_err)
    end

    TriggerEvent('sonar:farm:storage:withdrawn', {
        storage_id = storage_id,
        batch_id = batch_id,
        player_cid = player_cid,
        withdrawn_ts = os.time(),
    })

    return true, nil
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

local function run_storage_boot()
    if not Sonar.Farm.Storage or type(Sonar.Farm.Storage.Boot) ~= 'function' then
        log_error(locale('storage.boot.unavailable'))
        return false
    end

    return Sonar.Farm.Storage.Boot()
end

local function run_npc_buyer_boot()
    if not Sonar.Farm.NPCs or type(Sonar.Farm.NPCs.Boot) ~= 'function' then
        log_error(locale('npcs.boot.unavailable'))
        return false
    end

    return Sonar.Farm.NPCs.Boot()
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

local function register_sale_callbacks()
    if not lib or not lib.callback or type(lib.callback.register) ~= 'function' then
        log_error('ox_lib callback registry unavailable. Sale callbacks were not registered.')
        return
    end

    lib.callback.register('sonar:farm:storage:list_units', function()
        return Config and Config.Farm and Config.Farm.Storage and Config.Farm.Storage.units or {}
    end)

    lib.callback.register('sonar:farm:sale:preview', function(source, buyer_id, batch_id)
        if type(buyer_id) ~= 'string' or buyer_id == '' then
            return { ok = false, error = 'invalid_buyer_id' }
        end

        if type(batch_id) ~= 'string' or batch_id == '' then
            return { ok = false, error = 'invalid_batch_id' }
        end

        local preview_ok, preview, preview_err = pcall(build_sale_preview, source, buyer_id, batch_id)
        if not preview_ok then
            return { ok = false, error = tostring(preview) }
        end

        if not preview then
            return { ok = false, error = tostring(preview_err) }
        end

        return {
            ok = true,
            payout = preview.payout,
            data = preview,
        }
    end)
    lib.callback.register('sonar:farm:sale:sell', function(source, buyer_id, batch_id)
        if type(buyer_id) ~= 'string' or buyer_id == '' then
            return { ok = false, error = 'invalid_buyer_id' }
        end

        if type(batch_id) ~= 'string' or batch_id == '' then
            return { ok = false, error = 'invalid_batch_id' }
        end

        if not Sonar.Farm.NPCBuyerService or type(Sonar.Farm.NPCBuyerService.ExecuteSale) ~= 'function' then
            return { ok = false, error = 'npc_buyer_unavailable' }
        end

        local ok, payout, err = Sonar.Farm.NPCBuyerService.ExecuteSale(source, buyer_id, batch_id)
        if not ok then
            return { ok = false, error = tostring(err) }
        end

        return {
            ok = true,
            data = {
                buyer_id = buyer_id,
                batch_id = batch_id,
                payout = payout,
            },
        }
    end)
end

local function register_storage_swap_hook()
    local ox_inventory = get_ox_inventory()
    if not ox_inventory or type(ox_inventory.registerHook) ~= 'function' then
        return
    end

    if storage_swap_hook_id and type(ox_inventory.removeHooks) == 'function' then
        pcall(function()
            ox_inventory:removeHooks(storage_swap_hook_id)
        end)
        storage_swap_hook_id = nil
    end

    local hook_ok, hook_id_or_error = pcall(function()
        return ox_inventory:registerHook('swapItems', function()
            return true
        end, {
            inventoryFilter = { '^' .. get_storage_stash_prefix() },
        })
    end)

    if not hook_ok then
        log_error(('storage swap hook registration failed: %s'):format(tostring(hook_id_or_error)))
        return
    end

    storage_swap_hook_id = hook_id_or_error

    if not storage_swap_hook_id then
        return
    end

    AddEventHandler(storage_swap_hook_id, function(success, payload)
        if success ~= true or type(payload) ~= 'table' then
            return
        end

        local from_storage_id = get_storage_id_from_inventory(payload.fromInventory)
        local to_storage_id = get_storage_id_from_inventory(payload.toInventory)
        local from_type = tostring(payload.fromType or '')
        local to_type = tostring(payload.toType or '')
        local from_slot = type(payload.fromSlot) == 'table' and payload.fromSlot or {}
        local metadata = type(from_slot.metadata) == 'table' and from_slot.metadata or {}
        local batch_id = tostring(metadata.batch_id or '')
        local item_name = tostring(from_slot.name or '')

        if batch_id == '' or item_name:match('^sonar_batch_') == nil then
            return
        end

        if to_storage_id and from_type == 'player' and not from_storage_id then
            local ok, err = record_storage_deposit(payload.source, to_storage_id, batch_id, item_name, metadata)
            if not ok then
                log_error(format_locale_message('storage.hook.deposit_failed', {
                    batch_id = batch_id,
                    error = tostring(err),
                }))
            end
            return
        end

        if from_storage_id and to_type == 'player' and not to_storage_id then
            local ok, err = record_storage_withdraw(payload.source, from_storage_id, batch_id)
            if not ok then
                log_error(format_locale_message('storage.hook.withdraw_failed', {
                    batch_id = batch_id,
                    error = tostring(err),
                }))
            end
        end
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
    run_storage_boot()
    run_npc_buyer_boot()

    register_plot_callbacks()
    register_sale_callbacks()
    register_storage_swap_hook()

    if Config and Config.Farm and Config.Farm.Debug then
        log_info('debug mode ENABLED')
    end
end)

AddEventHandler('onResourceStop', function(resource_name)
    if resource_name ~= GetCurrentResourceName() then
        return
    end

    local ox_inventory = get_ox_inventory()
    if storage_swap_hook_id and ox_inventory and type(ox_inventory.removeHooks) == 'function' then
        pcall(function()
            ox_inventory:removeHooks(storage_swap_hook_id)
        end)
        storage_swap_hook_id = nil
    end

    if Sonar.Farm.Lifecycle and Sonar.Farm.Lifecycle.Scheduler and type(Sonar.Farm.Lifecycle.Scheduler.Stop) == 'function' then
        Sonar.Farm.Lifecycle.Scheduler.Stop()
    end

    log_info('shutting down')
end)
