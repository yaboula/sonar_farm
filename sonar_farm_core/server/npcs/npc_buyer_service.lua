Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}

local NPCBuyerService = {}

local VALID_BATCH_ID_PATTERN = '^sf%-%x%x%x%x%x%x%x%x$'

local function log_info(message)
    print(('[sonar_farm_core][npcs] %s'):format(message))
end

local function log_error(message)
    print(('[sonar_farm_core][npcs][ERROR] %s'):format(message))
end

local function get_npc_config()
    Config = Config or {}
    Config.Farm = Config.Farm or {}
    Config.Farm.NPCs = Config.Farm.NPCs or {}
    Config.Farm.NPCs.buyers = Config.Farm.NPCs.buyers or {}
    Config.Farm.NPCs.ValidQualityGrades = Config.Farm.NPCs.ValidQualityGrades or {}

    return Config.Farm.NPCs
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

local function is_positive_integer(value)
    return type(value) == 'number' and value > 0 and value == math.floor(value)
end

local function round_currency(amount)
    return math.floor((amount * 100) + 0.5) / 100
end

local function table_has_value(values, needle)
    if type(values) ~= 'table' then
        return false
    end

    for index = 1, #values do
        if values[index] == needle then
            return true
        end
    end

    return false
end

local function get_batch_row(batch_id)
    if not Sonar.Farm.DB then
        error('Sonar.Farm.DB is unavailable', 2)
    end

    return Sonar.Farm.DB.row([[
        SELECT
            `batch_id`,
            `plot_id`,
            `crop_id`,
            `player_cid`,
            `crop_type`,
            `quality`,
            `quality_score`,
            `weight_g`,
            `freshness`,
            `lineage_chain`,
            `harvested_ts`,
            `sold_ts`
        FROM `sonar_farm_batches`
        WHERE `batch_id` = ?
        LIMIT 1
    ]], { batch_id })
end

local function resolve_inventory_slot(src, item_name, batch_id)
    local ox_inventory = get_ox_inventory()
    if not ox_inventory then
        return nil, nil, 'inventory_unavailable'
    end

    local ok, slots = pcall(function()
        return ox_inventory:Search(src, 'slots', item_name, { batch_id = batch_id })
    end)

    if not ok then
        return nil, nil, 'inventory_lookup_failed'
    end

    if type(slots) ~= 'table' then
        return nil, nil, nil
    end

    for index = 1, #slots do
        local slot = slots[index]
        if type(slot) == 'table' and type(slot.metadata) == 'table' and slot.metadata.batch_id == batch_id then
            return slot, slot.metadata, nil
        end
    end

    return nil, nil, nil
end

local function ensure_batch_metadata(metadata)
    if not Sonar.Farm.PhysicalItem or type(Sonar.Farm.PhysicalItem.ValidateMetadata) ~= 'function' then
        return false, 'physical_item_unavailable'
    end

    return Sonar.Farm.PhysicalItem.ValidateMetadata(metadata)
end

function NPCBuyerService.GetBuyer(buyer_id)
    if not is_non_empty_string(buyer_id) then
        return nil, 'invalid_buyer_id'
    end

    local buyer = get_npc_config().buyers[buyer_id]
    if type(buyer) ~= 'table' then
        return nil, 'buyer_not_found'
    end

    return buyer, nil
end

function NPCBuyerService.CalculatePayout(buyer_id, crop_type, quality_grade, weight_kg)
    if not is_non_empty_string(crop_type) then
        return nil, nil, 'invalid_crop_type'
    end

    if type(weight_kg) ~= 'number' or weight_kg <= 0 then
        return nil, nil, 'invalid_weight_kg'
    end

    local buyer, buyer_err = NPCBuyerService.GetBuyer(buyer_id)
    if not buyer then
        return nil, nil, buyer_err
    end

    local npc_config = get_npc_config()
    if not npc_config.ValidQualityGrades[quality_grade] then
        return nil, nil, 'invalid_quality_grade'
    end

    if not table_has_value(buyer.accepted_crops, crop_type) then
        return nil, nil, 'crop_not_accepted'
    end

    local quality_mult = tonumber(buyer.quality_multipliers and buyer.quality_multipliers[quality_grade])
    if not quality_mult or quality_mult <= 0 then
        return nil, nil, 'invalid_quality_multiplier'
    end

    local base_price = tonumber(buyer.base_price_per_kg)
    if not base_price or base_price <= 0 then
        return nil, nil, 'invalid_base_price'
    end

    local freshness_mult = tonumber(buyer.freshness_multiplier) or tonumber(npc_config.DefaultFreshnessMultiplier) or 1.0
    local total = round_currency(base_price * quality_mult * freshness_mult * weight_kg)
    local breakdown = {
        base_price = base_price,
        quality_mult = quality_mult,
        freshness_mult = freshness_mult,
        weight_kg = weight_kg,
        total = total,
    }

    return total, breakdown, nil
end

function NPCBuyerService.ExecuteSale(src, buyer_id, batch_id)
    if not is_positive_integer(src) then
        return false, nil, 'invalid_source'
    end

    if not is_non_empty_string(batch_id) or not batch_id:match(VALID_BATCH_ID_PATTERN) then
        return false, nil, 'invalid_batch_id'
    end

    local player = Sonar.Farm.Bridge and Sonar.Farm.Bridge.GetPlayer and Sonar.Farm.Bridge.GetPlayer(src) or nil
    if not player or not is_non_empty_string(player.citizen_id) then
        return false, nil, 'player_unavailable'
    end

    local buyer, buyer_err = NPCBuyerService.GetBuyer(buyer_id)
    if not buyer then
        return false, nil, buyer_err
    end

    local batch = get_batch_row(batch_id)
    if not batch then
        return false, nil, 'batch_not_found'
    end

    if batch.sold_ts ~= nil then
        return false, nil, 'batch_already_sold'
    end

    local item_name = 'sonar_batch_' .. tostring(batch.crop_type)
    local slot, metadata, slot_err = resolve_inventory_slot(src, item_name, batch_id)
    if slot_err then
        return false, nil, slot_err
    end

    if not slot or type(metadata) ~= 'table' then
        return false, nil, 'batch_not_in_inventory'
    end

    local metadata_ok, metadata_err = ensure_batch_metadata(metadata)
    if metadata_ok ~= true then
        return false, nil, metadata_err or 'invalid_batch_metadata'
    end

    local weight_kg = (tonumber(metadata.weight_g) or tonumber(batch.weight_g) or 0) / 1000
    local payout, breakdown, payout_err = NPCBuyerService.CalculatePayout(
        buyer_id,
        tostring(metadata.crop_type or batch.crop_type),
        tostring(metadata.quality or batch.quality),
        weight_kg
    )
    if not payout then
        return false, nil, payout_err
    end

    TriggerEvent('sonar:farm:sale:initiated', {
        buyer_id = buyer_id,
        batch_id = batch_id,
        player_cid = player.citizen_id,
        crop_type = tostring(metadata.crop_type or batch.crop_type),
        quality = tostring(metadata.quality or batch.quality),
        weight_kg = weight_kg,
        payout_preview = payout,
    })

    local ox_inventory = get_ox_inventory()
    if not ox_inventory then
        return false, nil, 'inventory_unavailable'
    end

    local remove_ok, remove_result = pcall(function()
        return ox_inventory:RemoveItem(src, item_name, 1, { batch_id = batch_id }, slot.slot, false, false)
    end)
    if not remove_ok or remove_result == false then
        return false, nil, 'inventory_remove_failed'
    end

    local sold_ts = os.time()
    local db_ok, db_err = pcall(function()
        Sonar.Farm.DB.transaction({
            {
                query = [[
                    UPDATE `sonar_farm_batches`
                    SET `sold_ts` = ?
                    WHERE `batch_id` = ? AND `sold_ts` IS NULL
                ]],
                values = { sold_ts, batch_id },
            },
        })
    end)

    if not db_ok then
        pcall(function()
            ox_inventory:AddItem(src, item_name, 1, metadata, slot.slot)
        end)
        return false, nil, tostring(db_err)
    end

    local payout_account = buyer.payout_account or get_npc_config().DefaultPayoutAccount or 'bank'
    local finance_ok, finance_result = Sonar.Farm.Finance.Credit(
        src,
        payout_account,
        payout,
        'sale:' .. buyer_id .. ':' .. batch_id,
        'sale:' .. buyer_id .. ':' .. batch_id,
        {
            buyer_id = buyer_id,
            batch_id = batch_id,
            crop_type = tostring(metadata.crop_type or batch.crop_type),
            quality = tostring(metadata.quality or batch.quality),
            weight_g = tonumber(metadata.weight_g) or tonumber(batch.weight_g),
            payout = payout,
            payout_account = payout_account,
            breakdown = breakdown,
        }
    )

    if not finance_ok then
        pcall(function()
            Sonar.Farm.DB.transaction({
                {
                    query = [[
                        UPDATE `sonar_farm_batches`
                        SET `sold_ts` = NULL
                        WHERE `batch_id` = ?
                    ]],
                    values = { batch_id },
                },
            })
        end)
        pcall(function()
            ox_inventory:AddItem(src, item_name, 1, metadata, slot.slot)
        end)
        log_error(('finance credit failed for %s: %s'):format(batch_id, tostring(finance_result and finance_result.error_code or finance_result)))
        return false, nil, finance_result and finance_result.error_code or 'finance_credit_failed'
    end

    TriggerEvent('sonar:farm:sale:completed', {
        buyer_id = buyer_id,
        batch_id = batch_id,
        player_cid = player.citizen_id,
        payout = payout,
        sold_ts = sold_ts,
    })

    return true, payout, nil
end

function NPCBuyerService.Boot()
    local buyers = get_npc_config().buyers or {}
    local count = 0

    for buyer_id, buyer in pairs(buyers) do
        if type(buyer) ~= 'table' then
            log_error(('invalid buyer config for %s'):format(tostring(buyer_id)))
        else
            count = count + 1
        end
    end

    log_info(('NPC buyer boot ready: %d buyers registered'):format(count))
    return true
end

Sonar.Farm.NPCBuyerService = NPCBuyerService
