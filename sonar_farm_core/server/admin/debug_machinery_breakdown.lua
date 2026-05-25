-- Debug command to force machinery breakdown for testing
-- Usage: /sonarfarm:debug:machinery_breakdown <plate>

Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}

local function t(key, ...)
    return locale(key, ...)
end

local function log_line(target_src, line)
    if target_src == 0 then
        print(line)
    else
        TriggerClientEvent('chat:addMessage', target_src, {
            color = Config.Farm.Chat.BrandColor,
            args = { t('ui.brand_name'), line },
        })
    end
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

local function get_db()
    return Sonar and Sonar.Farm and Sonar.Farm.DB or nil
end

local function get_machinery_service()
    return Sonar and Sonar.Farm and Sonar.Farm.MachineryService or nil
end

local function is_debug_allowed(caller_src)
    if not Config or not Config.Farm or Config.Farm.Debug ~= true then
        log_line(caller_src, t('debug.machinery.disabled'))
        return false
    end

    if caller_src > 0 and not IsPlayerAceAllowed(caller_src, 'sonar.farm.admin') then
        log_line(caller_src, t('debug.machinery.ace_required'))
        return false
    end

    return true
end

local function log_state(caller_src, state)
    local model = type(state.model) == 'string' and state.model ~= '' and state.model or 'unknown'
    local broken_label = state.is_broken and t('debug.machinery.yes') or t('debug.machinery.no')
    log_line(caller_src, t('debug.machinery.state_line', state.plate, model, state.durability, broken_label))
end

local function run_status(caller_src, plate)
    local service = get_machinery_service()
    if not service or type(service.GetState) ~= 'function' then
        log_line(caller_src, t('debug.machinery.unavailable'))
        return
    end

    local normalized_plate = sanitize_plate(plate)
    if not normalized_plate then
        log_line(caller_src, t('debug.machinery.usage_status'))
        return
    end

    local state, err = service.GetState(normalized_plate)
    if not state then
        log_line(caller_src, t('debug.machinery.state_failed', normalized_plate, tostring(err or 'unknown')))
        return
    end

    log_state(caller_src, state)
end

local function run_usage(caller_src, plate, amount, model)
    local service = get_machinery_service()
    if not service or type(service.RecordUsage) ~= 'function' then
        log_line(caller_src, t('debug.machinery.unavailable'))
        return
    end

    local normalized_plate = sanitize_plate(plate)
    local usage_amount = tonumber(amount)
    if not normalized_plate or not usage_amount then
        log_line(caller_src, t('debug.machinery.usage_use'))
        return
    end

    local ok, state, err = service.RecordUsage(normalized_plate, usage_amount, model)
    if not ok then
        log_line(caller_src, t('debug.machinery.use_failed', normalized_plate, tostring(err or 'unknown')))
        return
    end

    log_line(caller_src, t('debug.machinery.use_ok', normalized_plate, usage_amount, state.wear_delta or 0))
    log_state(caller_src, state)
end

local function run_breakdown(caller_src, plate, durability)
    local service = get_machinery_service()
    local db = get_db()
    if not service or type(service.GetState) ~= 'function' then
        log_line(caller_src, t('debug.machinery.unavailable'))
        return
    end

    if not db or type(db.execute) ~= 'function' then
        log_line(caller_src, t('debug.machinery.db_unavailable'))
        return
    end

    local normalized_plate = sanitize_plate(plate)
    if not normalized_plate then
        log_line(caller_src, t('debug.machinery.usage_breakdown'))
        return
    end

    local state, err = service.GetState(normalized_plate)
    if not state then
        log_line(caller_src, t('debug.machinery.state_failed', normalized_plate, tostring(err or 'unknown')))
        return
    end

    local forced_durability = math.max(math.min(math.floor(tonumber(durability) or 5), 100), 0)
    db.execute([[
        UPDATE `sonar_farm_machinery_state`
        SET `durability` = ?, `is_broken` = 1
        WHERE `plate` = ?
    ]], { forced_durability, normalized_plate })

    TriggerEvent('sonar:farm:machinery:broke_down', {
        plate = normalized_plate,
        model = state.model,
        durability = forced_durability,
        is_broken = true,
    })

    log_line(caller_src, t('debug.machinery.breakdown_ok', normalized_plate, forced_durability))
end

local function run_repair(caller_src, plate)
    local service = get_machinery_service()
    if not service or type(service.Repair) ~= 'function' then
        log_line(caller_src, t('debug.machinery.unavailable'))
        return
    end

    local normalized_plate = sanitize_plate(plate)
    if not normalized_plate then
        log_line(caller_src, t('debug.machinery.usage_repair'))
        return
    end

    local ok, state, err = service.Repair(normalized_plate)
    if not ok then
        log_line(caller_src, t('debug.machinery.repair_failed', normalized_plate, tostring(err or 'unknown')))
        return
    end

    log_line(caller_src, t('debug.machinery.repair_ok', normalized_plate))
    log_state(caller_src, state)
end

RegisterCommand('sonarfarm:debug:machinery_status', function(source, args)
    local caller_src = tonumber(source) or 0
    if not is_debug_allowed(caller_src) then
        return
    end

    run_status(caller_src, args[1])
end, false)

RegisterCommand('sonarfarm:debug:machinery_use', function(source, args)
    local caller_src = tonumber(source) or 0
    if not is_debug_allowed(caller_src) then
        return
    end

    run_usage(caller_src, args[1], args[2], args[3])
end, false)

RegisterCommand('sonarfarm:debug:machinery_breakdown', function(source, args)
    local caller_src = tonumber(source) or 0
    if not is_debug_allowed(caller_src) then
        return
    end

    run_breakdown(caller_src, args[1], args[2])
end, false)

RegisterCommand('sonarfarm:debug:machinery_repair', function(source, args)
    local caller_src = tonumber(source) or 0
    if not is_debug_allowed(caller_src) then
        return
    end

    run_repair(caller_src, args[1])
end, false)
