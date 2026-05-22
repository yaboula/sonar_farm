Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Quality = Sonar.Farm.Quality or {}
Sonar.Farm.Quality.Factors = Sonar.Farm.Quality.Factors or {}

local FertilizationFactor = {}
local FACTOR_NAME = 'fertilization'
local DEFAULT_SCORE = 70
local stage_application_cache = {}

local function configured_default()
    local quality_config = Config and Config.Farm and Config.Farm.Quality or nil
    local defaults = quality_config and quality_config.NeutralDefaults or nil
    return defaults and defaults.fertilization or DEFAULT_SCORE
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

local function get_crop_fertilization_config(crop_type)
    local crops = Config and Config.Farm and Config.Farm.Crops or nil
    local crop = crops and crops[crop_type] or nil
    return crop and crop.fertilization or nil
end

local function item_is_optimal(item_name, optimal_items)
    if type(optimal_items) ~= 'table' then
        return false
    end

    for index = 1, #optimal_items do
        if optimal_items[index] == item_name then
            return true
        end
    end

    return false
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

function FertilizationFactor:track(plot_id, event, data)
    local db = get_db()
    if not db then
        return false, 'Sonar.Farm.DB is unavailable'
    end

    local score = clamp_score(data and (data.fertilization or data.score))
    db.execute([[
        INSERT INTO `sonar_farm_quality_tracking` (`plot_id`, `fertilization`, `calculated_at`)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE
            `fertilization` = VALUES(`fertilization`),
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

function FertilizationFactor:get(plot_id)
    local db = get_db()
    if not db then
        return configured_default()
    end

    local row = db.row('SELECT `fertilization` FROM `sonar_farm_quality_tracking` WHERE `plot_id` = ? LIMIT 1', { plot_id })
    if not row then
        return configured_default()
    end

    return clamp_score(row.fertilization)
end

function FertilizationFactor.TrackApplication(plot_id, item_name, crop_type, stage)
    if type(plot_id) ~= 'string' or plot_id == '' then
        return false, nil, 'plot_id must be a non-empty string'
    end

    if type(item_name) ~= 'string' or item_name == '' then
        return false, nil, 'item_name must be a non-empty string'
    end

    if type(crop_type) ~= 'string' or crop_type == '' then
        return false, nil, 'crop_type must be a non-empty string'
    end

    local stage_number = tonumber(stage)
    if not stage_number then
        return false, nil, 'stage must be a number'
    end

    local crop_config = get_crop_fertilization_config(crop_type)
    if type(crop_config) ~= 'table' then
        return false, nil, ('crop_type "%s" is missing fertilization config'):format(crop_type)
    end

    local current_score = FertilizationFactor:get(plot_id)
    local plot_cache = stage_application_cache[plot_id] or {}
    local next_count = (tonumber(plot_cache[stage_number]) or 0) + 1
    plot_cache[stage_number] = next_count
    stage_application_cache[plot_id] = plot_cache

    local new_score
    local event_name
    if next_count > (tonumber(crop_config.max_applications_per_stage) or 1) then
        new_score = tonumber(crop_config.overfertilize_floor) or 40
        event_name = 'overfertilized'
    elseif item_is_optimal(item_name, crop_config.optimal_items) then
        new_score = math.min(
            current_score + (tonumber(crop_config.score_gain_correct) or 15),
            tonumber(crop_config.ceiling) or 90
        )
        event_name = 'fertilized_correct'
    else
        new_score = math.max(current_score + (tonumber(crop_config.wrong_penalty) or -5), 0)
        event_name = 'fertilized_wrong'
    end

    local ok, score_or_error = FertilizationFactor:track(plot_id, event_name, { score = new_score })
    if not ok then
        return false, nil, score_or_error
    end

    TriggerEvent('sonar:farm:plot:fertilized', {
        plot_id = plot_id,
        item_name = item_name,
        new_score = clamp_score(new_score),
        stage = stage_number,
        crop_type = crop_type,
    })

    return true, clamp_score(new_score), nil
end

Sonar.Farm.Quality.Factors.Fertilization = FertilizationFactor