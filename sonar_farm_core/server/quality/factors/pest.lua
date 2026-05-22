Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Quality = Sonar.Farm.Quality or {}
Sonar.Farm.Quality.Factors = Sonar.Farm.Quality.Factors or {}

local PestFactor = {}
local FACTOR_NAME = 'pest_impact'
local DEFAULT_SCORE = 100
local active_pest_types = {}

local function configured_default()
    local quality_config = Config and Config.Farm and Config.Farm.Quality or nil
    local defaults = quality_config and quality_config.NeutralDefaults or nil
    return defaults and defaults.pest_impact or DEFAULT_SCORE
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

local function get_active_crop(plot_id)
    local db = get_db()
    if not db then
        return nil
    end

    return db.row('SELECT `crop_type` FROM `sonar_farm_crops` WHERE `plot_id` = ? LIMIT 1', { plot_id })
end

local function get_crop_pest_config(crop_type)
    local crops = Config and Config.Farm and Config.Farm.Crops or nil
    local crop = crops and crops[crop_type] or nil
    return crop and crop.pests or nil
end

function PestFactor:track(plot_id, event, data)
    local db = get_db()
    if not db then
        return false, 'Sonar.Farm.DB is unavailable'
    end

    local score = clamp_score(data and (data.pest_impact or data.score))
    db.execute([[
        INSERT INTO `sonar_farm_quality_tracking` (`plot_id`, `pest_impact`, `calculated_at`)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE
            `pest_impact` = VALUES(`pest_impact`),
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

function PestFactor:get(plot_id)
    local db = get_db()
    if not db then
        return configured_default()
    end

    local row = db.row('SELECT `pest_impact` FROM `sonar_farm_quality_tracking` WHERE `plot_id` = ? LIMIT 1', { plot_id })
    if not row then
        return configured_default()
    end

    return clamp_score(row.pest_impact)
end

function PestFactor.GetStatus(plot_id)
    local db = get_db()
    if not db or type(plot_id) ~= 'string' or plot_id == '' then
        return nil
    end

    local row = db.row('SELECT `pest_detected_ts`, `pest_severity` FROM `sonar_farm_quality_tracking` WHERE `plot_id` = ? LIMIT 1', { plot_id })
    if not row or row.pest_severity == nil or row.pest_severity == 'none' then
        return nil
    end

    return {
        severity = row.pest_severity,
        detected_ts = tonumber(row.pest_detected_ts),
    }
end

function PestFactor.GetActivePestType(plot_id)
    return active_pest_types[plot_id]
end

function PestFactor.Appear(plot_id, pest_type)
    if type(plot_id) ~= 'string' or plot_id == '' then
        return false, 'plot_id must be a non-empty string'
    end

    if type(pest_type) ~= 'string' or pest_type == '' then
        return false, 'pest_type must be a non-empty string'
    end

    if PestFactor.GetStatus(plot_id) ~= nil then
        return false, 'pest already active'
    end

    local db = get_db()
    if not db then
        return false, 'Sonar.Farm.DB is unavailable'
    end

    local current_score = PestFactor:get(plot_id)
    local detected_ts = os.time()
    db.execute('UPDATE `sonar_farm_quality_tracking` SET `pest_detected_ts` = ?, `pest_severity` = ? WHERE `plot_id` = ?', {
        detected_ts,
        'detected',
        plot_id,
    })
    active_pest_types[plot_id] = pest_type

    local ok, score_or_error = PestFactor:track(plot_id, 'pest_appeared', { score = current_score })
    if not ok then
        return false, score_or_error
    end

    TriggerEvent('sonar:farm:pest:appeared', {
        plot_id = plot_id,
        pest_type = pest_type,
        detected_ts = detected_ts,
        severity = 'detected',
    })

    return true, nil
end

function PestFactor.Treat(plot_id, pesticide_item)
    if type(plot_id) ~= 'string' or plot_id == '' then
        return false, nil, 'plot_id must be a non-empty string'
    end

    if type(pesticide_item) ~= 'string' or pesticide_item == '' then
        return false, nil, 'pesticide_item must be a non-empty string'
    end

    local status = PestFactor.GetStatus(plot_id)
    if not status then
        return false, nil, 'no active pest'
    end

    local active_crop = get_active_crop(plot_id)
    if not active_crop or type(active_crop.crop_type) ~= 'string' or active_crop.crop_type == '' then
        return false, nil, 'active crop not found'
    end

    local crop_config = get_crop_pest_config(active_crop.crop_type)
    if type(crop_config) ~= 'table' then
        return false, nil, ('crop_type "%s" is missing pest config'):format(active_crop.crop_type)
    end

    local current_score = PestFactor:get(plot_id)
    local new_score
    if status.severity == 'severe' then
        new_score = math.min(100, tonumber(crop_config.severe_treat_ceiling) or 60)
    else
        new_score = math.min(100, current_score + (tonumber(crop_config.treat_score_restore) or 30))
    end

    local ok, score_or_error = PestFactor:track(plot_id, 'pest_treated', { score = new_score })
    if not ok then
        return false, nil, score_or_error
    end

    local db = get_db()
    db.execute('UPDATE `sonar_farm_quality_tracking` SET `pest_detected_ts` = NULL, `pest_severity` = ? WHERE `plot_id` = ?', {
        'none',
        plot_id,
    })
    active_pest_types[plot_id] = nil

    TriggerEvent('sonar:farm:pest:treated', {
        plot_id = plot_id,
        pesticide_item = pesticide_item,
        new_score = clamp_score(new_score),
        severity = status.severity,
    })

    return true, clamp_score(new_score), nil
end

Sonar.Farm.Quality.Factors.Pest = PestFactor