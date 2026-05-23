-- ============================================================
-- Farm Sonar - Server entrypoint.
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

local function get_active_crop_row(plot_id)
    if not Sonar.Farm.DB or type(Sonar.Farm.DB.row) ~= 'function' then
        return nil
    end

    return Sonar.Farm.DB.row([[
        SELECT `plot_id`, `crop_type`, `stage`
        FROM `sonar_farm_crops`
        WHERE `plot_id` = ?
        LIMIT 1
    ]], { plot_id })
end

local function get_quality_factor(factor_name)
    local quality = Sonar and Sonar.Farm and Sonar.Farm.Quality or nil
    local factors = quality and quality.Factors or nil
    local factor = factors and factors[factor_name] or nil
    if type(factor) ~= 'table' then
        return nil
    end

    return factor
end

local function get_irrigation_max_charges()
    return math.max(tonumber(Config and Config.Farm and Config.Farm.Irrigation and Config.Farm.Irrigation.tank_max_charges) or 0, 0)
end

local function get_finance_service()
    return Sonar and Sonar.Farm and Sonar.Farm.Finance or nil
end

local function get_machinery_service()
    return Sonar and Sonar.Farm and Sonar.Farm.MachineryService or nil
end

local function get_machinery_kit_name()
    return Config
        and Config.Farm
        and Config.Farm.Machinery
        and Config.Farm.Machinery.Repair
        and Config.Farm.Machinery.Repair.item_name
        or 'sonar_machinery_kit'
end

local function build_greenhouse_maintenance_key(source, plot_id, crop_type)
    return ('greenhouse_maintenance:%s:%s:%s:%d'):format(tostring(source), tostring(plot_id), tostring(crop_type), os.time())
end

local function charge_greenhouse_maintenance(source, plot_id, crop_type, plant_policy)
    local amount = math.max(tonumber(plant_policy and plant_policy.maintenance_cost) or 0, 0)
    if amount <= 0 then
        return true, nil
    end

    local finance = get_finance_service()
    if not finance or type(finance.Debit) ~= 'function' then
        return false, 'greenhouse_maintenance_unavailable'
    end

    local account = tostring(plant_policy.maintenance_account or 'bank')
    local reason = tostring(plant_policy.maintenance_reason or 'greenhouse_maintenance')
    local idempotency_key = build_greenhouse_maintenance_key(source, plot_id, crop_type)
    local ok, result = finance.Debit(source, account, amount, reason, idempotency_key, {
        plot_id = plot_id,
        crop_type = crop_type,
    })

    if not ok then
        local error_code = type(result) == 'table' and tostring(result.error_code or 'greenhouse_maintenance_failed') or 'greenhouse_maintenance_failed'
        return false, string.lower(error_code)
    end

    return true, {
        amount = amount,
        account = account,
        reason = reason,
        idempotency_key = idempotency_key,
    }
end

local function refund_greenhouse_maintenance(source, charged_state)
    if type(charged_state) ~= 'table' then
        return
    end

    local finance = get_finance_service()
    if not finance or type(finance.Credit) ~= 'function' then
        return
    end

    finance.Credit(source, charged_state.account, charged_state.amount, charged_state.reason, charged_state.idempotency_key .. ':refund', {
        refunded = true,
    })
end

local function search_inventory_slots(source, item_name, metadata)
    local ox_inventory = get_ox_inventory()
    if not ox_inventory then
        return nil, 'inventory_unavailable'
    end

    local ok, slots_or_error = pcall(function()
        return ox_inventory:Search(source, 'slots', item_name, metadata)
    end)

    if not ok then
        return nil, 'inventory_lookup_failed'
    end

    return type(slots_or_error) == 'table' and slots_or_error or {}, nil
end

local function copy_metadata(metadata)
    local copied = {}
    if type(metadata) ~= 'table' then
        return copied
    end

    for key, value in pairs(metadata) do
        copied[key] = value
    end

    return copied
end

local function set_inventory_slot_metadata(source, slot_id, metadata)
    local ox_inventory = get_ox_inventory()
    if not ox_inventory or type(ox_inventory.SetMetadata) ~= 'function' then
        return false, 'inventory_metadata_unavailable'
    end

    local ok, result = pcall(function()
        return ox_inventory:SetMetadata(source, slot_id, metadata)
    end)

    if not ok then
        return false, 'inventory_metadata_failed'
    end

    return result ~= false, result ~= false and nil or 'inventory_metadata_failed'
end

local function find_water_tank_slot(source, required_charges)
    local slots, slot_error = search_inventory_slots(source, 'sonar_water_tank')
    if not slots then
        return nil, nil, slot_error
    end

    local needed = math.max(tonumber(required_charges) or 1, 1)
    local max_charges = get_irrigation_max_charges()

    for index = 1, #slots do
        local slot = slots[index]
        local metadata = type(slot) == 'table' and type(slot.metadata) == 'table' and slot.metadata or {}
        local charges = tonumber(metadata.charges)
        if charges == nil then
            charges = max_charges
        end

        if charges >= needed then
            return slot, charges, nil
        end
    end

    if #slots == 0 then
        return nil, nil, 'tank_missing'
    end

    return nil, nil, 'tank_empty'
end

local function find_refillable_tank_slot(source)
    local slots, slot_error = search_inventory_slots(source, 'sonar_water_tank')
    if not slots then
        return nil, nil, slot_error
    end

    local max_charges = get_irrigation_max_charges()

    for index = 1, #slots do
        local slot = slots[index]
        local metadata = type(slot) == 'table' and type(slot.metadata) == 'table' and slot.metadata or {}
        local charges = tonumber(metadata.charges)
        if charges == nil then
            charges = max_charges
        end

        if charges < max_charges then
            return slot, charges, nil
        end
    end

    if #slots == 0 then
        return nil, nil, 'tank_missing'
    end

    return nil, max_charges, 'tank_full'
end

local function find_first_item_slot(source, item_name)
    local slots, slot_error = search_inventory_slots(source, item_name)
    if not slots then
        return nil, slot_error
    end

    for index = 1, #slots do
        local slot = slots[index]
        if type(slot) == 'table' and (tonumber(slot.count) or 0) > 0 then
            return slot, nil
        end
    end

    return nil, 'item_missing'
end

local function repair_machinery_with_kit(source, plate)
    if type(source) ~= 'number' or source <= 0 then
        return { ok = false, error = 'invalid_source' }
    end

    if type(plate) ~= 'string' or plate == '' then
        return { ok = false, error = 'invalid_plate' }
    end

    local machinery_service = get_machinery_service()
    if not machinery_service or type(machinery_service.Repair) ~= 'function' then
        return { ok = false, error = 'machinery_unavailable' }
    end

    local ox_inventory = get_ox_inventory()
    if not ox_inventory then
        return { ok = false, error = 'inventory_unavailable' }
    end

    local kit_item_name = get_machinery_kit_name()
    local found_slot, slot_error = find_first_item_slot(source, kit_item_name)
    if not found_slot then
        return {
            ok = false,
            error = slot_error == 'item_missing' and 'machinery_kit_missing' or tostring(slot_error),
        }
    end

    local remove_ok, remove_result = pcall(function()
        return ox_inventory:RemoveItem(source, kit_item_name, 1)
    end)
    if not remove_ok or remove_result == false then
        return { ok = false, error = 'machinery_kit_missing' }
    end

    local repair_ok, repair_payload, repair_error = machinery_service.Repair(plate)
    if not repair_ok then
        pcall(function()
            ox_inventory:AddItem(source, kit_item_name, 1)
        end)
        return { ok = false, error = tostring(repair_error) }
    end

    return {
        ok = true,
        data = repair_payload,
    }
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

local function run_machinery_boot()
    if not Sonar.Farm.Machinery or type(Sonar.Farm.Machinery.Boot) ~= 'function' then
        log_error(locale('machinery.boot.unavailable'))
        return false
    end

    return Sonar.Farm.Machinery.Boot()
end

local function run_pest_service_boot()
    if not Sonar.Farm.PestService or type(Sonar.Farm.PestService.Boot) ~= 'function' then
        log_error('[pests] boot unavailable. Check fxmanifest.lua server_scripts order.')
        return false
    end

    local ok, result = pcall(Sonar.Farm.PestService.Boot)
    if not ok then
        log_error(('[pests] boot failed: %s'):format(tostring(result)))
        return false
    end

    if result ~= true then
        log_error('[pests] boot failed')
        return false
    end

    return true
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

local function run_offline_reconcile_boot()
    local persistence = Sonar and Sonar.Farm and Sonar.Farm.Persistence or nil
    if not persistence or not persistence.BootReconciler or type(persistence.BootReconciler.Boot) ~= 'function' then
        log_error(locale('persistence.boot.unavailable'))
        return false
    end

    return persistence.BootReconciler.Boot()
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

    lib.callback.register('sonar:farm:plot:plant', function(source, plot_id, crop_type)
        if type(plot_id) ~= 'string' or plot_id == '' then
            return { ok = false, error = 'invalid_plot_id' }
        end

        if type(crop_type) ~= 'string' or crop_type == '' then
            return { ok = false, error = 'invalid_crop_type' }
        end

        if not Sonar.Farm.CropLifecycle or type(Sonar.Farm.CropLifecycle.Plant) ~= 'function' then
            return { ok = false, error = 'lifecycle_unavailable' }
        end

        local crop_config = Config and Config.Farm and Config.Farm.Crops and Config.Farm.Crops[crop_type] or nil
        if type(crop_config) ~= 'table' then
            return { ok = false, error = 'invalid_crop_type' }
        end

        local player_cid = get_player_cid(source)
        if not player_cid then
            return { ok = false, error = 'player_unavailable' }
        end

        local plant_policy = nil
        if type(Sonar.Farm.CropLifecycle.GetPlantPolicy) == 'function' then
            local policy_or_error
            plant_policy, policy_or_error = Sonar.Farm.CropLifecycle.GetPlantPolicy(plot_id, crop_type)
            if not plant_policy then
                return { ok = false, error = tostring(policy_or_error) }
            end
        end

        local ox_inventory = get_ox_inventory()
        if not ox_inventory then
            return { ok = false, error = 'inventory_unavailable' }
        end

        local seed_item_name = ('sonar_seed_%s'):format(crop_type)
        local charged_greenhouse = nil

        local charge_ok, charge_or_error = charge_greenhouse_maintenance(source, plot_id, crop_type, plant_policy)
        if not charge_ok then
            return { ok = false, error = tostring(charge_or_error) }
        end
        charged_greenhouse = charge_or_error

        local remove_ok, remove_result = pcall(function()
            return ox_inventory:RemoveItem(source, seed_item_name, 1)
        end)

        if not remove_ok or remove_result == false then
            refund_greenhouse_maintenance(source, charged_greenhouse)
            return { ok = false, error = 'seed_missing' }
        end

        local ok, crop_or_error = Sonar.Farm.CropLifecycle.Plant(plot_id, player_cid, crop_type)
        if not ok then
            pcall(function()
                ox_inventory:AddItem(source, seed_item_name, 1)
            end)
            refund_greenhouse_maintenance(source, charged_greenhouse)
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
        local crop_type = tostring(metadata.crop_type or '')
        if crop_type == '' then
            return { ok = false, error = 'invalid_crop_type' }
        end

        local batch_item_name = ('sonar_batch_%s'):format(crop_type)
        metadata.item_name = batch_item_name
        metadata.quality_badge = tostring(metadata.quality or '')
        metadata.freshness_percent = tonumber(metadata.freshness) or 0
        metadata.batch_suffix = suffix

        local add_ok, add_result = pcall(function()
            return ox_inventory:AddItem(source, batch_item_name, 1, metadata)
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

    lib.callback.register('sonar:farm:plot:water', function(source, plot_id, charges_used)
        if type(plot_id) ~= 'string' or plot_id == '' then
            return { ok = false, error = 'invalid_plot_id' }
        end

        local active_crop = get_active_crop_row(plot_id)
        if not active_crop then
            return { ok = false, error = 'crop_not_active' }
        end

        local irrigation_factor = get_quality_factor('Irrigation')
        if not irrigation_factor or type(irrigation_factor.TrackWatering) ~= 'function' or type(irrigation_factor.get) ~= 'function' then
            return { ok = false, error = 'irrigation_unavailable' }
        end

        local requested_charges = math.max(tonumber(charges_used) or 1, 1)
        local tank_slot, current_charges, tank_error = find_water_tank_slot(source, requested_charges)
        if not tank_slot then
            return { ok = false, error = tank_error or 'tank_missing' }
        end

        local previous_score = tonumber(irrigation_factor:get(plot_id)) or 0
        local original_metadata = copy_metadata(tank_slot.metadata)
        local updated_metadata = copy_metadata(tank_slot.metadata)
        updated_metadata.charges = math.max((tonumber(current_charges) or 0) - requested_charges, 0)

        local metadata_ok, metadata_error = set_inventory_slot_metadata(source, tank_slot.slot, updated_metadata)
        if not metadata_ok then
            return { ok = false, error = metadata_error or 'inventory_metadata_failed' }
        end

        local ok, new_score, track_error = irrigation_factor.TrackWatering(plot_id, requested_charges, tonumber(active_crop.stage) or 0)
        if not ok then
            set_inventory_slot_metadata(source, tank_slot.slot, original_metadata)
            return { ok = false, error = tostring(track_error or 'watering_failed') }
        end

        local score_delta = (tonumber(new_score) or 0) - previous_score
        return {
            ok = true,
            new_score = new_score,
            delta = math.abs(score_delta),
            result = score_delta >= 0 and 'watered' or 'overwater',
            charges = updated_metadata.charges,
        }
    end)

    lib.callback.register('sonar:farm:plot:refill_tank', function(source)
        local tank_slot, _, tank_error = find_refillable_tank_slot(source)
        if not tank_slot then
            return { ok = false, error = tank_error or 'tank_missing' }
        end

        local updated_metadata = copy_metadata(tank_slot.metadata)
        updated_metadata.charges = get_irrigation_max_charges()

        local metadata_ok, metadata_error = set_inventory_slot_metadata(source, tank_slot.slot, updated_metadata)
        if not metadata_ok then
            return { ok = false, error = metadata_error or 'inventory_metadata_failed' }
        end

        return {
            ok = true,
            charges = updated_metadata.charges,
        }
    end)

    lib.callback.register('sonar:farm:plot:fertilize', function(source, plot_id, item_name)
        if type(plot_id) ~= 'string' or plot_id == '' then
            return { ok = false, error = 'invalid_plot_id' }
        end

        if type(item_name) ~= 'string' or item_name == '' then
            return { ok = false, error = 'invalid_item_name' }
        end

        local active_crop = get_active_crop_row(plot_id)
        if not active_crop or not is_non_empty_string(active_crop.crop_type) then
            return { ok = false, error = 'crop_not_active' }
        end

        local fertilization_factor = get_quality_factor('Fertilization')
        if not fertilization_factor or type(fertilization_factor.TrackApplication) ~= 'function' or type(fertilization_factor.get) ~= 'function' then
            return { ok = false, error = 'fertilization_unavailable' }
        end

        local slot, slot_error = find_first_item_slot(source, item_name)
        if not slot then
            return { ok = false, error = slot_error == 'item_missing' and 'fertilizer_missing' or slot_error }
        end

        local previous_score = tonumber(fertilization_factor:get(plot_id)) or 0
        local remove_ok, remove_result = pcall(function()
            return get_ox_inventory():RemoveItem(source, item_name, 1)
        end)
        if not remove_ok or remove_result == false then
            return { ok = false, error = 'fertilizer_missing' }
        end

        local ok, new_score, track_error = fertilization_factor.TrackApplication(
            plot_id,
            item_name,
            tostring(active_crop.crop_type),
            tonumber(active_crop.stage) or 0
        )
        if not ok then
            pcall(function()
                get_ox_inventory():AddItem(source, item_name, 1)
            end)
            return { ok = false, error = tostring(track_error or 'fertilization_failed') }
        end

        local crop_config = Config and Config.Farm and Config.Farm.Crops and Config.Farm.Crops[tostring(active_crop.crop_type)] or nil
        local fertilizer_config = crop_config and crop_config.fertilization or {}
        local score_delta = (tonumber(new_score) or 0) - previous_score
        local result = 'wrong'
        if tonumber(new_score) == tonumber(fertilizer_config.overfertilize_floor) then
            result = 'over'
        elseif score_delta > 0 then
            result = 'correct'
        end

        return {
            ok = true,
            new_score = new_score,
            delta = math.abs(score_delta),
            result = result,
        }
    end)

    lib.callback.register('sonar:farm:plot:treat_pest', function(source, plot_id, pesticide_item)
        if type(plot_id) ~= 'string' or plot_id == '' then
            return { ok = false, error = 'invalid_plot_id' }
        end

        if type(pesticide_item) ~= 'string' or pesticide_item == '' then
            return { ok = false, error = 'invalid_item_name' }
        end

        local pest_factor = get_quality_factor('Pest')
        if not pest_factor or type(pest_factor.Treat) ~= 'function' or type(pest_factor.GetStatus) ~= 'function' or type(pest_factor.get) ~= 'function' then
            return { ok = false, error = 'pest_unavailable' }
        end

        local status = pest_factor.GetStatus(plot_id)
        if not status then
            return { ok = false, error = 'no_active_pest' }
        end

        local slot, slot_error = find_first_item_slot(source, pesticide_item)
        if not slot then
            return { ok = false, error = slot_error == 'item_missing' and 'pesticide_missing' or slot_error }
        end

        local previous_score = tonumber(pest_factor:get(plot_id)) or 0
        local remove_ok, remove_result = pcall(function()
            return get_ox_inventory():RemoveItem(source, pesticide_item, 1)
        end)
        if not remove_ok or remove_result == false then
            return { ok = false, error = 'pesticide_missing' }
        end

        local ok, new_score, treat_error = pest_factor.Treat(plot_id, pesticide_item)
        if not ok then
            pcall(function()
                get_ox_inventory():AddItem(source, pesticide_item, 1)
            end)
            return { ok = false, error = tostring(treat_error or 'pest_treatment_failed') }
        end

        return {
            ok = true,
            new_score = new_score,
            delta = math.abs((tonumber(new_score) or 0) - previous_score),
            severity = status.severity,
        }
    end)

    lib.callback.register('sonar:farm:pest:get_status', function(source, plot_id)
        if source <= 0 or type(plot_id) ~= 'string' or plot_id == '' then
            return nil
        end

        local pest_factor = get_quality_factor('Pest')
        if not pest_factor or type(pest_factor.GetStatus) ~= 'function' then
            return nil
        end

        return pest_factor.GetStatus(plot_id)
    end)

    lib.callback.register('sonar:farm:climate:get_state', function()
        local climate_service = Sonar and Sonar.Farm and Sonar.Farm.ClimateService or nil
        if not climate_service or type(climate_service.GetState) ~= 'function' then
            return nil
        end

        local state = climate_service.GetState()
        if state then
            return state
        end

        if type(climate_service.Boot) == 'function' then
            local boot_ok = pcall(climate_service.Boot)
            if not boot_ok then
                return nil
            end

            return climate_service.GetState()
        end

        return nil
    end)

    lib.callback.register('sonar:farm:pest:get_active', function(source)
        if source <= 0 or not Sonar.Farm.PestService or type(Sonar.Farm.PestService.GetActivePests) ~= 'function' then
            return {}
        end

        return Sonar.Farm.PestService.GetActivePests()
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

local function register_machinery_callbacks()
    if not lib or not lib.callback or type(lib.callback.register) ~= 'function' then
        log_error('ox_lib callback registry unavailable. Machinery callbacks were not registered.')
        return
    end

    lib.callback.register('sonar:farm:machinery:report_usage', function(source, plate, amount, model)
        local machinery_service = get_machinery_service()
        if not machinery_service or type(machinery_service.RecordUsage) ~= 'function' then
            return { ok = false, error = 'machinery_unavailable' }
        end

        local usage_ok, state, usage_error = machinery_service.RecordUsage(plate, tonumber(amount), model)
        if not usage_ok then
            return { ok = false, error = tostring(usage_error) }
        end

        return {
            ok = true,
            data = state,
        }
    end)

    lib.callback.register('sonar:farm:server:repair_machinery', function(source, plate)
        return repair_machinery_with_kit(source, plate)
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
        'sonar:farm:plot:watered',
        'sonar:farm:plot:fertilized',
        'sonar:farm:pest:appeared',
        'sonar:farm:pest:treated',
        'sonar:farm:pest:severe',
        'sonar:farm:machinery:broke_down',
        'sonar:farm:machinery:repaired',
    }

    for index = 1, #relay_events do
        local event_name = relay_events[index]
        AddEventHandler(event_name, function(payload)
            TriggerClientEvent(event_name, -1, payload)
        end)
    end
end

RegisterNetEvent('sonar:farm:server:repair_machinery', function(plate)
    repair_machinery_with_kit(source, plate)
end)

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
    run_offline_reconcile_boot()
    if Sonar.Farm.ClimateService and type(Sonar.Farm.ClimateService.Boot) == 'function' then
        local climate_ok, climate_result = pcall(Sonar.Farm.ClimateService.Boot)
        if not climate_ok or climate_result ~= true then
            log_error(('[climate] boot failed: %s'):format(tostring(climate_result)))
        end
    else
        log_error('[climate] boot unavailable. Check fxmanifest.lua server_scripts order.')
    end
    run_lifecycle_boot()
    run_storage_boot()
    run_npc_buyer_boot()
    run_machinery_boot()
    run_pest_service_boot()

    register_plot_callbacks()
    register_sale_callbacks()
    register_machinery_callbacks()
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
