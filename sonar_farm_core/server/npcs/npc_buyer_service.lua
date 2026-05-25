Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}

local NPCBuyerService = {}

local VALID_BATCH_ID_PATTERN = '^sf%-%x%x%x%x%x%x%x%x$'
local BUYER_STATE_UPSERT_QUERY = [[
    INSERT INTO `sonar_farm_npc_buyer_state` (
        `buyer_id`,
        `volume_remaining_today_g`,
        `today_top_price_eur_per_g`,
        `previous_volume_remaining_today_g`,
        `previous_top_price_eur_per_g`,
        `contracts_enabled`,
        `previous_contracts_enabled`,
        `crop_volume_taken_today_json`,
        `last_reset_ts`,
        `updated_ts`
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE
        `volume_remaining_today_g` = VALUES(`volume_remaining_today_g`),
        `today_top_price_eur_per_g` = VALUES(`today_top_price_eur_per_g`),
        `previous_volume_remaining_today_g` = VALUES(`previous_volume_remaining_today_g`),
        `previous_top_price_eur_per_g` = VALUES(`previous_top_price_eur_per_g`),
        `contracts_enabled` = VALUES(`contracts_enabled`),
        `previous_contracts_enabled` = VALUES(`previous_contracts_enabled`),
        `crop_volume_taken_today_json` = VALUES(`crop_volume_taken_today_json`),
        `last_reset_ts` = VALUES(`last_reset_ts`),
        `updated_ts` = VALUES(`updated_ts`)
]]

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
    Config.Farm.NPCs.QualityRank = Config.Farm.NPCs.QualityRank or {}
    Config.Farm.NPCs.DefaultQualityMultipliers = Config.Farm.NPCs.DefaultQualityMultipliers or {}
    Config.Farm.NPCs.LegacyBuyerAliases = Config.Farm.NPCs.LegacyBuyerAliases or {}

    return Config.Farm.NPCs
end

local function get_climate_config()
    Config = Config or {}
    Config.Farm = Config.Farm or {}
    Config.Farm.Climate = Config.Farm.Climate or {}
    Config.Farm.Climate.Seasons = Config.Farm.Climate.Seasons or {}

    return Config.Farm.Climate
end

local function get_ox_inventory()
    if type(exports) ~= 'table' or not exports.ox_inventory then
        return nil
    end

    return exports.ox_inventory
end

local function get_now_ts()
    if type(NPCBuyerService.__test_now) == 'function' then
        local test_now = tonumber(NPCBuyerService.__test_now())
        if test_now then
            return test_now
        end
    end

    return os.time()
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

local function clamp_number(value, minimum, maximum)
    local numeric = tonumber(value) or 0
    if numeric < minimum then
        return minimum
    end
    if numeric > maximum then
        return maximum
    end
    return numeric
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

local function get_db()
    if not Sonar.Farm.DB then
        error('Sonar.Farm.DB is unavailable', 2)
    end

    return Sonar.Farm.DB
end

local function db_execute(query, values)
    local db = get_db()
    if type(db.execute) == 'function' then
        return db.execute(query, values)
    end

    if type(db.transaction) == 'function' then
        return db.transaction({
            {
                query = query,
                values = values,
            },
        })
    end

    error('Sonar.Farm.DB.execute is unavailable', 2)
end

local function get_json_codec()
    if type(json) == 'table' and type(json.encode) == 'function' and type(json.decode) == 'function' then
        return json
    end

    return nil
end

local function decode_crop_volume_map(raw_value)
    if type(raw_value) ~= 'string' or raw_value == '' then
        return {}
    end

    local codec = get_json_codec()
    if not codec then
        return {}
    end

    local ok, decoded = pcall(codec.decode, raw_value)
    if not ok or type(decoded) ~= 'table' then
        return {}
    end

    local normalized = {}
    for crop_name, value in pairs(decoded) do
        if type(crop_name) == 'string' then
            normalized[crop_name] = math.max(0, math.floor((tonumber(value) or 0) + 0.5))
        end
    end

    return normalized
end

local function encode_crop_volume_map(value)
    local codec = get_json_codec()
    if not codec then
        return '{}'
    end

    local ok, encoded = pcall(codec.encode, value or {})
    if not ok or type(encoded) ~= 'string' or encoded == '' then
        return '{}'
    end

    return encoded
end

local function get_effective_seconds(seconds)
    local multiplier = tonumber(Config and Config.Farm and Config.Farm.TimeMultiplier) or 1.0
    if multiplier <= 0 then
        multiplier = 1.0
    end

    return math.max(1, math.floor(((tonumber(seconds) or 1) * multiplier) + 0.5))
end

local function get_market_day_meta(now_ts)
    local climate = Sonar.Farm.ClimateService
    local state = climate and type(climate.GetState) == 'function' and climate.GetState() or nil
    local climate_config = get_climate_config()
    local season_key = climate_config.DefaultSeason or 'spring'
    local day_anchor_ts = tonumber(now_ts) or get_now_ts()
    local season_duration_seconds = 1

    if type(state) == 'table' then
        season_key = tostring(state.current_season or season_key)
        day_anchor_ts = tonumber(state.season_started_at) or day_anchor_ts
    end

    local season_definition = climate_config.Seasons[season_key] or {}
    season_duration_seconds = get_effective_seconds(season_definition.duration_seconds)

    return {
        day = math.floor((tonumber(now_ts) or get_now_ts()) / season_duration_seconds) + 1,
        season_key = season_key,
        day_anchor_ts = day_anchor_ts,
    }
end

local function get_quality_rank(quality_grade)
    return tonumber(get_npc_config().QualityRank[quality_grade]) or 0
end

local function resolve_buyer_id(buyer_id)
    local npc_config = get_npc_config()
    if type(npc_config.buyers[buyer_id]) == 'table' then
        return buyer_id
    end

    local alias_target = npc_config.LegacyBuyerAliases[buyer_id]
    if is_non_empty_string(alias_target) and type(npc_config.buyers[alias_target]) == 'table' then
        return alias_target
    end

    return buyer_id
end

local function get_batch_row(batch_id)
    return get_db().row([[
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

local function fetch_buyer_state_row(buyer_id)
    local row = get_db().row([[
        SELECT
            `buyer_id`,
            `volume_remaining_today_g`,
            `today_top_price_eur_per_g`,
            `previous_volume_remaining_today_g`,
            `previous_top_price_eur_per_g`,
            `contracts_enabled`,
            `previous_contracts_enabled`,
            `crop_volume_taken_today_json`,
            `last_reset_ts`,
            `updated_ts`
        FROM `sonar_farm_npc_buyer_state`
        WHERE `buyer_id` = ?
        LIMIT 1
    ]], { buyer_id })

    if type(row) ~= 'table' or row.buyer_id ~= buyer_id then
        return nil
    end

    return row
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

local function get_buyer_crop_ids(buyer)
    local accepted = type(buyer) == 'table' and buyer.accepted_crops or nil
    if type(accepted) ~= 'table' then
        return {}
    end

    local ids = {}
    local seen = {}
    local extra = {}

    for index = 1, #accepted do
        local crop_name = accepted[index]
        if is_non_empty_string(crop_name) and not seen[crop_name] then
            ids[#ids + 1] = crop_name
            seen[crop_name] = true
        end
    end

    for crop_name, rule in pairs(accepted) do
        if type(crop_name) == 'string' and type(rule) == 'table' and not seen[crop_name] then
            extra[#extra + 1] = crop_name
            seen[crop_name] = true
        end
    end

    table.sort(extra)
    for index = 1, #extra do
        ids[#ids + 1] = extra[index]
    end

    return ids
end

local function get_crop_rule(buyer, crop_type)
    local accepted_crops = type(buyer) == 'table' and buyer.accepted_crops or nil
    if type(accepted_crops) == 'table' and type(accepted_crops[crop_type]) == 'table' then
        return accepted_crops[crop_type], nil
    end

    if table_has_value(accepted_crops, crop_type) then
        local base_price_per_kg = tonumber(buyer.base_price_per_kg)
        local daily_quota_kg = tonumber(buyer.daily_quota_kg) or tonumber(get_npc_config().DefaultDailyQuotaKg) or 0
        if not base_price_per_kg or base_price_per_kg <= 0 then
            return nil, 'invalid_base_price'
        end

        return {
            min_quality = 'D',
            base_price_eur_per_g = base_price_per_kg / 1000,
            daily_capacity_g = math.max(0, math.floor((daily_quota_kg * 1000) + 0.5)),
        }, nil
    end

    return nil, 'crop_not_accepted'
end

local function get_crop_price_eur_per_g(buyer, crop_rule)
    local base_price = tonumber(crop_rule and crop_rule.base_price_eur_per_g)
    if not base_price or base_price <= 0 then
        return nil, 'invalid_base_price'
    end

    local personality_modifier = tonumber(buyer and buyer.personality_modifier) or 1.0
    if personality_modifier <= 0 then
        return nil, 'invalid_personality_modifier'
    end

    return base_price * personality_modifier, nil
end

local function build_buyer_metrics(buyer)
    local crop_ids = get_buyer_crop_ids(buyer)
    local total_capacity_g = 0
    local top_price_eur_per_g = 0

    for index = 1, #crop_ids do
        local crop_rule = get_crop_rule(buyer, crop_ids[index])
        if type(crop_rule) == 'table' then
            total_capacity_g = total_capacity_g + math.max(0, math.floor((tonumber(crop_rule.daily_capacity_g) or 0) + 0.5))
            local crop_price = select(1, get_crop_price_eur_per_g(buyer, crop_rule))
            if tonumber(crop_price) and crop_price > top_price_eur_per_g then
                top_price_eur_per_g = crop_price
            end
        end
    end

    return {
        total_capacity_g = total_capacity_g,
        top_price_eur_per_g = top_price_eur_per_g,
        crop_ids = crop_ids,
    }
end

local function normalize_coords(buyer)
    local coords = type(buyer) == 'table' and buyer.coords or nil
    if type(coords) == 'table' then
        return {
            x = tonumber(coords.x) or 0.0,
            y = tonumber(coords.y) or 0.0,
            z = tonumber(coords.z) or 0.0,
            w = tonumber(coords.w) or tonumber(buyer.heading) or 0.0,
        }
    end

    local world_coords = type(buyer) == 'table' and buyer.world_coords or {}
    return {
        x = tonumber(world_coords.x) or 0.0,
        y = tonumber(world_coords.y) or 0.0,
        z = tonumber(world_coords.z) or 0.0,
        w = tonumber(buyer and buyer.heading) or 0.0,
    }
end

local function calculate_distance_m(source, buyer)
    local fallback = tonumber(get_npc_config().CatalogDistanceFallbackM) or 99999.0
    if type(source) ~= 'number' or source <= 0 then
        return fallback
    end

    if type(GetPlayerPed) ~= 'function' or type(GetEntityCoords) ~= 'function' then
        return fallback
    end

    local player_ped = GetPlayerPed(source)
    if not player_ped or player_ped <= 0 then
        return fallback
    end

    local ok, player_coords = pcall(GetEntityCoords, player_ped)
    if not ok or player_coords == nil then
        return fallback
    end

    local px = tonumber(player_coords.x)
    local py = tonumber(player_coords.y)
    local pz = tonumber(player_coords.z)
    if px == nil or py == nil or pz == nil then
        return fallback
    end

    local buyer_coords = normalize_coords(buyer)
    local dx = px - buyer_coords.x
    local dy = py - buyer_coords.y
    local dz = pz - buyer_coords.z

    return math.floor(((math.sqrt((dx * dx) + (dy * dy) + (dz * dz)) * 100) + 0.5)) / 100
end

local function build_state_values(state)
    return {
        state.buyer_id,
        state.volume_remaining_today_g,
        state.today_top_price_eur_per_g,
        state.previous_volume_remaining_today_g,
        state.previous_top_price_eur_per_g,
        state.contracts_enabled and 1 or 0,
        state.previous_contracts_enabled and 1 or 0,
        encode_crop_volume_map(state.crop_volume_taken_today),
        state.last_reset_ts,
        state.updated_ts,
    }
end

local function emit_buyer_state_changed(state, reason)
    TriggerEvent('sonar:farm:sale:buyer_state_changed', {
        buyer_id = state.buyer_id,
        previous_volume_remaining_today_g = state.previous_volume_remaining_today_g,
        volume_remaining_today_g = state.volume_remaining_today_g,
        previous_top_price_eur_per_g = state.previous_top_price_eur_per_g,
        top_price_eur_per_g = state.today_top_price_eur_per_g,
        previous_contracts_enabled = state.previous_contracts_enabled,
        contracts_enabled = state.contracts_enabled,
        last_reset_ts = state.last_reset_ts,
        updated_ts = state.updated_ts,
        reason = reason,
    })
end

local function materialize_buyer_state(requested_buyer_id, buyer, resolved_buyer_id, now_ts, skip_write)
    local timestamp = tonumber(now_ts) or get_now_ts()
    local day_meta = get_market_day_meta(timestamp)
    local metrics = build_buyer_metrics(buyer)
    local current_contracts_enabled = buyer.contracts_enabled == true
    local row = fetch_buyer_state_row(resolved_buyer_id)
    local state
    local should_write = false
    local reason = 'unchanged'

    if not row then
        state = {
            buyer_id = resolved_buyer_id,
            volume_remaining_today_g = metrics.total_capacity_g,
            today_top_price_eur_per_g = metrics.top_price_eur_per_g,
            previous_volume_remaining_today_g = metrics.total_capacity_g,
            previous_top_price_eur_per_g = metrics.top_price_eur_per_g,
            contracts_enabled = current_contracts_enabled,
            previous_contracts_enabled = current_contracts_enabled,
            crop_volume_taken_today = {},
            last_reset_ts = day_meta.day_anchor_ts,
            updated_ts = timestamp,
        }
        should_write = true
        reason = 'created'
    else
        local current_volume_remaining_g = clamp_number(row.volume_remaining_today_g, 0, metrics.total_capacity_g)
        local current_top_price = tonumber(row.today_top_price_eur_per_g) or metrics.top_price_eur_per_g
        local previous_volume_remaining_g = tonumber(row.previous_volume_remaining_today_g) or current_volume_remaining_g
        local previous_top_price = tonumber(row.previous_top_price_eur_per_g) or current_top_price
        local previous_contracts_enabled = (tonumber(row.previous_contracts_enabled) or 0) == 1
        local current_contracts_stored = (tonumber(row.contracts_enabled) or 0) == 1
        local crop_volume_taken_today = decode_crop_volume_map(row.crop_volume_taken_today_json)

        state = {
            buyer_id = resolved_buyer_id,
            volume_remaining_today_g = current_volume_remaining_g,
            today_top_price_eur_per_g = current_top_price,
            previous_volume_remaining_today_g = previous_volume_remaining_g,
            previous_top_price_eur_per_g = previous_top_price,
            contracts_enabled = current_contracts_stored,
            previous_contracts_enabled = previous_contracts_enabled,
            crop_volume_taken_today = crop_volume_taken_today,
            last_reset_ts = tonumber(row.last_reset_ts) or day_meta.day_anchor_ts,
            updated_ts = tonumber(row.updated_ts) or timestamp,
        }

        if state.last_reset_ts ~= day_meta.day_anchor_ts then
            state.previous_volume_remaining_today_g = state.volume_remaining_today_g
            state.previous_top_price_eur_per_g = state.today_top_price_eur_per_g
            state.previous_contracts_enabled = state.contracts_enabled
            state.volume_remaining_today_g = metrics.total_capacity_g
            state.today_top_price_eur_per_g = metrics.top_price_eur_per_g
            state.contracts_enabled = current_contracts_enabled
            state.crop_volume_taken_today = {}
            state.last_reset_ts = day_meta.day_anchor_ts
            state.updated_ts = timestamp
            should_write = true
            reason = 'daily_reset'
        elseif current_top_price ~= metrics.top_price_eur_per_g or current_contracts_stored ~= current_contracts_enabled or current_volume_remaining_g ~= (tonumber(row.volume_remaining_today_g) or current_volume_remaining_g) then
            state.previous_volume_remaining_today_g = tonumber(row.volume_remaining_today_g) or current_volume_remaining_g
            state.previous_top_price_eur_per_g = current_top_price
            state.previous_contracts_enabled = current_contracts_stored
            state.volume_remaining_today_g = current_volume_remaining_g
            state.today_top_price_eur_per_g = metrics.top_price_eur_per_g
            state.contracts_enabled = current_contracts_enabled
            state.updated_ts = timestamp
            should_write = true
            reason = 'reconciled'
        end
    end

    if should_write and skip_write ~= true then
        db_execute(BUYER_STATE_UPSERT_QUERY, build_state_values(state))
        emit_buyer_state_changed(state, reason)
    end

    state.requested_buyer_id = requested_buyer_id
    state.season_key = day_meta.season_key
    state.day = day_meta.day
    state.total_capacity_g = metrics.total_capacity_g
    state.top_price_eur_per_g = metrics.top_price_eur_per_g
    state.crop_ids = metrics.crop_ids

    return state
end

local function build_crops_snapshot(buyer, state)
    local crops = {}

    for index = 1, #state.crop_ids do
        local crop_name = state.crop_ids[index]
        local crop_rule = get_crop_rule(buyer, crop_name)
        local price_eur_per_g = select(1, get_crop_price_eur_per_g(buyer, crop_rule)) or 0
        local capacity_total_g = math.max(0, math.floor((tonumber(crop_rule and crop_rule.daily_capacity_g) or 0) + 0.5))
        local capacity_taken_g = math.max(0, math.floor((tonumber(state.crop_volume_taken_today[crop_name]) or 0) + 0.5))

        crops[#crops + 1] = {
            crop = crop_name,
            min_quality = tostring(crop_rule and crop_rule.min_quality or 'D'),
            price_eur_per_g = price_eur_per_g,
            capacity_total_g = capacity_total_g,
            capacity_taken_g = capacity_taken_g,
        }
    end

    return crops
end

local function resolve_delta_since_last_check(state)
    if state.contracts_enabled and not state.previous_contracts_enabled then
        return 'new_contract'
    end

    if state.today_top_price_eur_per_g > state.previous_top_price_eur_per_g then
        return 'price_up'
    end

    if state.today_top_price_eur_per_g < state.previous_top_price_eur_per_g then
        return 'price_down'
    end

    if state.volume_remaining_today_g > state.previous_volume_remaining_today_g then
        return 'volume_up'
    end

    if state.volume_remaining_today_g < state.previous_volume_remaining_today_g then
        return 'volume_down'
    end

    return 'stable'
end

local function build_buyer_state_query(state, sold_ts, batch_id)
    return {
        {
            query = [[
                UPDATE `sonar_farm_batches`
                SET `sold_ts` = ?
                WHERE `batch_id` = ? AND `sold_ts` IS NULL
            ]],
            values = { sold_ts, batch_id },
        },
        {
            query = BUYER_STATE_UPSERT_QUERY,
            values = build_state_values(state),
        },
    }
end

function NPCBuyerService.GetBuyer(buyer_id)
    if not is_non_empty_string(buyer_id) then
        return nil, 'invalid_buyer_id'
    end

    local resolved_buyer_id = resolve_buyer_id(buyer_id)
    local buyer = get_npc_config().buyers[resolved_buyer_id]
    if type(buyer) ~= 'table' then
        return nil, 'buyer_not_found'
    end

    return buyer, nil, resolved_buyer_id
end

function NPCBuyerService.CalculatePayout(buyer_id, crop_type, quality_grade, weight_kg)
    if not is_non_empty_string(crop_type) then
        return nil, nil, 'invalid_crop_type'
    end

    if type(weight_kg) ~= 'number' or weight_kg <= 0 then
        return nil, nil, 'invalid_weight_kg'
    end

    local buyer, buyer_err, resolved_buyer_id = NPCBuyerService.GetBuyer(buyer_id)
    if not buyer then
        return nil, nil, buyer_err
    end

    local npc_config = get_npc_config()
    if not npc_config.ValidQualityGrades[quality_grade] then
        return nil, nil, 'invalid_quality_grade'
    end

    local crop_rule, crop_err = get_crop_rule(buyer, crop_type)
    if not crop_rule then
        return nil, nil, crop_err
    end

    local min_quality = tostring(crop_rule.min_quality or 'D')
    if get_quality_rank(quality_grade) < get_quality_rank(min_quality) then
        return nil, nil, 'quality_below_threshold'
    end

    local price_eur_per_g, price_err = get_crop_price_eur_per_g(buyer, crop_rule)
    if not price_eur_per_g then
        return nil, nil, price_err
    end

    local quality_mult = tonumber(buyer.quality_multipliers and buyer.quality_multipliers[quality_grade])
        or tonumber(npc_config.DefaultQualityMultipliers[quality_grade])
    if not quality_mult or quality_mult <= 0 then
        return nil, nil, 'invalid_quality_multiplier'
    end

    local freshness_mult = tonumber(buyer.freshness_multiplier) or tonumber(npc_config.DefaultFreshnessMultiplier) or 1.0
    local weight_g = math.max(1, math.floor((weight_kg * 1000) + 0.5))
    local state = materialize_buyer_state(buyer_id, buyer, resolved_buyer_id, get_now_ts(), false)
    if weight_g > state.volume_remaining_today_g then
        return nil, nil, 'volume_exceeded'
    end

    local total = round_currency(price_eur_per_g * quality_mult * freshness_mult * weight_g)
    local breakdown = {
        buyer_id = buyer_id,
        resolved_buyer_id = resolved_buyer_id,
        crop = crop_type,
        min_quality = min_quality,
        price_eur_per_g = price_eur_per_g,
        quality_mult = quality_mult,
        freshness_mult = freshness_mult,
        weight_g = weight_g,
        weight_kg = weight_kg,
        total = total,
        volume_remaining_today_g = state.volume_remaining_today_g,
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

    local buyer, buyer_err, resolved_buyer_id = NPCBuyerService.GetBuyer(buyer_id)
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

    local crop_type = tostring(metadata.crop_type or batch.crop_type)
    local quality_grade = tostring(metadata.quality or batch.quality)
    local weight_g = math.max(0, math.floor((tonumber(metadata.weight_g) or tonumber(batch.weight_g) or 0) + 0.5))
    local weight_kg = weight_g / 1000
    local payout, breakdown, payout_err = NPCBuyerService.CalculatePayout(buyer_id, crop_type, quality_grade, weight_kg)
    if not payout then
        return false, nil, payout_err
    end

    local state_before_sale = materialize_buyer_state(buyer_id, buyer, resolved_buyer_id, get_now_ts(), false)
    if weight_g > state_before_sale.volume_remaining_today_g then
        return false, nil, 'volume_exceeded'
    end

    TriggerEvent('sonar:farm:sale:initiated', {
        buyer_id = buyer_id,
        resolved_buyer_id = resolved_buyer_id,
        batch_id = batch_id,
        player_cid = player.citizen_id,
        crop_type = crop_type,
        quality = quality_grade,
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

    local state_after_sale = {
        buyer_id = state_before_sale.buyer_id,
        volume_remaining_today_g = math.max(0, state_before_sale.volume_remaining_today_g - weight_g),
        today_top_price_eur_per_g = state_before_sale.today_top_price_eur_per_g,
        previous_volume_remaining_today_g = state_before_sale.volume_remaining_today_g,
        previous_top_price_eur_per_g = state_before_sale.today_top_price_eur_per_g,
        contracts_enabled = state_before_sale.contracts_enabled,
        previous_contracts_enabled = state_before_sale.contracts_enabled,
        crop_volume_taken_today = decode_crop_volume_map(encode_crop_volume_map(state_before_sale.crop_volume_taken_today)),
        last_reset_ts = state_before_sale.last_reset_ts,
        updated_ts = get_now_ts(),
    }
    state_after_sale.crop_volume_taken_today[crop_type] = (tonumber(state_after_sale.crop_volume_taken_today[crop_type]) or 0) + weight_g

    local sold_ts = get_now_ts()
    local db_ok, db_err = pcall(function()
        return get_db().transaction(build_buyer_state_query(state_after_sale, sold_ts, batch_id))
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
            resolved_buyer_id = resolved_buyer_id,
            batch_id = batch_id,
            crop_type = crop_type,
            quality = quality_grade,
            weight_g = weight_g,
            payout = payout,
            payout_account = payout_account,
            breakdown = breakdown,
        }
    )

    if not finance_ok then
        pcall(function()
            get_db().transaction({
                {
                    query = [[
                        UPDATE `sonar_farm_batches`
                        SET `sold_ts` = NULL
                        WHERE `batch_id` = ?
                    ]],
                    values = { batch_id },
                },
                {
                    query = BUYER_STATE_UPSERT_QUERY,
                    values = build_state_values(state_before_sale),
                },
            })
        end)
        pcall(function()
            ox_inventory:AddItem(src, item_name, 1, metadata, slot.slot)
        end)
        log_error(('finance credit failed for %s: %s'):format(batch_id, tostring(finance_result and finance_result.error_code or finance_result)))
        return false, nil, finance_result and finance_result.error_code or 'finance_credit_failed'
    end

    emit_buyer_state_changed(state_after_sale, 'sale')
    TriggerEvent('sonar:farm:sale:completed', {
        buyer_id = buyer_id,
        resolved_buyer_id = resolved_buyer_id,
        batch_id = batch_id,
        player_cid = player.citizen_id,
        payout = payout,
        sold_ts = sold_ts,
        volume_remaining_today_g = state_after_sale.volume_remaining_today_g,
    })

    return true, payout, nil
end

function NPCBuyerService.GetCatalogSnapshot(source)
    local now_ts = get_now_ts()
    local day_meta = get_market_day_meta(now_ts)
    local buyers = get_npc_config().buyers or {}
    local buyer_ids = {}
    local catalog_buyers = {}

    for buyer_id, buyer in pairs(buyers) do
        if type(buyer) == 'table' then
            buyer_ids[#buyer_ids + 1] = buyer_id
        end
    end

    table.sort(buyer_ids)

    for index = 1, #buyer_ids do
        local resolved_buyer_id = buyer_ids[index]
        local buyer = buyers[resolved_buyer_id]
        local state = materialize_buyer_state(resolved_buyer_id, buyer, resolved_buyer_id, now_ts, false)
        local coords = normalize_coords(buyer)
        local distance_m = calculate_distance_m(source, buyer)

        catalog_buyers[#catalog_buyers + 1] = {
            id = resolved_buyer_id,
            display_name_key = tostring(buyer.display_name_key or ''),
            kind_key = 'npcs.kinds.' .. tostring(buyer.kind or 'buyer'),
            district_key = tostring(buyer.district_key or ''),
            coords = coords,
            distance_m = distance_m,
            contracts_open = state.contracts_enabled,
            featured = false,
            updated_ts = state.updated_ts,
            top_price_eur_per_g = state.today_top_price_eur_per_g,
            capacity_remaining_g = state.volume_remaining_today_g,
            capacity_total_g = state.total_capacity_g,
            delta_since_last_check = resolve_delta_since_last_check(state),
            crops = build_crops_snapshot(buyer, state),
        }
    end

    local featured_index = nil
    for index = 1, #catalog_buyers do
        local current = catalog_buyers[index]
        local featured = featured_index and catalog_buyers[featured_index] or nil
        if not featured or current.top_price_eur_per_g > featured.top_price_eur_per_g or (current.top_price_eur_per_g == featured.top_price_eur_per_g and current.distance_m < featured.distance_m) then
            featured_index = index
        end
    end

    if featured_index then
        catalog_buyers[featured_index].featured = true
    end

    return {
        day = day_meta.day,
        season_key = day_meta.season_key,
        server_now_ts = now_ts,
        buyers = catalog_buyers,
    }
end

function NPCBuyerService.Boot()
    local buyers = get_npc_config().buyers or {}
    local count = 0
    local now_ts = get_now_ts()

    for buyer_id, buyer in pairs(buyers) do
        if type(buyer) ~= 'table' then
            log_error(('invalid buyer config for %s'):format(tostring(buyer_id)))
        else
            materialize_buyer_state(buyer_id, buyer, buyer_id, now_ts, false)
            count = count + 1
        end
    end

    log_info(('NPC buyer boot ready: %d buyers registered'):format(count))
    return true
end

Sonar.Farm.NPCBuyerService = NPCBuyerService
