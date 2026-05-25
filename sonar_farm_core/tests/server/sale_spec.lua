Config = {
    Farm = {
        Climate = {
            DefaultSeason = 'spring',
            Seasons = {
                spring = {
                    duration_seconds = 86400,
                },
            },
        },
        NPCs = {
            ValidQualityGrades = {
                S = true,
                A = true,
                B = true,
                C = true,
                D = true,
            },
            QualityRank = {
                S = 5,
                A = 4,
                B = 3,
                C = 2,
                D = 1,
            },
            DefaultQualityMultipliers = {
                S = 2.0,
                A = 1.6,
                B = 1.0,
                C = 0.6,
                D = 0.3,
            },
            DefaultFreshnessMultiplier = 1.0,
            DefaultDailyQuotaKg = 99999,
            DefaultPayoutAccount = 'bank',
            CatalogDistanceFallbackM = 99999.0,
            LegacyBuyerAliases = {
                pedro = 'byr_molino_pedro',
            },
            buyers = {
                byr_molino_pedro = {
                    id = 'byr_molino_pedro',
                    display_name_key = 'npcs.buyers.byr_molino_pedro.name',
                    kind = 'mill',
                    district_key = 'npcs.districts.grapeseed_industrial',
                    ped_model = 's_m_m_farmer_01',
                    coords = { x = 1695.0, y = 4825.0, z = 42.0, w = 215.0 },
                    heading = 215.0,
                    interaction_radius = 5.0,
                    accepted_crops = {
                        'wheat',
                        wheat = {
                            min_quality = 'D',
                            base_price_eur_per_g = 0.0008,
                            daily_capacity_g = 3000,
                        },
                    },
                    quality_multipliers = {
                        S = 2.0,
                        A = 1.6,
                        B = 1.0,
                        C = 0.6,
                        D = 0.3,
                    },
                    freshness_multiplier = 1.0,
                    contracts_enabled = true,
                    personality_modifier = 1.0,
                    payout_account = 'bank',
                },
                byr_hotel_aurora = {
                    id = 'byr_hotel_aurora',
                    display_name_key = 'npcs.buyers.byr_hotel_aurora.name',
                    kind = 'hospitality',
                    district_key = 'npcs.districts.vinewood_hospitality',
                    ped_model = 'a_m_y_business_03',
                    coords = { x = -1283.27, y = -1158.91, z = 5.31, w = 116.83 },
                    heading = 116.83,
                    interaction_radius = 5.0,
                    accepted_crops = {
                        tomato = {
                            min_quality = 'A',
                            base_price_eur_per_g = 0.00162,
                            daily_capacity_g = 90000,
                        },
                    },
                    quality_multipliers = {
                        S = 2.0,
                        A = 1.6,
                        B = 1.0,
                        C = 0.6,
                        D = 0.3,
                    },
                    freshness_multiplier = 1.0,
                    contracts_enabled = true,
                    personality_modifier = 1.1,
                    payout_account = 'bank',
                },
            },
        },
    },
}

json = {
    encode = function(value)
        if type(value) ~= 'table' then
            return '{}'
        end

        local keys = {}
        for key in pairs(value) do
            keys[#keys + 1] = key
        end
        table.sort(keys)

        local parts = {}
        for index = 1, #keys do
            local key = keys[index]
            parts[#parts + 1] = ('"%s":%d'):format(key, tonumber(value[key]) or 0)
        end

        return '{' .. table.concat(parts, ',') .. '}'
    end,
    decode = function(raw)
        if type(raw) ~= 'string' or raw == '' or raw == '{}' then
            return {}
        end

        local decoded = {}
        for key, amount in raw:gmatch('"(.-)":(%d+)') do
            decoded[key] = tonumber(amount) or 0
        end

        return decoded
    end,
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
        ClimateService = {
            GetState = function()
                return {
                    current_season = 'spring',
                    season_started_at = 2000,
                }
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
        Finance = {},
    },
}

function GetPlayerPed(source)
    if source == 1 then
        return 101
    end

    return 0
end

function GetEntityCoords(entity)
    if entity == 101 then
        return {
            x = 1685.0,
            y = 4840.0,
            z = 42.0,
        }
    end

    return nil
end

local credit_calls = {}
local triggered_events = {}
local buyer_state_rows = {}
local inventory = {
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
                lineage_chain = { 'sf-origin-01' },
                created_at = 1000,
            },
        },
        {
            slot = 2,
            name = 'sonar_batch_wheat',
            metadata = {
                batch_id = 'sf-deadbeef',
                crop_type = 'wheat',
                weight_g = 1000,
                quality = 'D',
                quality_score = 35,
                freshness = 100,
                origin = {
                    plot_id = 'plot_02',
                    player_cid = 'CID-001',
                    harvested_ts = 1000,
                },
                lineage_chain = { 'sf-origin-02' },
                created_at = 1000,
            },
        },
    },
}

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

exports = {
    ox_inventory = {
        Search = function(_, inv, search, item_name, metadata)
            local found = {}
            local slots = inventory[inv] or {}
            for index = 1, #slots do
                local slot = slots[index]
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
        RemoveItem = function(_, inv, item_name, count, metadata, slot_id)
            local slots = inventory[inv] or {}
            for _ = 1, count do
                local removed = false
                for index = 1, #slots do
                    local slot = slots[index]
                    if slot.name == item_name and (slot_id == nil or slot.slot == slot_id) then
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
                            table.remove(slots, index)
                            removed = true
                            break
                        end
                    end
                end

                if not removed then
                    return false
                end
            end

            inventory[inv] = slots
            return true
        end,
        AddItem = function(_, inv, item_name, count, metadata, slot_id)
            inventory[inv] = inventory[inv] or {}
            for _ = 1, count do
                inventory[inv][#inventory[inv] + 1] = {
                    slot = slot_id or (#inventory[inv] + 1),
                    name = item_name,
                    metadata = clone(metadata),
                }
            end
            return true
        end,
    },
}

function TriggerEvent(event_name, payload)
    triggered_events[#triggered_events + 1] = {
        event_name = event_name,
        payload = payload,
    }
end

Sonar.Farm.Finance.Credit = function(src, account, amount, reason, idempotency_key, metadata)
    credit_calls[#credit_calls + 1] = {
        src = src,
        account = account,
        amount = amount,
        reason = reason,
        idempotency_key = idempotency_key,
        metadata = clone(metadata),
    }

    return true, {
        ok = true,
        movement_id = 'sfm_test',
        status = 'completed',
    }
end

local batches = {
    ['sf-a1b2c3d4'] = {
        batch_id = 'sf-a1b2c3d4',
        plot_id = 'plot_01',
        crop_id = 1,
        player_cid = 'CID-001',
        crop_type = 'wheat',
        quality = 'B',
        quality_score = 75,
        weight_g = 2500,
        freshness = 100,
        lineage_chain = '["sf-origin-01"]',
        harvested_ts = 1000,
        sold_ts = nil,
    },
    ['sf-deadbeef'] = {
        batch_id = 'sf-deadbeef',
        plot_id = 'plot_02',
        crop_id = 2,
        player_cid = 'CID-001',
        crop_type = 'wheat',
        quality = 'D',
        quality_score = 35,
        weight_g = 1000,
        freshness = 100,
        lineage_chain = '["sf-origin-02"]',
        harvested_ts = 1000,
        sold_ts = nil,
    },
    ['sf-cafebabe'] = {
        batch_id = 'sf-cafebabe',
        plot_id = 'plot_03',
        crop_id = 3,
        player_cid = 'CID-001',
        crop_type = 'wheat',
        quality = 'S',
        quality_score = 95,
        weight_g = 1000,
        freshness = 100,
        lineage_chain = '["sf-origin-03"]',
        harvested_ts = 1000,
        sold_ts = 2000,
    },
    ['sf-feedf00d'] = {
        batch_id = 'sf-feedf00d',
        plot_id = 'plot_04',
        crop_id = 4,
        player_cid = 'CID-001',
        crop_type = 'wheat',
        quality = 'A',
        quality_score = 85,
        weight_g = 1500,
        freshness = 100,
        lineage_chain = '["sf-origin-04"]',
        harvested_ts = 1000,
        sold_ts = nil,
    },
}

local function persist_buyer_state(values)
    buyer_state_rows[values[1]] = {
        buyer_id = values[1],
        volume_remaining_today_g = values[2],
        today_top_price_eur_per_g = values[3],
        previous_volume_remaining_today_g = values[4],
        previous_top_price_eur_per_g = values[5],
        contracts_enabled = values[6],
        previous_contracts_enabled = values[7],
        crop_volume_taken_today_json = values[8],
        last_reset_ts = values[9],
        updated_ts = values[10],
    }
end

Sonar.Farm.DB = {
    row = function(query, params)
        if query:find('FROM `sonar_farm_npc_buyer_state`', 1, true) then
            return clone(buyer_state_rows[params[1]])
        end

        if query:find('FROM `sonar_farm_batches`', 1, true) then
            return clone(batches[params[1]])
        end

        return nil
    end,
    transaction = function(queries)
        for index = 1, #queries do
            local query = queries[index].query
            local values = queries[index].values
            if query:find('UPDATE `sonar_farm_batches`', 1, true) then
                local batch = batches[values[2]]
                if batch then
                    batch.sold_ts = values[1]
                end
            elseif query:find('INSERT INTO `sonar_farm_npc_buyer_state`', 1, true) then
                persist_buyer_state(values)
            end
        end
        return true
    end,
}

dofile('sonar_farm_core/server/npcs/npc_buyer_service.lua')

local NPCBuyerService = Sonar.Farm.NPCBuyerService
NPCBuyerService.__test_now = function()
    return 3000
end

local _, get_buyer_err, resolved_buyer_id = NPCBuyerService.GetBuyer('pedro')
assert(get_buyer_err == nil, ('expected legacy alias lookup to succeed, got %s'):format(tostring(get_buyer_err)))
assert(resolved_buyer_id == 'byr_molino_pedro', ('expected pedro alias to resolve, got %s'):format(tostring(resolved_buyer_id)))

local payout_s, breakdown_s = NPCBuyerService.CalculatePayout('pedro', 'wheat', 'S', 1.0)
assert(payout_s == 1.6, ('expected S payout 1.6, got %s'):format(tostring(payout_s)))
assert(breakdown_s.quality_mult == 2.0, 'expected S quality multiplier')
assert(breakdown_s.resolved_buyer_id == 'byr_molino_pedro', 'expected payout breakdown to expose resolved buyer id')

local payout_a = select(1, NPCBuyerService.CalculatePayout('pedro', 'wheat', 'A', 1.0))
assert(payout_a == 1.28, ('expected A payout 1.28, got %s'):format(tostring(payout_a)))

local payout_d = select(1, NPCBuyerService.CalculatePayout('pedro', 'wheat', 'D', 1.0))
assert(payout_d == 0.24, ('expected D payout 0.24, got %s'):format(tostring(payout_d)))

local payout_c = select(1, NPCBuyerService.CalculatePayout('pedro', 'wheat', 'C', 1.0))
assert(payout_c == 0.48, ('expected C payout 0.48, got %s'):format(tostring(payout_c)))

local payout_b = select(1, NPCBuyerService.CalculatePayout('pedro', 'wheat', 'B', 2.5))
assert(payout_b == 2.0, ('expected B payout 2.0 for 2.5kg, got %s'):format(tostring(payout_b)))

local _, _, hotel_quality_err = NPCBuyerService.CalculatePayout('byr_hotel_aurora', 'tomato', 'B', 1.0)
assert(hotel_quality_err == 'quality_below_threshold', ('expected hotel threshold rejection, got %s'):format(tostring(hotel_quality_err)))

local sale_ok, sale_payout, sale_err = NPCBuyerService.ExecuteSale(1, 'pedro', 'sf-a1b2c3d4')
assert(sale_ok == true, ('expected sale happy path to succeed, got %s'):format(tostring(sale_err)))
assert(sale_payout == 2.0, ('expected happy path payout 2.0, got %s'):format(tostring(sale_payout)))
assert(#credit_calls == 1, 'expected exactly one finance credit call')
assert(credit_calls[1].account == 'bank', 'expected bank payout account')
assert(credit_calls[1].amount == 2.0, 'expected finance credit amount 2.0')
assert(credit_calls[1].reason == 'sale:pedro:sf-a1b2c3d4', 'expected legacy sale reason to remain stable')
assert(credit_calls[1].metadata.resolved_buyer_id == 'byr_molino_pedro', 'expected finance metadata to include resolved buyer id')
assert(batches['sf-a1b2c3d4'].sold_ts ~= nil, 'expected sold_ts stamped after sale')
assert(batches['sf-a1b2c3d4'].lineage_chain == '["sf-origin-01"]', 'expected lineage_chain unchanged after sale')
assert(#inventory[1] == 1, 'expected sold item removed from inventory')
assert(buyer_state_rows['byr_molino_pedro'] ~= nil, 'expected buyer state row persisted')
assert(buyer_state_rows['byr_molino_pedro'].volume_remaining_today_g == 500, ('expected remaining buyer capacity 500g, got %s'):format(tostring(buyer_state_rows['byr_molino_pedro'].volume_remaining_today_g)))
assert(buyer_state_rows['byr_molino_pedro'].crop_volume_taken_today_json == '{"wheat":2500}', ('expected crop volume tracking json, got %s'):format(tostring(buyer_state_rows['byr_molino_pedro'].crop_volume_taken_today_json)))

local volume_ok, _, volume_err = NPCBuyerService.ExecuteSale(1, 'pedro', 'sf-deadbeef')
assert(volume_ok == false, 'expected insufficient buyer capacity to fail')
assert(volume_err == 'volume_exceeded', ('expected volume_exceeded error, got %s'):format(tostring(volume_err)))

local not_owned_ok, _, not_owned_err = NPCBuyerService.ExecuteSale(1, 'pedro', 'sf-feedf00d')
assert(not_owned_ok == false, 'expected batch outside player inventory to fail')
assert(not_owned_err == 'batch_not_in_inventory', 'expected batch_not_in_inventory error')

local missing_ok, _, missing_err = NPCBuyerService.ExecuteSale(1, 'pedro', 'sf-ffffffff')
assert(missing_ok == false, 'expected missing batch sale to fail')
assert(missing_err == 'batch_not_found', 'expected batch_not_found error')

local sold_ok, _, sold_err = NPCBuyerService.ExecuteSale(1, 'pedro', 'sf-cafebabe')
assert(sold_ok == false, 'expected already sold batch to fail')
assert(sold_err == 'batch_already_sold', 'expected batch_already_sold error')

local snapshot = NPCBuyerService.GetCatalogSnapshot(1)
assert(snapshot.day == 1, ('expected market day 1, got %s'):format(tostring(snapshot.day)))
assert(snapshot.season_key == 'spring', ('expected spring season key, got %s'):format(tostring(snapshot.season_key)))
assert(snapshot.server_now_ts == 3000, ('expected snapshot now ts 3000, got %s'):format(tostring(snapshot.server_now_ts)))
assert(#snapshot.buyers == 2, ('expected 2 catalog buyers, got %s'):format(tostring(#snapshot.buyers)))

local pedro_snapshot = nil
local hotel_snapshot = nil
local featured_count = 0
for index = 1, #snapshot.buyers do
    local buyer = snapshot.buyers[index]
    if buyer.featured then
        featured_count = featured_count + 1
    end
    if buyer.id == 'byr_molino_pedro' then
        pedro_snapshot = buyer
    elseif buyer.id == 'byr_hotel_aurora' then
        hotel_snapshot = buyer
    end
end

assert(featured_count == 1, ('expected exactly one featured buyer, got %s'):format(tostring(featured_count)))
assert(pedro_snapshot ~= nil, 'expected pedro snapshot entry')
assert(hotel_snapshot ~= nil, 'expected hotel snapshot entry')
assert(pedro_snapshot.capacity_remaining_g == 500, ('expected pedro remaining capacity 500g, got %s'):format(tostring(pedro_snapshot.capacity_remaining_g)))
assert(pedro_snapshot.capacity_total_g == 3000, ('expected pedro total capacity 3000g, got %s'):format(tostring(pedro_snapshot.capacity_total_g)))
assert(pedro_snapshot.delta_since_last_check == 'volume_down', ('expected pedro delta volume_down, got %s'):format(tostring(pedro_snapshot.delta_since_last_check)))
assert(pedro_snapshot.distance_m < Config.Farm.NPCs.CatalogDistanceFallbackM, 'expected computed distance instead of fallback')
assert(#pedro_snapshot.crops == 1, ('expected pedro crop snapshot count 1, got %s'):format(tostring(#pedro_snapshot.crops)))
assert(pedro_snapshot.crops[1].capacity_taken_g == 2500, ('expected wheat capacity taken 2500g, got %s'):format(tostring(pedro_snapshot.crops[1].capacity_taken_g)))
assert(hotel_snapshot.featured == true, 'expected hotel to be featured by top price')
assert(hotel_snapshot.top_price_eur_per_g > pedro_snapshot.top_price_eur_per_g, 'expected hotel top price to exceed pedro top price')

assert(#triggered_events >= 4, 'expected buyer state and sale events to be emitted')
print('sale_spec.lua: OK (legacy alias, buyer state persistence, catalog snapshot, failure paths)')