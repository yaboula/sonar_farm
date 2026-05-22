Config = {
    Farm = {
        Storage = {
            AllowedTypes = {
                dry = true,
                cold = true,
            },
            DefaultRadius = 2.0,
            DefaultDecayMultiplier = 1.0,
            StashPrefix = 'sonar_farm_silo_',
            units = {
                {
                    storage_id = 'silo_grapeseed_01',
                    display_name_key = 'storage.silo_grapeseed_01.name',
                    storage_type = 'dry',
                    coords = { x = 1680.0, y = 4820.0, z = 42.0 },
                    radius = 3.0,
                    max_slots = 2,
                    max_weight_kg = 5000,
                    decay_multiplier = 1.0,
                },
            },
        },
    },
}

Sonar = {
    Farm = {
        Bridge = {
            GetPlayer = function(src)
                if src == 1 then
                    return {
                        citizen_id = 'CID-001',
                    }
                end

                return nil
            end,
        },
        PhysicalItem = {
            ValidateMetadata = function(metadata)
                if type(metadata) ~= 'table' or metadata.batch_id == nil then
                    return false, 'invalid metadata'
                end

                return true
            end,
        },
    },
}

local db_state = {
    units = {},
    contents = {},
    batches = {
        ['sf-a1b2c3d4'] = {
            batch_id = 'sf-a1b2c3d4',
            player_cid = 'CID-001',
            crop_type = 'wheat',
            quality = 'B',
            quality_score = 75,
            weight_g = 2500,
            freshness = 100,
            lineage_chain = '[]',
            sold_ts = nil,
        },
        ['sf-deadbeef'] = {
            batch_id = 'sf-deadbeef',
            player_cid = 'CID-001',
            crop_type = 'wheat',
            quality = 'A',
            quality_score = 85,
            weight_g = 2500,
            freshness = 100,
            lineage_chain = '[]',
            sold_ts = nil,
        },
        ['sf-cafebabe'] = {
            batch_id = 'sf-cafebabe',
            player_cid = 'CID-001',
            crop_type = 'wheat',
            quality = 'S',
            quality_score = 95,
            weight_g = 2500,
            freshness = 100,
            lineage_chain = '[]',
            sold_ts = nil,
        },
    },
}

local stash_registry = {}
local player_inventory = {
    [1] = {
        {
            slot = 1,
            name = 'sonar_batch_wheat',
            metadata = {
                batch_id = 'sf-a1b2c3d4',
                crop_type = 'wheat',
                weight_g = 2500,
                quality = 'B',
                quality_score = 75,
                freshness = 100,
                origin = {
                    plot_id = 'plot_01',
                    player_cid = 'CID-001',
                    harvested_ts = 1000,
                },
                lineage_chain = {},
                created_at = 1000,
            },
        },
        {
            slot = 2,
            name = 'sonar_batch_wheat',
            metadata = {
                batch_id = 'sf-deadbeef',
                crop_type = 'wheat',
                weight_g = 2500,
                quality = 'A',
                quality_score = 85,
                freshness = 100,
                origin = {
                    plot_id = 'plot_02',
                    player_cid = 'CID-001',
                    harvested_ts = 1000,
                },
                lineage_chain = {},
                created_at = 1000,
            },
        },
        {
            slot = 3,
            name = 'sonar_batch_wheat',
            metadata = {
                batch_id = 'sf-cafebabe',
                crop_type = 'wheat',
                weight_g = 2500,
                quality = 'S',
                quality_score = 95,
                freshness = 100,
                origin = {
                    plot_id = 'plot_03',
                    player_cid = 'CID-001',
                    harvested_ts = 1000,
                },
                lineage_chain = {},
                created_at = 1000,
            },
        },
    },
}
local stash_inventory = {}
local triggered_events = {}

local function clone(value)
    if type(value) ~= 'table' then
        return value
    end

    local copy = {}
    for key, nested in pairs(value) do
        copy[key] = clone(nested)
    end
    return copy
end

local function get_inventory(inv)
    if type(inv) == 'number' then
        player_inventory[inv] = player_inventory[inv] or {}
        return player_inventory[inv]
    end

    stash_inventory[inv] = stash_inventory[inv] or {}
    return stash_inventory[inv]
end

local function find_slot(inventory, item_name, metadata, wanted_slot)
    for index = 1, #inventory do
        local slot = inventory[index]
        if slot.name == item_name and (wanted_slot == nil or slot.slot == wanted_slot) then
            local matches = true
            if type(metadata) == 'table' then
                for key, value in pairs(metadata) do
                    if type(slot.metadata) ~= 'table' or slot.metadata[key] ~= value then
                        matches = false
                        break
                    end
                end
            end

            if matches then
                return index, slot
            end
        end
    end

    return nil, nil
end

exports = {
    ox_inventory = {
        RegisterStash = function(_, id, label, slots, max_weight)
            stash_registry[id] = {
                label = label,
                slots = slots,
                max_weight = max_weight,
            }
        end,
        GetInventory = function(_, inv)
            if type(inv) == 'string' and stash_registry[inv] then
                return { id = inv }
            end

            if type(inv) == 'number' then
                return { id = inv }
            end

            return nil
        end,
        Search = function(_, inv, search, item_name, metadata)
            local inventory = get_inventory(inv)
            local found = {}

            for index = 1, #inventory do
                local slot = inventory[index]
                if slot.name == item_name then
                    local matches = true
                    if type(metadata) == 'table' then
                        for key, value in pairs(metadata) do
                            if slot.metadata[key] ~= value then
                                matches = false
                                break
                            end
                        end
                    end

                    if matches then
                        found[#found + 1] = clone(slot)
                    end
                end
            end

            if search == 'count' then
                return #found
            end

            return found
        end,
        RemoveItem = function(_, inv, item_name, count, metadata, slot)
            local inventory = get_inventory(inv)
            for _ = 1, count do
                local index = select(1, find_slot(inventory, item_name, metadata, slot))
                if not index then
                    return false
                end
                table.remove(inventory, index)
            end

            return true
        end,
        AddItem = function(_, inv, item_name, count, metadata, slot)
            local inventory = get_inventory(inv)
            for _ = 1, count do
                inventory[#inventory + 1] = {
                    slot = slot or (#inventory + 1),
                    name = item_name,
                    metadata = clone(metadata),
                }
            end

            return true, { slot = slot or #inventory }
        end,
    },
}

function locale(key)
    return key
end

function vector3(x, y, z)
    return { x = x, y = y, z = z }
end

function TriggerEvent(event_name, payload)
    triggered_events[#triggered_events + 1] = {
        event_name = event_name,
        payload = payload,
    }
end

Sonar.Farm.DB = {
    row = function(query, params)
        if query:find('FROM `sonar_farm_storage_units`', 1, true) then
            return clone(db_state.units[params[1]])
        end

        if query:find('FROM `sonar_farm_storage_contents`', 1, true) then
            local batch_id = params[1]
            for _, row in pairs(db_state.contents) do
                if row.batch_id == batch_id then
                    return clone(row)
                end
            end
            return nil
        end

        if query:find('FROM `sonar_farm_batches`', 1, true) then
            return clone(db_state.batches[params[1]])
        end

        return nil
    end,
    rows = function(query, params)
        if query:find('FROM `sonar_farm_storage_units`', 1, true) then
            local rows = {}
            for _, row in pairs(db_state.units) do
                rows[#rows + 1] = clone(row)
            end
            table.sort(rows, function(left, right)
                return left.storage_id < right.storage_id
            end)
            return rows
        end

        if query:find('FROM `sonar_farm_storage_contents`', 1, true) then
            local rows = {}
            for _, row in pairs(db_state.contents) do
                if row.storage_id == params[1] then
                    rows[#rows + 1] = clone(row)
                end
            end
            table.sort(rows, function(left, right)
                return left.batch_id < right.batch_id
            end)
            return rows
        end

        return {}
    end,
    scalar = function(query, params)
        if query:find('COUNT%(%*%) FROM `sonar_farm_storage_contents`') then
            local count = 0
            for _, row in pairs(db_state.contents) do
                if row.storage_id == params[1] then
                    count = count + 1
                end
            end
            return count
        end

        return nil
    end,
    execute = function(query, params)
        if query:find('INSERT INTO `sonar_farm_storage_units`', 1, true) then
            db_state.units[params[1]] = {
                storage_id = params[1],
                storage_type = params[2],
                display_name_key = params[3],
                coords_x = params[4],
                coords_y = params[5],
                coords_z = params[6],
                radius = params[7],
                max_slots = params[8],
                max_weight_kg = params[9],
                decay_multiplier = params[10],
            }
            return true
        end

        if query:find('UPDATE `sonar_farm_storage_units`', 1, true) then
            db_state.units[params[10]] = {
                storage_id = params[10],
                storage_type = params[1],
                display_name_key = params[2],
                coords_x = params[3],
                coords_y = params[4],
                coords_z = params[5],
                radius = params[6],
                max_slots = params[7],
                max_weight_kg = params[8],
                decay_multiplier = params[9],
            }
            return true
        end

        return true
    end,
    transaction = function(queries)
        for index = 1, #queries do
            local query = queries[index].query
            local values = queries[index].values

            if query:find('INSERT INTO `sonar_farm_storage_contents`', 1, true) then
                db_state.contents[values[2]] = {
                    id = 1,
                    storage_id = values[1],
                    batch_id = values[2],
                    player_cid = values[3],
                    item_name = values[4],
                    deposited_ts = values[5],
                }
            elseif query:find('DELETE FROM `sonar_farm_storage_contents`', 1, true) then
                db_state.contents[values[1]] = nil
            end
        end

        return true
    end,
}

dofile('sonar_farm_core/server/storage/storage_service.lua')

local StorageService = Sonar.Farm.StorageService

local boot_result = StorageService.SyncSeededStorage()
assert(boot_result.created == 1, 'expected one created storage unit on first boot')
assert(stash_registry.sonar_farm_silo_silo_grapeseed_01 ~= nil, 'expected stash registration on boot')

local second_boot = StorageService.SyncSeededStorage()
assert(second_boot.unchanged == 1, 'expected idempotent second boot')

local deposit_ok, deposit_payload = StorageService.Deposit(1, 'silo_grapeseed_01', 'sf-a1b2c3d4')
assert(deposit_ok == true, 'expected deposit to succeed')
assert(type(deposit_payload) == 'table', 'expected deposit payload')
assert(db_state.contents['sf-a1b2c3d4'] ~= nil, 'expected storage contents row after deposit')
assert(#player_inventory[1] == 2, 'expected player inventory item removed after deposit')
assert(#stash_inventory['sonar_farm_silo_silo_grapeseed_01'] == 1, 'expected stash to contain deposited item')

local withdraw_ok, withdraw_payload = StorageService.Withdraw(1, 'silo_grapeseed_01', 'sf-a1b2c3d4')
assert(withdraw_ok == true, 'expected withdraw to succeed')
assert(type(withdraw_payload) == 'table', 'expected withdraw payload')
assert(db_state.contents['sf-a1b2c3d4'] == nil, 'expected storage contents row removed after withdraw')
assert(#player_inventory[1] == 3, 'expected player inventory item restored after withdraw')
assert(#stash_inventory['sonar_farm_silo_silo_grapeseed_01'] == 0, 'expected stash item removed after withdraw')

local deposit_ok_1 = StorageService.Deposit(1, 'silo_grapeseed_01', 'sf-a1b2c3d4')
local deposit_ok_2 = StorageService.Deposit(1, 'silo_grapeseed_01', 'sf-deadbeef')
assert(deposit_ok_1 == true and deposit_ok_2 == true, 'expected first two deposits to succeed')
local deposit_ok_3, deposit_err_3 = StorageService.Deposit(1, 'silo_grapeseed_01', 'sf-cafebabe')
assert(deposit_ok_3 == false, 'expected deposit to fail when storage capacity is exceeded')
assert(deposit_err_3 == 'storage_capacity_exceeded', 'expected storage_capacity_exceeded error')

local missing_withdraw_ok, missing_withdraw_err = StorageService.Withdraw(1, 'silo_grapeseed_01', 'sf-ffffffff')
assert(missing_withdraw_ok == false, 'expected missing batch withdraw to fail')
assert(missing_withdraw_err == 'batch_not_stored', 'expected batch_not_stored on missing withdraw')

assert(#triggered_events >= 4, 'expected storage events to be emitted')
print('storage_spec.lua: OK (deposit, withdraw, capacity, idempotent boot)')
