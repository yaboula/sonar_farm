Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}

local StorageService = {}

local CREATE_REASON = 'storage_seed_create'
local UPDATE_CONFIG_REASON = 'storage_seed_update'
local VALID_BATCH_ID_PATTERN = '^sf%-%x%x%x%x%x%x%x%x$'

local function log_info(message)
    print(('[sonar_farm_core][storage] %s'):format(message))
end

local function log_error(message)
    print(('[sonar_farm_core][storage][ERROR] %s'):format(message))
end

local function get_db()
    if not Sonar.Farm.DB then
        error('Sonar.Farm.DB is unavailable', 2)
    end

    return Sonar.Farm.DB
end

local function get_storage_config()
    Config = Config or {}
    Config.Farm = Config.Farm or {}
    Config.Farm.Storage = Config.Farm.Storage or {}
    Config.Farm.Storage.AllowedTypes = Config.Farm.Storage.AllowedTypes or {}
    Config.Farm.Storage.units = Config.Farm.Storage.units or {}

    return Config.Farm.Storage
end

local function get_ox_inventory()
    if type(exports) ~= 'table' or not exports.ox_inventory then
        return nil
    end

    return exports.ox_inventory
end

local function is_non_empty_string(value)
    return type(value) == 'string' and value ~= ''
end

local function is_number(value)
    return type(value) == 'number'
end

local function is_positive_number(value)
    return type(value) == 'number' and value > 0
end

local function is_positive_integer(value)
    return type(value) == 'number' and value > 0 and value == math.floor(value)
end

local function normalize_coords(entry)
    local coords = entry.coords or {}

    return {
        x = tonumber(entry.coords_x) or tonumber(coords.x),
        y = tonumber(entry.coords_y) or tonumber(coords.y),
        z = tonumber(entry.coords_z) or tonumber(coords.z),
    }
end

local function build_stash_id(storage_id)
    local storage_config = get_storage_config()
    local prefix = storage_config.StashPrefix or 'sonar_farm_silo_'
    return prefix .. storage_id
end

local function validate_seed_entry(entry)
    if type(entry) ~= 'table' then
        return false, 'entry must be a table'
    end

    if not is_non_empty_string(entry.storage_id) then
        return false, 'storage_id must be a non-empty string'
    end

    if not is_non_empty_string(entry.display_name_key) then
        return false, 'display_name_key must be a non-empty string'
    end

    local storage_config = get_storage_config()
    if not storage_config.AllowedTypes[entry.storage_type] then
        return false, ('storage_type is invalid: %s'):format(tostring(entry.storage_type))
    end

    local coords = normalize_coords(entry)
    if not is_number(coords.x) then
        return false, 'coords.x must be a number'
    end

    if not is_number(coords.y) then
        return false, 'coords.y must be a number'
    end

    if not is_number(coords.z) then
        return false, 'coords.z must be a number'
    end

    if not is_positive_number(tonumber(entry.radius) or storage_config.DefaultRadius) then
        return false, 'radius must be a positive number'
    end

    if not is_positive_integer(tonumber(entry.max_slots)) then
        return false, 'max_slots must be a positive integer'
    end

    if not is_positive_number(tonumber(entry.max_weight_kg)) then
        return false, 'max_weight_kg must be a positive number'
    end

    if not is_positive_number(tonumber(entry.decay_multiplier) or storage_config.DefaultDecayMultiplier or 1.0) then
        return false, 'decay_multiplier must be a positive number'
    end

    return true
end

local function normalize_seed_entry(entry)
    local coords = normalize_coords(entry)
    local storage_config = get_storage_config()

    return {
        storage_id = entry.storage_id,
        storage_type = entry.storage_type,
        display_name_key = entry.display_name_key,
        coords_x = coords.x,
        coords_y = coords.y,
        coords_z = coords.z,
        radius = tonumber(entry.radius) or storage_config.DefaultRadius or 2.0,
        max_slots = math.floor(tonumber(entry.max_slots) or 0),
        max_weight_kg = tonumber(entry.max_weight_kg),
        decay_multiplier = tonumber(entry.decay_multiplier) or storage_config.DefaultDecayMultiplier or 1.0,
    }
end

local function fetch_unit_row(storage_id)
    return get_db().row([[
        SELECT
            `storage_id`,
            `storage_type`,
            `display_name_key`,
            `coords_x`,
            `coords_y`,
            `coords_z`,
            `radius`,
            `max_slots`,
            `max_weight_kg`,
            `decay_multiplier`
        FROM `sonar_farm_storage_units`
        WHERE `storage_id` = ?
        LIMIT 1
    ]], { storage_id })
end

local function insert_unit(entry)
    get_db().execute([[
        INSERT INTO `sonar_farm_storage_units` (
            `storage_id`,
            `storage_type`,
            `display_name_key`,
            `coords_x`,
            `coords_y`,
            `coords_z`,
            `radius`,
            `max_slots`,
            `max_weight_kg`,
            `decay_multiplier`
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        entry.storage_id,
        entry.storage_type,
        entry.display_name_key,
        entry.coords_x,
        entry.coords_y,
        entry.coords_z,
        entry.radius,
        entry.max_slots,
        entry.max_weight_kg,
        entry.decay_multiplier,
    })
end

local function update_unit(entry)
    get_db().execute([[
        UPDATE `sonar_farm_storage_units`
        SET
            `storage_type` = ?,
            `display_name_key` = ?,
            `coords_x` = ?,
            `coords_y` = ?,
            `coords_z` = ?,
            `radius` = ?,
            `max_slots` = ?,
            `max_weight_kg` = ?,
            `decay_multiplier` = ?
        WHERE `storage_id` = ?
    ]], {
        entry.storage_type,
        entry.display_name_key,
        entry.coords_x,
        entry.coords_y,
        entry.coords_z,
        entry.radius,
        entry.max_slots,
        entry.max_weight_kg,
        entry.decay_multiplier,
        entry.storage_id,
    })
end

local function numeric_changed(current_value, next_value)
    return math.abs((tonumber(current_value) or 0) - (tonumber(next_value) or 0)) > 0.0001
end

local function diff_config_owned(existing, entry)
    local changed = {}

    if tostring(existing.storage_type) ~= tostring(entry.storage_type) then
        changed[#changed + 1] = 'storage_type'
    end

    if tostring(existing.display_name_key) ~= tostring(entry.display_name_key) then
        changed[#changed + 1] = 'display_name_key'
    end

    if numeric_changed(existing.coords_x, entry.coords_x) then
        changed[#changed + 1] = 'coords_x'
    end

    if numeric_changed(existing.coords_y, entry.coords_y) then
        changed[#changed + 1] = 'coords_y'
    end

    if numeric_changed(existing.coords_z, entry.coords_z) then
        changed[#changed + 1] = 'coords_z'
    end

    if numeric_changed(existing.radius, entry.radius) then
        changed[#changed + 1] = 'radius'
    end

    if tonumber(existing.max_slots) ~= tonumber(entry.max_slots) then
        changed[#changed + 1] = 'max_slots'
    end

    if numeric_changed(existing.max_weight_kg, entry.max_weight_kg) then
        changed[#changed + 1] = 'max_weight_kg'
    end

    if numeric_changed(existing.decay_multiplier, entry.decay_multiplier) then
        changed[#changed + 1] = 'decay_multiplier'
    end

    return changed
end

local function register_stash(unit)
    local ox_inventory = get_ox_inventory()
    if not ox_inventory then
        return false, 'ox_inventory export is unavailable'
    end

    local stash_id = build_stash_id(unit.storage_id)
    local label = locale(unit.display_name_key)
    if type(label) ~= 'string' or label == unit.display_name_key then
        label = unit.display_name_key
    end

    local ok, err = pcall(function()
        ox_inventory:RegisterStash(
            stash_id,
            label,
            tonumber(unit.max_slots) or 0,
            math.floor((tonumber(unit.max_weight_kg) or 0) * 1000),
            false,
            nil,
            vector3(tonumber(unit.coords_x) or 0.0, tonumber(unit.coords_y) or 0.0, tonumber(unit.coords_z) or 0.0)
        )
    end)

    if not ok then
        return false, tostring(err)
    end

    return true
end

local function ensure_batch_record(batch_id)
    return get_db().row([[
        SELECT
            `batch_id`,
            `player_cid`,
            `crop_type`,
            `quality`,
            `quality_score`,
            `weight_g`,
            `freshness`,
            `lineage_chain`,
            `sold_ts`
        FROM `sonar_farm_batches`
        WHERE `batch_id` = ?
        LIMIT 1
    ]], { batch_id })
end

local function get_inventory_slots(inv, item_name, metadata)
    local ox_inventory = get_ox_inventory()
    if not ox_inventory then
        return nil, 'ox_inventory export is unavailable'
    end

    local ok, result = pcall(function()
        return ox_inventory:Search(inv, 'slots', item_name, metadata)
    end)

    if not ok then
        return nil, tostring(result)
    end

    if type(result) ~= 'table' then
        return {}
    end

    return result
end

local function resolve_slot_with_batch(inv, item_name, batch_id)
    local slots, err = get_inventory_slots(inv, item_name, { batch_id = batch_id })
    if not slots then
        return nil, nil, err
    end

    for index = 1, #slots do
        local slot = slots[index]
        if type(slot) == 'table' and type(slot.metadata) == 'table' and slot.metadata.batch_id == batch_id then
            return slot, slot.metadata, nil
        end
    end

    return nil, nil, nil
end

local function count_contents(storage_id)
    local count = get_db().scalar([[SELECT COUNT(*) FROM `sonar_farm_storage_contents` WHERE `storage_id` = ?]], { storage_id })

    return tonumber(count) or 0
end

local function fetch_content_by_batch(batch_id)
    return get_db().row([[
        SELECT `id`, `storage_id`, `batch_id`, `player_cid`, `item_name`, `deposited_ts`
        FROM `sonar_farm_storage_contents`
        WHERE `batch_id` = ?
        LIMIT 1
    ]], { batch_id })
end

local function fetch_unit(storage_id)
    return get_db().row([[
        SELECT
            `storage_id`,
            `storage_type`,
            `display_name_key`,
            `coords_x`,
            `coords_y`,
            `coords_z`,
            `radius`,
            `max_slots`,
            `max_weight_kg`,
            `decay_multiplier`
        FROM `sonar_farm_storage_units`
        WHERE `storage_id` = ?
        LIMIT 1
    ]], { storage_id })
end

local function build_deposit_payload(storage_id, batch_id, player_cid, item_name, deposited_ts)
    return {
        storage_id = storage_id,
        batch_id = batch_id,
        player_cid = player_cid,
        item_name = item_name,
        deposited_ts = deposited_ts,
    }
end

local function build_withdraw_payload(storage_id, batch_id, player_cid, withdrawn_ts)
    return {
        storage_id = storage_id,
        batch_id = batch_id,
        player_cid = player_cid,
        withdrawn_ts = withdrawn_ts,
    }
end

local function validate_physical_metadata(metadata)
    if not Sonar.Farm.PhysicalItem or type(Sonar.Farm.PhysicalItem.ValidateMetadata) ~= 'function' then
        return false, 'physical_item_unavailable'
    end

    return Sonar.Farm.PhysicalItem.ValidateMetadata(metadata)
end

function StorageService.SyncSeededStorage()
    local storage_config = get_storage_config()
    local seed = storage_config.units or {}
    local result = {
        created = 0,
        updated = 0,
        unchanged = 0,
        skipped = 0,
        total = #seed,
    }

    for index = 1, #seed do
        local entry = seed[index]
        local valid, err = validate_seed_entry(entry)

        if not valid then
            result.skipped = result.skipped + 1
            log_error(('skipping invalid storage seed entry [%d]: %s'):format(index, tostring(err)))
        else
            local normalized = normalize_seed_entry(entry)
            local existing = fetch_unit_row(normalized.storage_id)

            if not existing then
                insert_unit(normalized)
                result.created = result.created + 1
                TriggerEvent('sonar:farm:storage:state_changed', {
                    storage_id = normalized.storage_id,
                    previous_state = nil,
                    next_state = 'ready',
                    changed_fields = { 'created' },
                    reason = CREATE_REASON,
                })
            else
                local changed = diff_config_owned(existing, normalized)
                if #changed == 0 then
                    result.unchanged = result.unchanged + 1
                else
                    update_unit(normalized)
                    result.updated = result.updated + 1
                    TriggerEvent('sonar:farm:storage:state_changed', {
                        storage_id = normalized.storage_id,
                        previous_state = 'ready',
                        next_state = 'ready',
                        changed_fields = changed,
                        reason = UPDATE_CONFIG_REASON,
                    })
                end
            end
        end
    end

    local units = get_db().rows([[
        SELECT
            `storage_id`,
            `storage_type`,
            `display_name_key`,
            `coords_x`,
            `coords_y`,
            `coords_z`,
            `radius`,
            `max_slots`,
            `max_weight_kg`,
            `decay_multiplier`
        FROM `sonar_farm_storage_units`
        ORDER BY `storage_id` ASC
    ]], {}) or {}

    for index = 1, #units do
        local ok, err = register_stash(units[index])
        if not ok then
            log_error(('stash registration failed for %s: %s'):format(tostring(units[index].storage_id), tostring(err)))
        end
    end

    return result
end

function StorageService.ReloadSeededStorage(_src)
    return StorageService.SyncSeededStorage()
end

function StorageService.Boot()
    local ok, result = pcall(StorageService.SyncSeededStorage)
    if not ok then
        log_error(('storage boot failed: %s'):format(tostring(result)))
        return false
    end

    log_info(('Storage boot ready: %d units seeded (%d created, %d updated, %d unchanged, %d skipped)'):format(
        result.total,
        result.created,
        result.updated,
        result.unchanged,
        result.skipped
    ))

    return result.skipped == 0
end

function StorageService.GetUnit(storage_id)
    if not is_non_empty_string(storage_id) then
        return nil, 'invalid_storage_id'
    end

    local unit = fetch_unit(storage_id)
    if not unit then
        return nil, 'storage_not_found'
    end

    unit.stash_id = build_stash_id(unit.storage_id)
    return unit, nil
end

function StorageService.ListContents(storage_id)
    if not is_non_empty_string(storage_id) then
        return nil, 'invalid_storage_id'
    end

    local unit = fetch_unit(storage_id)
    if not unit then
        return nil, 'storage_not_found'
    end

    local rows = get_db().rows([[
        SELECT
            `storage_id`,
            `batch_id`,
            `player_cid`,
            `item_name`,
            `deposited_ts`
        FROM `sonar_farm_storage_contents`
        WHERE `storage_id` = ?
        ORDER BY `deposited_ts` ASC, `id` ASC
    ]], { storage_id }) or {}

    return rows, nil
end

function StorageService.Deposit(src, storage_id, batch_id)
    if not is_positive_integer(src) then
        return false, 'invalid_source'
    end

    if not is_non_empty_string(storage_id) then
        return false, 'invalid_storage_id'
    end

    if not is_non_empty_string(batch_id) or not batch_id:match(VALID_BATCH_ID_PATTERN) then
        return false, 'invalid_batch_id'
    end

    local player = Sonar.Farm.Bridge and Sonar.Farm.Bridge.GetPlayer and Sonar.Farm.Bridge.GetPlayer(src) or nil
    if not player or not is_non_empty_string(player.citizen_id) then
        return false, 'player_unavailable'
    end

    local unit = fetch_unit(storage_id)
    if not unit then
        return false, 'storage_not_found'
    end

    if count_contents(storage_id) >= (tonumber(unit.max_slots) or 0) then
        return false, 'storage_capacity_exceeded'
    end

    if fetch_content_by_batch(batch_id) then
        return false, 'batch_already_stored'
    end

    local batch = ensure_batch_record(batch_id)
    if not batch then
        return false, 'batch_not_found'
    end

    if batch.sold_ts ~= nil then
        return false, 'batch_already_sold'
    end

    local item_name = 'sonar_batch_' .. tostring(batch.crop_type or 'wheat')
    local slot, metadata, slot_err = resolve_slot_with_batch(src, item_name, batch_id)
    if slot_err then
        return false, 'inventory_lookup_failed'
    end

    if not slot or type(metadata) ~= 'table' then
        return false, 'batch_not_in_inventory'
    end

    local metadata_ok, metadata_err = validate_physical_metadata(metadata)
    if metadata_ok ~= true then
        return false, metadata_err or 'invalid_batch_metadata'
    end

    item_name = tostring(slot.name or item_name)
    local ox_inventory = get_ox_inventory()
    if not ox_inventory then
        return false, 'inventory_unavailable'
    end

    local stash_id = build_stash_id(storage_id)
    if not ox_inventory:GetInventory(stash_id, false) then
        local registered, registered_err = register_stash(unit)
        if not registered then
            return false, registered_err or 'stash_registration_failed'
        end
    end

    local remove_ok, remove_result = pcall(function()
        return ox_inventory:RemoveItem(src, item_name, 1, { batch_id = batch_id }, slot.slot, false, false)
    end)
    if not remove_ok or remove_result == false then
        return false, 'inventory_remove_failed'
    end

    local add_ok, add_result = pcall(function()
        return ox_inventory:AddItem(stash_id, item_name, 1, metadata)
    end)
    if not add_ok or add_result == false then
        pcall(function()
            ox_inventory:AddItem(src, item_name, 1, metadata, slot.slot)
        end)
        return false, 'storage_add_failed'
    end

    local deposited_ts = os.time()
    local transaction_ok, transaction_err = pcall(function()
        get_db().transaction({
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
                    player.citizen_id,
                    item_name,
                    deposited_ts,
                },
            },
        })
    end)

    if not transaction_ok then
        pcall(function()
            ox_inventory:RemoveItem(stash_id, item_name, 1, { batch_id = batch_id }, nil, false, false)
        end)
        pcall(function()
            ox_inventory:AddItem(src, item_name, 1, metadata, slot.slot)
        end)
        return false, tostring(transaction_err)
    end

    local payload = build_deposit_payload(storage_id, batch_id, player.citizen_id, item_name, deposited_ts)
    TriggerEvent('sonar:farm:storage:deposited', payload)

    return true, payload
end

function StorageService.Withdraw(src, storage_id, batch_id)
    if not is_positive_integer(src) then
        return false, 'invalid_source'
    end

    if not is_non_empty_string(storage_id) then
        return false, 'invalid_storage_id'
    end

    if not is_non_empty_string(batch_id) or not batch_id:match(VALID_BATCH_ID_PATTERN) then
        return false, 'invalid_batch_id'
    end

    local player = Sonar.Farm.Bridge and Sonar.Farm.Bridge.GetPlayer and Sonar.Farm.Bridge.GetPlayer(src) or nil
    if not player or not is_non_empty_string(player.citizen_id) then
        return false, 'player_unavailable'
    end

    local unit = fetch_unit(storage_id)
    if not unit then
        return false, 'storage_not_found'
    end

    local row = fetch_content_by_batch(batch_id)
    if not row or row.storage_id ~= storage_id then
        return false, 'batch_not_stored'
    end

    local ox_inventory = get_ox_inventory()
    if not ox_inventory then
        return false, 'inventory_unavailable'
    end

    local stash_id = build_stash_id(storage_id)
    local slot, metadata, slot_err = resolve_slot_with_batch(stash_id, row.item_name, batch_id)
    if slot_err then
        return false, 'inventory_lookup_failed'
    end

    if not slot or type(metadata) ~= 'table' then
        return false, 'batch_not_in_storage'
    end

    local add_ok, add_result = pcall(function()
        return ox_inventory:AddItem(src, row.item_name, 1, metadata)
    end)
    if not add_ok or add_result == false then
        return false, 'player_inventory_full'
    end

    local remove_ok, remove_result = pcall(function()
        return ox_inventory:RemoveItem(stash_id, row.item_name, 1, { batch_id = batch_id }, slot.slot, false, false)
    end)
    if not remove_ok or remove_result == false then
        pcall(function()
            ox_inventory:RemoveItem(src, row.item_name, 1, { batch_id = batch_id }, nil, false, false)
        end)
        return false, 'storage_remove_failed'
    end

    local transaction_ok, transaction_err = pcall(function()
        get_db().transaction({
            {
                query = 'DELETE FROM `sonar_farm_storage_contents` WHERE `batch_id` = ? LIMIT 1',
                values = { batch_id },
            },
        })
    end)

    if not transaction_ok then
        pcall(function()
            ox_inventory:AddItem(stash_id, row.item_name, 1, metadata, slot.slot)
        end)
        pcall(function()
            ox_inventory:RemoveItem(src, row.item_name, 1, { batch_id = batch_id }, nil, false, false)
        end)
        return false, tostring(transaction_err)
    end

    local payload = build_withdraw_payload(storage_id, batch_id, player.citizen_id, os.time())
    TriggerEvent('sonar:farm:storage:withdrawn', payload)

    return true, payload
end

Sonar.Farm.StorageService = StorageService
