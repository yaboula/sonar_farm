Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Quality = Sonar.Farm.Quality or {}
Sonar.Farm.Quality.Factors = Sonar.Farm.Quality.Factors or {}

local IrrigationFactor = {}
local FACTOR_NAME = 'irrigation'
local DEFAULT_SCORE = 70
local stage_application_cache = {}

local function configured_default()
    local quality_config = Config and Config.Farm and Config.Farm.Quality or nil
    local defaults = quality_config and quality_config.NeutralDefaults or nil
    return defaults and defaults.irrigation or DEFAULT_SCORE
end

local function clamp_score(value)
    local score = tonumber(value) or configured_default()
    if score < 0 then
        return 0
    end
    if score > 100 then
        return 100
    end
    return math.floor(score + 0.5)
end

local function get_db()
    return Sonar and Sonar.Farm and Sonar.Farm.DB or nil
end

local function get_irrigation_config()
    local farm_config = Config and Config.Farm or nil
    return farm_config and farm_config.Irrigation or {}
end

local function reset_stage_cache(plot_id)
    if type(plot_id) ~= 'string' or plot_id == '' then
        return
    end

    stage_application_cache[plot_id] = nil
end

if type(AddEventHandler) == 'function' then
    AddEventHandler('sonar:farm:plot:stage_advanced', function(payload)
        local plot_id = type(payload) == 'table' and payload.plot_id or nil
        reset_stage_cache(plot_id)
    end)
end

function IrrigationFactor:track(plot_id, event, data)
    local db = get_db()
    if not db then
        return false, 'Sonar.Farm.DB is unavailable'
    end

    local score = clamp_score(data and (data.irrigation or data.score))
    db.execute([[
        INSERT INTO `sonar_farm_quality_tracking` (`plot_id`, `irrigation`, `calculated_at`)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE
            `irrigation` = VALUES(`irrigation`),
            `calculated_at` = VALUES(`calculated_at`)
    ]], { plot_id, score, os.time() })

    TriggerEvent('sonar:farm:quality:tracked', {
        plot_id = plot_id,
        factor = FACTOR_NAME,
        event = event,
        score = score,
        tracked_at = os.time(),
    })

    return true, score
end

function IrrigationFactor:get(plot_id)
    local db = get_db()
    if not db then
        return configured_default()
    end

    local row = db.row('SELECT `irrigation` FROM `sonar_farm_quality_tracking` WHERE `plot_id` = ? LIMIT 1', { plot_id })
    if not row then
        return configured_default()
    end

    return clamp_score(row.irrigation)
end

function IrrigationFactor.TrackWatering(plot_id, charges_used, stage)
    if type(plot_id) ~= 'string' or plot_id == '' then
        return false, nil, 'plot_id must be a non-empty string'
    end

    local stage_number = tonumber(stage)
    if not stage_number then
        return false, nil, 'stage must be a number'
    end

    local db = get_db()
    if not db then
        return false, nil, 'Sonar.Farm.DB is unavailable'
    end

    local current_score = IrrigationFactor:get(plot_id)
    local irrigation_config = get_irrigation_config()
    local plot_cache = stage_application_cache[plot_id] or {}
    local next_count = (tonumber(plot_cache[stage_number]) or 0) + 1
    plot_cache[stage_number] = next_count
    stage_application_cache[plot_id] = plot_cache

    local new_score
    local event_name
    if next_count >= (tonumber(irrigation_config.overwater_threshold) or 3) then
        new_score = math.max(
            current_score - (tonumber(irrigation_config.score_loss_overwater) or 15),
            tonumber(irrigation_config.overwater_floor) or 50
        )
        event_name = 'overwatered'
    else
        new_score = math.min(
            current_score + (tonumber(irrigation_config.score_gain_per_water) or 10),
            tonumber(irrigation_config.optimal_ceiling) or 90
        )
        event_name = 'watered'
    end

    local ok, score_or_error = IrrigationFactor:track(plot_id, event_name, { score = new_score })
    if not ok then
        return false, nil, score_or_error
    end

    local crop = db.row('SELECT `next_stage_ts` FROM `sonar_farm_crops` WHERE `plot_id` = ? LIMIT 1', { plot_id })
    if crop and crop.next_stage_ts ~= nil then
        db.execute('UPDATE `sonar_farm_quality_tracking` SET `next_irrigation_due_ts` = ? WHERE `plot_id` = ?', {
            tonumber(crop.next_stage_ts),
            plot_id,
        })
    end

    TriggerEvent('sonar:farm:plot:watered', {
        plot_id = plot_id,
        charges_used = tonumber(charges_used) or 1,
        new_score = clamp_score(new_score),
        stage = stage_number,
    })

    return true, clamp_score(new_score), nil
end

Sonar.Farm.Quality.Factors.Irrigation = IrrigationFactor