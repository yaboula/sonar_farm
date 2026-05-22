Config = {
    Farm = {
        NPCs = {
            ValidQualityGrades = {
                S = true,
                A = true,
                B = true,
                C = true,
                D = true,
            },
            DefaultFreshnessMultiplier = 1.0,
            DefaultDailyQuotaKg = 99999,
            DefaultPayoutAccount = 'bank',
            buyers = {
                pedro = {
                    display_name_key = 'npcs.pedro.name',
                    ped_model = 's_m_m_farmer_01',
                    coords = { x = 1695.0, y = 4825.0, z = 42.0 },
                    heading = 215.0,
                    interaction_radius = 5.0,
                    accepted_crops = { 'wheat' },
                    base_price_per_kg = 0.80,
                    quality_multipliers = {
                        S = 2.0,
                        A = 1.6,
                        B = 1.0,
                        C = 0.6,
                        D = 0.3,
                    },
                    freshness_multiplier = 1.0,
                    daily_quota_kg = 99999,
                    payout_account = 'bank',
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
        Finance = {},
    },
}

local credit_calls = {}
local triggered_events = {}
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

Sonar.Farm.DB = {
    row = function(_query, params)
        return clone(batches[params[1]])
    end,
    transaction = function(queries)
        for index = 1, #queries do
            local query = queries[index].query
            local values = queries[index].values
            if query:find('UPDATE `sonar_farm_batches`', 1, true) then
                local batch = batches[values[2]]
                if batch and batch.sold_ts == nil then
                    batch.sold_ts = values[1]
                end
            end
        end
        return true
    end,
}

dofile('sonar_farm_core/server/npcs/npc_buyer_service.lua')

local NPCBuyerService = Sonar.Farm.NPCBuyerService

local payout_s, breakdown_s = NPCBuyerService.CalculatePayout('pedro', 'wheat', 'S', 1.0)
assert(payout_s == 1.6, ('expected S payout 1.6, got %s'):format(tostring(payout_s)))
assert(breakdown_s.quality_mult == 2.0, 'expected S quality multiplier')

local payout_a = select(1, NPCBuyerService.CalculatePayout('pedro', 'wheat', 'A', 1.0))
assert(payout_a == 1.28, ('expected A payout 1.28, got %s'):format(tostring(payout_a)))

local payout_d = select(1, NPCBuyerService.CalculatePayout('pedro', 'wheat', 'D', 1.0))
assert(payout_d == 0.24, ('expected D payout 0.24, got %s'):format(tostring(payout_d)))

local payout_c = select(1, NPCBuyerService.CalculatePayout('pedro', 'wheat', 'C', 1.0))
assert(payout_c == 0.48, ('expected C payout 0.48, got %s'):format(tostring(payout_c)))

local payout_b = select(1, NPCBuyerService.CalculatePayout('pedro', 'wheat', 'B', 2.5))
assert(payout_b == 2.0, ('expected B payout 2.0 for 2.5kg, got %s'):format(tostring(payout_b)))

local sale_ok, sale_payout, sale_err = NPCBuyerService.ExecuteSale(1, 'pedro', 'sf-a1b2c3d4')
assert(sale_ok == true, ('expected sale happy path to succeed, got %s'):format(tostring(sale_err)))
assert(sale_payout == 2.0, ('expected happy path payout 2.0, got %s'):format(tostring(sale_payout)))
assert(#credit_calls == 1, 'expected exactly one finance credit call')
assert(credit_calls[1].account == 'bank', 'expected bank payout account')
assert(credit_calls[1].amount == 2.0, 'expected finance credit amount 2.0')
assert(credit_calls[1].reason == 'sale:pedro:sf-a1b2c3d4', 'expected sale reason')
assert(batches['sf-a1b2c3d4'].sold_ts ~= nil, 'expected sold_ts stamped after sale')
assert(batches['sf-a1b2c3d4'].lineage_chain == '["sf-origin-01"]', 'expected lineage_chain unchanged after sale')
assert(#inventory[1] == 1, 'expected sold item removed from inventory')

local not_owned_ok, _, not_owned_err = NPCBuyerService.ExecuteSale(1, 'pedro', 'sf-feedf00d')
assert(not_owned_ok == false, 'expected batch outside player inventory to fail')
assert(not_owned_err == 'batch_not_in_inventory', 'expected batch_not_in_inventory error')

local missing_ok, _, missing_err = NPCBuyerService.ExecuteSale(1, 'pedro', 'sf-ffffffff')
assert(missing_ok == false, 'expected missing batch sale to fail')
assert(missing_err == 'batch_not_found', 'expected batch_not_found error')

local sold_ok, _, sold_err = NPCBuyerService.ExecuteSale(1, 'pedro', 'sf-cafebabe')
assert(sold_ok == false, 'expected already sold batch to fail')
assert(sold_err == 'batch_already_sold', 'expected batch_already_sold error')

assert(#triggered_events >= 2, 'expected sale initiated/completed events')
print('sale_spec.lua: OK (payout formula, happy path, failure paths)')
