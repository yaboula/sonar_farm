Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}

local MachineryService = {}

local function log_info(message)
    print(('[sonar_farm_core][machinery] %s'):format(message))
end

local function get_db()
    if not Sonar.Farm.DB then
        error('Sonar.Farm.DB is unavailable', 2)
    end

    return Sonar.Farm.DB
end

local function get_machinery_config()
    Config = Config or {}
    Config.Farm = Config.Farm or {}
    Config.Farm.Machinery = Config.Farm.Machinery or {}
    Config.Farm.Machinery.Models = Config.Farm.Machinery.Models or {}
    Config.Farm.Machinery.Usage = Config.Farm.Machinery.Usage or {}
    Config.Farm.Machinery.Breakdown = Config.Farm.Machinery.Breakdown or {}
    Config.Farm.Machinery.Repair = Config.Farm.Machinery.Repair or {}

    return Config.Farm.Machinery
end

local function is_non_empty_string(value)
    return type(value) == 'string' and value ~= ''
end

local function sanitize_plate(plate)
    if type(plate) ~= 'string' then
        return nil
    end

    local trimmed = plate:match('^%s*(.-)%s*$')
    if trimmed == nil or trimmed == '' then
        return nil
    end

    if #trimmed > 16 then
        trimmed = trimmed:sub(1, 16)
    end

    return string.upper(trimmed)
end

local function clamp_durability(value)
    local number = tonumber(value) or 0
    if number < 0 then
        return 0
    end
    if number > 100 then
        return 100
    end

    return math.floor(number)
end

local function get_default_durability()
    local machinery = get_machinery_config()
    return clamp_durability(machinery.DefaultDurability or 100)
end

local function get_break_threshold()
    local machinery = get_machinery_config()
    return clamp_durability(machinery.CriticalBreakThreshold or 30)
end

local function get_breakdown_chance_pct()
    local machinery = get_machinery_config()
    local chance = tonumber(machinery.Breakdown and machinery.Breakdown.critical_chance_pct) or 0
    if chance < 0 then
        return 0
    end
    if chance > 100 then
        return 100
    end

    return chance
end

local function get_usage_settings()
    local machinery = get_machinery_config()
    local usage = machinery.Usage or {}

    return {
        seconds_per_durability = math.max(tonumber(usage.seconds_per_durability) or 60, 1),
        min_report_seconds = math.max(tonumber(usage.min_report_seconds) or 60, 1),
        max_report_seconds = math.max(tonumber(usage.max_report_seconds) or 900, 1),
    }
end

local function get_model_registry()
    local machinery = get_machinery_config()
    return machinery.Models or {}
end

local function normalize_model(model)
    if not is_non_empty_string(model) then
        return nil
    end

    return string.lower(model)
end

local function get_model_config(model)
    local registry = get_model_registry()
    local normalized = normalize_model(model)
    if not normalized then
        return nil, nil
    end

    local config = registry[normalized]
    if type(config) ~= 'table' then
        return nil, normalized
    end

    return config, normalized
end

local function is_valid_usage_amount(amount)
    if type(amount) ~= 'number' or amount ~= amount or amount <= 0 then
        return false
    end

    local usage = get_usage_settings()
    return amount >= usage.min_report_seconds and amount <= usage.max_report_seconds
end

local function get_usage_delta(amount, wear_multiplier)
    local usage = get_usage_settings()
    local ratio = amount / usage.seconds_per_durability
    local adjusted = ratio * (tonumber(wear_multiplier) or 1.0)
    local rounded = math.floor(adjusted + 0.5)
    if rounded < 1 then
        return 1
    end

    return rounded
end

local function fetch_state_row(plate)
    return get_db().row([[
        SELECT `plate`, `model`, `durability`, `is_broken`
        FROM `sonar_farm_machinery_state`
        WHERE `plate` = ?
        LIMIT 1
    ]], { plate })
end

local function build_state_payload(row)
    if type(row) ~= 'table' then
        return nil
    end

    return {
        plate = tostring(row.plate or ''),
        model = row.model,
        durability = clamp_durability(row.durability),
        is_broken = tonumber(row.is_broken) == 1 or row.is_broken == true,
    }
end

local function insert_state(plate, model, durability, is_broken)
    get_db().execute([[
        INSERT INTO `sonar_farm_machinery_state` (
            `plate`,
            `model`,
            `durability`,
            `is_broken`
        ) VALUES (?, ?, ?, ?)
    ]], {
        plate,
        model,
        clamp_durability(durability),
        is_broken and 1 or 0,
    })
end

local function update_state(plate, durability, is_broken, model)
    get_db().execute([[
        UPDATE `sonar_farm_machinery_state`
        SET
            `durability` = ?,
            `is_broken` = ?,
            `model` = COALESCE(?, `model`)
        WHERE `plate` = ?
    ]], {
        clamp_durability(durability),
        is_broken and 1 or 0,
        model,
        plate,
    })
end

local function emit_breakdown(payload)
    TriggerEvent('sonar:farm:machinery:broke_down', payload)
end

local function emit_repaired(payload)
    TriggerEvent('sonar:farm:machinery:repaired', payload)
end

function MachineryService.Boot()
    local machinery = get_machinery_config()
    local model_count = 0
    for _, config in pairs(machinery.Models or {}) do
        if type(config) == 'table' then
            model_count = model_count + 1
        end
    end

    log_info(('Machinery boot ready: %d models registered, threshold=%d, usage=%ss/durability'):format(
        model_count,
        get_break_threshold(),
        get_usage_settings().seconds_per_durability
    ))

    return true
end

function MachineryService.GetState(plate)
    local normalized_plate = sanitize_plate(plate)
    if not normalized_plate then
        return nil, 'invalid_plate'
    end

    local row = fetch_state_row(normalized_plate)
    if not row then
        return nil, 'machinery_not_found'
    end

    return build_state_payload(row), nil
end

function MachineryService.RecordUsage(plate, amount, model)
    local normalized_plate = sanitize_plate(plate)
    if not normalized_plate then
        return false, nil, 'invalid_plate'
    end

    if not is_valid_usage_amount(amount) then
        return false, nil, 'invalid_usage_amount'
    end

    local model_config, normalized_model = get_model_config(model)
    if model ~= nil and not model_config then
        return false, nil, 'invalid_machinery_model'
    end

    local existing = fetch_state_row(normalized_plate)
    local stored_model = normalize_model(existing and existing.model or nil)
    local active_model = normalized_model or stored_model
    local active_model_config = model_config

    if active_model and not active_model_config then
        active_model_config = get_model_registry()[active_model]
    end

    if active_model and type(active_model_config) ~= 'table' then
        return false, nil, 'invalid_machinery_model'
    end

    if not active_model then
        return false, nil, 'machinery_model_required'
    end

    local wear_delta = get_usage_delta(amount, active_model_config.wear_multiplier)
    local durability_before = existing and clamp_durability(existing.durability) or get_default_durability()
    local durability_after = clamp_durability(durability_before - wear_delta)
    local was_broken = existing and (tonumber(existing.is_broken) == 1 or existing.is_broken == true) or false
    local should_break = was_broken

    if durability_after <= 0 then
        should_break = true
    elseif durability_after <= get_break_threshold() then
        local chance_roll = math.random(1, 100)
        should_break = chance_roll <= get_breakdown_chance_pct()
    end

    if not existing then
        insert_state(normalized_plate, active_model, durability_after, should_break)
    else
        update_state(normalized_plate, durability_after, should_break, normalized_model)
    end

    local state = {
        plate = normalized_plate,
        model = active_model,
        durability = durability_after,
        is_broken = should_break,
        usage_amount = amount,
        wear_delta = wear_delta,
    }

    if should_break and not was_broken then
        emit_breakdown(state)
    end

    return true, state, nil
end

function MachineryService.Repair(plate)
    local normalized_plate = sanitize_plate(plate)
    if not normalized_plate then
        return false, nil, 'invalid_plate'
    end

    local existing = fetch_state_row(normalized_plate)
    if not existing then
        return false, nil, 'machinery_not_found'
    end

    local repaired_durability = clamp_durability(get_machinery_config().Repair.restore_durability or 100)
    update_state(normalized_plate, repaired_durability, false, nil)

    local payload = {
        plate = normalized_plate,
        model = existing.model,
        durability = repaired_durability,
        is_broken = false,
    }

    emit_repaired(payload)
    return true, payload, nil
end

Sonar.Farm.MachineryService = MachineryService
